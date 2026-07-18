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
  group('publish', () {
    late PubSub client;

    setUp(() async {
      client = await createClient();
    });

    tearDown(() async {
      await client.close();
    });

    test(
      'publish to non-existent topic throws TopicNotFoundException',
      () async {
        final topicName =
            'non-existent-${DateTime.now().millisecondsSinceEpoch}';
        final topic = client.topic(topicName);

        expect(
          () => topic.publish(utf8.encode('Hello')),
          throwsA(isA<TopicNotFoundException>()),
        );
      },
    );

    test('publish and pull message', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client.topic(topicName);
      final subscription = client.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topic.name);
      addTearDown(() async => await subscription.delete());

      final data = utf8.encode('Hello PubSub');
      await topic.publish(data);

      final messages = await pullReliably(subscription, count: 1);
      expect(messages, hasLength(1));
      expect(messages.first.data, equals(data));

      await subscription.acknowledgeNow([messages.first]);
    });

    test('publish and streaming pull message', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
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

    test('publish and pull message with attributes', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
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

    test('publish multiple messages and pull batch', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client.topic(topicName);
      final subscription = client.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topic.name);
      addTearDown(() async => await subscription.delete());

      final data1 = utf8.encode('Message 1');
      final data2 = utf8.encode('Message 2');
      await topic.publish(data1);
      await topic.publish(data2);

      final messages = await pullReliably(subscription, count: 2);
      expect(messages, hasLength(2));

      final receivedData = messages.map((m) => m.data).toList();
      expect(receivedData, containsAll([data1, data2]));

      await subscription.acknowledgeNow(messages);
    });
  });
}
