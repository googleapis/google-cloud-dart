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
library;

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('modifyAckDeadline', () {
    group(
      'google-cloud / emulator',
      tags: ['firebase-emulator', 'google-cloud'],
      () {
        late PubSub client;

        setUp(() async {
          client = await createClient();
        });

        tearDown(() async {
          await client.close();
        });

        test('modifyAckDeadline for non-existent subscription throws '
            'NotFoundException', () async {
          final subscriptionName = testResourceName('non-existent');
          final subscription = client.subscription(subscriptionName);

          expect(
            () => subscription.modifyAckDeadlineNow([
              ReceivedMessage(
                ackId: 'ack-id',
                messageId: 'msg-id',
                publishTime: DateTime.now(),
                message: Message(data: []),
              ),
            ], 30),
            throwsA(isA<NotFoundException>()),
          );
        });
      },
    );

    group('mock', () {
      late FakeSubscriberClient fakeSubscriber;
      late PubSub client;

      setUp(() {
        fakeSubscriber = FakeSubscriberClient();
        client = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          subscriberClient: fakeSubscriber,
        );
      });

      tearDown(() async {
        await client.close();
      });

      ReceivedMessage dummyMessage(String ackId) => ReceivedMessage(
        ackId: ackId,
        messageId: 'msg-$ackId',
        publishTime: DateTime.now(),
        message: Message(data: const [1]),
      );

      test('deduplicates by keeping latest deadline per ackId and groups by '
          'deadline', () async {
        final sub = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        sub
          ..modifyAckDeadline(dummyMessage('ack-1'), 10)
          ..modifyAckDeadline(dummyMessage('ack-1'), 30) // overrides 10
          ..modifyAckDeadline(dummyMessage('ack-2'), 30)
          ..modifyAckDeadline(dummyMessage('ack-3'), 0); // nack

        await sub.close();

        expect(fakeSubscriber.recordedModifyAckRequests, hasLength(2));
        final bySeconds = {
          for (final req in fakeSubscriber.recordedModifyAckRequests)
            req.ackDeadlineSeconds: req.ackIds,
        };
        expect(bySeconds[30], ['ack-1', 'ack-2']);
        expect(bySeconds[0], ['ack-3']);
      });

      test(
        'keeps every emitted ModifyAckDeadlineRequest within maxBytes',
        () async {
          const limit = 250;
          final sub = client.subscription(
            'test-sub',
            ackSettings: AckSettings(
              batching: BatchingSettings(
                maxMessages: 1000,
                maxBytes: limit,
                maxDelay: const Duration(seconds: 10),
              ),
            ),
          );

          for (var i = 0; i < 20; i++) {
            sub.modifyAckDeadline(dummyMessage('ack-${'x' * 30}-$i'), 600);
          }
          await sub.close();

          expect(
            fakeSubscriber.recordedModifyAckRequests.length,
            greaterThan(1),
          );
          for (final request in fakeSubscriber.recordedModifyAckRequests) {
            expect(request.writeToBuffer().length, lessThanOrEqualTo(limit));
          }
        },
      );
    });
  });
}
