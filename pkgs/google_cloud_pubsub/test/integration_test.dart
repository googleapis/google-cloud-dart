import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('PubSub Integration', () {
    PubSub? client;

    setUp(() {
      final host = Platform.environment['PUBSUB_EMULATOR_HOST'];
      if (host == null) {
        markTestSkipped('PUBSUB_EMULATOR_HOST environment variable not set');
        return;
      }
      client = PubSub(projectId: 'test-project');
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

      // Publish message
      final messageId = await topic.publish(utf8.encode('Hello World'));
      expect(messageId, isNotNull);

      // Delete topic
      await topic.delete();
    });
  });
}
