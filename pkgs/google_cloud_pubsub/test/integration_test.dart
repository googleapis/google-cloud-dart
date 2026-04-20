@Tags(['google-cloud'])
import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

void main() {
  group('PubSub Integration', () {
    PubSub? client;

    setUp(() async {
      final host = Platform.environment['PUBSUB_EMULATOR_HOST'];
      final project = Platform.environment['GOOGLE_CLOUD_PROJECT'];

      if (host != null) {
        client = PubSub(projectId: 'test-project');
      } else if (project != null) {
        client = PubSub(projectId: project);
      } else {
        markTestSkipped(
          'Neither PUBSUB_EMULATOR_HOST nor GOOGLE_CLOUD_PROJECT '
          'environment variable set',
        );
        return;
      }
    });

    tearDown(() async {
      await client?.close();
    });

    test('create topic and publish message', () async {
      if (client == null) return; // Skipped

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
      if (client == null) return; // Skipped

      final topic = client!.topic(
        'non-existent-${DateTime.now().millisecondsSinceEpoch}',
      );
      final deleted = await topic.delete();
      expect(deleted, isFalse);
    });

    test('create existing topic throws TopicAlreadyExistsException', () async {
      if (client == null) return; // Skipped

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
        if (client == null) return; // Skipped

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
      if (client == null) return; // Skipped

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
        if (client == null) return; // Skipped

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
      if (client == null) return; // Skipped

      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(subscription.pull, throwsA(isA<SubscriptionNotFoundException>()));
    });

    test('acknowledge for non-existent subscription throws '
        'SubscriptionNotFoundException', () async {
      if (client == null) return; // Skipped

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
      if (client == null) return; // Skipped

      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client!.subscription(subscriptionName);

      expect(
        () => subscription.modifyAckDeadline(['ack-id'], 10),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });

    test('publish and pull message', () async {
      if (client == null) return; // Skipped

      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName = 'test-sub-${DateTime.now().millisecondsSinceEpoch}';
      final topic = client!.topic(topicName);
      final subscription = client!.subscription(subscriptionName);

      await topic.create();
      addTearDown(() async => await topic.delete());

      await subscription.create(topic: topicName);
      addTearDown(() async => await subscription.delete());

      final data = utf8.encode('Hello PubSub');
      await topic.publish(data);

      // Pull message
      final messages = await client!.pull(subscriptionName);
      expect(messages, hasLength(1));
      expect(messages.first.message.data, equals(data));

      // Ack message
      await client!.acknowledge(subscriptionName, [messages.first.ackId]);
    });

    test('publish and streaming pull message', () async {
      if (client == null) return; // Skipped

      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName = 'test-sub-${DateTime.now().millisecondsSinceEpoch}';
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
      
      // Use stream.first to get the first message and automatically cancel the stream.
      final receivedMessage = await stream.first;
      
      expect(receivedMessage.message.data, equals(data));
      
      // Ack message
      await client!.acknowledge(subscriptionName, [receivedMessage.ackId]);
    });

    test('streaming pull throws StreamBrokenException when subscription is deleted', () async {
      if (client == null) return; // Skipped

      final topicName = 'test-topic-${DateTime.now().millisecondsSinceEpoch}';
      final subscriptionName = 'test-sub-${DateTime.now().millisecondsSinceEpoch}';
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
  });
}
