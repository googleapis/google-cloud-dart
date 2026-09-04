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

@TestOn('vm')
library;

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/retry.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

void main() {
  group('isRetryable', () {
    test('ALREADY_EXISTS (gRPC code 6) must NOT be retried', () {
      const error = grpc.GrpcError.custom(
        grpc.StatusCode.alreadyExists,
        'Already exists',
      );
      expect(isRetryable(error), isFalse);
    });

    test('ConflictException must NOT be retried', () {
      final error = ConflictException('Already exists conflict');
      expect(isRetryable(error), isFalse);
    });

    test('deterministic client errors are not retryable', () {
      expect(isRetryable(NotFoundException('not found')), isFalse);
      expect(isRetryable(ForbiddenException('forbidden')), isFalse);
      expect(isRetryable(BadRequestException('bad request')), isFalse);
      expect(isRetryable(UnauthorizedException('unauthorized')), isFalse);
      expect(isRetryable(PreconditionFailedException('precondition')), isFalse);
      expect(
        isRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.invalidArgument,
            'invalid argument',
          ),
        ),
        isFalse,
      );
      expect(
        isRetryable(
          const grpc.GrpcError.custom(grpc.StatusCode.notFound, 'not found'),
        ),
        isFalse,
      );
      expect(
        isRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.permissionDenied,
            'permission denied',
          ),
        ),
        isFalse,
      );
      expect(
        isRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.unauthenticated,
            'unauthenticated',
          ),
        ),
        isFalse,
      );
      expect(
        isRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.unimplemented,
            'unimplemented',
          ),
        ),
        isFalse,
      );
    });

    test('transient errors are retryable', () {
      expect(isRetryable(const grpc.GrpcError.aborted('aborted')), isTrue);
      expect(
        isRetryable(const grpc.GrpcError.unavailable('service unavailable')),
        isTrue,
      );
      expect(
        isRetryable(const grpc.GrpcError.deadlineExceeded('deadline exceeded')),
        isTrue,
      );
      expect(
        isRetryable(const grpc.GrpcError.internal('internal error')),
        isTrue,
      );
      expect(
        isRetryable(
          const grpc.GrpcError.resourceExhausted('resource exhausted'),
        ),
        isTrue,
      );
      expect(isRetryable(const grpc.GrpcError.unknown('unknown')), isTrue);
      expect(
        isRetryable(ServiceUnavailableException('service unavailable')),
        isTrue,
      );
      expect(isRetryable(GatewayTimeoutException('timeout')), isTrue);
      expect(
        isRetryable(TooManyRequestsException('too many requests')),
        isTrue,
      );
      expect(
        isRetryable(InternalServerErrorException('internal server error')),
        isTrue,
      );
    });

    test('non-Exception objects are not retryable', () {
      expect(isRetryable(StateError('state error')), isFalse);
      expect(isRetryable(ArgumentError('argument error')), isFalse);
      expect(isRetryable('string error'), isFalse);
    });

    test('StatusCode.aborted is retryable for raw and mapped exceptions', () {
      expect(isRetryable(const grpc.GrpcError.aborted('aborted')), isTrue);
      expect(
        isRetryable(
          ConflictException(
            'aborted',
            status: Status(code: grpc.StatusCode.aborted, message: 'aborted'),
          ),
        ),
        isTrue,
      );
      expect(
        isRetryable(
          ServiceException('aborted', statusCode: grpc.StatusCode.aborted),
        ),
        isTrue,
      );
      // Plain ConflictException without aborted is NOT retryable
      expect(isRetryable(ConflictException('conflict')), isFalse);
    });

    test(
      'StatusCode.dataLoss is NOT retryable for raw and mapped exceptions',
      () {
        expect(
          isRetryable(
            const grpc.GrpcError.custom(grpc.StatusCode.dataLoss, 'data loss'),
          ),
          isFalse,
        );
        expect(
          isRetryable(
            ServiceException(
              'data loss',
              statusCode: grpc.StatusCode.dataLoss,
              status: Status(
                code: grpc.StatusCode.dataLoss,
                message: 'data loss',
              ),
            ),
          ),
          isFalse,
        );
        expect(
          isRetryable(
            InternalServerErrorException(
              'data loss',
              status: Status(
                code: grpc.StatusCode.dataLoss,
                message: 'data loss',
              ),
            ),
          ),
          isFalse,
        );
      },
    );
  });

  group('RetrySettings', () {
    test('defaults and backwards compatibility with maxRetryInterval', () {
      final settings = RetrySettings();
      expect(settings.totalTimeout, equals(const Duration(minutes: 1)));
      expect(settings.initialDelay, equals(const Duration(milliseconds: 100)));
      expect(settings.delayMultiplier, equals(1.3));
      expect(settings.maxDelay, equals(const Duration(seconds: 60)));
      expect(settings.maxRetries, isNull);

      // ignore: deprecated_member_use_from_same_package
      expect(settings.maxRetryInterval, equals(const Duration(minutes: 1)));

      // ignore: deprecated_member_use_from_same_package
      final deprecatedSettings = RetrySettings(
        maxRetryInterval: const Duration(seconds: 30),
      );
      expect(
        deprecatedSettings.totalTimeout,
        equals(const Duration(seconds: 30)),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(
        deprecatedSettings.maxRetryInterval,
        equals(const Duration(seconds: 30)),
      );

      final unlimited = settings.copyWith(totalTimeout: null);
      expect(unlimited.totalTimeout, isNull);
    });

    test('parameter validation throws ArgumentError for invalid values', () {
      expect(
        () => RetrySettings(maxRetries: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(maxRetries: -10),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(delayMultiplier: -1.0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(delayMultiplier: 0.0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(delayMultiplier: 0.5),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(initialDelay: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(initialDelay: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(maxDelay: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(maxDelay: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(totalTimeout: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(totalTimeout: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(totalTimeout: const Duration(microseconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RetrySettings(totalTimeout: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(
        () => RetrySettings(maxRetryInterval: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(
        () => RetrySettings(maxRetryInterval: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('valid parameter edge cases succeed', () {
      final zeroRetries = RetrySettings(maxRetries: 0);
      expect(zeroRetries.maxRetries, equals(0));

      final minMultiplier = RetrySettings(delayMultiplier: 1.0);
      expect(minMultiplier.delayMultiplier, equals(1.0));

      final nullTimeout = RetrySettings(totalTimeout: null);
      expect(nullTimeout.totalTimeout, isNull);
    });

    test('copyWith parameter validation throws ArgumentError', () {
      final base = RetrySettings();

      expect(
        () => base.copyWith(maxRetries: -1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(maxRetries: -5),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(maxRetries: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(delayMultiplier: -1.0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(delayMultiplier: 0.0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(delayMultiplier: 0.99),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(initialDelay: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(initialDelay: const Duration(milliseconds: -10)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(maxDelay: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(maxDelay: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(totalTimeout: Duration.zero),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(totalTimeout: const Duration(seconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(totalTimeout: const Duration(microseconds: -1)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => base.copyWith(totalTimeout: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );

      final updated = base.copyWith(
        maxRetries: 0,
        delayMultiplier: 1.0,
        totalTimeout: null,
      );
      expect(updated.maxRetries, equals(0));
      expect(updated.delayMultiplier, equals(1.0));
      expect(updated.totalTimeout, isNull);
    });
  });

  group('delaySequence and randomized jitter', () {
    test('randomized jitter produces varied delays within ±20% bounds', () {
      const initialDelay = Duration(milliseconds: 100);
      const maxDelay = Duration(seconds: 10);
      const multiplier = 2.0;

      final delays = delaySequence(
        maxRetries: 5,
        totalTimeout: const Duration(minutes: 5),
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: multiplier,
      ).toList();

      expect(delays.length, equals(5));

      for (var i = 0; i < delays.length; i++) {
        final base = initialDelay * pow(multiplier, i);
        final minBound = Duration(
          microseconds: (base.inMicroseconds * 0.799).round(),
        );
        final maxBound = Duration(
          microseconds: (base.inMicroseconds * 1.201).round(),
        );
        expect(
          delays[i] >= minBound && delays[i] <= maxBound,
          isTrue,
          reason:
              'Step $i delay ${delays[i]} should be between '
              '$minBound and $maxBound',
        );
      }
    });

    test('multiple sequences produce varied delays due to randomness', () {
      const initialDelay = Duration(milliseconds: 100);
      const maxDelay = Duration(seconds: 10);

      final seq1 = delaySequence(
        maxRetries: 10,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: 1.5,
      ).toList();

      final seq2 = delaySequence(
        maxRetries: 10,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: 1.5,
      ).toList();

      expect(seq1, isNot(equals(seq2)));
    });

    test('clamps to maxDelay with jitter applied to maxDelay', () {
      const initialDelay = Duration(seconds: 1);
      const maxDelay = Duration(seconds: 2);
      const multiplier = 3.0;

      final delays = delaySequence(
        maxRetries: 5,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: multiplier,
      ).toList();

      // Step 0: base 1s -> [800ms, 1200ms]
      expect(delays[0].inMicroseconds, inInclusiveRange(800000, 1200000));

      // Step 1: raw 3s >= max 2s -> base 2s -> [1600ms, 2400ms]
      expect(delays[1].inMicroseconds, inInclusiveRange(1600000, 2400000));

      // Step 2: raw 9s >= max 2s -> base 2s -> [1600ms, 2400ms]
      expect(delays[2].inMicroseconds, inInclusiveRange(1600000, 2400000));
    });

    test('stops yielding after totalTimeout', () {
      var currentTime = DateTime(2026, 1, 1, 0, 0, 0);
      final testClock = Clock(() => currentTime);

      final delays = delaySequence(
        totalTimeout: const Duration(seconds: 5),
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 1),
        delayMultiplier: 1.0,
        clock: testClock,
      ).iterator;

      var yieldedCount = 0;
      while (delays.moveNext()) {
        yieldedCount++;
        currentTime = currentTime.add(const Duration(seconds: 2));
      }

      // At t=0: yields step 1, currentTime advances to 2s
      // At t=2: yields step 2, currentTime advances to 4s
      // At t=4: yields step 3, currentTime advances to 6s
      // At t=6: 6s > 5s totalTimeout, breaks
      expect(yieldedCount, equals(3));
    });

    test('reproducible jitter with seeded Random', () {
      final rng1 = Random(42);
      final rng2 = Random(42);

      final delays1 = delaySequence(
        maxRetries: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 1),
        delayMultiplier: 1.5,
        random: rng1,
      ).toList();

      final delays2 = delaySequence(
        maxRetries: 5,
        initialDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(seconds: 1),
        delayMultiplier: 1.5,
        random: rng2,
      ).toList();

      expect(delays1, equals(delays2));
    });
  });

  group('runWithRetry', () {
    test('non-retryable error throws immediately without retrying', () async {
      var callCount = 0;
      await expectLater(
        () => runWithRetry(
          () async {
            callCount++;
            throw const grpc.GrpcError.alreadyExists('Already exists');
          },
          settings: RetrySettings(maxRetries: 5),
          isIdempotent: true,
        ),
        throwsA(isA<grpc.GrpcError>()),
      );

      expect(callCount, equals(1));
    });

    test('retryable error retries up to maxRetries', () async {
      var callCount = 0;
      await expectLater(
        () => runWithRetry(
          () async {
            callCount++;
            throw const grpc.GrpcError.unavailable('Unavailable');
          },
          settings: RetrySettings(
            maxRetries: 3,
            initialDelay: const Duration(milliseconds: 1),
            maxDelay: const Duration(milliseconds: 5),
          ),
          isIdempotent: true,
        ),
        throwsA(isA<grpc.GrpcError>()),
      );

      expect(callCount, equals(4)); // 1 initial + 3 retries
    });
  });
}
