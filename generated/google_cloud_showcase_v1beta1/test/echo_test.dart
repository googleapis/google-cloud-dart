// Copyright 2025 Google LLC
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

/// Derived from the equivalent tests for:
/// - [go](https://github.com/googleapis/gapic-showcase/blob/main/server/services/echo_service_test.go)
/// - [rust](https://github.com/googleapis/google-cloud-rust/blob/main/src/integration-tests/src/showcase/echo.rs)
@TestOn('vm')
library;

import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:google_cloud_rpc/rpc.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/insecure_proxy_http_client.dart';

import 'showcase_server.dart';

Matcher anyTypeName(dynamic matcher) => const TypeMatcher<protobuf.Any>()
    .having((a) => a.typeName, 'typeName', matcher);

void main() async {
  late Echo echoService;
  late ShowcaseServer showcaseServer;
  group('echo', () {
    setUpAll(() async {
      showcaseServer = await ShowcaseServer.start();
      echoService = Echo(client: InsecureProxyHttpClient(http.Client()));
    });

    tearDownAll(() async {
      echoService.close();
      await showcaseServer.stop();
    });

    test('echo content', () async {
      const content = 'hello world';
      final response = await echoService.echo(
        EchoRequest(content: content, severity: Severity.critical),
      );
      expect(response.content, content);
      expect(response.severity, Severity.critical);
    });

    test('echo error', () async {
      await expectLater(
        () => echoService.echo(
          EchoRequest(
            error: Status(
              code: 3, // INVALID_ARGUMENT
            ),
          ),
        ),
        throwsA(
          isA<StatusException>().having(
            (e) => e.status.code,
            'status.code',
            400, // HTTP equivalent of INVALID_ARGUMENT
          ),
        ),
      );
    });

    test(
      'request_id unset',
      () async {
        final response = await echoService.echo(
          EchoRequest(content: 'request_id unset'),
        );
        expect(response.requestId, isNotEmpty);
        expect(response.otherRequestId, isNotEmpty);
      },
      skip: 'https://github.com/googleapis/google-cloud-dart/issues/80',
    );

    test('request_id custom', () async {
      const requestId = '92500ce6-fba2-4fc5-92ad-b7250282c2fc';
      const otherRequestId = '7289ea3a-7f36-44e7-ac2f-3d906f199c3c';
      final response = await echoService.echo(
        EchoRequest(
          content: 'request_id custom',
          requestId: requestId,
          otherRequestId: otherRequestId,
        ),
      );
      expect(response.requestId, requestId);
      expect(response.otherRequestId, otherRequestId);
    });

    test('error details', () async {
      const text = 'the quick brown fox jumps over the lazy dog';
      final request = EchoErrorDetailsRequest(
        singleDetailText: text,
        multiDetailText: [text, text],
      );

      final response = await echoService.echoErrorDetails(request);

      final details = response.singleDetail!.error!.details!;
      final info = details.unpackFrom(ErrorInfo.fromJson);
      expect(info.reason, text);
    });

    test('fail with details', () async {
      const text = 'the quick brown fox jumps over the lazy dog';
      final request = FailEchoWithDetailsRequest(message: text);

      await expectLater(
        () => echoService.failEchoWithDetails(request),
        throwsA(
          isA<StatusException>()
              .having(
                (e) => e.status.code,
                'status.code',
                409, // Aborted
              )
              .having((e) => e.status.details, 'status.details', [
                anyTypeName('google.rpc.ErrorInfo'),
                anyTypeName('google.rpc.LocalizedMessage'),
                wrapMatcher((protobuf.Any x) {
                  final poetryError = x.unpackFrom(PoetryError.fromJson);
                  return poetryError.poem == text;
                }),
                anyTypeName('google.rpc.RetryInfo'),
                anyTypeName('google.rpc.DebugInfo'),
                anyTypeName('google.rpc.QuotaFailure'),
                anyTypeName('google.rpc.PreconditionFailure'),
                anyTypeName('google.rpc.BadRequest'),
                anyTypeName('google.rpc.RequestInfo'),
                anyTypeName('google.rpc.ResourceInfo'),
                anyTypeName('google.rpc.Help'),
              ]),
        ),
      );
    });

    test('pagination', () async {
      const content = 'The rain in Spain falls mainly on the plain!';
      final response1 = await echoService.pagedExpand(
        PagedExpandRequest(pageSize: 3, content: content),
      );
      expect(response1.responses, hasLength(3));
      expect(response1.responses.map((r) => r.content), ['The', 'rain', 'in']);
      expect(response1.nextPageToken, '3');

      final response2 = await echoService.pagedExpand(
        PagedExpandRequest(
          pageSize: 3,
          content: content,
          pageToken: response1.nextPageToken,
        ),
      );
      expect(response2.responses, hasLength(3));
      expect(response2.responses.map((r) => r.content), [
        'Spain',
        'falls',
        'mainly',
      ]);
      expect(response2.nextPageToken, '6');
    });

    test('legacy pagination', () async {
      const content = 'The rain in Spain falls mainly on the plain!';
      final response1 = await echoService.pagedExpandLegacy(
        PagedExpandLegacyRequest(maxResults: 3, content: content),
      );
      expect(response1.responses, hasLength(3));
      expect(response1.responses.map((r) => r.content), ['The', 'rain', 'in']);
      expect(response1.nextPageToken, '3');

      final response2 = await echoService.pagedExpandLegacy(
        PagedExpandLegacyRequest(
          maxResults: 3,
          content: content,
          pageToken: response1.nextPageToken,
        ),
      );
      expect(response2.responses, hasLength(3));
      expect(response2.responses.map((r) => r.content), [
        'Spain',
        'falls',
        'mainly',
      ]);
      expect(response2.nextPageToken, '6');
    });

    test('legacy mapped pagination', () async {
      const content = 'It was the best of times, it was the worst of times';
      final response = await echoService.pagedExpandLegacyMapped(
        PagedExpandRequest(content: content),
      );
      expect(
        response.alphabetized,
        equals({
          'b': PagedExpandResponseList(words: ['best']),
          'I': PagedExpandResponseList(words: ['It']),
          'i': PagedExpandResponseList(words: ['it']),
          'o': PagedExpandResponseList(words: ['of', 'of']),
          't': PagedExpandResponseList(
            words: ['the', 'times,', 'the', 'times'],
          ),
          'w': PagedExpandResponseList(words: ['was', 'was', 'worst']),
        }),
      );
    });
  });
}
