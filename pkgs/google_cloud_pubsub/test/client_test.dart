import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

void main() {
  group('PubSub', () {
    test('constructs with project ID', () async {
      final client = PubSub(projectId: 'my-project');
      addTearDown(client.close);
      expect(client, isNotNull);
    });

    test('topic returns a Topic instance', () {
      final client = PubSub(projectId: 'my-project');
      addTearDown(client.close);
      final topic = client.topic('my-topic');
      expect(topic, isNotNull);
      expect(topic.name, 'my-topic');
    });

    test('subscription returns a Subscription instance', () {
      final client = PubSub(projectId: 'my-project');
      addTearDown(client.close);
      final subscription = client.subscription('my-subscription');
      expect(subscription, isNotNull);
      expect(subscription.name, 'my-subscription');
    });
  });
}
