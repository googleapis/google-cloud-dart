[![pub package](https://img.shields.io/pub/v/google_cloud_pubsub.svg)](https://pub.dev/packages/google_cloud_pubsub)
[![package publisher](https://img.shields.io/pub/publisher/google_cloud_pubsub.svg)](https://pub.dev/packages/google_cloud_pubsub/publisher)

A Dart client for Google Cloud Pub/Sub.

> [!NOTE]
> This package is currently experimental and published under the
> [labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order
> to solicit feedback.
>
> For packages in the labs.dart.dev publisher we generally plan to either
> graduate the package into a supported publisher (dart.dev, tools.dart.dev)
> after a period of feedback and iteration, or discontinue the package.
> These packages have a much higher expected rate of API and breaking changes.
>
> Your feedback is valuable and will help us evolve this package. For general
> feedback, suggestions, and comments, please file an issue in the
> [bug tracker](https://github.com/googleapis/google-cloud-dart/issues).

## Using Google Cloud PubSub

All access to Google Cloud Pub/Sub is made through the `PubSub` class.

```dart
import 'dart:convert';
import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';

void main() async {
  // Note: You must provide an `authenticator` for authentication in production.
  final pubSub = PubSub(
    projectId: 'your-project-id',
    authenticator: await applicationDefaultCredentialsAuthenticator(
      ['https://www.googleapis.com/auth/pubsub'],
    ),
  );

  // Create a topic (with optional batching and retry settings).
  final topic = await pubSub.topic(
    'put-your-topic-name-here',
    publishSettings: PublishSettings(
      batching: BatchingSettings(
        maxMessages: 100,
        maxDelay: Duration(milliseconds: 10),
      ),
    ),
  ).create();

  // Create a subscription to that topic.
  final subscription = await pubSub
      .subscription(
        'put-your-subscription-name-here',
        ackSettings: AckSettings(
          batching: BatchingSettings(maxDelay: Duration(milliseconds: 50)),
        ),
      )
      .create(topic: topic.name);

  // Publish a message. This is automatically batched and retried.
  await topic.publish(utf8.encode('message 1'));

  // Pull messages from the subscription.
  final messages = await subscription.pull(maxMessages: 1);

  for (final receivedMessage in messages) {
    print('Received message: ${utf8.decode(receivedMessage.data)}');

    // Acknowledge the message.
    await subscription.acknowledge([receivedMessage.ackId]);
  }

  print(
    'Your topic is available at:\n'
    'https://pubsub.googleapis.com/v1/${topic.name}',
  );

  // Clean up and flush any pending batches.
  subscription.close();
  topic.close();
  
  await subscription.delete();
  await topic.delete();

  pubSub.close();
}
```

> [!NOTE]
> You must [set up authentication][] before using this package outside of 
> Google Cloud.

[set up authentication]: https://docs.cloud.google.com/pubsub/docs/reference/libraries#authentication
