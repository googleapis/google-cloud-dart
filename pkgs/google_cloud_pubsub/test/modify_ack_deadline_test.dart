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

@TestOn('vm')
@Tags(['firebase-emulator'])
library;

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('modifyAckDeadline', () {
    late PubSub client;

    setUp(() async {
      client = await createClient();
    });

    tearDown(() async {
      await client.close();
    });

    test('modifyAckDeadline for non-existent subscription throws '
        'SubscriptionNotFoundException', () async {
      final subscriptionName =
          'non-existent-${DateTime.now().millisecondsSinceEpoch}';
      final subscription = client.subscription(subscriptionName);

      expect(
        () => subscription.modifyAckDeadlineNow([
          ReceivedMessage(
            ackId: 'ack-id',
            messageId: 'msg-id',
            publishTime: DateTime.now(),
            message: Message(data: []),
          ),
        ], 10),
        throwsA(isA<SubscriptionNotFoundException>()),
      );
    });
  });
}
