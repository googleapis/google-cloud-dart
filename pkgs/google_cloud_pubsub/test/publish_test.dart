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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as generated;
import 'package:grpc/grpc.dart' as grpc;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('publish', () {
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
          'publish to non-existent topic throws NotFoundException',
          () async {
            final topicName = testResourceName('non-existent');
            final topic = client.topic(topicName);

            expect(
              () => topic.publish(utf8.encode('Hello')),
              throwsA(isA<NotFoundException>()),
            );
          },
        );

        test('publish and pull message with attributes', () async {
          final topicName = testResourceName('test-topic');
          final subscriptionName = testResourceName('test-sub');
          final topic = client.topic(topicName);
          final subscription = client.subscription(subscriptionName);

          await topic.create();
          addTearDown(() async => await topic.delete());

          await subscription.create(topic: topic.name);
          addTearDown(() async => await subscription.delete());

          final data = utf8.encode('Hello PubSub with Attributes');
          final attributes = {'key1': 'value1', 'key2': 'value2'};
          await topic.publish(data, attributes: attributes);

          final messages = await pullReliably(subscription, count: 1);
          expect(messages, hasLength(1));
          expect(messages.first.data, equals(data));
          expect(messages.first.attributes, equals(attributes));

          await subscription.acknowledgeNow([messages.first]);
        });

        test('publish and streaming pull message', () async {
          final topicName = testResourceName('test-topic');
          final subscriptionName = testResourceName('test-sub');
          final topic = client.topic(topicName);
          final subscription = client.subscription(subscriptionName);

          await topic.create();
          addTearDown(() async => await topic.delete());

          await subscription.create(topic: topic.name);
          addTearDown(() async => await subscription.delete());

          final data = utf8.encode('Hello Streaming PubSub');
          await topic.publish(data);

          final stream = subscription.streamingPull();
          final receivedMessage = await stream.first;

          expect(receivedMessage.data, equals(data));
          await subscription.acknowledgeNow([receivedMessage]);
        });

        test(
          'batched publish delivers distinct message IDs and flushes on close',
          () async {
            final topicName = testResourceName('batch-topic');
            final subscriptionName = testResourceName('batch-sub');
            final topic = client.topic(
              topicName,
              publishSettings: PublishSettings(
                batching: BatchingSettings(
                  maxMessages: 100,
                  maxDelay: const Duration(seconds: 30),
                ),
              ),
            );
            final subscription = client.subscription(subscriptionName);

            await topic.create();
            addTearDown(() async => await topic.delete());

            await subscription.create(topic: topic.name);
            addTearDown(() async => await subscription.delete());

            const count = 25;
            final futures = [
              for (var i = 0; i < count; i++)
                topic.publish(
                  utf8.encode('msg-$i'),
                  attributes: {'index': '$i'},
                ),
            ];

            // Closing the topic flushes the pending batch before maxDelay.
            await topic.close();
            final messageIds = await Future.wait(futures);
            expect(messageIds.toSet(), hasLength(count));

            final received = await pullReliably(subscription, count: count);
            expect(received, hasLength(count));
            expect(
              received.map((m) => utf8.decode(m.data)).toSet(),
              equals({for (var i = 0; i < count; i++) 'msg-$i'}),
            );
            await subscription.acknowledgeNow(received);
          },
        );
      },
    );

    group('mock', () {
      late FakePublisherClient fakePublisher;
      late PubSub client;

      setUp(() {
        fakePublisher = FakePublisherClient();
        client = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          publisherClient: fakePublisher,
        );
      });

      tearDown(() async {
        await client.close();
      });

      test(
        'batches concurrent publishes and maps message IDs in order',
        () async {
          final topic = client.topic(
            'test-topic',
            publishSettings: PublishSettings(
              batching: BatchingSettings(
                maxMessages: 3,
                maxDelay: const Duration(seconds: 10),
              ),
            ),
          );

          final f1 = topic.publish([1]);
          final f2 = topic.publish([2]);
          expect(fakePublisher.publishCalled, isFalse);

          final f3 = topic.publish([3]);
          expect(await Future.wait([f1, f2, f3]), ['msg-0', 'msg-1', 'msg-2']);
          expect(fakePublisher.publishCallCount, 1);
        },
      );

      test(
        'retries transient batch failure and completes all futures',
        () async {
          var attempts = 0;
          fakePublisher.publishBehavior = (request) async {
            if (++attempts == 1) {
              throw const grpc.GrpcError.unavailable('Transient failure');
            }
            return generated.PublishResponse()
              ..messageIds.addAll(['id-1', 'id-2']);
          };

          final topic = client.topic(
            'test-topic',
            publishSettings: PublishSettings(
              batching: BatchingSettings(maxMessages: 2),
              retry: const ExponentialRetry(
                initialDelay: Duration(milliseconds: 1),
              ),
            ),
          );

          expect(
            await Future.wait([
              topic.publish([1]),
              topic.publish([2]),
            ]),
            ['id-1', 'id-2'],
          );
          expect(attempts, 2);
        },
      );

      test('keeps every emitted PublishRequest within maxBytes', () async {
        const limit = 250;
        final topic = client.topic(
          'test-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxMessages: 1000,
              maxBytes: limit,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final futures = [
          for (var i = 0; i < 20; i++)
            topic.publish(Uint8List(30), attributes: {'k': 'v-$i'}),
        ];
        await topic.close();
        await Future.wait(futures);

        expect(fakePublisher.recordedRequests.length, greaterThan(1));
        for (final request in fakePublisher.recordedRequests) {
          expect(request.writeToBuffer().length, lessThanOrEqualTo(limit));
        }
      });

      test(
        'close() flushes buffered messages and rejects subsequent publish',
        () async {
          final topic = client.topic(
            'test-topic',
            publishSettings: PublishSettings(
              batching: BatchingSettings(
                maxMessages: 10,
                maxDelay: const Duration(seconds: 10),
              ),
            ),
          );

          final future = topic.publish([1, 2, 3]);
          await topic.close();
          expect(await future, 'msg-0');
          expect(() => topic.publish([4]), throwsStateError);
        },
      );
    });
  });
}
