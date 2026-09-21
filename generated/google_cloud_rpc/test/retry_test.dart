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
    });
  });

  group('defaultRetry.isRetryable', () {
    test('classifies retryable exceptions', () {
      expect(defaultRetry.isRetryable(TooManyRequestsException('429')), isTrue);
      expect(
        defaultRetry.isRetryable(InternalServerErrorException('500')),
        isTrue,
      );
      expect(defaultRetry.isRetryable(BadGatewayException('502')), isTrue);
      expect(
        defaultRetry.isRetryable(ServiceUnavailableException('503')),
        isTrue,
      );
      expect(defaultRetry.isRetryable(GatewayTimeoutException('504')), isTrue);
      expect(defaultRetry.isRetryable(RequestTimeoutException('408')), isTrue);
      expect(defaultRetry.isRetryable(http.ClientException('network')), isTrue);
      expect(
        defaultRetry.isRetryable(ChecksumValidationException('bad checksum')),
        isTrue,
      );
      expect(
        defaultRetry.isRetryable(
          ConflictException('aborted', status: Status(code: 10)),
        ),
        isTrue,
      );
    });

    test('classifies non-retryable exceptions', () {
      expect(defaultRetry.isRetryable(BadRequestException('400')), isFalse);
      expect(defaultRetry.isRetryable(NotFoundException('404')), isFalse);
      expect(defaultRetry.isRetryable(ConflictException('409')), isFalse);
      expect(
        defaultRetry.isRetryable(
          InternalServerErrorException('data loss', status: Status(code: 15)),
        ),
        isFalse,
      );
    });
  });

  group('ExponentialRetry', () {
    test('first try succeeds', () async {
      expect(
        await const ExponentialRetry().run(() async => 5, isIdempotent: true),
        5,
      );
    });

    test('first try fails, unretryable failure', () async {
      expect(
        () => const ExponentialRetry().run<int>(
          () => throw BadRequestException('bad request'),
          isIdempotent: true,
        ),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('first try fails, non-idempotent', () async {
      var count = 0;
      expect(
        () => const ExponentialRetry(maxRetries: 5).run(() async {
          ++count;
          if (count == 1) {
            throw http.ClientException('transport failure');
          } else {
            fail('unexpected retry: $count');
          }
        }, isIdempotent: false),
        throwsA(isA<http.ClientException>()),
      );
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
        }, isIdempotent: true),
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
        }, isIdempotent: true),
        5,
      );
    });

    test('value equality and hashCode', () {
      const a = ExponentialRetry(maxRetries: 3, jitter: 0.2);
      const b = ExponentialRetry(maxRetries: 3, jitter: 0.2);
      const c = ExponentialRetry(maxRetries: 4, jitter: 0.2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
