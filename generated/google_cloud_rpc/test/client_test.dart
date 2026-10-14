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

import 'dart:convert';

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:google_cloud_rpc/retry.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:google_cloud_rpc/src/version.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
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

    test('200 response, unexpected content-type', () async {
      final service = ServiceClient(
        client: MockClient(
          (request) async =>
              Response('', 200, headers: {'content-type': 'text/plain'}),
        ),
      );

      expect(
        service.postStreaming(sampleUrl, enableSse: true),
        emitsInOrder([emitsError(isA<ServiceException>()), emitsDone]),
      );
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
        {
        'fruit': 'apple',
      });
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
}
