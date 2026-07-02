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

import 'dart:io';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

final isEmulator = Platform.environment['PUBSUB_EMULATOR_HOST'] != null;

/// Creates a [PubSub] client configured for either the emulator or production
/// based on environment variables.
Future<PubSub> createClient() async {
  final host = Platform.environment['PUBSUB_EMULATOR_HOST'];
  final project = Platform.environment['GOOGLE_CLOUD_PROJECT'];

  if (host != null) {
    return PubSub(projectId: 'test-project');
  } else if (project != null) {
    return PubSub(
      projectId: project,
      authenticator: await applicationDefaultCredentialsAuthenticator([
        'https://www.googleapis.com/auth/pubsub',
      ]),
    );
  } else {
    fail(
      'Neither PUBSUB_EMULATOR_HOST nor GOOGLE_CLOUD_PROJECT '
      'environment variable set',
    );
  }
}

/// Pulls up to [count] messages from the [subscription], retrying up to 10
/// times with a 1-second delay between attempts if the expected count is
/// not met.
///
/// Because message delivery in Google Cloud Pub/Sub is eventually consistent,
/// a published message may not be immediately available in the first pull
/// request. Polling dynamically like this avoids both test flakiness (by
/// waiting up to 10 seconds) and unnecessary test suite delay (by returning
/// instantly as soon as all messages are retrieved).
Future<List<ReceivedMessage>> pullReliably(
  Subscription subscription, {
  required int count,
}) async {
  final messages = <ReceivedMessage>[];
  for (var i = 0; i < 10 && messages.length < count; i++) {
    if (i > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final pulled = await subscription.pull(
      maxMessages: count - messages.length,
    );
    messages.addAll(pulled);
  }
  return messages;
}
