import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

import 'src/credentials.dart';

void main() {
  group('PubSub Integration', () {
    PubSub? client;

    Future<List<ReceivedMessage>> pullReliably(
      String subscriptionName, {
      required int count,
    }) async {
      final messages = <ReceivedMessage>[];
      for (var i = 0; i < 10 && messages.length < count; i++) {
        if (i > 0) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        final pulled = await client!.pull(
          subscriptionName,
          maxMessages: count - messages.length,
        );
        messages.addAll(pulled);
      }
      return messages;
    }

    setUp(() async {
      final host = Platform.environment['PUBSUB_EMULATOR_HOST'];
      final project = Platform.environment['GOOGLE_CLOUD_PROJECT'];

      if (host != null) {
        client = PubSub(projectId: 'test-project');
      } else if (project != null) {
        client = PubSub(
          projectId: project,
          tokenProvider: applicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/pubsub'],
          ),
        );
      } else {
        fail(
          'Neither PUBSUB_EMULATOR_HOST nor GOOGLE_CLOUD_PROJECT '
          'environment variable set',
        );
      }
    });

    tearDown(() async {
      await client?.close();
    });

    test('create topic and publish message', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);

      // Create topic
      await topic.create();
      addTearDown(() async => await topic.delete());

      // Publish message
      final messageId = await topic.publish(utf8.encode('Hello World'));
      expect(messageId, isNotNull);

      // Delete topic
      expect(await topic.delete(), isTrue);
    });

    test('Delete non-existent topic returns false', () async {
      final topic = client!.topic(
        'non-existent-${DateTime.now().millisecondsSinceEpoch}',
      );
      final deleted = await topic.delete();
      expect(deleted, isFalse);
    });

    test('create existing topic throws TopicAlreadyExistsException', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      expect(topic.create(), throwsA(isA<TopicAlreadyExistsException>()));

      await topic.delete();
    });

    test(
      'create existing subscription throws SubscriptionAlreadyExistsException',
      () async {
        final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
        final subscriptionName =
            'test-sub-${DateTime.now().millisecondsSinceEpoch}';
        final topic = client!.topic(topicName);
        final subscription = client!.subscription(subscriptionName);

        await topic.create();
        addTearDown(() async => await topic.delete());
        await subscription.create(topic: topicName);
        addTearDown(() async => await subscription.delete());

        expect(
          () => subscription.create(topic: topicName),
          throwsA(isA<SubscriptionAlreadyExistsException>()),
        );

        await subscription.delete();
        await topic.delete();
      },
    );

    test('create subscription for non-existent topic throws '
        'TopicNotFoundException', () async {
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(
        () => subscription.create(topic: 'non-existent-topic'),
        throwsA(isA<TopicNotFoundException>()),
      );
    });

    test(
      'publish to non-existent topic throws TopicNotFoundException',
      () async {
        final topicName =
            'non-existent-${DateTime.now().millisecondsSinceEpoch}';
        final topic = client!.topic(topicName);

        expect(
          () => topic.publish(utf8.encode('Hello')),
          throwsA(isA<TopicNotFoundException>()),
        );
      },
    );

    test('pull from non-existent subscription throws '
        'SubscriptionNotFoundException', () async {
      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(subscription.pull, throwsA(isA<SubscriptionNotFoundException>()));
    });

    test('acknowledge for non-existent subscription throws '
        'SubscriptionNotFoundException', () async {
      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(
        () => subscription.acknowledge(['ack-id']),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });

    test('modifyAckDeadline for non-existent subscription throws '
        'SubscriptionNotFoundException', () async {
      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(
        () => subscription.modifyAckDeadline(['ack-id'], 10),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });

    test('publish and pull message', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-'
          '${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);
      addTearDown(() async => await subscription.delete());

      final data = utf8.encode('Hello PubSub');
      await topic.publish(data);

      // Pull message
      final messages = await pullReliably(subscriptionName, count: 1);
      expect(messages, hasLength(1));
      expect(messages.first.message.data, equals(data));

      // Ack message
      await client!.acknowledge(subscriptionName, [messages.first.ackId]);
    });

    test('publish and streaming pull message', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-'
          '${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);
      addTearDown(() async => await subscription.delete());

      final data = utf8.encode('Hello Streaming PubSub');
      await topic.publish(data);

      // Start streaming pull
      final stream = client!.streamingPull(subscriptionName);

      // Use stream.first to get the first message and automatically cancel the
      // stream.
      final receivedMessage = await stream.first;

      expect(receivedMessage.message.data, equals(data));

      // Ack message
      await client!.acknowledge(subscriptionName, [receivedMessage.ackId]);
    });

    test('streaming pull throws StreamBrokenException '
        'when subscription is deleted', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-'
          '${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);

      // Start streaming pull
      final stream = client!.streamingPull(subscriptionName);

      // Delete subscription to break the stream
      await subscription.delete();

      // Expect stream to throw StreamBrokenException
      expect(stream.first, throwsA(isA<StreamBrokenException>()));
    });

    test('publish and pull message with attributes', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);
      addTearDown(() async => await subscription.delete());

      final data = utf8.encode('Hello PubSub with Attributes');
      final attributes = {'key1': 'value1', 'key2': 'value2'};
      await topic.publish(data, attributes: attributes);

      // Pull message
      final messages = await pullReliably(subscriptionName, count: 1);
      expect(messages, hasLength(1));
      expect(messages.first.message.data, equals(data));
      expect(messages.first.message.attributes, equals(attributes));

      // Ack message
      await client!.acknowledge(subscriptionName, [messages.first.ackId]);
    });

    test('publish multiple messages and pull batch', () async {
      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName =
          'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);
      addTearDown(() async => await subscription.delete());

      final data1 = utf8.encode('Message 1');
      final data2 = utf8.encode('Message 2');
      await topic.publish(data1);
      await topic.publish(data2);

      // Pull messages
      final messages = await pullReliably(subscriptionName, count: 2);
      expect(messages, hasLength(2));

      final receivedData = messages.map((m) => m.message.data).toList();
      expect(receivedData, containsAll([data1, data2]));

      // Ack messages
      await client!.acknowledge(
        subscriptionName,
        messages.map((m) => m.ackId).toList(),
      );
    });
  });
}
