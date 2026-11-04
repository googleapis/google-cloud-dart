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
import 'package:google_cloud_storage/src/user_agent_web.dart'
    if (dart.library.io) 'package:google_cloud_storage/src/user_agent_vm.dart';
import 'package:google_cloud_storage/src/version.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _isVm = bool.fromEnvironment('dart.library.io');
const _expectedUserAgent = _isVm ? 'gcloud-dart/$packageVersion' : null;

void main() {
  group('user agent header', () {
    test('sets default User-Agent on JSON RPC requests on VM', () async {
      late http.Request actualRequest;
      final mockClient = MockClient((request) async {
        actualRequest = request;
        return http.Response('{"items": []}', 200);
      });

      final storage = Storage(client: mockClient, projectId: 'test-project');
      addTearDown(storage.close);

      await storage.listBuckets().drain<Object?>();

      expect(actualRequest.headers['user-agent'], _expectedUserAgent);
      expect(
        actualRequest.headers['x-goog-api-client'],
        contains('gccl/$packageVersion'),
      );
    });

    test('sets default User-Agent on media downloads on VM', () async {
      late http.Request actualRequest;
      final mockClient = MockClient((request) async {
        actualRequest = request;
        return http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {'x-goog-stored-content-encoding': 'identity'},
        );
      });

      final storage = Storage(client: mockClient, projectId: 'test-project');
      addTearDown(storage.close);

      await storage.downloadObject('test-bucket', 'test-obj');

      expect(actualRequest.headers['user-agent'], _expectedUserAgent);
    });

    test('sets default User-Agent on multipart uploads on VM', () async {
      late http.Request actualRequest;
      final mockClient = MockClient((request) async {
        actualRequest = request;
        return http.Response(
          '{"name": "test-obj", "bucket": "test-bucket"}',
          200,
        );
      });

      final storage = Storage(client: mockClient, projectId: 'test-project');
      addTearDown(storage.close);

      await storage.uploadObject('test-bucket', 'test-obj', [1, 2, 3]);

      expect(actualRequest.headers['user-agent'], _expectedUserAgent);
    });

    test('sets default User-Agent on resumable uploads on VM', () async {
      final actualRequests = <http.Request>[];
      final mockClient = MockClient((request) async {
        actualRequests.add(request);
        if (request.method == 'POST') {
          return http.Response(
            '',
            200,
            headers: {
              'location': 'https://storage.googleapis.com/upload-session',
            },
          );
        }
        return http.Response(
          '{"name": "test-obj", "bucket": "test-bucket"}',
          200,
        );
      });

      final storage = Storage(client: mockClient, projectId: 'test-project');
      addTearDown(storage.close);

      final sink = storage.uploadObjectFromSink('test-bucket', 'test-obj')
        ..add([1, 2, 3]);
      await sink.close();

      expect(actualRequests, hasLength(2));
      expect(
        actualRequests,
        everyElement(
          (http.Request r) => r.headers['user-agent'] == _expectedUserAgent,
        ),
      );
    });

    test('sets default User-Agent when passed async client on VM', () async {
      late http.Request actualRequest;
      final mockClient = MockClient((request) async {
        actualRequest = request;
        return http.Response('{"items": []}', 200);
      });

      final storage = Storage(
        client: Future.value(mockClient),
        projectId: 'test-project',
      );
      addTearDown(storage.close);

      await storage.listBuckets().drain<Object?>();

      expect(actualRequest.headers['user-agent'], _expectedUserAgent);
    });

    test('preserves caller-supplied User-Agent header', () async {
      late http.BaseRequest actualRequest;
      final mockClient = MockClient((request) async {
        actualRequest = request;
        return http.Response('{"items": []}', 200);
      });

      final wrappedClient = clientWithUserAgent(mockClient);
      addTearDown(wrappedClient.close);

      final directRequest = http.Request(
        'GET',
        Uri.https('storage.googleapis.com', '/storage/v1/b'),
      )..headers['User-Agent'] = 'custom-agent/1.0.0';
      await wrappedClient.send(directRequest);

      expect(actualRequest.headers['user-agent'], 'custom-agent/1.0.0');

      final storage = Storage(
        client: _CustomUserAgentClient(mockClient, 'custom-wrapper/2.0.0'),
        projectId: 'test-project',
      );
      addTearDown(storage.close);

      await storage.listBuckets().drain<Object?>();

      expect(actualRequest.headers['user-agent'], 'custom-wrapper/2.0.0');
    });

    test('closes underlying sync and async clients', () async {
      var syncClosed = false;
      final syncClient = _TrackingCloseClient(() => syncClosed = true);
      Storage(client: syncClient, projectId: 'test-project').close();
      expect(syncClosed, isTrue);

      var asyncClosed = false;
      final asyncClient = _TrackingCloseClient(() => asyncClosed = true);
      final futureClient = Future.value(asyncClient);
      Storage(client: futureClient, projectId: 'test-project').close();
      await pumpEventQueue();
      expect(asyncClosed, isTrue);
    });
  });
}

final class _CustomUserAgentClient extends http.BaseClient {
  final http.Client _inner;
  final String _userAgent;

  _CustomUserAgentClient(this._inner, this._userAgent);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = _userAgent;
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final class _TrackingCloseClient extends http.BaseClient {
  final void Function() _onClose;

  _TrackingCloseClient(this._onClose);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(const Stream.empty(), 200);

  @override
  void close() => _onClose();
}
