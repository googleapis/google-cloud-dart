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

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/retry.dart';
import 'package:grpc/grpc.dart' as grpc;

import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('isPubSubRetryable', () {
    test('deterministic client errors are not retryable', () {
      expect(isPubSubRetryable(NotFoundException('not found')), isFalse);
      expect(isPubSubRetryable(ForbiddenException('forbidden')), isFalse);
      expect(isPubSubRetryable(BadRequestException('bad request')), isFalse);
      expect(isPubSubRetryable(UnauthorizedException('unauthorized')), isFalse);
      expect(isPubSubRetryable(ConflictException('conflict')), isFalse);
      expect(
        isPubSubRetryable(
          const grpc.GrpcError.custom(
            grpc.StatusCode.alreadyExists,
            'already exists',
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
            grpc.StatusCode.invalidArgument,
            'invalid argument',
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
        isPubSubRetryable(ServiceUnavailableException('unavailable')),
        isTrue,
      );
      expect(isPubSubRetryable(GatewayTimeoutException('timeout')), isTrue);
      expect(
        isPubSubRetryable(TooManyRequestsException('too many requests')),
        isTrue,
      );
      expect(
        isPubSubRetryable(InternalServerErrorException('internal')),
        isTrue,
      );
    });

    test(
      'mapped ABORTED is retryable while DATA_LOSS and ALREADY_EXISTS are not',
      () async {
        final fakePublisher = FakePublisherClient();
        final client = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          publisherClient: fakePublisher,
        );
        addTearDown(client.close);

        fakePublisher.publishBehavior = (_) async =>
            throw const grpc.GrpcError.aborted('aborted');
        await expectLater(
          client.publish('projects/test-project/topics/t', [1]),
          throwsA(
            isA<ConflictException>().having(
              isPubSubRetryable,
              'retryable',
              isTrue,
            ),
          ),
        );

        fakePublisher.publishBehavior = (_) async =>
            throw const grpc.GrpcError.alreadyExists('already exists');
        await expectLater(
          client.publish('projects/test-project/topics/t', [1]),
          throwsA(
            isA<ConflictException>().having(
              isPubSubRetryable,
              'retryable',
              isFalse,
            ),
          ),
        );

        fakePublisher.publishBehavior = (_) async =>
            throw const grpc.GrpcError.dataLoss('data loss');
        await expectLater(
          client.publish('projects/test-project/topics/t', [1]),
          throwsA(
            isA<InternalServerErrorException>().having(
              isPubSubRetryable,
              'retryable',
              isFalse,
            ),
          ),
        );
      },
    );
  });

  group('defaultPubSubRetry & normalizePubSubRetry', () {
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

    test('normalizePubSubRetry substitutes isPubSubRetryable by default', () {
      final normalized =
          normalizePubSubRetry(const ExponentialRetry(maxRetries: 3))
              as ExponentialRetry;
      expect(normalized.maxRetries, 3);
      expect(normalized.isRetryable, same(isPubSubRetryable));
    });
  });
}
