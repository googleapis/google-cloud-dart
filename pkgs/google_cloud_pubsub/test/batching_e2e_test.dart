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
@Tags(['firebase-emulator'])
library;

import 'dart:convert';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('batching against a real server', () {
    late PubSub client;
    late Topic topic;
    late Subscription subscription;

    setUp(() async {
      client = await createClient();
      final suffix = DateTime.now().microsecondsSinceEpoch;
      topic = client.topic('test-topic-$suffix');
      subscription = client.subscription('test-sub-$suffix');

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topic.name);
      addTearDown(() async => await subscription.delete());
    });

    tearDown(() async {
      await client.close();
    });

    test('batched publish delivers every message with a distinct id', () async {
      // The messages are handed to the batcher without an intervening await,
      // so they are all buffered before the batch delay elapses. With the
      // default maxMessages of 100 they are published as a single request,
      // which is the path that message ids are mapped back over.
      const messageCount = 25;
      final publishes = [
        for (var i = 0; i < messageCount; i++)
          topic.publish(utf8.encode('batched-message-$i')),
      ];
      final messageIds = await Future.wait(publishes);

      expect(messageIds, hasLength(messageCount));
      expect(messageIds, everyElement(isNotEmpty));
      expect(
        messageIds.toSet(),
        hasLength(messageCount),
        reason: 'the server should assign a distinct id to every message',
      );

      final received = await pullReliably(subscription, count: messageCount);
      expect(received, hasLength(messageCount));
      expect(
        received.map((message) => utf8.decode(message.data)).toSet(),
        equals({for (var i = 0; i < messageCount; i++) 'batched-message-$i'}),
      );

      await subscription.acknowledgeNow(received);
    });

    test('publishes spanning several batches all arrive', () async {
      // Exceeds the default maxMessages of 100, so this spans two requests.
      const messageCount = 150;
      final publishes = [
        for (var i = 0; i < messageCount; i++)
          topic.publish(utf8.encode('spanning-message-$i')),
      ];
      final messageIds = await Future.wait(publishes);

      expect(messageIds.toSet(), hasLength(messageCount));

      final received = await pullReliably(subscription, count: messageCount);
      expect(received, hasLength(messageCount));
      expect(
        received.map((message) => utf8.decode(message.data)).toSet(),
        equals({for (var i = 0; i < messageCount; i++) 'spanning-message-$i'}),
      );

      await subscription.acknowledgeNow(received);
    });

    test('close flushes messages that are still buffered', () async {
      // A batch delay far longer than the test means the timer can never
      // fire, and three small messages reach neither maxMessages nor
      // maxBytes. Flushing on close is therefore the only way these are
      // ever published.
      final bufferedTopic = client.topic(
        topic.id,
        publishSettings: PublishSettings(
          batching: BatchingSettings(maxDelay: const Duration(minutes: 10)),
        ),
      );

      // Deliberately not awaited: these are still sitting in the batcher
      // when close is called.
      final publishes = [
        for (var i = 0; i < 3; i++)
          bufferedTopic.publish(utf8.encode('pending-$i')),
      ];

      await bufferedTopic.close();
      await Future.wait(publishes);

      final received = await pullReliably(subscription, count: 3);
      expect(received, hasLength(3));
      expect(
        received.map((message) => utf8.decode(message.data)).toSet(),
        equals({'pending-0', 'pending-1', 'pending-2'}),
      );

      await subscription.acknowledgeNow(received);
    });

    test('batched acknowledgment prevents redelivery', () async {
      await topic.publish(utf8.encode('acknowledged'));
      await topic.publish(utf8.encode('nacked'));

      final received = await pullReliably(subscription, count: 2);
      expect(received, hasLength(2));

      final acknowledged = received.firstWhere(
        (message) => utf8.decode(message.data) == 'acknowledged',
      );
      final nacked = received.firstWhere(
        (message) => utf8.decode(message.data) == 'nacked',
      );

      // Goes through the background batcher rather than the unary RPC, and
      // is only sent when close flushes it.
      subscription.acknowledge(acknowledged);
      await subscription.close();

      // The subscription is closed, so continue with a fresh handle to the
      // same subscription on the server.
      final reopened = client.subscription(subscription.id);

      // Release the lease on both messages. Without this the acknowledged
      // message would be withheld simply because it is still leased from
      // the pull above, and a dropped acknowledgment would look identical
      // to a delivered one. With both leases released, the acknowledgment
      // is the only thing that can keep a message from coming back.
      await reopened.modifyAckDeadlineNow([acknowledged, nacked], 0);

      // A single pull returns everything currently available.
      final redelivered = await reopened.pull(maxMessages: 10);
      final redeliveredData = redelivered
          .map((message) => utf8.decode(message.data))
          .toList();

      expect(
        redeliveredData,
        contains('nacked'),
        reason: 'a message that was never acknowledged should come back',
      );
      expect(
        redeliveredData,
        isNot(contains('acknowledged')),
        reason: 'the batched acknowledgment should have reached the server',
      );

      await reopened.acknowledgeNow(redelivered);
    });
  });
}
