// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// A client that returns [responses] in order and records the requests.
MockClient _mockClient(
  List<http.Request> requests,
  List<http.Response Function()> responses,
) => MockClient((request) async {
  requests.add(request);
  if (requests.length > responses.length) {
    throw StateError('Unexpected request: ${request.method} ${request.url}');
  }
  return responses[requests.length - 1]();
});

http.Response _unavailable() => http.Response('', 503);

http.Response _ok() => http.Response('{}', 200);

void main() {
  late List<http.Request> requests;

  setUp(() => requests = []);

  group('client retry', () {
    test('is used for idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      await storage.bucketMetadata('bucket');
      expect(requests, hasLength(2));
    });

    test('is not used for non-idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      await expectLater(
        storage.deleteBucketAcl('bucket', 'allUsers'),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });

    test('is used if a precondition makes the operation idempotent', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok, _unavailable, _ok]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      await storage.deleteBucket('bucket', ifMetagenerationMatch: BigInt.one);
      expect(requests, hasLength(2));

      await expectLater(
        storage.deleteBucket('bucket'),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(3));
    });

    test('noRetry disables retries', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
        retry: noRetry,
      );

      await expectLater(
        storage.bucketMetadata('bucket'),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });
  });

  group('call retry', () {
    test('is used for non-idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await storage.deleteBucketAcl(
        'bucket',
        'allUsers',
        retry: const NoDelayRetry(),
      );
      expect(requests, hasLength(2));
    });

    test('overrides the client retry', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
        retry: noRetry,
      );

      await storage.bucketMetadata('bucket', retry: const NoDelayRetry());
      expect(requests, hasLength(2));
    });

    test('noRetry disables retries', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      await expectLater(
        storage.bucketMetadata('bucket', retry: noRetry),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });
  });

  test('listObjects retries each page separately', () async {
    final storage = Storage(
      client: _mockClient(requests, [
        () => http.Response(
          '{"items": [{"name": "a"}], "nextPageToken": "page2"}',
          200,
        ),
        _unavailable,
        () => http.Response('{"items": [{"name": "b"}]}', 200),
      ]),
      projectId: 'project',
      retry: const NoDelayRetry(),
    );

    final objects = await storage.listObjects('bucket').toList();

    expect(objects.map((o) => o.name), ['a', 'b']);
    expect(requests, hasLength(3));
    expect(requests[0].url.queryParameters['pageToken'], isNull);
    expect(requests[1].url.queryParameters['pageToken'], 'page2');
    expect(requests[2].url.queryParameters['pageToken'], 'page2');
  });

  group('uploadObjectFromSink', () {
    http.Response session() => http.Response(
      '',
      200,
      headers: {'location': 'https://example.com/session'},
    );

    test('does not retry starting a non-idempotent upload', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, session]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      final sink = storage.uploadObjectFromSink('bucket', 'object')
        ..add([1, 2, 3]);
      await expectLater(
        sink.close(),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });

    test('retries starting an idempotent upload', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, session, _ok]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      final sink = storage.uploadObjectFromSink(
        'bucket',
        'object',
        ifGenerationMatch: BigInt.zero,
      )..add([1, 2, 3]);
      await sink.close();
      expect(requests.map((r) => r.method), ['POST', 'POST', 'PUT']);
    });

    test('retries uploading data with the client retry', () async {
      final storage = Storage(
        client: _mockClient(requests, [
          session,
          () => throw http.ClientException('connection reset'),
          // The status check finds that the upload is complete.
          _ok,
        ]),
        projectId: 'project',
        retry: const NoDelayRetry(),
      );

      final sink = storage.uploadObjectFromSink('bucket', 'object')
        ..add([1, 2, 3]);
      await sink.close();
      expect(requests.map((r) => r.method), ['POST', 'PUT', 'PUT']);
      expect(requests.last.headers['Content-Range'], 'bytes */*');
    });
  });
}
