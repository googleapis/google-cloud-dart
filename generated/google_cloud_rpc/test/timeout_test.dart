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
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:google_cloud_protobuf/protobuf.dart' show JsonEncodable;
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:google_cloud_rpc/retry.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:meta/meta.dart' show isTest;
import 'package:test/test.dart';

final class _TestPayload extends JsonEncodable {
  final Map<String, Object?> json;
  _TestPayload(this.json);

  @override
  Object? toJson() => json;
}

/// A stream whose `onDone` fires synchronously inside `listen`.
final class _SyncDoneStream<T> extends Stream<T> {
  final List<T> items;
  _SyncDoneStream([this.items = const []]);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    items.forEach(onData ?? (_) {});
    onDone?.call();
    return Stream<T>.empty().listen(null);
  }
}

/// Controls a mock streaming HTTP body without `async*`, so cancelling the
/// subscription immediately cancels any scheduled chunk timers in `FakeAsync`.
final class _ScheduledBody {
  final StreamController<List<int>> controller;
  final List<Timer> _timers = [];
  bool _closedNormally = false;
  int cancelCount = 0;

  /// Whether the client cancelled the stream before the server closed it.
  bool get isCancelled => cancelCount > 0;

  _ScheduledBody({Future<void>? Function()? onCancel})
    : controller = StreamController<List<int>>() {
    controller.onCancel = () {
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
      if (_closedNormally) return Future<void>.value();
      ++cancelCount;
      return onCancel != null ? onCancel() : Future<void>.value();
    };
  }

  Stream<List<int>> get stream => controller.stream;

  void addBytesAt(Duration delay, List<int> bytes) {
    if (delay == Duration.zero) {
      controller.add(bytes);
    } else {
      _timers.add(
        Timer(delay, () {
          if (!controller.isClosed) controller.add(bytes);
        }),
      );
    }
  }

  void addUtf8At(Duration delay, String text) =>
      addBytesAt(delay, utf8.encode(text));

  void addPeriodicUtf8(Duration period, String text) {
    _timers.add(
      Timer.periodic(period, (_) {
        if (!controller.isClosed) controller.add(utf8.encode(text));
      }),
    );
  }

  void addPeriodicBytes(Duration period, List<int> bytes) {
    _timers.add(
      Timer.periodic(period, (_) {
        if (!controller.isClosed) controller.add(bytes);
      }),
    );
  }

  void errorAt(Duration delay, Object error) {
    _timers.add(
      Timer(delay, () {
        if (!controller.isClosed) controller.addError(error);
      }),
    );
  }

  void closeAt(Duration delay) {
    if (delay == Duration.zero) {
      _closedNormally = true;
      unawaited(controller.close());
    } else {
      _timers.add(
        Timer(delay, () {
          if (!controller.isClosed) {
            _closedNormally = true;
            unawaited(controller.close());
          }
        }),
      );
    }
  }
}

@isTest
void fakeAsyncTest(String description, void Function(FakeAsync async) body) =>
    test(description, () => fakeAsync(body));

Matcher _isTimeoutWith(Duration expectedDuration) => isA<TimeoutException>()
    .having((e) => e.duration, 'duration', expectedDuration);

const _methods = ['DELETE', 'GET', 'PATCH', 'POST', 'PUT'];
const _sseHeaders = {'content-type': 'text/event-stream'};
const _jsonHeaders = {'content-type': 'application/json'};
final _sampleUrl = Uri.https('example.org', '/v1/items', {'filter': 'active'});
final _samplePayload = _TestPayload({'hello': 'world'});

Future<Map<String, dynamic>> _callUnary(
  ServiceClient service,
  String method,
  Uri url, {
  JsonEncodable? body,
  RetryRunner retry = noRetry,
  Duration? timeout,
}) => switch (method) {
  'DELETE' => service.delete(url, retry: retry, timeout: timeout),
  'GET' => service.get(url, retry: retry, timeout: timeout),
  'PATCH' => service.patch(url, body: body, retry: retry, timeout: timeout),
  'POST' => service.post(url, body: body, retry: retry, timeout: timeout),
  'PUT' => service.put(url, body: body, retry: retry, timeout: timeout),
  _ => throw ArgumentError.value(method, 'method'),
};

Stream<Map<String, dynamic>> _callStreaming(
  ServiceClient service,
  String method,
  Uri url, {
  required bool enableSse,
  JsonEncodable? body,
  RetryRunner retry = noRetry,
  Duration? timeout,
  Duration? streamWaitTimeout,
}) => switch (method) {
  'DELETE' => service.deleteStreaming(
    url,
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  ),
  'GET' => service.getStreaming(
    url,
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  ),
  'PATCH' => service.patchStreaming(
    url,
    enableSse: enableSse,
    body: body,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  ),
  'POST' => service.postStreaming(
    url,
    enableSse: enableSse,
    body: body,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  ),
  'PUT' => service.putStreaming(
    url,
    enableSse: enableSse,
    body: body,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  ),
  _ => throw ArgumentError.value(method, 'method'),
};

bool _methodHasBody(String method) =>
    method == 'PATCH' || method == 'POST' || method == 'PUT';

void main() {
  const t = Duration(milliseconds: 100);
  const w = Duration(milliseconds: 40);

  group('parameter validation', () {
    final invalidDurations = [
      Duration.zero,
      const Duration(microseconds: -1),
      const Duration(milliseconds: -50),
      const Duration(hours: -1),
    ];

    for (final method in _methods) {
      test('unary $method rejects non-positive timeout synchronously without '
          'sending a request', () {
        var sent = false;
        final service = ServiceClient(
          client: MockClient((_) async {
            sent = true;
            return Response('{}', 200);
          }),
        );

        for (final invalid in invalidDurations) {
          expect(
            () => _callUnary(
              service,
              method,
              _sampleUrl,
              body: _methodHasBody(method) ? _samplePayload : null,
              timeout: invalid,
            ),
            throwsA(
              isA<ArgumentError>().having((e) => e.name, 'name', 'timeout'),
            ),
          );
        }
        expect(sent, isFalse);
      });

      for (final enableSse in [false, true]) {
        test('streaming $method (enableSse: $enableSse) rejects non-positive '
            'timeout or streamWaitTimeout synchronously before listen', () {
          var sent = false;
          final service = ServiceClient(
            client: MockClient((_) async {
              sent = true;
              return Response('[]', 200, headers: _jsonHeaders);
            }),
          );

          for (final invalid in invalidDurations) {
            expect(
              () => _callStreaming(
                service,
                method,
                _sampleUrl,
                enableSse: enableSse,
                body: _methodHasBody(method) ? _samplePayload : null,
                timeout: invalid,
              ),
              throwsA(
                isA<ArgumentError>().having((e) => e.name, 'name', 'timeout'),
              ),
            );
            expect(
              () => _callStreaming(
                service,
                method,
                _sampleUrl,
                enableSse: enableSse,
                body: _methodHasBody(method) ? _samplePayload : null,
                streamWaitTimeout: invalid,
              ),
              throwsA(
                isA<ArgumentError>().having(
                  (e) => e.name,
                  'name',
                  'streamWaitTimeout',
                ),
              ),
            );
            expect(
              () => _callStreaming(
                service,
                method,
                _sampleUrl,
                enableSse: enableSse,
                body: _methodHasBody(method) ? _samplePayload : null,
                timeout: invalid,
                streamWaitTimeout: invalid,
              ),
              throwsArgumentError,
            );
          }
          expect(sent, isFalse);
        });
      }
    }

    fakeAsyncTest('accepts 1-microsecond positive durations', (async) {
      const tiny = Duration(microseconds: 1);
      final service = ServiceClient(
        client: MockClient((request) async {
          if (request.url.queryParameters['alt'] == 'sse') {
            return Response('data: {"ok":true}\n', 200, headers: _sseHeaders);
          }
          return Response('{"ok":true}', 200);
        }),
      );

      expect(service.get(_sampleUrl, timeout: tiny), completion({'ok': true}));
      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              timeout: tiny,
              streamWaitTimeout: tiny,
            )
            .toList(),
        completion([
          {'ok': true},
        ]),
      );
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('unary timeouts (single attempt)', () {
    for (final method in _methods) {
      group(method, () {
        fakeAsyncTest('succeeds when headers and body complete just before '
            'timeout and leaves no timers', (async) {
          final body = _ScheduledBody()
            ..addUtf8At(const Duration(milliseconds: 70), '{"ok":')
            ..addUtf8At(const Duration(milliseconds: 99), 'true}')
            ..closeAt(const Duration(milliseconds: 99));
          final service = ServiceClient(
            client: MockClient.streaming((request, _) async {
              await Future<void>.delayed(const Duration(milliseconds: 40));
              return StreamedResponse(body.stream, 200);
            }),
          );

          Object? result;
          unawaited(
            _callUnary(
              service,
              method,
              _sampleUrl,
              body: _methodHasBody(method) ? _samplePayload : null,
              timeout: t,
            ).then((v) => result = v, onError: (Object e) => result = e),
          );

          async.elapse(const Duration(milliseconds: 98));
          expect(result, isNull);
          async.elapse(const Duration(milliseconds: 1));
          expect(result, {'ok': true});
          expect(body.isCancelled, isFalse);
          expect(async.pendingTimers, isEmpty);
        });

        fakeAsyncTest(
          'times out at exact `timeout` when headers never arrive',
          (async) {
            final service = ServiceClient(
              client: MockClient((_) => Completer<Response>().future),
            );

            Object? error;
            Duration? errorAt;
            unawaited(
              _callUnary(
                service,
                method,
                _sampleUrl,
                body: _methodHasBody(method) ? _samplePayload : null,
                timeout: t,
              ).then(
                (_) => fail('expected TimeoutException'),
                onError: (Object e) {
                  error = e;
                  errorAt = async.elapsed;
                },
              ),
            );

            async.elapse(t - const Duration(milliseconds: 1));
            expect(error, isNull, reason: 'must not time out early');

            async.elapse(const Duration(milliseconds: 1));
            expect(error, _isTimeoutWith(t));
            expect(errorAt, t);
            expect(async.pendingTimers, isEmpty);
          },
        );

        fakeAsyncTest('times out at exact `timeout` when body stalls and '
            'cancels response stream', (async) {
          final body = _ScheduledBody()
            ..addUtf8At(const Duration(milliseconds: 20), '{"partial":');
          final service = ServiceClient(
            client: MockClient.streaming((request, _) async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
              return StreamedResponse(body.stream, 200);
            }),
          );

          Object? error;
          Duration? errorAt;
          unawaited(
            _callUnary(
              service,
              method,
              _sampleUrl,
              body: _methodHasBody(method) ? _samplePayload : null,
              timeout: t,
            ).then(
              (_) => fail('expected TimeoutException'),
              onError: (Object e) {
                error = e;
                errorAt = async.elapsed;
              },
            ),
          );

          async.elapse(t - const Duration(milliseconds: 1));
          expect(error, isNull);
          expect(body.isCancelled, isFalse);

          async.elapse(const Duration(milliseconds: 1));
          expect(error, _isTimeoutWith(t));
          expect(errorAt, t);
          expect(body.cancelCount, 1);
          expect(async.pendingTimers, isEmpty);
        });
      });
    }

    fakeAsyncTest('times out even if body bytes are actively arriving past '
        '`timeout`', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 30), '{"a":"')
        ..addPeriodicUtf8(const Duration(milliseconds: 20), 'x');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(body.stream, 200),
        ),
      );

      Object? error;
      Duration? errorAt;
      unawaited(
        service.get(_sampleUrl, timeout: t).catchError((Object e) {
          error = e;
          errorAt = async.elapsed;
          return <String, dynamic>{};
        }),
      );

      async.elapse(t);
      expect(error, _isTimeoutWith(t));
      expect(errorAt, t);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('decodes multi-byte UTF-8 split across chunks within '
        '`timeout`', (async) {
      final appleEmojiBytes = utf8.encode('{"emoji":"🍎"}');
      final split = appleEmojiBytes.indexOf(0xF0) + 2; // Split 4-byte emoji.
      final body = _ScheduledBody()
        ..addBytesAt(
          const Duration(milliseconds: 25),
          appleEmojiBytes.sublist(0, split),
        )
        ..addBytesAt(
          const Duration(milliseconds: 60),
          appleEmojiBytes.sublist(split),
        )
        ..closeAt(const Duration(milliseconds: 60));
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(body.stream, 200),
        ),
      );

      expect(service.get(_sampleUrl, timeout: t), completion({'emoji': '🍎'}));
      async.elapse(t);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('empty 200 body arriving before `timeout` returns empty map '
        'with no pending timers', (async) {
      final body = _ScheduledBody()..closeAt(const Duration(milliseconds: 70));
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(body.stream, 200),
        ),
      );

      expect(service.get(_sampleUrl, timeout: t), completion(isEmpty));
      async.elapse(const Duration(milliseconds: 70));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('synchronous-done 200 body completes cleanly with no '
        'pending timers', (async) {
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(
            _SyncDoneStream([utf8.encode('{"sync":true}')]),
            200,
          ),
        ),
      );

      expect(service.get(_sampleUrl, timeout: t), completion({'sync': true}));
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    });

    group('error responses', () {
      for (final (statusCode, matcher) in <(int, Matcher)>[
        (400, isA<BadRequestException>()),
        (401, isA<UnauthorizedException>()),
        (403, isA<ForbiddenException>()),
        (404, isA<NotFoundException>()),
        (409, isA<ConflictException>()),
        (429, isA<TooManyRequestsException>()),
        (500, isA<InternalServerErrorException>()),
        (503, isA<ServiceUnavailableException>()),
      ]) {
        fakeAsyncTest('$statusCode completing within `timeout` throws '
            'ServiceException and cleans up timer', (async) {
          final body = _ScheduledBody()
            ..addUtf8At(const Duration(milliseconds: 20), 'error message')
            ..closeAt(const Duration(milliseconds: 20));
          final service = ServiceClient(
            client: MockClient.streaming((request, _) async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
              return StreamedResponse(body.stream, statusCode);
            }),
          );

          expect(service.get(_sampleUrl, timeout: t), throwsA(matcher));
          async.elapse(const Duration(milliseconds: 50));
          expect(async.pendingTimers, isEmpty);
        });
      }

      fakeAsyncTest('500 with invalid UTF-8 body completing within `timeout` '
          'throws ServiceException and cleans up timer', (async) {
        final body = _ScheduledBody()
          ..addBytesAt(const Duration(milliseconds: 20), [0xff, 0xfe])
          ..closeAt(const Duration(milliseconds: 40));
        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async => StreamedResponse(body.stream, 500),
          ),
        );

        expect(
          service.get(_sampleUrl, timeout: t),
          throwsA(isA<InternalServerErrorException>()),
        );
        async.elapse(const Duration(milliseconds: 50));
        expect(async.pendingTimers, isEmpty);
      });

      fakeAsyncTest('503 error body stalling past cumulative `timeout` fails '
          'with TimeoutException at `timeout` and cancels stream', (async) {
        final body = _ScheduledBody()
          ..addUtf8At(const Duration(milliseconds: 10), '{"error":');
        final service = ServiceClient(
          client: MockClient.streaming((_, _) async {
            await Future<void>.delayed(const Duration(milliseconds: 60));
            return StreamedResponse(body.stream, 503);
          }),
        );

        Object? error;
        Duration? errorAt;
        unawaited(
          service.get(_sampleUrl, timeout: t).catchError((Object e) {
            error = e;
            errorAt = async.elapsed;
            return <String, dynamic>{};
          }),
        );

        async.elapse(t - const Duration(milliseconds: 1));
        expect(error, isNull);
        async.elapse(const Duration(milliseconds: 1));
        expect(error, _isTimeoutWith(t));
        expect(errorAt, t);
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      });
    });

    group('abandoned response & cancellation error hygiene', () {
      fakeAsyncTest('ignores ClientException thrown by send() after timeout', (
        async,
      ) {
        final completer = Completer<Response>();
        final service = ServiceClient(
          client: MockClient((_) => completer.future),
        );
        expect(service.get(_sampleUrl, timeout: t), throwsA(_isTimeoutWith(t)));
        async.elapse(t);
        completer.completeError(ClientException('late socket failure'));
        async.flushMicrotasks();
      });

      fakeAsyncTest('ignores ClientException from response.stream.cancel() '
          'when body times out', (async) {
        final uncaught = <Object>[];
        final body = _ScheduledBody(
          onCancel: () =>
              Future<void>.error(ClientException('broken pipe on cancel')),
        )..addUtf8At(Duration.zero, '{"a":');

        runZonedGuarded(() {
          final service = ServiceClient(
            client: MockClient.streaming(
              (_, _) async => StreamedResponse(body.stream, 200),
            ),
          );
          expect(
            service.get(_sampleUrl, timeout: t),
            throwsA(_isTimeoutWith(t)),
          );
          async
            ..elapse(t)
            ..flushMicrotasks();
        }, (e, _) => uncaught.add(e));

        expect(body.cancelCount, 1);
        expect(uncaught, isEmpty);
      });

      fakeAsyncTest('ignores ClientException from cancelling a response that '
          'starts after timeout', (async) {
        final uncaught = <Object>[];
        final body = _ScheduledBody(
          onCancel: () =>
              Future<void>.error(ClientException('late cancel failure')),
        );

        runZonedGuarded(() {
          final service = ServiceClient(
            client: MockClient.streaming((_, _) async {
              await Future<void>.delayed(t * 2);
              return StreamedResponse(body.stream, 200);
            }),
          );
          expect(
            service.get(_sampleUrl, timeout: t),
            throwsA(_isTimeoutWith(t)),
          );
          async.elapse(t * 2);
        }, (e, _) => uncaught.add(e));

        expect(body.cancelCount, 1);
        expect(uncaught, isEmpty);
      });
    });
  });

  group('unary timeouts with retries', () {
    for (final method in _methods) {
      fakeAsyncTest('$method retries timeout with identical request and fresh '
          'per-attempt timeout budget', (async) {
        final requests = <Request>[];
        final service = ServiceClient(
          client: MockClient.streaming((baseRequest, bodyStream) async {
            final bodyBytes = await bodyStream.toBytes();
            final copy = Request(baseRequest.method, baseRequest.url)
              ..headers.addAll(baseRequest.headers)
              ..bodyBytes = bodyBytes;
            requests.add(copy);

            if (requests.length == 1) {
              // Attempt 1 stalls waiting for headers.
              return Completer<StreamedResponse>().future;
            }
            if (requests.length == 2) {
              // Attempt 2 stalls mid-body.
              final stalled = _ScheduledBody()
                ..addUtf8At(const Duration(milliseconds: 20), '{"x":');
              return StreamedResponse(stalled.stream, 200);
            }
            // Attempt 3 takes 85ms (< 100ms timeout) and succeeds.
            await Future<void>.delayed(const Duration(milliseconds: 40));
            final okBody = _ScheduledBody()
              ..addUtf8At(const Duration(milliseconds: 45), '{"attempt":3}')
              ..closeAt(const Duration(milliseconds: 45));
            return StreamedResponse(okBody.stream, 200);
          }),
        );

        expect(
          _callUnary(
            service,
            method,
            _sampleUrl,
            body: _methodHasBody(method) ? _samplePayload : null,
            timeout: t,
            retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
          ),
          completion({'attempt': 3}),
        );

        async.elapse(t * 3);
        expect(requests, hasLength(3));
        for (final req in requests) {
          expect(req.method, method);
          expect(req.url, _sampleUrl);
          expect(req.headers, requests.first.headers);
          expect(
            req.body,
            _methodHasBody(method) ? '{"hello":"world"}' : isEmpty,
          );
        }
        expect(async.pendingTimers, isEmpty);
      });
    }

    fakeAsyncTest('backoff delay longer than `timeout` does not consume next '
        "attempt's `timeout` budget", (async) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          if (attempts == 1) {
            return Completer<StreamedResponse>().future;
          }
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return StreamedResponse(
            Stream.value(utf8.encode('{"ok":true}')),
            200,
          );
        }),
      );

      expect(
        service.get(
          _sampleUrl,
          timeout: t,
          retry: const ExponentialRetry.onCodes(
            [Code.deadlineExceeded],
            initialDelay: Duration(seconds: 5),
            maxDelay: Duration(seconds: 5),
          ),
        ),
        completion({'ok': true}),
      );

      async.elapse(const Duration(seconds: 6));
      expect(attempts, 2);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('does not retry TimeoutException when only Code.unavailable '
        'is retryable', (async) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient((_) {
          ++attempts;
          return Completer<Response>().future;
        }),
      );

      expect(
        service.get(
          _sampleUrl,
          timeout: t,
          retry: const NoDelayRetry.onCodes([Code.unavailable], maxRetries: 5),
        ),
        throwsA(_isTimeoutWith(t)),
      );
      async.elapse(t * 3);
      expect(attempts, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest(
      'retries mixed transient and timeout failures until success',
      (async) {
        var attempts = 0;
        final stalledBodies = <_ScheduledBody>[];
        final service = ServiceClient(
          client: MockClient.streaming((_, _) async {
            ++attempts;
            switch (attempts) {
              case 1:
                return Completer<StreamedResponse>().future; // Header timeout.
              case 2:
                return StreamedResponse(
                  Stream.value(utf8.encode('unavailable')),
                  503,
                );
              case 3:
                final b = _ScheduledBody()
                  ..addUtf8At(Duration.zero, '{"half":');
                stalledBodies.add(b);
                return StreamedResponse(b.stream, 200); // 200 body timeout.
              case 4:
                throw ClientException('connection reset');
              case 5:
                final b = _ScheduledBody()..addUtf8At(Duration.zero, '{"err":');
                stalledBodies.add(b);
                return StreamedResponse(
                  b.stream,
                  503,
                ); // 503 error body timeout.
              default:
                return StreamedResponse(
                  Stream.value(utf8.encode('{"attempt":$attempts}')),
                  200,
                );
            }
          }),
        );

        expect(
          service.get(
            _sampleUrl,
            timeout: t,
            retry: const NoDelayRetry.onCodes([
              Code.deadlineExceeded,
              Code.unavailable,
            ]),
          ),
          completion({'attempt': 6}),
        );

        async.elapse(t * 5);
        expect(attempts, 6);
        for (final b in stalledBodies) {
          expect(b.cancelCount, 1);
        }
        expect(async.pendingTimers, isEmpty);
      },
    );

    fakeAsyncTest('discards and cancels Attempt 1 late response that arrives '
        'while Attempt 2 is in flight', (async) {
      final attempt1Completer = Completer<StreamedResponse>();
      final attempt1Body = _ScheduledBody()
        ..addUtf8At(Duration.zero, '{"stale":true}');
      var attempts = 0;

      final service = ServiceClient(
        client: MockClient.streaming((_, _) {
          ++attempts;
          if (attempts == 1) return attempt1Completer.future;
          return Future.delayed(
            const Duration(milliseconds: 50),
            () => StreamedResponse(
              Stream.value(utf8.encode('{"fresh":true}')),
              200,
            ),
          );
        }),
      );

      expect(
        service.get(
          _sampleUrl,
          timeout: t,
          retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
        ),
        completion({'fresh': true}),
      );

      // Attempt 1 times out at t = 100ms; Attempt 2 starts.
      async.elapse(t + const Duration(milliseconds: 10));
      expect(attempts, 2);

      // Attempt 1's response arrives late while Attempt 2 is still running.
      attempt1Completer.complete(StreamedResponse(attempt1Body.stream, 200));
      async.elapse(const Duration(milliseconds: 50));
      expect(attempt1Body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('respects maxRetries and surfaces final failure type', (
      async,
    ) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient((_) {
          ++attempts;
          return Completer<Response>().future;
        }),
      );

      expect(
        service.get(
          _sampleUrl,
          timeout: t,
          retry: const NoDelayRetry.onCodes([
            Code.deadlineExceeded,
          ], maxRetries: 3),
        ),
        throwsA(_isTimeoutWith(t)),
      );

      async.elapse(t * 4);
      expect(attempts, 4);
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('streaming cold-start, methods, and concurrency', () {
    fakeAsyncTest('stream is cold: elapsing time before listen does not send '
        'request or start timeout/streamWaitTimeout timers', (async) {
      var sent = 0;
      final service = ServiceClient(
        client: MockClient((_) async {
          ++sent;
          await Future<void>.delayed(const Duration(milliseconds: 25));
          return Response('data: {"ok":1}\n', 200, headers: _sseHeaders);
        }),
      );

      final stream = service.getStreaming(
        _sampleUrl,
        enableSse: true,
        timeout: t,
        streamWaitTimeout: w,
      );

      // Elapse 10x both timeouts before listening.
      async.elapse(t * 10);
      expect(sent, 0);
      expect(async.pendingTimers, isEmpty);

      expect(
        stream.toList(),
        completion([
          {'ok': 1},
        ]),
      );
      async.elapse(const Duration(milliseconds: 25));
      expect(sent, 1);
      expect(async.pendingTimers, isEmpty);
    });

    for (final method in _methods) {
      for (final enableSse in [false, true]) {
        fakeAsyncTest('$method (enableSse: $enableSse) succeeds within '
            'timeouts, preserves query parameters, and cleans up timers', (
          async,
        ) {
          late Request captured;
          final service = ServiceClient(
            client: MockClient((request) async {
              captured = request;
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return enableSse
                  ? Response(
                      'data: {"m":"$method"}\n',
                      200,
                      headers: _sseHeaders,
                    )
                  : Response('[{"m":"$method"}]', 200, headers: _jsonHeaders);
            }),
          );

          expect(
            _callStreaming(
              service,
              method,
              _sampleUrl,
              enableSse: enableSse,
              body: _methodHasBody(method) ? _samplePayload : null,
              timeout: t,
              streamWaitTimeout: w,
            ).toList(),
            completion([
              {'m': method},
            ]),
          );

          async.elapse(const Duration(milliseconds: 20));
          expect(captured.method, method);
          expect(
            captured.url,
            Uri.https('example.org', '/v1/items', {
              'filter': 'active',
              if (enableSse) 'alt': 'sse',
            }),
          );
          expect(
            captured.body,
            _methodHasBody(method) ? '{"hello":"world"}' : isEmpty,
          );
          expect(async.pendingTimers, isEmpty);
        });

        fakeAsyncTest('$method (enableSse: $enableSse) header stall uses '
            'min(timeout, streamWaitTimeout)', (async) {
          final service = ServiceClient(
            client: MockClient((_) => Completer<Response>().future),
          );

          for (final (reqTimeout, waitTimeout, expected) in [
            (t, null, t),
            (null, w, w),
            (t, w, w),
            (w, t, w),
            (w, w, w),
          ]) {
            Object? caught;
            Duration? failedAt;
            final start = async.elapsed;
            _callStreaming(
              service,
              method,
              _sampleUrl,
              enableSse: enableSse,
              body: _methodHasBody(method) ? _samplePayload : null,
              timeout: reqTimeout,
              streamWaitTimeout: waitTimeout,
            ).listen(
              (_) {},
              onError: (Object e) {
                caught = e;
                failedAt = async.elapsed - start;
              },
            );

            async.elapse(expected - const Duration(milliseconds: 1));
            expect(caught, isNull);
            async.elapse(const Duration(milliseconds: 1));
            expect(caught, _isTimeoutWith(expected));
            expect(failedAt, expected);
            expect(async.pendingTimers, isEmpty);
          }
        });
      }
    }

    fakeAsyncTest('concurrent requests on the same ServiceClient have '
        'independent timeouts', (async) {
      final fastBody = _ScheduledBody();
      final slowBody = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 30), 'data: {"id":1}\n')
        ..addUtf8At(const Duration(milliseconds: 70), 'data: {"id":2}\n')
        ..closeAt(const Duration(milliseconds: 80));

      final service = ServiceClient(
        client: MockClient.streaming((request, _) async {
          final isFast = request.url.path.endsWith('/fast');
          return StreamedResponse(
            isFast ? fastBody.stream : slowBody.stream,
            200,
            headers: _sseHeaders,
          );
        }),
      );

      Object? fastError;
      service
          .getStreaming(
            Uri.https('example.org', '/fast'),
            enableSse: true,
            streamWaitTimeout: const Duration(milliseconds: 20),
          )
          .listen((_) {}, onError: (Object e) => fastError = e);

      final slowResults = <Map<String, dynamic>>[];
      var slowDone = false;
      service
          .getStreaming(
            Uri.https('example.org', '/slow'),
            enableSse: true,
            timeout: const Duration(milliseconds: 100),
            streamWaitTimeout: const Duration(milliseconds: 50),
          )
          .listen(slowResults.add, onDone: () => slowDone = true);

      async.elapse(const Duration(milliseconds: 20));
      expect(fastError, _isTimeoutWith(const Duration(milliseconds: 20)));
      expect(fastBody.cancelCount, 1);
      expect(slowBody.isCancelled, isFalse);

      async.elapse(const Duration(milliseconds: 60));
      expect(slowResults, [
        {'id': 1},
        {'id': 2},
      ]);
      expect(slowDone, isTrue);
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('streaming SSE streamWaitTimeout semantics', () {
    fakeAsyncTest('allows up to `streamWaitTimeout` for response start AND '
        'another `streamWaitTimeout` for the first event', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 35), 'data: {"seq":1}\n')
        ..addUtf8At(const Duration(milliseconds: 70), 'data: {"seq":2}\n')
        ..closeAt(const Duration(milliseconds: 100));
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          // 35ms for headers (< 40ms w), then 35ms for event 1 (70ms > w).
          await Future<void>.delayed(const Duration(milliseconds: 35));
          return StreamedResponse(body.stream, 200, headers: _sseHeaders);
        }),
      );

      expect(
        service
            .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
            .toList(),
        completion([
          {'seq': 1},
          {'seq': 2},
        ]),
      );

      async.elapse(const Duration(milliseconds: 140));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest(
      'times out if 200 SSE headers arrive in time but first '
      'event does not arrive within `streamWaitTimeout` (and does not retry)',
      (async) {
        var attempts = 0;
        final body = _ScheduledBody();
        final service = ServiceClient(
          client: MockClient.streaming((_, _) async {
            ++attempts;
            await Future<void>.delayed(const Duration(milliseconds: 15));
            return StreamedResponse(body.stream, 200, headers: _sseHeaders);
          }),
        );

        final events = <Object>[];
        Duration? errorAt;
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
              streamWaitTimeout: w,
            )
            .listen(
              events.add,
              onError: (Object e) {
                events.add(e);
                errorAt = async.elapsed;
              },
            );

        async.elapse(const Duration(milliseconds: 54));
        expect(events, isEmpty);

        async.elapse(const Duration(milliseconds: 1));
        expect(events, [_isTimeoutWith(w)]);
        expect(errorAt, const Duration(milliseconds: 55)); // 15ms + 40ms
        expect(attempts, 1, reason: 'must not retry after SSE response starts');
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      },
    );

    fakeAsyncTest('delivers events incrementally over a stream much longer '
        'than `streamWaitTimeout`', (async) {
      final body = _ScheduledBody();
      for (var i = 1; i <= 8; ++i) {
        body.addUtf8At(Duration(milliseconds: 25 * i), 'data: {"i":$i}\n');
      }
      body.closeAt(const Duration(milliseconds: 220));

      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final arrivals = <(int, int)>[];
      var done = false;
      service
          .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
          .listen((event) {
            arrivals.add((event['i'] as int, async.elapsed.inMilliseconds));
          }, onDone: () => done = true);

      async.elapse(const Duration(milliseconds: 220));
      expect(arrivals, [for (var i = 1; i <= 8; ++i) (i, 25 * i)]);
      expect(done, isTrue);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('times out if server never closes stream within '
        '`streamWaitTimeout` after the last event', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"last":true}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      var done = false;
      service
          .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
          .listen(
            received.add,
            onError: received.add,
            onDone: () => done = true,
          );

      async.elapse(const Duration(milliseconds: 49));
      expect(received, [
        {'last': true},
      ]);
      expect(done, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(received, [
        {'last': true},
        _isTimeoutWith(w),
      ]);
      expect(done, isTrue);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    for (final (label, writePeriodic)
        in <(String, void Function(_ScheduledBody))>[
          (
            'SSE comment lines (: keepalive)',
            (b) => b.addPeriodicUtf8(
              const Duration(milliseconds: 8),
              ': keepalive\n',
            ),
          ),
          (
            'blank lines',
            (b) => b.addPeriodicUtf8(const Duration(milliseconds: 8), '\n'),
          ),
          (
            'CRLF blank lines',
            (b) => b.addPeriodicUtf8(const Duration(milliseconds: 8), '\r\n'),
          ),
          (
            'non-data SSE fields (event/id/retry)',
            (b) => b.addPeriodicUtf8(
              const Duration(milliseconds: 8),
              'event: ping\nid: 99\nretry: 1000\n',
            ),
          ),
          (
            'incomplete data: line without newline',
            (b) => b
              ..addUtf8At(Duration.zero, 'data: {"long":"')
              ..addPeriodicUtf8(const Duration(milliseconds: 8), 'a'),
          ),
          (
            'empty 0-byte chunks',
            (b) => b.addPeriodicBytes(
              const Duration(milliseconds: 8),
              Uint8List(0),
            ),
          ),
        ]) {
      fakeAsyncTest('times out on $label without a complete data event', (
        async,
      ) {
        final body = _ScheduledBody();
        writePeriodic(body);
        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async =>
                StreamedResponse(body.stream, 200, headers: _sseHeaders),
          ),
        );

        final received = <Object>[];
        var done = false;
        service
            .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
            .listen(
              received.add,
              onError: received.add,
              onDone: () => done = true,
            );

        async.elapse(w - const Duration(milliseconds: 1));
        expect(received, isEmpty);

        async.elapse(const Duration(milliseconds: 1));
        expect(received, [_isTimeoutWith(w)]);
        expect(done, isTrue);
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      });
    }

    fakeAsyncTest('completes event split across prefix, multi-byte UTF-8, '
        'and SSE comments within `streamWaitTimeout`', (async) {
      final emojiBytes = utf8.encode('🚀'); // 4-byte UTF-8
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), ': comment\n')
        ..addUtf8At(const Duration(milliseconds: 18), 'da')
        ..addUtf8At(const Duration(milliseconds: 24), 'ta: {"rocket":"')
        ..addBytesAt(const Duration(milliseconds: 30), emojiBytes.sublist(0, 2))
        ..addBytesAt(const Duration(milliseconds: 35), emojiBytes.sublist(2))
        ..addUtf8At(const Duration(milliseconds: 38), '"}\n')
        ..addUtf8At(const Duration(milliseconds: 65), 'data: {"done":true}')
        ..closeAt(const Duration(milliseconds: 70));

      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      expect(
        service
            .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
            .toList(),
        completion([
          {'rocket': '🚀'},
          {'done': true},
        ]),
      );

      async.elapse(const Duration(milliseconds: 80));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('handles burst of multiple events in one chunk followed by '
        'quiet period < `streamWaitTimeout`', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(
          const Duration(milliseconds: 10),
          'data: {"n":1}\ndata: {"n":2}\ndata: {"n":3}\n',
        )
        ..addUtf8At(const Duration(milliseconds: 45), 'data: {"n":4}\n')
        ..closeAt(const Duration(milliseconds: 50));

      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      expect(
        service
            .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
            .toList(),
        completion([
          {'n': 1},
          {'n': 2},
          {'n': 3},
          {'n': 4},
        ]),
      );

      async.elapse(const Duration(milliseconds: 60));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('handles Content-Type parameters and uppercase MIME type', (
      async,
    ) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 20), 'data: {"ok":1}\n')
        ..closeAt(const Duration(milliseconds: 30));
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(
            body.stream,
            200,
            headers: {'content-type': 'TEXT/EVENT-STREAM; charset=utf-8'},
          ),
        ),
      );

      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              timeout: t,
              streamWaitTimeout: w,
            )
            .toList(),
        completion([
          {'ok': 1},
        ]),
      );
      async.elapse(const Duration(milliseconds: 40));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('cleans up both timeout timers when stream fails with '
        'FormatException or ClientException mid-stream', (async) {
      for (final triggerMalformedJson in [true, false]) {
        final body = _ScheduledBody()
          ..addUtf8At(const Duration(milliseconds: 10), 'data: {"ok":1}\n');
        if (triggerMalformedJson) {
          body.addUtf8At(
            const Duration(milliseconds: 20),
            'data: {not json}\n',
          );
        } else {
          body.errorAt(
            const Duration(milliseconds: 20),
            ClientException('mid-stream reset'),
          );
        }

        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async =>
                StreamedResponse(body.stream, 200, headers: _sseHeaders),
          ),
        );

        final received = <Object>[];
        var done = false;
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              timeout: t,
              streamWaitTimeout: w,
              retry: const NoDelayRetry.onCodes([
                Code.unavailable,
                Code.deadlineExceeded,
              ]),
            )
            .listen(
              received.add,
              onError: received.add,
              onDone: () => done = true,
              cancelOnError: true,
            );

        async.elapse(const Duration(milliseconds: 25));
        expect(received, [
          {'ok': 1},
          triggerMalformedJson
              ? isA<FormatException>()
              : isA<ClientException>(),
        ]);
        expect(done, isFalse, reason: 'cancelOnError suppresses onDone');
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      }
    });
  });

  group('streaming SSE dual timeout (`timeout` + `streamWaitTimeout`)', () {
    fakeAsyncTest('`streamWaitTimeout` fires first and cleans up `timeout` '
        'timer when stream stalls early', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"n":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: const Duration(milliseconds: 500),
            streamWaitTimeout: w, // 40ms
          )
          .listen(received.add, onError: received.add);

      async.elapse(const Duration(milliseconds: 50)); // 10ms + 40ms
      expect(received, [
        {'n': 1},
        _isTimeoutWith(w),
      ]);
      expect(body.cancelCount, 1);
      expect(
        async.pendingTimers,
        isEmpty,
        reason: '500ms deadline timer must be cancelled immediately at 50ms',
      );
    });

    fakeAsyncTest('`timeout` fires first and cleans up `streamWaitTimeout` '
        'timer when remaining stream budget is shorter', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 80), 'data: {"n":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t, // 100ms
            streamWaitTimeout: const Duration(milliseconds: 90),
          )
          .listen(received.add, onError: received.add);

      async.elapse(t);
      expect(received, [
        {'n': 1},
        _isTimeoutWith(t),
      ]);
      expect(body.cancelCount, 1);
      expect(
        async.pendingTimers,
        isEmpty,
        reason:
            'streamWaitTimeout timer must be cancelled immediately at 100ms',
      );
    });

    fakeAsyncTest('simultaneous expiry of `timeout` and `streamWaitTimeout` '
        'emits exactly one TimeoutException and cancels once', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 30), 'data: {"n":1}\n')
        ..addUtf8At(const Duration(milliseconds: 60), 'data: {"n":2}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      var doneCount = 0;
      service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t, // Fires at 100ms
            streamWaitTimeout: w, // 60ms + 40ms = 100ms!
          )
          .listen(
            received.add,
            onError: received.add,
            onDone: () => ++doneCount,
          );

      async.elapse(t * 2);
      expect(received, [
        {'n': 1},
        {'n': 2},
        isA<TimeoutException>(),
      ]);
      expect(doneCount, 1);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('streaming pause and resume', () {
    fakeAsyncTest('`await for` consumer taking longer than `streamWaitTimeout` '
        'per event succeeds', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"i":1}\n')
        ..addUtf8At(const Duration(milliseconds: 20), 'data: {"i":2}\n')
        ..addUtf8At(const Duration(milliseconds: 30), 'data: {"i":3}\n')
        ..closeAt(const Duration(milliseconds: 35));

      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final processed = <int>[];
      Object? failure;
      unawaited(
        (() async {
          try {
            await for (final event in service.getStreaming(
              _sampleUrl,
              enableSse: true,
              streamWaitTimeout: w, // 40ms
            )) {
              // Spend 150ms (> 3 * w) processing each event.
              await Future<void>.delayed(const Duration(milliseconds: 150));
              processed.add(event['i'] as int);
            }
          } catch (e) {
            failure = e;
          }
        })(),
      );

      async.elapse(const Duration(milliseconds: 600));
      expect(failure, isNull);
      expect(processed, [1, 2, 3]);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('nested pause() calls only resume `streamWaitTimeout` once '
        'all pauses are resumed', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"i":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      late final StreamSubscription<Map<String, dynamic>> sub;
      sub = service
          .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
          .listen((event) {
            received.add(event);
            sub
              ..pause()
              ..pause();
          }, onError: received.add);

      async.elapse(const Duration(milliseconds: 10));
      expect(received, [
        {'i': 1},
      ]);

      // Paused twice: first resume after 100ms leaves pause count at 1.
      async.elapse(const Duration(milliseconds: 100));
      sub.resume();
      async.elapse(const Duration(milliseconds: 100));
      expect(received, hasLength(1), reason: 'still paused once');

      // Second resume unpauses; server sends event 20ms later (< 40ms w).
      sub.resume();
      body
        ..addUtf8At(const Duration(milliseconds: 20), 'data: {"i":2}\n')
        ..closeAt(const Duration(milliseconds: 25));
      async.elapse(const Duration(milliseconds: 30));

      expect(received, [
        {'i': 1},
        {'i': 2},
      ]);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('pausing mid-wait does not count paused duration towards '
        '`streamWaitTimeout`, and still times out if silent after resume', (
      async,
    ) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 5), 'data: {"i":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      final sub = service
          .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
          .listen(received.add, onError: received.add);

      // Event 1 at 5ms, then 20ms of unpaused wait (t = 25ms).
      async.elapse(const Duration(milliseconds: 25));
      expect(received, [
        {'i': 1},
      ]);

      // Pause for 200ms (t = 25ms..225ms).
      sub.pause();
      async.elapse(const Duration(milliseconds: 200));
      expect(received, hasLength(1));
      expect(body.isCancelled, isFalse);

      // Resume at t = 225ms; server stays silent -> must time out within w.
      sub.resume();
      async.elapse(w);
      expect(received, [
        {'i': 1},
        _isTimeoutWith(w),
      ]);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('time spent paused BEFORE response starts does not count '
        'towards `streamWaitTimeout`', (async) {
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          // Server responds at t = 220ms (20ms after resume at t = 200ms).
          await Future<void>.delayed(const Duration(milliseconds: 220));
          return StreamedResponse(
            Stream.value(utf8.encode('data: {"ok":true}\n')),
            200,
            headers: _sseHeaders,
          );
        }),
      );

      final received = <Object>[];
      var done = false;
      final sub =
          service
              .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
              .listen(
                received.add,
                onError: received.add,
                onDone: () => done = true,
              )
            ..pause();

      // Immediately paused before response starts.
      async.elapse(const Duration(milliseconds: 200));
      expect(received, isEmpty);

      // Resume at t = 200ms; headers + event arrive at t = 220ms (< 40ms w).
      sub.resume();
      async.elapse(const Duration(milliseconds: 30));
      expect(received, [
        {'ok': true},
      ]);
      expect(done, isTrue);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('time spent paused while reading a JSON list response does '
        'not count towards `streamWaitTimeout`', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), '[{"ok":')
        ..addUtf8At(const Duration(milliseconds: 220), 'true}]')
        ..closeAt(const Duration(milliseconds: 220));
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _jsonHeaders),
        ),
      );

      final received = <Object>[];
      var done = false;
      final sub = service
          .getStreaming(_sampleUrl, enableSse: false, streamWaitTimeout: w)
          .listen(
            received.add,
            onError: received.add,
            onDone: () => done = true,
          );

      // Let headers and first JSON chunk arrive at 10ms, then pause for 200ms.
      async.elapse(const Duration(milliseconds: 15));
      sub.pause();
      async.elapse(const Duration(milliseconds: 195)); // t = 210ms
      expect(received, isEmpty);

      // Resume at t = 210ms; rest of JSON arrives at t = 220ms (10ms < 40ms w).
      sub.resume();
      async.elapse(const Duration(milliseconds: 20));
      expect(received, [
        {'ok': true},
      ]);
      expect(done, isTrue);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('`timeout` DOES count time that the subscription is paused '
        'before headers arrive', (async) {
      var lateResponseCancelled = false;
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          await Future<void>.delayed(t * 2);
          return StreamedResponse(
            StreamController<List<int>>(
              onCancel: () => lateResponseCancelled = true,
            ).stream,
            200,
            headers: _sseHeaders,
          );
        }),
      );

      final received = <Object>[];
      var done = false;
      final sub =
          service
              .getStreaming(_sampleUrl, enableSse: true, timeout: t)
              .listen(
                received.add,
                onError: received.add,
                onDone: () => done = true,
              )
            ..pause();

      async.elapse(t * 2);
      expect(lateResponseCancelled, isTrue);

      sub.resume();
      async.flushMicrotasks();
      expect(received, [_isTimeoutWith(t)]);
      expect(done, isTrue);
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('streaming JSON list & error responses with timeouts', () {
    fakeAsyncTest('JSON list arriving in chunks within `streamWaitTimeout` '
        'succeeds even when total duration exceeds `streamWaitTimeout`', (
      async,
    ) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 25), '[{"a":1},')
        ..addUtf8At(const Duration(milliseconds: 55), '{"a":2},')
        ..addUtf8At(const Duration(milliseconds: 85), '{"a":3}]')
        ..closeAt(const Duration(milliseconds: 95));

      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _jsonHeaders),
        ),
      );

      expect(
        service
            .getStreaming(_sampleUrl, enableSse: false, streamWaitTimeout: w)
            .toList(),
        completion([
          {'a': 1},
          {'a': 2},
          {'a': 3},
        ]),
      );

      async.elapse(const Duration(milliseconds: 100));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('JSON list stalling for `streamWaitTimeout` is cancelled '
        'and retried', (async) {
      var attempts = 0;
      final stalled = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), '[{"a":1},');
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          if (attempts == 1) {
            return StreamedResponse(stalled.stream, 200, headers: _jsonHeaders);
          }
          return StreamedResponse(
            Stream.value(utf8.encode('[{"a":2}]')),
            200,
            headers: _jsonHeaders,
          );
        }),
      );

      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: false,
              streamWaitTimeout: w,
              retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            )
            .toList(),
        completion([
          {'a': 2},
        ]),
      );

      async.elapse(const Duration(milliseconds: 60));
      expect(attempts, 2);
      expect(stalled.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('JSON list exceeding `timeout` despite steady chunks is '
        'cancelled and retried', (async) {
      var attempts = 0;
      final slow = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 25), '[')
        ..addPeriodicUtf8(const Duration(milliseconds: 25), '{"x":1},');
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          if (attempts == 1) {
            return StreamedResponse(slow.stream, 200, headers: _jsonHeaders);
          }
          return StreamedResponse(
            Stream.value(utf8.encode('[{"ok":true}]')),
            200,
            headers: _jsonHeaders,
          );
        }),
      );

      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: false,
              timeout: t,
              streamWaitTimeout: w,
              retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            )
            .toList(),
        completion([
          {'ok': true},
        ]),
      );

      async.elapse(t + const Duration(milliseconds: 10));
      expect(attempts, 2);
      expect(slow.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('empty 0-byte chunks do not reset `streamWaitTimeout` on '
        'JSON list or error responses', (async) {
      for (final (status, headers) in [
        (200, _jsonHeaders),
        (503, const <String, String>{}),
      ]) {
        final body = _ScheduledBody()
          ..addUtf8At(Duration.zero, '[')
          ..addPeriodicBytes(const Duration(milliseconds: 8), Uint8List(0));
        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async =>
                StreamedResponse(body.stream, status, headers: headers),
          ),
        );

        final received = <Object>[];
        service
            .getStreaming(_sampleUrl, enableSse: false, streamWaitTimeout: w)
            .listen(received.add, onError: received.add);

        async.elapse(w);
        expect(received, [_isTimeoutWith(w)]);
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      }
    });

    fakeAsyncTest('503 error body stalling for `streamWaitTimeout` is '
        'cancelled and retried', (async) {
      var attempts = 0;
      final stalledError = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), '{"error":');
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          if (attempts == 1) {
            return StreamedResponse(stalledError.stream, 503);
          }
          return StreamedResponse(
            Stream.value(utf8.encode('data: {"recovered":true}\n')),
            200,
            headers: _sseHeaders,
          );
        }),
      );

      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              streamWaitTimeout: w,
              retry: const NoDelayRetry.onCodes([Code.deadlineExceeded]),
            )
            .toList(),
        completion([
          {'recovered': true},
        ]),
      );

      async.elapse(const Duration(milliseconds: 60));
      expect(attempts, 2);
      expect(stalledError.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('unsupported Content-Type with timeouts cancels response '
        'and leaves no pending timers', (async) {
      final body = _ScheduledBody();
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async => StreamedResponse(
            body.stream,
            200,
            headers: {'content-type': 'text/plain'},
          ),
        ),
      );

      final received = <Object>[];
      service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t,
            streamWaitTimeout: w,
          )
          .listen(received.add, onError: received.add);

      async.flushMicrotasks();
      expect(received, [isA<ServiceException>()]);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });

  group('streaming retries and cancellation with active timeouts', () {
    fakeAsyncTest('full retry gauntlet across header stall, error stall, 503, '
        'ClientException, JSON stall, then SSE success with fresh `timeout`', (
      async,
    ) {
      var attempts = 0;
      final bodies = <_ScheduledBody>[];
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          switch (attempts) {
            case 1:
              return Completer<StreamedResponse>()
                  .future; // Header timeout (w).
            case 2:
              final b = _ScheduledBody()..addUtf8At(Duration.zero, '{"err":');
              bodies.add(b);
              return StreamedResponse(b.stream, 503); // Error body stall (w).
            case 3:
              return StreamedResponse(Stream.value(utf8.encode('busy')), 503);
            case 4:
              throw ClientException('transient network error');
            case 5:
              final b = _ScheduledBody()..addUtf8At(Duration.zero, '[{"x":1},');
              bodies.add(b);
              return StreamedResponse(
                b.stream,
                200,
                headers: _jsonHeaders,
              ); // JSON stall (w).
            default:
              // Attempt 6 takes 85ms (< 100ms timeout) across two SSE events.
              final b = _ScheduledBody()
                ..addUtf8At(const Duration(milliseconds: 35), 'data: {"a":1}\n')
                ..addUtf8At(const Duration(milliseconds: 70), 'data: {"a":2}\n')
                ..closeAt(const Duration(milliseconds: 85));
              return StreamedResponse(b.stream, 200, headers: _sseHeaders);
          }
        }),
      );

      expect(
        service
            .postStreaming(
              _sampleUrl,
              enableSse: true,
              body: _samplePayload,
              timeout: t,
              streamWaitTimeout: w,
              retry: const ExponentialRetry.onCodes(
                [Code.deadlineExceeded, Code.unavailable],
                initialDelay: Duration(milliseconds: 200),
                maxDelay: Duration(milliseconds: 200),
              ),
            )
            .toList(),
        completion([
          {'a': 1},
          {'a': 2},
        ]),
      );

      async.elapse(const Duration(seconds: 3));
      expect(attempts, 6);
      for (final b in bodies) {
        expect(b.cancelCount, 1);
      }
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('`stream.first` / early cancel mid-SSE cancels response and '
        'leaves zero timeout timers', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"first":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      Map<String, dynamic>? firstEvent;
      unawaited(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              timeout: t,
              streamWaitTimeout: w,
            )
            .first
            .then((v) => firstEvent = v),
      );

      async.elapse(const Duration(milliseconds: 10));
      expect(firstEvent, {'first': 1});
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('cancelling while paused cancels response and cleans up '
        'both `timeout` and `streamWaitTimeout` timers', (async) {
      final body = _ScheduledBody()
        ..addUtf8At(const Duration(milliseconds: 10), 'data: {"first":1}\n');
      final service = ServiceClient(
        client: MockClient.streaming(
          (_, _) async =>
              StreamedResponse(body.stream, 200, headers: _sseHeaders),
        ),
      );

      final received = <Object>[];
      late final StreamSubscription<Map<String, dynamic>> sub;
      sub = service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t,
            streamWaitTimeout: w,
          )
          .listen((event) {
            received.add(event);
            sub.pause();
          }, onError: received.add);

      async.elapse(const Duration(milliseconds: 10));
      expect(received, [
        {'first': 1},
      ]);

      // Cancel while paused!
      var cancelDone = false;
      unawaited(sub.cancel().then((_) => cancelDone = true));
      async.flushMicrotasks();
      expect(cancelDone, isTrue);
      expect(body.cancelCount, 1);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('cancelling during retry backoff after a timeout stops '
        'all timers and attempts', (async) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient((_) {
          ++attempts;
          return Completer<Response>().future;
        }),
      );

      final received = <Object>[];
      final sub = service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t,
            streamWaitTimeout: w,
            retry: const ExponentialRetry.onCodes(
              [Code.deadlineExceeded],
              initialDelay: Duration(seconds: 10),
              maxDelay: Duration(seconds: 10),
            ),
          )
          .listen(received.add, onError: received.add);

      // Attempt 1 times out at w (40ms); now waiting in backoff timer.
      async.elapse(w + const Duration(milliseconds: 5));
      expect(attempts, 1);
      expect(async.pendingTimers, isNotEmpty);

      unawaited(sub.cancel());
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);

      async.elapse(const Duration(minutes: 1));
      expect(attempts, 1);
      expect(received, isEmpty);
    });

    fakeAsyncTest('cancelling while reading JSON list or error body with '
        'active timeouts cancels stream and timers', (async) {
      for (final (status, headers) in [
        (200, _jsonHeaders),
        (503, const <String, String>{}),
      ]) {
        final body = _ScheduledBody()
          ..addUtf8At(const Duration(milliseconds: 5), '[{"a":');
        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async =>
                StreamedResponse(body.stream, status, headers: headers),
          ),
        );

        final sub = service
            .getStreaming(
              _sampleUrl,
              enableSse: false,
              timeout: t,
              streamWaitTimeout: w,
            )
            .listen((_) {});

        async.elapse(const Duration(milliseconds: 10));
        expect(body.isCancelled, isFalse);

        unawaited(sub.cancel());
        async.flushMicrotasks();
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      }
    });

    fakeAsyncTest('custom ExponentialRetry(retryIf: ...) works for both unary '
        'and streaming timeouts', (async) {
      var unaryAttempts = 0;
      var streamAttempts = 0;
      final seenDurations = <Duration?>[];
      final retry = ExponentialRetry(
        retryIf: (e) {
          if (e is TimeoutException) {
            seenDurations.add(e.duration);
            return true;
          }
          return false;
        },
        initialDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(milliseconds: 10),
        maxRetries: 2,
      );

      final service = ServiceClient(
        client: MockClient((request) {
          if (request.url.queryParameters['alt'] == 'sse') {
            ++streamAttempts;
            return streamAttempts == 1
                ? Completer<Response>().future
                : Future.value(
                    Response('data: {"s":1}\n', 200, headers: _sseHeaders),
                  );
          }
          ++unaryAttempts;
          return unaryAttempts == 1
              ? Completer<Response>().future
              : Future.value(Response('{"u":1}', 200));
        }),
      );

      expect(
        service.get(_sampleUrl, timeout: t, retry: retry),
        completion({'u': 1}),
      );
      expect(
        service
            .getStreaming(
              _sampleUrl,
              enableSse: true,
              streamWaitTimeout: w,
              retry: retry,
            )
            .toList(),
        completion([
          {'s': 1},
        ]),
      );

      async.elapse(const Duration(seconds: 1));
      expect(unaryAttempts, 2);
      expect(streamAttempts, 2);
      expect(seenDurations, containsAll([t, w]));
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('cancelOnError: true vs false both cancel response stream '
        'exactly once on timeout', (async) {
      for (final cancelOnError in [false, true]) {
        final body = _ScheduledBody()
          ..addUtf8At(const Duration(milliseconds: 10), 'data: {"i":1}\n');
        final service = ServiceClient(
          client: MockClient.streaming(
            (_, _) async =>
                StreamedResponse(body.stream, 200, headers: _sseHeaders),
          ),
        );

        final received = <Object>[];
        var doneCount = 0;
        service
            .getStreaming(_sampleUrl, enableSse: true, streamWaitTimeout: w)
            .listen(
              received.add,
              onError: received.add,
              onDone: () => ++doneCount,
              cancelOnError: cancelOnError,
            );

        async.elapse(const Duration(milliseconds: 50));
        expect(received, [
          {'i': 1},
          _isTimeoutWith(w),
        ]);
        expect(doneCount, cancelOnError ? 0 : 1);
        expect(body.cancelCount, 1);
        expect(async.pendingTimers, isEmpty);
      }
    });

    fakeAsyncTest('streaming stream is single-subscription and re-listening '
        'throws StateError without leaking timers', (async) {
      final service = ServiceClient(
        client: MockClient(
          (_) async => Response('data: {"ok":1}\n', 200, headers: _sseHeaders),
        ),
      );

      final stream = service.getStreaming(
        _sampleUrl,
        enableSse: true,
        timeout: t,
        streamWaitTimeout: w,
      );
      expect(
        stream.toList(),
        completion([
          {'ok': 1},
        ]),
      );
      async.flushMicrotasks();
      expect(() => stream.listen((_) {}), throwsStateError);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('pausing during retry backoff does not cause Attempt 2 to '
        'fail `streamWaitTimeout` while still paused', (async) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient.streaming((_, _) async {
          ++attempts;
          if (attempts == 1) {
            return StreamedResponse(Stream.value(utf8.encode('busy')), 503);
          }
          // Attempt 2 starts during pause (~50ms) and responds at t = 320ms
          // (20ms after resume at t = 300ms, < 40ms w).
          await Future<void>.delayed(const Duration(milliseconds: 270));
          return StreamedResponse(
            Stream.value(utf8.encode('data: {"ok":2}\n')),
            200,
            headers: _sseHeaders,
          );
        }),
      );

      final received = <Object>[];
      var done = false;
      final sub = service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            streamWaitTimeout: w,
            retry: const ExponentialRetry.onCodes(
              [Code.unavailable],
              initialDelay: Duration(milliseconds: 50),
              maxDelay: Duration(milliseconds: 50),
            ),
          )
          .listen(
            received.add,
            onError: received.add,
            onDone: () => done = true,
          );

      // Attempt 1 fails with 503 at t = 0; pause for 300ms during backoff.
      async.flushMicrotasks();
      expect(attempts, 1);
      sub.pause();
      async.elapse(const Duration(milliseconds: 300));
      expect(received, isEmpty);

      sub.resume();
      async.elapse(const Duration(milliseconds: 60));
      expect(received, [
        {'ok': 2},
      ]);
      expect(done, isTrue);
      expect(async.pendingTimers, isEmpty);
    });

    fakeAsyncTest('streaming timeouts are not retried by default (noRetry)', (
      async,
    ) {
      var attempts = 0;
      final service = ServiceClient(
        client: MockClient((_) {
          ++attempts;
          return Completer<Response>().future;
        }),
      );

      final received = <Object>[];
      service
          .getStreaming(
            _sampleUrl,
            enableSse: true,
            timeout: t,
            streamWaitTimeout: w,
          )
          .listen(received.add, onError: received.add);

      async.elapse(t * 5);
      expect(attempts, 1);
      expect(received, [_isTimeoutWith(w)]);
      expect(async.pendingTimers, isEmpty);
    });
  });
}
