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

import 'dart:async';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';

/// An example demonstrating how to initialize and use the [PubSub] client
/// with Google Application Default Credentials (ADC) authentication.
Future<void> main() async {
  // Asynchronously construct the ADC authenticator with the required Pub/Sub scope.
  final authenticator = await applicationDefaultCredentialsAuthenticator([
    'https://www.googleapis.com/auth/pubsub',
  ]);

  // Pass the authenticator to the PubSub client constructor.
  final pubsub = PubSub(
    projectId: 'my-project-id',
    authenticator: authenticator,
  );

  try {
    // The client will use the authenticator to make authenticated requests.
    // Topics and Subscriptions handle batching and robust retries automatically.
    final topic = pubsub.topic(
      'my-topic',
      publishSettings: const PublishSettings(
        batching: BatchingSettings(
          maxMessages: 50,
          maxDelay: Duration(milliseconds: 20),
        ),
      ),
    );
    print('Successfully initialized client for topic: ${topic.topicId}');

    // Messages published will be batched.
    // await topic.publish(utf8.encode('Hello World'));

    // Example of using a subscription with AckSettings
    final subscription = pubsub.subscription(
      'my-subscription',
      ackSettings: const AckSettings(
        batching: BatchingSettings(
          maxMessages: 50,
          maxDelay: Duration(milliseconds: 20),
        ),
      ),
    );

    // Pull and acknowledge messages
    // final messages = await subscription.pull(maxMessages: 10);
    // for (final message in messages) {
    //   print('Received: ${utf8.decode(message.message.data)}');
    //   // Acknowledges are batched automatically in the background
    //   subscription.acknowledge(message);
    // }

    // Ensure pending batches are flushed.
    topic.close();
    subscription.close();
  } finally {
    await pubsub.close();
  }
}
