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

import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:google_cloud_protobuf/protobuf.dart' show JsonEncodable;
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:google_cloud_rpc/retry.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:google_cloud_rpc/src/version.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:meta/meta.dart' show isTest;
import 'package:test/test.dart';

class TestMessage extends JsonEncodable {
  final String message;
  TestMessage(this.message);
  @override
  Object? toJson() => message;
}

final sampleUrl = Uri.https('example.org', '/path');
final apiBaseHeaderPattern =
    r'^gl-dart/(?:3\.\d+\.\d+|0) ' +
    RegExp.escape('gax/$packageVersion ') +
    RegExp.escape('rest/$packageVersion');

/// Declares a test whose [body] runs in [fakeAsync], so time only passes when
/// [body] calls `async.elapse`.
@isTest
void fakeAsyncTest(String description, void Function(FakeAsync async) body) =>
    test(description, () => fakeAsync(body));

/// A [ServiceClient] that sends its requests with [client], for use in a
/// [fakeAsyncTest].
ServiceClient fakeAsyncService(Client client) =>
    ServiceClient(client: _FakeAsyncClient(client));

/// Gives each response from a [Client] a body whose cancellation completes on
/// fake time.
///
/// Cancelling a subscription usually returns an already-completed future from
/// the root zone. When a [StreamController]'s `onCancel` returns that future,
/// as `ServiceClient`'s timeouts do, the stream waits for it on the real event
/// loop before it delivers an error or done event, and a [fakeAsyncTest]
/// doesn't run the real event loop.
final class _FakeAsyncClient extends BaseClient {
  final Client _client;

  _FakeAsyncClient(this._client);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final response = await _client.send(request);
    late final StreamSubscription<List<int>> subscription;
    late final StreamController<List<int>> body;
    body = StreamController(
      sync: true,
      onListen: () {
        subscription = response.stream.listen(
          body.add,
          onError: body.addError,
          onDone: body.close,
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () {
        unawaited(subscription.cancel());
        return Future<void>.value();
      },
    );
    return StreamedResponse(
      body.stream,
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('non-streaming', () {
    group('requests without body', () {
      late Request actualRequest;
      final service = ServiceClient(
        client: MockClient((request) async {
          actualRequest = request;
          return Response('', 200);
        }),
      );

      for (final (method, fn) in [
        ('DELETE', service.delete),
        ('GET', service.get),
        ('PATCH', service.patch),
        ('POST', service.post),
        ('PUT', service.put),
      ]) {
        test(method, () async {
          await fn(sampleUrl);

          expect(actualRequest.method, method);
          expect(actualRequest.url, sampleUrl);
          expect(actualRequest.headers, {
            'x-goog-api-client': matches(apiBaseHeaderPattern),
          });
          expect(actualRequest.body, isEmpty);
        });
      }
    });

    test('appends gccl token when gcclVersion provided', () async {
      late Request customRequest;
      final customService = ServiceClient(
        client: MockClient((request) async {
          customRequest = request;
          return Response('', 200);
        }),
        gcclVersion: '0.6.4-wip',
      );

      await customService.get(sampleUrl);

      expect(customRequest.headers, {
        'x-goog-api-client': matches(
          apiBaseHeaderPattern + RegExp.escape(' gccl/0.6.4-wip'),
        ),
      });
      expect(
        customService.clientHeader,
        matches(apiBaseHeaderPattern + RegExp.escape(' gccl/0.6.4-wip')),
      );
    });

    test('appends gapic token when gapicVersion provided', () async {
      late Request customRequest;
      final customService = ServiceClient(
        client: MockClient((request) async {
          customRequest = request;
          return Response('', 200);
        }),
        gapicVersion: '0.1.0',
      );

      await customService.get(sampleUrl);

      expect(customRequest.headers, {
        'x-goog-api-client': matches(
          apiBaseHeaderPattern + RegExp.escape(' gapic/0.1.0'),
        ),
      });
      expect(
        customService.clientHeader,
        matches(apiBaseHeaderPattern + RegExp.escape(' gapic/0.1.0')),
      );
    });

    test(
      'appends both gapic and gccl tokens when both versions provided',
      () async {
        late Request customRequest;
        final customService = ServiceClient(
          client: MockClient((request) async {
            customRequest = request;
            return Response('', 200);
          }),
          gapicVersion: '0.1.0',
          gcclVersion: '0.2.0',
        );

        await customService.get(sampleUrl);

        expect(customRequest.headers, {
          'x-goog-api-client': matches(
            apiBaseHeaderPattern + RegExp.escape(' gapic/0.1.0 gccl/0.2.0'),
          ),
        });
        expect(
          customService.clientHeader,
          matches(
            apiBaseHeaderPattern + RegExp.escape(' gapic/0.1.0 gccl/0.2.0'),
          ),
        );
      },
    );

    group('requests with body', () {
      late Request actualRequest;
      final service = ServiceClient(
        client: MockClient((request) async {
          actualRequest = request;
          return Response('', 200);
        }),
      );

      for (final (method, fn) in [
        ('PATCH', service.patch),
        ('POST', service.post),
        ('PUT', service.put),
      ]) {
        test(method, () async {
          await fn(sampleUrl, body: TestMessage('<test payload>'));

          expect(actualRequest.method, method);
          expect(actualRequest.url, sampleUrl);
          expect(actualRequest.headers, {
            'content-type': 'application/json',
            'x-goog-api-client': matches(apiBaseHeaderPattern),
          });
          expect(actualRequest.body, '"<test payload>"');
        });
      }
    });

    test('http client exception', () async {
      final service = ServiceClient(
        client: MockClient((request) async {
          throw ClientException('network failure');
        }),
      );

      await expectLater(
        () => service.post(sampleUrl),
        throwsA(
          isA<ClientException>().having(
            (e) => e.message,
            'message',
            'network failure',
          ),
        ),
      );
    });

    test('500 response, no status, no response body', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response('', 500)),
      );

      await expectLater(
        () => service.post(sampleUrl),
        throwsA(
          isA<InternalServerErrorException>().having(
            (e) => e.message,
            'message',
            'unknown error',
          ),
        ),
      );
    });

    test('500 response, no status, with undecodable response body', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response.bytes([0xff], 500)),
      );

      await expectLater(
        () => service.post(sampleUrl),
        throwsA(
          isA<InternalServerErrorException>().having(
            (e) => e.message,
            'message',
            'unknown error',
          ),
        ),
      );
    });

    test('400 response with status', () async {
      final status = Status(code: 1, message: 'failure', details: []);
      final responseBody = jsonEncode({'error': status.toJson()});
      final service = ServiceClient(
        client: MockClient((request) async => Response(responseBody, 400)),
      );

      await expectLater(
        () => service.post(sampleUrl),
        throwsA(
          isA<BadRequestException>()
              .having((e) => e.message, 'message', 'failure')
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.status?.toJson(), 'status', status.toJson()),
        ),
      );
    });

    test('400 response, JSON response without status', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response('"Hello!"', 400)),
      );

      await expectLater(
        () => service.post(sampleUrl),
        throwsA(
          isA<BadRequestException>().having(
            (e) => e.message,
            'message',
            '"Hello!"',
          ),
        ),
      );
    });

    test('200 response, json response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response('{"fruit":"apple"}', 200),
        ),
      );

      expect(await service.post(sampleUrl), {'fruit': 'apple'});
    });
  });

  group('streaming', () {
    group('requests without body without SSE', () {
      late Request actualRequest;
      final service = ServiceClient(
        client: MockClient((request) async {
          actualRequest = request;
          return Response(
            '',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      for (final (method, fn) in [
        ('DELETE', service.deleteStreaming),
        ('GET', service.getStreaming),
        ('PATCH', service.patchStreaming),
        ('POST', service.postStreaming),
        ('PUT', service.putStreaming),
      ]) {
        test(method, () async {
          await fn(
            Uri.parse('http://example.com/'),
            enableSse: false,
          ).drain<Object?>();

          expect(actualRequest.method, method);
          expect(actualRequest.url, Uri.parse('http://example.com/'));
          expect(actualRequest.headers, {
            'x-goog-api-client': matches(apiBaseHeaderPattern),
          });
          expect(actualRequest.body, isEmpty);
        });
      }
    });

    group('requests without body with SSE', () {
      late Request actualRequest;
      final service = ServiceClient(
        client: MockClient((request) async {
          actualRequest = request;
          return Response(
            '',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      for (final (method, fn) in [
        ('DELETE', service.deleteStreaming),
        ('GET', service.getStreaming),
        ('PATCH', service.patchStreaming),
        ('POST', service.postStreaming),
        ('PUT', service.putStreaming),
      ]) {
        test(method, () async {
          await fn(
            Uri.parse('http://example.com/'),
            enableSse: true,
          ).drain<Object?>();

          expect(actualRequest.method, method);
          expect(actualRequest.url, Uri.parse('http://example.com/?alt=sse'));
          expect(actualRequest.headers, {
            'x-goog-api-client': matches(apiBaseHeaderPattern),
          });
          expect(actualRequest.body, isEmpty);
        });
      }
    });

    group('requests with body', () {
      late Request actualRequest;
      final service = ServiceClient(
        client: MockClient((request) async {
          actualRequest = request;
          return Response(
            '',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }),
      );

      for (final (method, fn) in [
        ('PATCH', service.patchStreaming),
        ('POST', service.postStreaming),
        ('PUT', service.putStreaming),
      ]) {
        test(method, () async {
          await fn(
            Uri.parse('http://example.com/'),
            body: TestMessage('<test payload>'),
            enableSse: true,
          ).drain<Object?>();

          expect(actualRequest.method, method);
          expect(actualRequest.url, Uri.parse('http://example.com/?alt=sse'));
          expect(actualRequest.headers, {
            'content-type': 'application/json',
            'x-goog-api-client': matches(apiBaseHeaderPattern),
          });
          expect(actualRequest.body, '"<test payload>"');
        });
      }
    });

    test('http client exception', () async {
      final service = ServiceClient(
        client: MockClient((request) async {
          throw ClientException('network failure');
        }),
      );

      await expectLater(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<ClientException>().having(
              (e) => e.message,
              'message',
              'network failure',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('500 response, no status, no response body', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response('', 500)),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<InternalServerErrorException>().having(
              (e) => e.message,
              'message',
              'unknown error',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('500 response, no status, with undecodable response body', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response.bytes([0xff], 500)),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<InternalServerErrorException>().having(
              (e) => e.message,
              'message',
              'unknown error',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('400 response with status', () async {
      final status = Status(code: 1, message: 'failure', details: []);
      final responseBody = jsonEncode({'error': status.toJson()});
      final service = ServiceClient(
        client: MockClient((request) async => Response(responseBody, 400)),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<BadRequestException>().having(
              (e) => e.status?.toJson(),
              'status',
              status.toJson(),
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('400 response, JSON response without status', () async {
      final service = ServiceClient(
        client: MockClient((request) async => Response('"Hello!"', 400)),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<BadRequestException>().having(
              (e) => e.message,
              'message',
              '"Hello!"',
            ),
          ),
          emitsDone,
        ]),
      );
    });

    test('200 response, unsupported content type', () async {
      var cancelled = false;
      final service = ServiceClient(
        client: MockClient.streaming(
          (request, body) async => StreamedResponse(
            StreamController<List<int>>(
              onCancel: () => cancelled = true,
            ).stream,
            200,
            headers: {'content-type': 'text/html'},
          ),
        ),
      );

      await expectLater(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          emitsError(
            isA<ServiceException>().having(
              (e) => e.message,
              'message',
              contains('text/html'),
            ),
          ),
          emitsDone,
        ]),
      );
      expect(cancelled, isTrue, reason: 'the response should be cancelled');
    });

    test('200 response, empty event stream response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async =>
              Response('', 200, headers: {'content-type': 'text/event-stream'}),
        ),
      );

      expect(service.postStreaming(sampleUrl, enableSse: true), emitsDone);
    });

    test('200 response, empty JSON list response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      expect(service.postStreaming(sampleUrl, enableSse: true), emitsDone);
    });

    test('200 response, single event stream response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            'data: {"fruit":"apple"}',
            200,
            headers: {'content-type': 'text/event-stream'},
          ),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          {'fruit': 'apple'},
          emitsDone,
        ]),
      );
    });

    test('200 response, single json response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            '[{"fruit":"apple"}]',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          {'fruit': 'apple'},
          emitsDone,
        ]),
      );
    });

    test('200 response, two data event stream responses', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            'data: {"fruit":"apple"}\ndata: {"fruit":"banana"}',
            200,
            headers: {'content-type': 'text/event-stream'},
          ),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          {'fruit': 'apple'},
          {'fruit': 'banana'},
          emitsDone,
        ]),
      );
    });

    test('200 response, two json response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            '[{"fruit":"apple"},{"fruit":"banana"}]',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          {'fruit': 'apple'},
          {'fruit': 'banana'},
          emitsDone,
        ]),
      );
    });

    test('200 response, non-data lines response', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async => Response(
            'data: {"fruit":"apple"}\nevent: ?\n\n\ndata: {"fruit":"banana"}',
            200,
            headers: {'content-type': 'text/event-stream'},
          ),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([
          {'fruit': 'apple'},
          {'fruit': 'banana'},
          emitsDone,
        ]),
      );
    });
  });

  group('retry', () {
    final payload = TestMessage('<test payload>');

    group('non-streaming', () {
      late List<Request> requests;
      late List<Response> responses;
      late ServiceClient service;

      setUp(() {
        requests = [];
        responses = [];
        service = ServiceClient(
          client: MockClient((request) async {
            requests.add(request);
            return responses.removeAt(0);
          }),
        );
      });

      Future<Map<String, dynamic>> send(
        String method, {
        RetryRunner retry = noRetry,
      }) => switch (method) {
        'DELETE' => service.delete(sampleUrl, retry: retry),
        'GET' => service.get(sampleUrl, retry: retry),
        'PATCH' => service.patch(sampleUrl, body: payload, retry: retry),
        'POST' => service.post(sampleUrl, body: payload, retry: retry),
        'PUT' => service.put(sampleUrl, body: payload, retry: retry),
        _ => throw ArgumentError.value(method, 'method'),
      };

      for (final method in ['DELETE', 'GET', 'PATCH', 'POST', 'PUT']) {
        test('$method is not retried by default', () async {
          responses.addAll([Response('', 503), Response('{}', 200)]);

          await expectLater(
            send(method),
            throwsA(isA<ServiceUnavailableException>()),
          );
          expect(requests, hasLength(1));
        });

        test('$method is retried with an identical request', () async {
          responses.addAll([
            Response('', 503),
            Response('{"fruit":"apple"}', 200),
          ]);

          expect(
            await send(
              method,
              retry: const NoDelayRetry.onCodes([Code.unavailable]),
            ),
            {'fruit': 'apple'},
          );
          expect(requests, hasLength(2));
          for (final request in requests) {
            expect(request.method, method);
            expect(request.url, sampleUrl);
            expect(request.headers, requests.first.headers);
            expect(
              request.body,
              method == 'DELETE' || method == 'GET'
                  ? isEmpty
                  : '"<test payload>"',
            );
          }
        });
      }

      test('stops when the retry budget is exhausted', () async {
        responses.addAll([for (var i = 0; i < 3; ++i) Response('', 503)]);

        await expectLater(
          send(
            'GET',
            retry: const NoDelayRetry.onCodes([
              Code.unavailable,
            ], maxRetries: 2),
          ),
          throwsA(isA<ServiceUnavailableException>()),
        );
        expect(requests, hasLength(3));
      });

      test('does not retry unmatched codes', () async {
        responses.addAll([Response('', 400), Response('{}', 200)]);

        await expectLater(
          send('GET', retry: const NoDelayRetry.onCodes([Code.unavailable])),
          throwsA(isA<BadRequestException>()),
        );
        expect(requests, hasLength(1));
      });
    });

    test('retries a failure while reading the response body', () async {
      var count = 0;
      final service = ServiceClient(
        client: MockClient.streaming((request, body) async {
          ++count;
          return count == 1
              ? StreamedResponse(
                  Stream<List<int>>.error(ClientException('connection reset')),
                  200,
                )
              : StreamedResponse(
                  Stream.value(utf8.encode('{"fruit":"apple"}')),
                  200,
                );
        }),
      );

      expect(
        await service.get(
          sampleUrl,
          retry: const NoDelayRetry.onCodes([Code.unavailable]),
        ),
        {'fruit': 'apple'},
      );
      expect(count, 2);
    });

    group('streaming', () {
      test('is not retried by default', () async {
        var count = 0;
        final service = ServiceClient(
          client: MockClient((request) async {
            ++count;
            return count == 1
                ? Response('', 503)
                : Response(
                    'data: {"fruit":"apple"}',
                    200,
                    headers: {'content-type': 'text/event-stream'},
                  );
          }),
        );

        await expectLater(
          service.postStreaming(sampleUrl, enableSse: true),
          emitsInOrder([
            emitsError(isA<ServiceUnavailableException>()),
            emitsDone,
          ]),
        );
        expect(count, 1);
      });

      test('retried until the response starts', () async {
        final requests = <Request>[];
        final service = ServiceClient(
          client: MockClient((request) async {
            requests.add(request);
            return requests.length == 1
                ? Response('', 503)
                : Response(
                    'data: {"fruit":"apple"}\ndata: {"fruit":"banana"}',
                    200,
                    headers: {'content-type': 'text/event-stream'},
                  );
          }),
        );

        await expectLater(
          service.postStreaming(
            sampleUrl,
            enableSse: true,
            body: payload,
            retry: const NoDelayRetry.onCodes([Code.unavailable]),
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            {'fruit': 'banana'},
            emitsDone,
          ]),
        );
        expect(requests, hasLength(2));
        for (final request in requests) {
          expect(
            request.url,
            Uri.https('example.org', '/path', {'alt': 'sse'}),
          );
          expect(request.body, '"<test payload>"');
        }
      });

      test('retries a failure while reading a JSON list response', () async {
        var count = 0;
        final service = ServiceClient(
          client: MockClient.streaming((request, body) async {
            ++count;
            const headers = {'content-type': 'application/json'};
            return count == 1
                ? StreamedResponse(
                    Stream<List<int>>.error(
                      ClientException('connection reset'),
                    ),
                    200,
                    headers: headers,
                  )
                : StreamedResponse(
                    Stream.value(utf8.encode('[{"fruit":"apple"}]')),
                    200,
                    headers: headers,
                  );
          }),
        );

        await expectLater(
          service.getStreaming(
            sampleUrl,
            enableSse: false,
            retry: const NoDelayRetry.onCodes([Code.unavailable]),
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            emitsDone,
          ]),
        );
        expect(count, 2);
      });

      test('not retried after events are delivered', () async {
        Stream<List<int>> events() async* {
          yield utf8.encode('data: {"fruit":"apple"}\n');
          throw ClientException('connection reset');
        }

        var count = 0;
        final service = ServiceClient(
          client: MockClient.streaming((request, body) async {
            ++count;
            return StreamedResponse(
              events(),
              200,
              headers: {'content-type': 'text/event-stream'},
            );
          }),
        );

        await expectLater(
          service.getStreaming(
            sampleUrl,
            enableSse: true,
            retry: const NoDelayRetry.onCodes([Code.unavailable]),
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            emitsError(isA<ClientException>()),
            emitsDone,
          ]),
        );
        expect(count, 1);
      });
    });
  });

  group('timeout', () {
    const timeout = Duration(milliseconds: 50);
    final payload = TestMessage('<test payload>');
    const sseHeaders = {'content-type': 'text/event-stream'};

    Future<Response> noResponse(Request request) =>
        Completer<Response>().future;

    group('non-streaming', () {
      late List<Request> requests;
      // The response to each request, in order. `null` means that the response
      // never arrives.
      late List<Response?> responses;
      late ServiceClient service;

      setUp(() {
        requests = [];
        responses = [];
        service = fakeAsyncService(
          MockClient((request) {
            requests.add(request);
            final response = responses.removeAt(0);
            return response == null
                ? Completer<Response>().future
                : Future.value(response);
          }),
        );
      });

      Future<Map<String, dynamic>> send(
        String method, {
        RetryRunner retry = noRetry,
        Duration? timeout,
      }) => switch (method) {
        'DELETE' => service.delete(sampleUrl, retry: retry, timeout: timeout),
        'GET' => service.get(sampleUrl, retry: retry, timeout: timeout),
        'PATCH' => service.patch(
          sampleUrl,
          body: payload,
          retry: retry,
          timeout: timeout,
        ),
        'POST' => service.post(
          sampleUrl,
          body: payload,
          retry: retry,
          timeout: timeout,
        ),
        'PUT' => service.put(
          sampleUrl,
          body: payload,
          retry: retry,
          timeout: timeout,
        ),
        _ => throw ArgumentError.value(method, 'method'),
      };

      for (final method in ['DELETE', 'GET', 'PATCH', 'POST', 'PUT']) {
        group(method, () {
          fakeAsyncTest('a response that arrives in time', (async) {
            responses.add(Response('{"fruit":"apple"}', 200));

            expect(
              send(method, timeout: timeout),
              completion({'fruit': 'apple'}),
            );
            async.elapse(timeout ~/ 2);
            expect(
              async.pendingTimersDebugString,
              isEmpty,
              reason: 'no timer should outlive the request',
            );
          });

          test('rejects a timeout that is not positive', () {
            expect(
              () => send(method, timeout: Duration.zero),
              throwsArgumentError,
            );
            expect(
              () => send(method, timeout: const Duration(seconds: -1)),
              throwsArgumentError,
            );
            expect(requests, isEmpty);
          });

          fakeAsyncTest('$method times out if there is no response', (async) {
            responses.add(null); // No response.

            expect(
              send(method, timeout: timeout),
              throwsA(
                isA<TimeoutException>()
                    .having((e) => e.duration, 'duration', timeout)
                    .having(
                      (e) => e.message,
                      'message',
                      contains('$sampleUrl'),
                    ),
              ),
            );
            async.elapse(timeout);
            expect(requests, hasLength(1));
          });
        });
      }

      fakeAsyncTest('an attempt that timed out is retried', (async) {
        responses.addAll([
          null, // No response.
          Response('{"fruit":"apple"}', 200),
        ]);

        expect(
          send(
            'GET',
            timeout: timeout,
            retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
          ),
          completion({'fruit': 'apple'}),
        );
        async.elapse(timeout);
        expect(requests, hasLength(2));
      });

      fakeAsyncTest('times out if the response body does not complete', (
        async,
      ) {
        var cancelled = false;
        final responseBody = StreamController<List<int>>(
          onCancel: () => cancelled = true,
        )..add(utf8.encode('{"fruit":'));
        final service = fakeAsyncService(
          MockClient.streaming(
            (request, body) async => StreamedResponse(responseBody.stream, 200),
          ),
        );

        expect(
          service.get(sampleUrl, timeout: timeout),
          throwsA(isA<TimeoutException>()),
        );
        async.elapse(timeout);
        expect(cancelled, isTrue, reason: 'the response should be cancelled');
      });

      fakeAsyncTest('includes the wait for the response to start', (async) {
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            // Half of `timeout` passes before the response starts.
            await Future<void>.delayed(timeout ~/ 2);
            return StreamedResponse(StreamController<List<int>>().stream, 200);
          }),
        );

        // It times out when `timeout` has passed since the request started, not
        // since the response started.
        expect(
          service.get(sampleUrl, timeout: timeout),
          throwsA(
            isA<TimeoutException>()
                .having((e) => e.duration, 'duration', timeout)
                // Check that the expected elapsed time has passed at the time
                // that the exception was thrown.
                .having((_) => async.elapsed, 'elapsed time', timeout),
          ),
        );
        async.elapse(timeout * 2);
      });

      fakeAsyncTest('ignores failures after timeout', (async) {
        final response = Completer<Response>();
        final service = fakeAsyncService(
          MockClient((request) => response.future),
        );

        expect(
          service.get(sampleUrl, timeout: timeout),
          throwsA(isA<TimeoutException>()),
        );
        async.elapse(timeout);

        response.complete(Response('', 503));
        async.flushMicrotasks();
      });

      fakeAsyncTest('cancels a response that starts after the timeout', (
        async,
      ) {
        var cancelled = false;
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            await Future<void>.delayed(timeout * 2);
            return StreamedResponse(
              StreamController<List<int>>(
                onCancel: () => cancelled = true,
              ).stream,
              200,
            );
          }),
        );

        expect(
          service.get(sampleUrl, timeout: timeout),
          throwsA(isA<TimeoutException>()),
        );
        async.elapse(timeout * 2);
        expect(
          cancelled,
          isTrue,
          reason: 'nothing reads a response that starts after the timeout',
        );
      });
    });

    group('streaming', () {
      fakeAsyncTest('times out if the response does not start by `timeout`', (
        async,
      ) {
        final service = fakeAsyncService(MockClient(noResponse));

        expect(
          service.getStreaming(sampleUrl, enableSse: true, timeout: timeout),
          emitsInOrder([
            emitsError(
              isA<TimeoutException>()
                  .having((e) => e.duration, 'duration', timeout)
                  .having((e) => e.message, 'message', contains('$sampleUrl')),
            ),
            emitsDone,
          ]),
        );
        async.elapse(timeout);
      });

      fakeAsyncTest(
        'times out if the response does not start by `streamWaitTimeout`',
        (async) {
          final service = fakeAsyncService(MockClient(noResponse));

          expect(
            service.getStreaming(
              sampleUrl,
              enableSse: true,
              streamWaitTimeout: timeout,
            ),
            emitsInOrder([
              emitsError(
                isA<TimeoutException>()
                    .having((e) => e.duration, 'duration', timeout)
                    .having(
                      (e) => e.message,
                      'message',
                      contains('$sampleUrl'),
                    ),
              ),
              emitsDone,
            ]),
          );
          async.elapse(timeout);
        },
      );

      fakeAsyncTest('the shorter of timeout and streamWaitTimeout limits the '
          'wait for the response to start', (async) {
        final service = fakeAsyncService(MockClient(noResponse));

        for (final (requestTimeout, streamWaitTimeout) in [
          (null, timeout),
          (timeout, null),
          (timeout, timeout * 2),
          (timeout * 2, timeout),
        ]) {
          expect(
            service.getStreaming(
              sampleUrl,
              enableSse: true,
              timeout: requestTimeout,
              streamWaitTimeout: streamWaitTimeout,
            ),
            emitsError(
              isA<TimeoutException>()
                  .having((e) => e.duration, 'duration', timeout)
                  .having(
                    (e) => e.message,
                    'message',
                    contains('did not return any data'),
                  ),
            ),
          );
        }
        async.elapse(timeout);
      });

      fakeAsyncTest('an attempt that timed out is retried until the '
          'response starts', (async) {
        var count = 0;
        final service = fakeAsyncService(
          MockClient((request) {
            ++count;
            return count == 1
                ? Completer<Response>()
                      .future // Never completes.
                : Future.value(
                    Response(
                      'data: {"fruit":"apple"}',
                      200,
                      headers: sseHeaders,
                    ),
                  );
          }),
        );

        expect(
          service.getStreaming(
            sampleUrl,
            enableSse: true,
            retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            timeout: timeout,
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            emitsDone,
          ]),
        );
        async.elapse(timeout);
        expect(count, 2);
        expect(
          async.pendingTimersDebugString,
          isEmpty,
          reason: 'no timer should outlive the request',
        );
      });

      fakeAsyncTest('times out if the server stops sending events for '
          '`streamWaitTimeout`', (async) {
        var count = 0;
        var cancelled = false;
        final events = StreamController<List<int>>(
          onCancel: () => cancelled = true,
        )..add(utf8.encode('data: {"fruit":"apple"}\n'));
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            ++count;
            return StreamedResponse(events.stream, 200, headers: sseHeaders);
          }),
        );

        expect(
          service.getStreaming(
            sampleUrl,
            enableSse: true,
            retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            streamWaitTimeout: timeout,
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            emitsError(
              isA<TimeoutException>().having(
                (e) => e.duration,
                'duration',
                timeout,
              ),
            ),
            emitsDone,
          ]),
        );
        async.elapse(timeout);
        // An event was delivered before the timeout, so it isn't retried.
        expect(count, 1);
        expect(cancelled, isTrue, reason: 'the response should be cancelled');
      });

      fakeAsyncTest('cancels a response that starts after the timeout', (
        async,
      ) {
        var cancelled = false;
        final events = StreamController<List<int>>(
          onCancel: () => cancelled = true,
        );
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            await Future<void>.delayed(timeout * 2);
            return StreamedResponse(events.stream, 200, headers: sseHeaders);
          }),
        );

        expect(
          service.getStreaming(sampleUrl, enableSse: true, timeout: timeout),
          emitsInOrder([emitsError(isA<TimeoutException>()), emitsDone]),
        );
        async.elapse(timeout * 2);
        expect(
          cancelled,
          isTrue,
          reason: 'nothing reads a response that starts after the timeout',
        );
      });

      fakeAsyncTest('a JSON list response that does not arrive in time is '
          'cancelled and retried', (async) {
        var count = 0;
        var cancelled = false;
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            ++count;
            return StreamedResponse(
              count == 1
                  ? StreamController<List<int>>(
                      onCancel: () => cancelled = true,
                    ).stream
                  : Stream.value(utf8.encode('[{"fruit":"apple"}]')),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        expect(
          service.getStreaming(
            sampleUrl,
            enableSse: false,
            retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            timeout: timeout,
          ),
          emitsInOrder([
            {'fruit': 'apple'},
            emitsDone,
          ]),
        );
        async.elapse(timeout);
        expect(count, 2);
        expect(
          cancelled,
          isTrue,
          reason: 'the first response should be cancelled',
        );
      });

      test('rejects a timeout or streamWaitTimeout that is not positive', () {
        final service = ServiceClient(client: MockClient(noResponse));

        for (final value in [Duration.zero, const Duration(seconds: -1)]) {
          expect(
            () => service.getStreaming(
              sampleUrl,
              enableSse: true,
              timeout: value,
            ),
            throwsA(
              isA<ArgumentError>().having((e) => e.name, 'name', 'timeout'),
            ),
          );
          expect(
            () => service.getStreaming(
              sampleUrl,
              enableSse: true,
              streamWaitTimeout: value,
            ),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.name,
                'name',
                'streamWaitTimeout',
              ),
            ),
          );
        }
      });

      fakeAsyncTest('timeout limits the whole stream', (async) {
        var cancelled = false;
        final events = StreamController<List<int>>(
          onCancel: () => cancelled = true,
        );
        // The server sends events well within `streamWaitTimeout`, but never
        // stops.
        Timer.periodic(const Duration(milliseconds: 7), (_) {
          events.add(utf8.encode('data: {"fruit":"apple"}\n'));
        });
        final service = fakeAsyncService(
          MockClient.streaming(
            (request, body) async =>
                StreamedResponse(events.stream, 200, headers: sseHeaders),
          ),
        );

        expect(
          service.getStreaming(
            sampleUrl,
            enableSse: true,
            timeout: const Duration(milliseconds: 50),
            streamWaitTimeout: const Duration(milliseconds: 10),
          ),
          emitsInOrder([
            // The events sent at 7, 14, ..., 49 ms.
            for (var i = 0; i < 7; ++i) {'fruit': 'apple'},
            emitsError(
              isA<TimeoutException>().having(
                (e) => e.duration,
                'duration',
                timeout,
              ),
            ),
            emitsDone,
          ]),
        );
        async.elapse(timeout);
        expect(cancelled, isTrue, reason: 'the response should be cancelled');
      });

      fakeAsyncTest('timeout includes the wait for the response to '
          'start', (async) {
        final service = fakeAsyncService(
          MockClient.streaming((request, body) async {
            // Half of `timeout` passes before the response starts.
            await Future<void>.delayed(timeout ~/ 2);
            return StreamedResponse(
              StreamController<List<int>>().stream,
              200,
              headers: sseHeaders,
            );
          }),
        );

        // It times out when `timeout` has passed since the request started,
        // not since the response started.
        expect(
          service.getStreaming(sampleUrl, enableSse: true, timeout: timeout),
          emitsInOrder([
            emitsError(
              isA<TimeoutException>()
                  .having((e) => e.duration, 'duration', timeout)
                  // Check that the expected elapsed time has passed at the time
                  // that the exception was thrown.
                  .having((_) => async.elapsed, 'elapsed time', timeout),
            ),
            emitsDone,
          ]),
        );
        async.elapse(timeout * 2);
      });

      fakeAsyncTest('timeout counts time that the stream was paused', (async) {
        late final Timer timer;
        final events = StreamController<List<int>>(
          onCancel: () {
            cancelled = true;
            timer.cancel();
          },
        )..add(utf8.encode('data: {"fruit":"apple"}\n'));
        // The server keeps sending events while the caller is paused but they
        // won't be received because the subscription is paused after the first
        // event is received.
        timer = Timer.periodic(timeout ~/ 10, (_) {
          events.add(utf8.encode('data: {"fruit":"banana"}\n'));
        });
        final service = fakeAsyncService(
          MockClient.streaming(
            (request, body) async =>
                StreamedResponse(events.stream, 200, headers: sseHeaders),
          ),
        );

        final received = <Object>[];
        var done = false;
        late final StreamSubscription<Map<String, dynamic>> subscription;
        subscription = service
            .getStreaming(sampleUrl, enableSse: true, timeout: timeout)
            .listen(
              (event) {
                received.add(event);
                // The caller takes longer than `timeout` to handle this
                // event.
                subscription.pause(Future<void>.delayed(timeout * 3));
              },
              onError: received.add,
              onDone: () => done = true,
            );

        async.elapse(timeout);
        expect(
          cancelled,
          isTrue,
          reason: 'the response should be cancelled when `timeout` passes',
        );
        async.elapse(timeout * 2);
        expect(received, [
          {'fruit': 'apple'},
          isA<TimeoutException>().having(
            (e) => e.duration,
            'duration',
            timeout,
          ),
        ]);
        expect(done, isTrue);
      });

      fakeAsyncTest('timeout stops when the response ends', (async) {
        final service = fakeAsyncService(
          MockClient(
            // With the newline, the event arrives before the end of the
            // response.
            (request) async =>
                Response('data: {"fruit":"apple"}\n', 200, headers: sseHeaders),
          ),
        );

        final received = <Object>[];
        var done = false;
        late final StreamSubscription<Map<String, dynamic>> subscription;
        subscription = service
            .getStreaming(sampleUrl, enableSse: true, timeout: timeout)
            .listen(
              (event) {
                received.add(event);
                // The response ends with this event, but the caller takes
                // longer than `timeout` to handle it.
                subscription.pause(Future<void>.delayed(timeout * 2));
              },
              onError: received.add,
              onDone: () => done = true,
            );

        async.elapse(timeout * 2);
        expect(received, [
          {'fruit': 'apple'},
        ]);
        expect(done, isTrue);
      });

      fakeAsyncTest('streamWaitTimeout does not limit the whole stream', (
        async,
      ) {
        Stream<List<int>> events() async* {
          for (var i = 0; i < 6; ++i) {
            await Future<void>.delayed(timeout ~/ 4);
            yield utf8.encode('data: {"count":$i}\n');
          }
        }

        final service = fakeAsyncService(
          MockClient.streaming(
            (request, body) async =>
                StreamedResponse(events(), 200, headers: sseHeaders),
          ),
        );

        expect(
          service
              .getStreaming(
                sampleUrl,
                enableSse: true,
                streamWaitTimeout: timeout,
              )
              .toList(),
          completion([
            for (var i = 0; i < 6; ++i) {'count': i},
          ]),
        );
        async.elapse(timeout * 2);
      });

      fakeAsyncTest('time that the caller spends between events does not count '
          'towards streamWaitTimeout', (async) {
        final events = StreamController<List<int>>()
          ..add(utf8.encode('data: {"fruit":"apple"}\n'));
        final service = fakeAsyncService(
          MockClient.streaming(
            (request, body) async =>
                StreamedResponse(events.stream, 200, headers: sseHeaders),
          ),
        );

        final received = <Object>[];
        var done = false;
        late final StreamSubscription<Map<String, dynamic>> subscription;
        subscription = service
            .getStreaming(
              sampleUrl,
              enableSse: true,
              streamWaitTimeout: timeout,
            )
            .listen(
              (event) {
                received.add(event);
                if (received.length == 1) {
                  // The server sends the next event promptly, but the caller
                  // takes longer than `streamWaitTimeout` to handle this one.
                  Timer(timeout ~/ 5, () {
                    events.add(utf8.encode('data: {"fruit":"banana"}\n'));
                  });
                  subscription.pause(Future<void>.delayed(timeout * 3));
                } else {
                  unawaited(events.close());
                }
              },
              onError: received.add,
              onDone: () => done = true,
            );

        async.elapse(timeout * 3);
        expect(received, [
          {'fruit': 'apple'},
          {'fruit': 'banana'},
        ]);
        expect(done, isTrue);
      });
    });
  });

  group('cancelling a streaming request', () {
    const timeout = Duration(milliseconds: 50);
    const sseHeaders = {'content-type': 'text/event-stream'};

    fakeAsyncTest('while waiting for the response stops retrying', (async) {
      var requests = 0;
      final service = fakeAsyncService(
        MockClient((request) {
          ++requests;
          return Completer<Response>().future;
        }),
      );

      final subscription = service
          .getStreaming(
            sampleUrl,
            enableSse: true,
            timeout: timeout,
            retry: const ExponentialRetry.onCodes([Code.deadlineExceeded]),
          )
          .listen(neverCalled);
      // Let the first attempt send its request.
      async.flushMicrotasks();

      // The waiting attempt would time out and be retried, but nobody is
      // listening, so `cancel` doesn't report its failure.
      unawaited(subscription.cancel());
      async.elapse(timeout);
      expect(requests, 1, reason: 'there should be no more attempts');
      expect(
        async.pendingTimersDebugString,
        isEmpty,
        reason: '`ExponentialRetry` should not wait to retry',
      );
    });

    test('cancels a response that starts afterwards', () async {
      final requested = Completer<void>();
      final respond = Completer<void>();
      var cancelled = false;
      final service = ServiceClient(
        client: MockClient.streaming((request, body) async {
          requested.complete();
          await respond.future;
          return StreamedResponse(
            StreamController<List<int>>(
              onCancel: () => cancelled = true,
            ).stream,
            200,
            headers: sseHeaders,
          );
        }),
      );

      final subscription = service
          .getStreaming(sampleUrl, enableSse: true)
          .listen(neverCalled);
      await requested.future;
      final cancelling = subscription.cancel();
      respond.complete();
      await pumpEventQueue();
      expect(
        cancelled,
        isTrue,
        reason: 'nothing reads a response that starts after cancelling',
      );
      await cancelling;
    });

    test('while reading a JSON list response cancels the response', () async {
      final reading = Completer<void>();
      var cancelled = false;
      final jsonList = StreamController<List<int>>(
        onListen: reading.complete,
        onCancel: () => cancelled = true,
      )..add(utf8.encode('[{"fruit":"apple"},'));
      final service = ServiceClient(
        client: MockClient.streaming(
          (request, body) async => StreamedResponse(
            jsonList.stream,
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final subscription = service
          .getStreaming(sampleUrl, enableSse: false)
          .listen(neverCalled);
      await reading.future;
      final cancelling = subscription.cancel();
      await pumpEventQueue();
      expect(cancelled, isTrue, reason: 'the response should be cancelled');
      await cancelling;
    });

    test('while waiting for more events cancels the response', () async {
      var cancelled = false;
      final events = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      )..add(utf8.encode('data: {"fruit":"apple"}\n'));
      final service = ServiceClient(
        client: MockClient.streaming(
          (request, body) async =>
              StreamedResponse(events.stream, 200, headers: sseHeaders),
        ),
      );

      final received = Completer<void>();
      final subscription = service
          .getStreaming(sampleUrl, enableSse: true)
          .listen((_) => received.complete());
      await received.future;
      // Let the request wait for more events, which the server never sends.
      await pumpEventQueue();

      final cancelling = subscription.cancel();
      await pumpEventQueue();
      expect(cancelled, isTrue, reason: 'the response should be cancelled');
      await cancelling;
    });
  });
}
