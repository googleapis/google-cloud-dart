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

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:google_cloud_rpc/retry.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

bool _isBadRequest(Object error) => error is BadRequestException;

void main() {
  group('delaySequence', () {
    test('calculates exponential backoff correctly', () {
      final delays = delaySequence(
        maxRetries: 5,
        initialDelay: const Duration(seconds: 1),
        delayMultiplier: 2.5,
        maxDelay: const Duration(seconds: 100),
      ).toList();

      expect(delays, [
        const Duration(seconds: 1),
        const Duration(seconds: 2, milliseconds: 500),
        const Duration(seconds: 6, milliseconds: 250),
        const Duration(seconds: 15, milliseconds: 625),
        const Duration(seconds: 39, milliseconds: 62, microseconds: 500),
      ]);
    });

    test('respects maxDelay', () {
      final delays = delaySequence(
        maxRetries: 5,
        initialDelay: const Duration(seconds: 1),
        delayMultiplier: 2.5,
        maxDelay: const Duration(seconds: 16),
      ).toList();

      expect(delays, [
        const Duration(seconds: 1),
        const Duration(seconds: 2, milliseconds: 500),
        const Duration(seconds: 6, milliseconds: 250),
        const Duration(seconds: 15, milliseconds: 625),
        const Duration(seconds: 16),
      ]);
    });

    test('respects maxRetryInterval', () {
      var time = DateTime.now();
      final clock = Clock(() => time);
      final delays = delaySequence(
        initialDelay: const Duration(seconds: 1),
        delayMultiplier: 2,
        maxDelay: const Duration(seconds: 10),
        maxRetryInterval: const Duration(seconds: 3),
        clock: clock,
      ).iterator;

      expect(delays.moveNext(), isTrue);
      expect(delays.current, const Duration(seconds: 1));
      time = time.add(delays.current);

      expect(delays.moveNext(), isTrue);
      expect(delays.current, const Duration(seconds: 2));
      time = time.add(delays.current);

      expect(delays.moveNext(), isTrue);
      expect(delays.current, const Duration(seconds: 4));
      time = time.add(delays.current);

      expect(delays.moveNext(), isFalse);
    });

    test('applies jitter within bounds when configured', () {
      final delays = delaySequence(
        maxRetries: 20,
        initialDelay: const Duration(seconds: 10),
        delayMultiplier: 1.0,
        maxDelay: const Duration(seconds: 10),
        jitter: 0.2,
        random: Random(42),
      ).toList();

      expect(delays, hasLength(20));
      for (final d in delays) {
        expect(d.inMilliseconds, greaterThanOrEqualTo(8000));
        expect(d.inMilliseconds, lessThanOrEqualTo(12000));
      }
      expect(delays.toSet().length, greaterThan(1));
      // Jitter is applied after the delay is capped at `maxDelay`.
      expect(delays.any((d) => d > const Duration(seconds: 10)), isTrue);
    });

    test('matches the documented jitter example', () {
      final delays = delaySequence(
        maxRetries: 6,
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
        delayMultiplier: 2,
        jitter: 0.2,
        random: Random(42),
      ).toList();

      const unjittered = [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 10),
        Duration(seconds: 10),
      ];
      expect(delays, hasLength(unjittered.length));
      expect(delays, isNot(unjittered));
      for (var i = 0; i < delays.length; i++) {
        expect(delays[i], greaterThanOrEqualTo(unjittered[i] * 0.8));
        expect(delays[i], lessThanOrEqualTo(unjittered[i] * 1.2));
      }
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

  group('hasStatusCode', () {
    test('matches gRPC status codes', () {
      final unavailable = ServiceUnavailableException(
        'unavailable',
        status: Status(code: 14),
      );
      expect(hasStatusCode(unavailable, const [Code.unavailable]), isTrue);
      expect(
        hasStatusCode(unavailable, const [
          Code.deadlineExceeded,
          Code.unavailable,
        ]),
        isTrue,
      );
      expect(
        hasStatusCode(unavailable, const [Code.deadlineExceeded]),
        isFalse,
      );
    });

    test('distinguishes gRPC status codes with the same HTTP status', () {
      final aborted = ConflictException('aborted', status: Status(code: 10));
      expect(hasStatusCode(aborted, const [Code.aborted]), isTrue);
      expect(hasStatusCode(aborted, const [Code.alreadyExists]), isFalse);

      final dataLoss = InternalServerErrorException(
        'data loss',
        status: Status(code: 15),
      );
      expect(hasStatusCode(dataLoss, const [Code.dataLoss]), isTrue);
      expect(hasStatusCode(dataLoss, const [Code.internal]), isFalse);
    });

    test('matches HTTP status codes', () {
      expect(
        hasStatusCode(ServiceUnavailableException('503'), const [
          Code.unavailable,
        ]),
        isTrue,
      );
      expect(
        hasStatusCode(GatewayTimeoutException('504'), const [
          Code.deadlineExceeded,
        ]),
        isTrue,
      );
      expect(
        hasStatusCode(TooManyRequestsException('429'), const [
          Code.resourceExhausted,
        ]),
        isTrue,
      );
      expect(
        hasStatusCode(BadRequestException('400'), const [
          Code.deadlineExceeded,
          Code.unavailable,
        ]),
        isFalse,
      );
    });

    test('matches HTTP status codes when the status has the HTTP code', () {
      // A REST error response like `{"error": {"code": 503, ...}}`.
      final error = ServiceUnavailableException(
        'unavailable',
        status: Status(code: 503, message: 'unavailable'),
      );
      expect(hasStatusCode(error, const [Code.unavailable]), isTrue);
      expect(hasStatusCode(error, const [Code.internal]), isFalse);
    });

    test('cannot distinguish codes that share an HTTP status code', () {
      expect(
        hasStatusCode(ConflictException('409'), const [Code.aborted]),
        isTrue,
      );
      expect(
        hasStatusCode(ConflictException('409'), const [Code.alreadyExists]),
        isTrue,
      );
    });

    test('treats a transport failure as UNAVAILABLE', () {
      final error = http.ClientException('connection refused');
      expect(hasStatusCode(error, const [Code.unavailable]), isTrue);
      expect(hasStatusCode(error, const [Code.deadlineExceeded]), isFalse);
    });

    test('does not match other errors', () {
      expect(
        hasStatusCode(const FormatException('bad json'), const [
          Code.unavailable,
        ]),
        isFalse,
      );
      expect(hasStatusCode(StateError('bug'), const [Code.unknown]), isFalse);
      expect(hasStatusCode(ServiceUnavailableException('503'), []), isFalse);
    });
  });

  group('NoRetry', () {
    test('returns the result', () async {
      expect(await noRetry.run(() async => 5), 5);
    });

    test('does not retry', () async {
      var count = 0;
      await expectLater(
        noRetry.run<int>(() async {
          ++count;
          throw http.ClientException('transport failure');
        }),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });

    test('rejects every error and has no delays', () {
      expect(noRetry.isRetryable(http.ClientException('failure')), isFalse);
      expect(noRetry.delays(), isEmpty);
    });

    test('value equality', () {
      // ignore: prefer_const_constructors
      expect(NoRetry(), equals(noRetry));
      // ignore: prefer_const_constructors
      expect(NoRetry().hashCode, equals(noRetry.hashCode));
      expect(noRetry, isNot(equals(const ExponentialRetry(maxRetries: 0))));
    });
  });

  group('ExponentialRetry', () {
    test('first try succeeds', () async {
      expect(await const ExponentialRetry().run(() async => 5), 5);
    });

    test('first try fails, unretryable failure', () async {
      var count = 0;
      await expectLater(
        const ExponentialRetry().run<int>(() async {
          ++count;
          throw BadRequestException('bad request');
        }),
        throwsA(isA<BadRequestException>()),
      );
      expect(count, 1);
    });

    test('first try fails, no retries', () async {
      var count = 0;
      expect(
        () => const ExponentialRetry(maxRetries: 0).run(() async {
          ++count;
          if (count == 1) {
            throw http.ClientException('transport failure');
          } else {
            fail('unexpected retry: $count');
          }
        }),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('second try succeeds', () async {
      var count = 0;
      expect(
        await const ExponentialRetry(initialDelay: Duration()).run(() async {
          ++count;
          if (count == 1) {
            throw http.ClientException('transport failure');
          } else if (count == 2) {
            return 5;
          } else {
            fail('unexpected retry: $count');
          }
        }),
        5,
      );
    });

    test('stops after maxRetries', () async {
      var count = 0;
      await expectLater(
        const NoDelayRetry(maxRetries: 2).run<int>(() async {
          ++count;
          throw http.ClientException('transport failure');
        }),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 3);
    });

    test('retries the errors that retryIf accepts', () async {
      var count = 0;
      expect(
        await const NoDelayRetry(retryIf: _isBadRequest).run(() async {
          if (++count == 1) throw BadRequestException('bad request');
          return 5;
        }),
        5,
      );
      expect(count, 2);
    });

    test('does not retry the errors that retryIf rejects', () async {
      var count = 0;
      await expectLater(
        const NoDelayRetry(retryIf: _isBadRequest).run<int>(() async {
          ++count;
          throw http.ClientException('transport failure');
        }),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });

    test('retries status codes with hasStatusCode', () async {
      final retry = NoDelayRetry(
        retryIf: (e) => hasStatusCode(e, const [Code.unavailable]),
      );

      var count = 0;
      expect(
        await retry.run(() async {
          if (++count == 1) throw ServiceUnavailableException('503');
          return 5;
        }),
        5,
      );
      expect(count, 2);

      count = 0;
      await expectLater(
        retry.run<int>(() async {
          ++count;
          throw InternalServerErrorException('500');
        }),
        throwsA(isA<InternalServerErrorException>()),
      );
      expect(count, 1);
    });

    test('never retries an Error', () async {
      var count = 0;
      await expectLater(
        NoDelayRetry(retryIf: (_) => true).run<int>(() async {
          ++count;
          throw StateError('bug');
        }),
        throwsStateError,
      );
      expect(count, 1);
    });

    test('isRetryable uses retryIf', () {
      const retry = ExponentialRetry(retryIf: _isBadRequest);
      expect(retry.isRetryable(BadRequestException('400')), isTrue);
      expect(retry.isRetryable(ServiceUnavailableException('503')), isFalse);
    });

    test('retryIf defaults to isTransientError', () {
      expect(const ExponentialRetry().retryIf, equals(isTransientError));
      expect(const NoDelayRetry().retryIf, equals(isTransientError));
    });

    test('value equality and hashCode', () {
      // ignore: prefer_const_constructors
      final a = ExponentialRetry(maxRetries: 3, jitter: 0.2);
      // ignore: prefer_const_constructors
      final b = ExponentialRetry(maxRetries: 3, jitter: 0.2);
      // ignore: prefer_const_constructors
      final c = ExponentialRetry(maxRetries: 4, jitter: 0.2);
      // ignore: prefer_const_constructors
      final d = ExponentialRetry(
        retryIf: _isBadRequest,
        maxRetries: 3,
        jitter: 0.2,
      );
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}
