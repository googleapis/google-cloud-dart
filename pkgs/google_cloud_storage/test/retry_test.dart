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

import 'dart:async';

import 'package:google_cloud_rpc/rpc.dart' show Status;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _noDelayRetry = NoDelayRetry(retryIf: isTransientError);

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

/// Runs [body] with timers that fire immediately, so that [defaultRetry]
/// retries without waiting.
Future<T> _withoutDelays<T>(Future<T> Function() body) => runZoned(
  body,
  zoneSpecification: ZoneSpecification(
    createTimer: (self, parent, zone, duration, callback) =>
        parent.createTimer(zone, Duration.zero, callback),
  ),
);

void main() {
  late List<http.Request> requests;

  setUp(() => requests = []);

  group('default retry', () {
    test('is used for idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await _withoutDelays(() => storage.bucketMetadata('bucket'));
      expect(requests, hasLength(2));
    });

    test('is not used for non-idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await expectLater(
        _withoutDelays(() => storage.deleteBucketAcl('bucket', 'allUsers')),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });

    test('is used if a precondition makes the operation idempotent', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok, _unavailable, _ok]),
        projectId: 'project',
      );

      await _withoutDelays(
        () => storage.deleteObject(
          'bucket',
          'object',
          ifGenerationMatch: BigInt.one,
        ),
      );
      expect(requests, hasLength(2));

      await expectLater(
        _withoutDelays(() => storage.deleteObject('bucket', 'object')),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(3));
    });
  });

  group('call retry', () {
    test('is used for idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _unavailable, _ok]),
        projectId: 'project',
      );

      await storage.bucketMetadata('bucket', retry: _noDelayRetry);
      expect(requests, hasLength(3));
    });

    test('is used for non-idempotent operations', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await storage.deleteBucketAcl('bucket', 'allUsers', retry: _noDelayRetry);
      expect(requests, hasLength(2));
    });

    test('noRetry disables retries', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await expectLater(
        storage.bucketMetadata('bucket', retry: noRetry),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });
  });

  // See https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency
  group('idempotency', () {
    test('deleting a bucket is always idempotent', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, _ok]),
        projectId: 'project',
      );

      await _withoutDelays(() => storage.deleteBucket('bucket'));
      expect(requests, hasLength(2));
    });

    test('changing an object ACL is never idempotent', () async {
      final storage = Storage(
        client: _mockClient(requests, [
          _unavailable,
          _unavailable,
          _unavailable,
        ]),
        projectId: 'project',
      );
      final generation = BigInt.one;

      await _withoutDelays(() async {
        await expectLater(
          storage.deleteObjectAcl(
            'bucket',
            'object',
            'allUsers',
            generation: generation,
          ),
          throwsA(isA<ServiceUnavailableException>()),
        );
        await expectLater(
          storage.patchObjectAcl(
            'bucket',
            'object',
            'allUsers',
            'READER',
            generation: generation,
          ),
          throwsA(isA<ServiceUnavailableException>()),
        );
        await expectLater(
          storage.updateObjectAcl(
            'bucket',
            'object',
            'allUsers',
            'READER',
            generation: generation,
          ),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });
      expect(requests.map((r) => r.method), ['DELETE', 'PATCH', 'PUT']);
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
    );

    final objects = await _withoutDelays(
      () => storage.listObjects('bucket').toList(),
    );

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
      );

      await _withoutDelays(() async {
        final sink = storage.uploadObjectFromSink('bucket', 'object')
          ..add([1, 2, 3]);
        await expectLater(
          sink.close(),
          throwsA(isA<ServiceUnavailableException>()),
        );
      });
      expect(requests, hasLength(1));
    });

    test('retries starting an idempotent upload', () async {
      final storage = Storage(
        client: _mockClient(requests, [_unavailable, session, _ok]),
        projectId: 'project',
      );

      await _withoutDelays(() async {
        final sink = storage.uploadObjectFromSink(
          'bucket',
          'object',
          ifGenerationMatch: BigInt.zero,
        )..add([1, 2, 3]);
        await sink.close();
      });
      expect(requests.map((r) => r.method), ['POST', 'POST', 'PUT']);
    });

    test('retries uploading data of a non-idempotent upload', () async {
      final storage = Storage(
        client: _mockClient(requests, [
          session,
          () => throw http.ClientException('connection reset'),
          // The status check finds that the upload is complete.
          _ok,
        ]),
        projectId: 'project',
      );

      await _withoutDelays(() async {
        final sink = storage.uploadObjectFromSink('bucket', 'object')
          ..add([1, 2, 3]);
        await sink.close();
      });
      expect(requests.map((r) => r.method), ['POST', 'PUT', 'PUT']);
      expect(requests.last.headers['Content-Range'], 'bytes */*');
    });
  });

  group('defaultRetry', () {
    test('retries transient errors with full jitter', () {
      expect(
        defaultRetry.isRetryable(ServiceUnavailableException('503')),
        isTrue,
      );
      expect(defaultRetry.isRetryable(BadRequestException('400')), isFalse);
      expect(defaultRetry.jitter, 1.0);
    });
  });

  group('isTransientError', () {
    test('classifies retryable exceptions', () {
      expect(isTransientError(TooManyRequestsException('429')), isTrue);
      expect(isTransientError(InternalServerErrorException('500')), isTrue);
      expect(isTransientError(BadGatewayException('502')), isTrue);
      expect(isTransientError(ServiceUnavailableException('503')), isTrue);
      expect(isTransientError(GatewayTimeoutException('504')), isTrue);
      expect(isTransientError(RequestTimeoutException('408')), isTrue);
      expect(isTransientError(http.ClientException('network')), isTrue);
      expect(
        isTransientError(ChecksumValidationException('bad checksum')),
        isTrue,
      );
      expect(
        isTransientError(
          ConflictException('aborted', status: Status(code: 10)),
        ),
        isTrue,
      );
      expect(
        isTransientError(
          ServiceException(
            'unavailable',
            statusCode: 0,
            status: Status(code: 14),
          ),
        ),
        isTrue,
      );
    });

    test('classifies non-retryable exceptions', () {
      expect(isTransientError(BadRequestException('400')), isFalse);
      expect(isTransientError(NotFoundException('404')), isFalse);
      expect(isTransientError(ConflictException('409')), isFalse);
      expect(
        isTransientError(
          InternalServerErrorException('data loss', status: Status(code: 15)),
        ),
        isFalse,
      );
      expect(
        isTransientError(
          ServiceException('invalid', statusCode: 0, status: Status(code: 3)),
        ),
        isFalse,
      );
      expect(isTransientError(const FormatException('bad json')), isFalse);
    });

    test('does not retry errors', () {
      expect(isTransientError(StateError('bug')), isFalse);
    });
  });
}
