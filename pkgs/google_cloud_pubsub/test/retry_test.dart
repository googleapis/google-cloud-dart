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
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('defaultRetry', () {
    test('defaults match Pub/Sub exponential backoff specification', () {
      expect(defaultRetry.maxRetryInterval, equals(const Duration(minutes: 1)));
      expect(
        defaultRetry.initialDelay,
        equals(const Duration(milliseconds: 100)),
      );
      expect(defaultRetry.delayMultiplier, equals(1.3));
      expect(defaultRetry.maxDelay, equals(const Duration(seconds: 60)));
      expect(defaultRetry.jitter, equals(0.2));
      expect(defaultRetry.maxRetries, isNull);
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
              defaultRetry.isRetryable,
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
              defaultRetry.isRetryable,
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
              defaultRetry.isRetryable,
              'retryable',
              isFalse,
            ),
          ),
        );
      },
    );
  });
}
