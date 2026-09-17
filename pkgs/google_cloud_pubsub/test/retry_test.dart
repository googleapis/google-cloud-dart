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

import 'package:clock/clock.dart';
import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

void main() {
  group('isPubSubRetryable', () {
    test('ALREADY_EXISTS (gRPC code 6) must NOT be retried', () {
      const error = grpc.GrpcError.custom(
        grpc.StatusCode.alreadyExists,
        'Already exists',
      );
      expect(isPubSubRetryable(error), isFalse);
    });

    test('ConflictException must NOT be retried', () {
      final error = ConflictException('Already exists conflict');
      expect(isPubSubRetryable(error), isFalse);
    });

    test('deterministic client errors are not retryable', () {
      expect(isPubSubRetryable(NotFoundException('not found')), isFalse);
      expect(isPubSubRetryable(ForbiddenException('forbidden')), isFalse);
      expect(isPubSubRetryable(BadRequestException('bad request')), isFalse);
      expect(isPubSubRetryable(UnauthorizedException('unauthorized')), isFalse);
      expect(
        isPubSubRetryable(PreconditionFailedException('precondition')),
        isFalse,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.invalidArgument,
            'invalid argument',
          ),
        ),
        isFalse,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(grpc.StatusCode.notFound, 'not found'),
        ),
        isFalse,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.permissionDenied,
            'permission denied',
          ),
        ),
        isFalse,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.unauthenticated,
            'unauthenticated',
          ),
        ),
        isFalse,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.unimplemented,
            'unimplemented',
          ),
        ),
        isFalse,
      );
    });

    test('transient errors are retryable', () {
      expect(
        isPubSubRetryable(const grpc.GrpcError.aborted('aborted')),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.unavailable('service unavailable'),
        ),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.deadlineExceeded('deadline exceeded'),
        ),
        isTrue,
      );
      expect(
        isPubSubRetryable(const grpc.GrpcError.internal('internal error')),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.resourceExhausted('resource exhausted'),
        ),
        isTrue,
      );
      expect(
        isPubSubRetryable(const grpc.GrpcError.unknown('unknown')),
        isTrue,
      );
      expect(
        isPubSubRetryable(ServiceUnavailableException('service unavailable')),
        isTrue,
      );
      expect(isPubSubRetryable(GatewayTimeoutException('timeout')), isTrue);
      expect(
        isPubSubRetryable(TooManyRequestsException('too many requests')),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          InternalServerErrorException('internal server error'),
        ),
        isTrue,
      );
    });

    test('non-Exception objects are not retryable', () {
      expect(isPubSubRetryable(StateError('state error')), isFalse);
      expect(isPubSubRetryable(ArgumentError('argument error')), isFalse);
      expect(isPubSubRetryable('string error'), isFalse);
    });

    test('StatusCode.aborted is retryable for raw and mapped exceptions', () {
      expect(
        isPubSubRetryable(const grpc.GrpcError.aborted('aborted')),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          ConflictException(
            'aborted',
            status: Status(code: grpc.StatusCode.aborted, message: 'aborted'),
          ),
        ),
        isTrue,
      );
      expect(
        isPubSubRetryable(
          ServiceException(
            'aborted',
            statusCode: 500,
            status: Status(code: grpc.StatusCode.aborted, message: 'aborted'),
          ),
        ),
        isTrue,
      );
      // Plain ConflictException without aborted is NOT retryable
      expect(isPubSubRetryable(ConflictException('conflict')), isFalse);
    });

    test('BadGatewayException and RequestTimeoutException are retryable', () {
      expect(isPubSubRetryable(BadGatewayException('bad gateway')), isTrue);
      expect(
        isPubSubRetryable(RequestTimeoutException('request timeout')),
        isTrue,
      );
    });

    test(
      'StatusCode.dataLoss is NOT retryable for raw and mapped exceptions',
      () {
        expect(
          isPubSubRetryable(
            const grpc.GrpcError.custom(grpc.StatusCode.dataLoss, 'data loss'),
          ),
          isFalse,
        );
        expect(
          isPubSubRetryable(
            ServiceException(
              'data loss',
              statusCode: 500,
              status: Status(
                code: grpc.StatusCode.dataLoss,
                message: 'data loss',
              ),
            ),
          ),
          isFalse,
        );
        expect(
          isPubSubRetryable(
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

  group('defaultPubSubRetry', () {
    test('defaults match Pub/Sub exponential backoff specification', () {
      expect(
        defaultPubSubRetry.maxRetryInterval,
        equals(const Duration(minutes: 1)),
      );
      expect(
        defaultPubSubRetry.initialDelay,
        equals(const Duration(milliseconds: 100)),
      );
      expect(defaultPubSubRetry.delayMultiplier, equals(1.3));
      expect(defaultPubSubRetry.maxDelay, equals(const Duration(seconds: 60)));
      expect(defaultPubSubRetry.jitter, equals(0.2));
      expect(defaultPubSubRetry.maxRetries, isNull);
    });
  });

  group('RetryRunner.run with Pub/Sub errors', () {
    const testRetry = ExponentialRetry(
      maxRetries: 3,
      initialDelay: Duration(milliseconds: 1),
      maxDelay: Duration(milliseconds: 5),
      jitter: 0.2,
      isRetryable: isPubSubRetryable,
    );

    test('non-retryable error throws immediately without retrying', () async {
      var callCount = 0;
      await expectLater(
        () => testRetry.run(() async {
          callCount++;
          throw const grpc.GrpcError.alreadyExists('Already exists');
        }, isIdempotent: true),
        throwsA(isA<grpc.GrpcError>()),
      );

      expect(callCount, equals(1));
    });

    test('retryable error retries up to maxRetries', () async {
      var callCount = 0;
      await expectLater(
        () => testRetry.run(() async {
          callCount++;
          throw const grpc.GrpcError.unavailable('Unavailable');
        }, isIdempotent: true),
        throwsA(isA<grpc.GrpcError>()),
      );

      expect(callCount, equals(4)); // 1 initial + 3 retries
    });

    test('isIdempotent false throws immediately without retrying', () async {
      var callCount = 0;
      await expectLater(
        () => testRetry.run(() async {
          callCount++;
          throw const grpc.GrpcError.unavailable('Unavailable');
        }, isIdempotent: false),
        throwsA(isA<grpc.GrpcError>()),
      );
      expect(callCount, equals(1));
    });

    test('returns value on initial attempt success', () async {
      final result = await testRetry.run(
        () async => 'success',
        isIdempotent: true,
      );
      expect(result, equals('success'));
    });

    test('recovers after transient retryable errors', () async {
      var attempts = 0;
      final result = await testRetry.run(() async {
        attempts++;
        if (attempts < 3) {
          throw const grpc.GrpcError.unavailable('Unavailable');
        }
        return 'recovered';
      }, isIdempotent: true);
      expect(result, equals('recovered'));
      expect(attempts, equals(3));
    });

    test('retries retryable ServiceException', () async {
      var attempts = 0;
      final result = await testRetry.run(() async {
        attempts++;
        if (attempts < 2) {
          throw ServiceUnavailableException('Service Unavailable');
        }
        return 'done';
      }, isIdempotent: true);
      expect(result, equals('done'));
      expect(attempts, equals(2));
    });

    test('maxRetryInterval halts retries when deadline expires', () async {
      var currentTime = DateTime(2026, 1, 1, 12, 0);
      final mockClock = Clock(() => currentTime);
      var callCount = 0;

      const timeoutRetry = ExponentialRetry(
        maxRetryInterval: Duration(seconds: 1),
        initialDelay: Duration(milliseconds: 1),
        maxDelay: Duration(milliseconds: 5),
        isRetryable: isPubSubRetryable,
      );

      await expectLater(
        () => timeoutRetry.run(
          () async {
            callCount++;
            // Advance time past the 1-second timeout
            currentTime = currentTime.add(const Duration(seconds: 2));
            throw const grpc.GrpcError.unavailable('Unavailable');
          },
          isIdempotent: true,
          clock: mockClock,
        ),
        throwsA(isA<grpc.GrpcError>()),
      );

      expect(callCount, equals(1));
    });

    test(
      'ExponentialRetry with maxRetries: 0 executes exactly once and rethrows',
      () async {
        var attempts = 0;
        const zeroRetry = ExponentialRetry(
          maxRetries: 0,
          isRetryable: isPubSubRetryable,
        );
        await expectLater(
          () => zeroRetry.run(() async {
            attempts++;
            throw const grpc.GrpcError.unavailable('Transient');
          }, isIdempotent: true),
          throwsA(isA<grpc.GrpcError>()),
        );
        expect(attempts, equals(1));
      },
    );
  });
}
