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

Future<void> streamingPullExample(PubSub pubsub) async {
  // #docregion streaming_pull_example
  final subscription = pubsub.subscription('my-subscription');

  // Establish a streaming pull with 3 parallel streams for high throughput
  // and custom retry settings for handling transient connection drops.
  final stream = subscription.streamingPull(
    maxConcurrentStreams: 3,
    streamAckDeadlineSeconds: 30,
    retry: RetrySettings(
      maxRetries: 10,
      initialDelay: const Duration(seconds: 1),
      maxDelay: const Duration(seconds: 30),
    ),
  );

  final listener = stream.listen(
    (ReceivedMessage message) {
      print('Received message: ${message.message.data}');

      // Acknowledge the message. This buffers the ACK in the background
      // and batches it with others, sending it over one of the active
      // gRPC streams or falling back to a unary RPC if streams are down.
      subscription.acknowledge(message);
    },
    onError: (Object error) {
      print('Stream encountered a permanent error: $error');
    },
    onDone: () {
      print('Stream closed.');
    },
  );

  // Later, to stop receiving messages and clean up resources:
  await listener.cancel();
  // #enddocregion streaming_pull_example
}

Future<void> acknowledgeNowExample(PubSub pubsub) async {
  // #docregion acknowledge_now_example
  final subscription = pubsub.subscription('my-subscription');

  // Pull up to 10 messages from the subscription.
  final messages = await subscription.pull(maxMessages: 10);

  if (messages.isNotEmpty) {
    try {
      // Acknowledge all pulled messages immediately and wait for the RPC
      // to complete. This bypasses background batching.
      await subscription.acknowledgeNow(messages);
      print('Successfully acknowledged ${messages.length} messages.');
    } on Exception catch (e) {
      print('Failed to acknowledge messages: $e');
    }
  }
  // #enddocregion acknowledge_now_example
}
