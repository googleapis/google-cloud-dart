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

// #docregion main
import 'dart:convert';
import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';

void main() async {
  // By default, `PubSub` will automatically authenticate using
  // Application Default Credentials (ADC).
  final pubSub = PubSub(projectId: 'your-project-id');

  // Create a topic (with optional batching and retry settings).
  final topic = await pubSub
      .topic(
        'put-your-topic-name-here',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 100,
            maxDelay: const Duration(milliseconds: 10),
          ),
        ),
      )
      .create();

  // Create a subscription to that topic.
  final subscription = await pubSub
      .subscription(
        'put-your-subscription-name-here',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxDelay: const Duration(milliseconds: 50),
          ),
        ),
      )
      .create(topic: topic.name);

  // Publish a message. This is automatically batched and retried.
  await topic.publish(utf8.encode('message 1'));

  // Pull messages from the subscription.
  final messages = await subscription.pull(maxMessages: 1);

  for (final receivedMessage in messages) {
    print('Received message: ${utf8.decode(receivedMessage.data)}');

    // Acknowledge the message in the background.
    subscription.acknowledge(receivedMessage);
  }

  // Or receive messages continuously via streaming pull.
  await topic.publish(utf8.encode('message 2'));
  await for (final message
      in subscription.streamingPull(maxConcurrentStreams: 2).take(1)) {
    print('Streamed message: ${utf8.decode(message.data)}');
    await message.acknowledge();
  }

  print(
    'Your topic is available at:\n'
    'https://pubsub.googleapis.com/v1/${topic.name}',
  );

  // Clean up and flush any pending batches.
  await subscription.close();
  await topic.close();

  await subscription.delete();
  await topic.delete();

  await pubSub.close();
}

// #enddocregion main
