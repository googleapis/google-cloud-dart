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

/// An example demonstrating how to initialize and use the [PubSub] client.
Future<void> main() async {
  // By default, `PubSub` will automatically authenticate using
  // Application Default Credentials (ADC).
  final pubsub = PubSub(projectId: 'my-project-id');

  try {
    final topic = pubsub.topic(
      'my-topic',
      publishSettings: const PublishSettings(
        batching: BatchingSettings(
          maxMessages: 50,
          maxDelay: Duration(milliseconds: 20),
        ),
      ),
    );
    print('Successfully initialized client for topic: ${topic.id}');

    final subscription = pubsub.subscription(
      'my-subscription',
      ackSettings: const AckSettings(
        batching: BatchingSettings(
          maxMessages: 50,
          maxDelay: Duration(milliseconds: 20),
        ),
      ),
    );
    print('Successfully initialized subscription: ${subscription.id}');

    topic.close();
    subscription.close();
  } finally {
    await pubsub.close();
  }
}
