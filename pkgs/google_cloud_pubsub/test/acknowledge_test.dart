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

import 'dart:convert';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('acknowledge', () {
    group(
      'google-cloud / emulator',
      tags: ['firebase-emulator', 'google-cloud'],
      () {
        late PubSub client;

        setUp(() async {
          client = await createClient();
        });

        tearDown(() async {
          await client.close();
        });

        test(
          'acknowledge for non-existent subscription throws NotFoundException',
          () async {
            final subscriptionName = testResourceName('non-existent');
            final subscription = client.subscription(subscriptionName);

            expect(
              () => subscription.acknowledgeNow([
                ReceivedMessage(
                  ackId: 'ack-id',
                  messageId: 'msg-id',
                  publishTime: DateTime.now(),
                  message: Message(data: []),
                ),
              ]),
              throwsA(isA<NotFoundException>()),
            );
          },
        );

        test(
          'batched acknowledge flushed on close() prevents redelivery',
          () async {
            final topicName = testResourceName('ack-topic');
            final subscriptionName = testResourceName('ack-sub');
            final topic = client.topic(topicName);
            final subscription = client.subscription(
              subscriptionName,
              ackSettings: AckSettings(
                batching: BatchingSettings(
                  maxMessages: 50,
                  maxDelay: const Duration(seconds: 30),
                ),
              ),
            );

            await topic.create();
            addTearDown(() async => await topic.delete());

            await subscription.create(topic: topic.name);
            addTearDown(() async => await subscription.delete());

            for (var i = 0; i < 5; i++) {
              await topic.publish(utf8.encode('ack-msg-$i'));
            }
            await topic.close();

            final received = await pullReliably(subscription, count: 5);
            expect(received, hasLength(5));
            for (final msg in received) {
              subscription.acknowledge(msg);
            }
            await subscription.close();

            final reopen = client.subscription(subscriptionName);
            addTearDown(() async => await reopen.close());
            final redelivered = await reopen.pull(maxMessages: 5);
            expect(redelivered, isEmpty);
          },
        );
      },
    );

    group('mock', () {
      late FakeSubscriberClient fakeSubscriber;
      late PubSub client;

      setUp(() {
        fakeSubscriber = FakeSubscriberClient();
        client = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          subscriberClient: fakeSubscriber,
        );
      });

      tearDown(() async {
        await client.close();
      });

      ReceivedMessage dummyMessage(String ackId) => ReceivedMessage(
        ackId: ackId,
        messageId: 'msg-$ackId',
        publishTime: DateTime.now(),
        message: Message(data: const [1]),
      );

      test(
        'batches and deduplicates ack IDs, retrying on transient error',
        () async {
          var attempts = 0;
          fakeSubscriber.acknowledgeBehavior = (ackIds) async {
            if (++attempts == 1) {
              throw const grpc.GrpcError.unavailable('Transient');
            }
          };

          final sub =
              client.subscription(
                  'test-sub',
                  ackSettings: AckSettings(
                    batching: BatchingSettings(
                      maxMessages: 10,
                      maxDelay: const Duration(seconds: 10),
                    ),
                    retry: const ExponentialRetry(
                      initialDelay: Duration(milliseconds: 1),
                    ),
                  ),
                )
                ..acknowledge(dummyMessage('ack-1'))
                ..acknowledge(dummyMessage('ack-1'))
                ..acknowledge(dummyMessage('ack-2'));

          await sub.close();
          expect(attempts, 2);
          expect(fakeSubscriber.lastAckIds, ['ack-1', 'ack-2']);
          expect(
            () => sub.acknowledge(dummyMessage('ack-3')),
            throwsStateError,
          );
        },
      );

      test('keeps every emitted AcknowledgeRequest within maxBytes', () async {
        const limit = 250;
        final sub = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1000,
              maxBytes: limit,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        for (var i = 0; i < 20; i++) {
          sub.acknowledge(dummyMessage('ack-${'x' * 30}-$i'));
        }
        await sub.close();

        expect(fakeSubscriber.recordedAckRequests.length, greaterThan(1));
        for (final request in fakeSubscriber.recordedAckRequests) {
          expect(request.writeToBuffer().length, lessThanOrEqualTo(limit));
        }
      });
    });
  });
}
