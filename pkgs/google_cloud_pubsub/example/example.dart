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
    final topic = pubsub.topic('my-topic');
    print('Successfully initialized client for topic: ${topic.id}');
  } finally {
    await pubsub.close();
  }
}
