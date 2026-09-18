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

import 'dart:async';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as pb;
import 'package:grpc/grpc.dart' as grpc;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as pb_ts;
import 'package:test/test.dart';

import 'test_utils.dart';

class _StreamingSubscriberFake extends FakeSubscriberClient {
  final List<StreamController<pb.StreamingPullResponse>> responseControllers =
      [];
  final List<List<pb.StreamingPullRequest>> connectionRequests = [];

  @override
  grpc.ResponseStream<pb.StreamingPullResponse> streamingPull(
    Stream<pb.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    final controller = StreamController<pb.StreamingPullResponse>();
    final recorded = <pb.StreamingPullRequest>[];
    responseControllers.add(controller);
    connectionRequests.add(recorded);
    request.listen(
      recorded.add,
      onError: (_) {},
      onDone: () {
        if (!controller.isClosed) unawaited(controller.close());
      },
    );
    return FakeResponseStream(controller.stream);
  }
}

pb.StreamingPullResponse _makeResponse(String ackId, String text) =>
    pb.StreamingPullResponse()
      ..receivedMessages.add(
        pb.ReceivedMessage()
          ..ackId = ackId
          ..deliveryAttempt = 1
          ..message = (pb.PubsubMessage()
            ..messageId = 'id-$ackId'
            ..data = text.codeUnits
            ..publishTime = pb_ts.Timestamp.fromDateTime(
              DateTime.utc(2026, 1, 1),
            )),
      );

void main() {
  group('streamingPull', () {
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

        test(
          'streaming pull throws ServiceException when subscription is deleted',
          () async {
            final topicName = testResourceName('test-topic');
            final subscriptionName = testResourceName('test-sub');
            final topic = client.topic(topicName);
            final subscription = client.subscription(subscriptionName);

            await topic.create();
            addTearDown(() async => await topic.delete());

            await subscription.create(topic: topic.name);

            final stream = subscription.streamingPull();

            // Delete subscription to break the stream.
            await subscription.delete();

            expect(stream.first, throwsA(isA<ServiceException>()));
          },
        );
      },
    );

    group('mock', () {
      late _StreamingSubscriberFake fakeSubscriber;
      late PubSub client;

      setUp(() {
        fakeSubscriber = _StreamingSubscriberFake();
        client = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          subscriberClient: fakeSubscriber,
        );
      });

      tearDown(() async {
        await client.close();
      });

      test(
        'opens maxConcurrentStreams parallel streams and merges messages',
        () async {
          final sub = client.subscription('test-sub');
          final received = <String>[];
          final subListener = sub
              .streamingPull(maxConcurrentStreams: 2)
              .listen((m) => received.add(String.fromCharCodes(m.data)));

          await Future<void>.delayed(const Duration(milliseconds: 20));
          expect(fakeSubscriber.responseControllers, hasLength(2));

          fakeSubscriber.responseControllers[0].add(
            _makeResponse('a1', 'from-0'),
          );
          fakeSubscriber.responseControllers[1].add(
            _makeResponse('a2', 'from-1'),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(received, containsAll(['from-0', 'from-1']));
          await subListener.cancel();
        },
      );

      test('automatically reconnects on transient UNAVAILABLE error', () async {
        final sub = client.subscription('test-sub');
        final received = <String>[];
        final subListener = sub
            .streamingPull(
              retry: const ExponentialRetry(
                initialDelay: Duration(milliseconds: 5),
              ),
            )
            .listen((m) => received.add(String.fromCharCodes(m.data)));

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.responseControllers, hasLength(1));

        fakeSubscriber.responseControllers[0].addError(
          const grpc.GrpcError.unavailable('Server restart'),
        );
        await fakeSubscriber.responseControllers[0].close();

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(fakeSubscriber.responseControllers, hasLength(2));

        fakeSubscriber.responseControllers[1].add(
          _makeResponse('a2', 'after-reconnect'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(received, ['after-reconnect']);
        await subListener.cancel();
      });

      test('routes batched acks over active stream and falls back to unary RPC '
          'when disconnected', () async {
        final sub = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final completer = Completer<ReceivedMessage>();
        final subListener = sub.streamingPull().listen(completer.complete);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        fakeSubscriber.responseControllers[0].add(_makeResponse('a1', 'm1'));
        final msg = await completer.future;

        await msg.acknowledge();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          fakeSubscriber.connectionRequests[0].any(
            (r) => r.ackIds.contains('a1'),
          ),
          isTrue,
        );
        expect(fakeSubscriber.acknowledgeCalled, isFalse);

        // Cancel the stream; subsequent acks fall back to unary RPC.
        await subListener.cancel();
        sub.acknowledge(msg);
        await sub.close();

        expect(fakeSubscriber.acknowledgeCalled, isTrue);
        expect(fakeSubscriber.lastAckIds, ['a1']);
      });
    });
  });
}
