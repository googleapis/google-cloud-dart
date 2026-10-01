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
import 'dart:convert';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as pb;
import 'package:grpc/grpc.dart' as grpc;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as timestamp_pb;
import 'package:test/test.dart';

import 'test_utils.dart';

class _StreamingSubscriberFake extends FakeSubscriberClient {
  final List<StreamController<pb.StreamingPullResponse>> responseControllers =
      [];
  final List<List<pb.StreamingPullRequest>> connectionRequests = [];
  Completer<void> _nextConnection = Completer<void>();

  Future<void> waitForConnections(int count) async {
    while (responseControllers.length < count) {
      await _nextConnection.future;
    }
  }

  @override
  grpc.ResponseStream<pb.StreamingPullResponse> streamingPull(
    Stream<pb.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    final controller = StreamController<pb.StreamingPullResponse>();
    final recorded = <pb.StreamingPullRequest>[];
    responseControllers.add(controller);
    connectionRequests.add(recorded);
    if (!_nextConnection.isCompleted) {
      _nextConnection.complete();
      _nextConnection = Completer<void>();
    }
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
            ..publishTime = timestamp_pb.Timestamp.fromDateTime(
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

        test('parallel streamingPull routes modifyAckDeadline and acknowledge '
            'over active streams', () async {
          final topicName = testResourceName('stream-topic');
          final subscriptionName = testResourceName('stream-sub');
          final topic = client.topic(topicName);
          final subscription = client.subscription(
            subscriptionName,
            ackSettings: AckSettings(
              batching: BatchingSettings(
                maxMessages: 1,
                maxDelay: const Duration(milliseconds: 20),
              ),
            ),
          );

          await topic.create();
          addTearDown(() async => await topic.delete());

          await subscription.create(topic: topic.name);
          addTearDown(() async => await subscription.delete());

          final done = Completer<void>();
          var deliveries = 0;
          String? firstMessageId;
          ReceivedMessage? secondDelivery;

          final streamSubscription = subscription
              .streamingPull(
                maxConcurrentStreams: 2,
                streamAckDeadlineSeconds: 600,
              )
              .listen((message) async {
                deliveries++;
                if (deliveries == 1) {
                  firstMessageId = message.messageId;
                  expect(utf8.decode(message.data), 'stream-e2e-msg');
                  await message.modifyAckDeadline(0);
                } else if (deliveries == 2) {
                  expect(message.messageId, firstMessageId);
                  secondDelivery = message;
                  await message.acknowledge();
                  if (!done.isCompleted) done.complete();
                }
              }, onError: done.completeError);

          await topic.publish(utf8.encode('stream-e2e-msg'));
          await topic.close();

          await done.future.timeout(const Duration(seconds: 10));
          // Allow the stream-routed ACK frame to reach the server before
          // tearing down the stream.
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await streamSubscription.cancel();
          await subscription.close();

          final reopen = client.subscription(subscriptionName);
          addTearDown(() async => await reopen.close());
          await reopen.modifyAckDeadlineNow([secondDelivery!], 0);
          await client.publish(topic.name, utf8.encode('sentinel'));

          final afterAck = await pullReliably(reopen, count: 1);
          expect(
            afterAck.map((message) => utf8.decode(message.data)).toList(),
            ['sentinel'],
          );
          await reopen.acknowledgeNow(afterAck);
        });
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

      test('validates parameters and closed state synchronously', () async {
        final subscription = client.subscription('test-sub');
        expect(
          () => subscription.streamingPull(maxConcurrentStreams: 0),
          throwsArgumentError,
        );
        expect(
          () => subscription.streamingPull(streamAckDeadlineSeconds: 9),
          throwsRangeError,
        );
        expect(
          () => subscription.streamingPull(streamAckDeadlineSeconds: 601),
          throwsRangeError,
        );

        await subscription.close();
        expect(subscription.streamingPull, throwsStateError);
      });

      test(
        'opens maxConcurrentStreams parallel streams and merges messages',
        () async {
          final subscription = client.subscription('test-sub');
          final received = <String>[];
          final streamSubscription = subscription
              .streamingPull(maxConcurrentStreams: 2)
              .listen(
                (message) => received.add(String.fromCharCodes(message.data)),
              );

          await fakeSubscriber.waitForConnections(2);
          expect(fakeSubscriber.responseControllers, hasLength(2));

          fakeSubscriber.responseControllers[0].add(
            _makeResponse('a1', 'from-0'),
          );
          fakeSubscriber.responseControllers[1].add(
            _makeResponse('a2', 'from-1'),
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(received, containsAll(['from-0', 'from-1']));
          await streamSubscription.cancel();
        },
      );

      test('automatically reconnects on transient UNAVAILABLE error', () async {
        final subscription = client.subscription('test-sub');
        final received = <String>[];
        final streamSubscription = subscription
            .streamingPull(
              retry: const ExponentialRetry(
                initialDelay: Duration(milliseconds: 5),
              ),
            )
            .listen(
              (message) => received.add(String.fromCharCodes(message.data)),
            );

        await fakeSubscriber.waitForConnections(1);
        expect(fakeSubscriber.responseControllers, hasLength(1));

        fakeSubscriber.responseControllers[0].addError(
          const grpc.GrpcError.unavailable('Server restart'),
        );
        await fakeSubscriber.responseControllers[0].close();

        await fakeSubscriber.waitForConnections(2);
        expect(fakeSubscriber.responseControllers, hasLength(2));

        fakeSubscriber.responseControllers[1].add(
          _makeResponse('a2', 'after-reconnect'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(received, ['after-reconnect']);
        await streamSubscription.cancel();
      });

      test(
        'healthy connection receiving messages resets retry backoff',
        () async {
          final subscription = client.subscription('test-sub');
          final received = <String>[];
          final streamSubscription = subscription
              .streamingPull(
                retry: const ExponentialRetry(
                  maxRetries: 1,
                  initialDelay: Duration(milliseconds: 5),
                ),
              )
              .listen(
                (message) => received.add(String.fromCharCodes(message.data)),
              );

          await fakeSubscriber.waitForConnections(1);
          fakeSubscriber.responseControllers[0].add(_makeResponse('a1', 'm1'));
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Disconnect 1: uses retry budget, reset by receiving m1.
          fakeSubscriber.responseControllers[0].addError(
            const grpc.GrpcError.unavailable('Disconnect 1'),
          );
          await fakeSubscriber.responseControllers[0].close();

          await fakeSubscriber.waitForConnections(2);
          fakeSubscriber.responseControllers[1].add(_makeResponse('a2', 'm2'));
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Disconnect 2: succeeds despite maxRetries: 1 since m2 reset
          // backoff.
          fakeSubscriber.responseControllers[1].addError(
            const grpc.GrpcError.unavailable('Disconnect 2'),
          );
          await fakeSubscriber.responseControllers[1].close();

          await fakeSubscriber.waitForConnections(3);
          fakeSubscriber.responseControllers[2].add(_makeResponse('a3', 'm3'));
          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(received, ['m1', 'm2', 'm3']);
          await streamSubscription.cancel();
        },
      );

      test(
        'non-retryable error fails immediately without reconnecting',
        () async {
          final subscription = client.subscription('test-sub');
          final errorCompleter = Completer<Object>();
          final streamSubscription = subscription
              .streamingPull(maxConcurrentStreams: 2)
              .listen((_) {}, onError: errorCompleter.complete);

          await fakeSubscriber.waitForConnections(2);
          fakeSubscriber.responseControllers[0].addError(
            const grpc.GrpcError.notFound('Subscription not found'),
          );

          final error = await errorCompleter.future;
          expect(error, isA<NotFoundException>());
          expect(fakeSubscriber.responseControllers, hasLength(2));

          await streamSubscription.cancel();
        },
      );

      test('exhausting retries on one stream keeps sibling stream alive until '
          'all streams fail', () async {
        final subscription = client.subscription('test-sub');
        final received = <String>[];
        final errors = <Object>[];
        final doneCompleter = Completer<void>();
        final streamSubscription = subscription
            .streamingPull(
              maxConcurrentStreams: 2,
              retry: const ExponentialRetry(maxRetries: 0),
            )
            .listen(
              (message) => received.add(String.fromCharCodes(message.data)),
              onError: errors.add,
              onDone: doneCompleter.complete,
            );

        await fakeSubscriber.waitForConnections(2);

        // Stream 0 fails with no retries allowed.
        fakeSubscriber.responseControllers[0].addError(
          const grpc.GrpcError.unavailable('Stream 0 dropped'),
        );
        await fakeSubscriber.responseControllers[0].close();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(doneCompleter.isCompleted, isFalse);
        expect(errors, isEmpty);

        // Stream 1 continues to deliver messages.
        fakeSubscriber.responseControllers[1].add(
          _makeResponse('a1', 'still-alive'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(received, ['still-alive']);

        // When Stream 1 also exhausts retries, the last error is emitted and
        // the stream closes.
        fakeSubscriber.responseControllers[1].addError(
          const grpc.GrpcError.unavailable('Stream 1 dropped'),
        );
        await fakeSubscriber.responseControllers[1].close();

        await doneCompleter.future;
        expect(errors, [isA<ServiceUnavailableException>()]);
        await streamSubscription.cancel();
      });

      test('routes batched acks and modifyAckDeadline over active stream and '
          'falls back to unary RPC when disconnected', () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final completer = Completer<ReceivedMessage>();
        final streamSubscription = subscription.streamingPull().listen(
          completer.complete,
        );

        await fakeSubscriber.waitForConnections(1);
        fakeSubscriber.responseControllers[0].add(_makeResponse('a1', 'm1'));
        final message = await completer.future;

        await message.modifyAckDeadline(45);
        await message.acknowledge();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          fakeSubscriber.connectionRequests[0].any(
            (request) =>
                request.modifyDeadlineAckIds.contains('a1') &&
                request.modifyDeadlineSeconds.contains(45),
          ),
          isTrue,
        );
        expect(
          fakeSubscriber.connectionRequests[0].any(
            (request) => request.ackIds.contains('a1'),
          ),
          isTrue,
        );
        expect(fakeSubscriber.modifyAckDeadlineCalled, isFalse);
        expect(fakeSubscriber.acknowledgeCalled, isFalse);

        // Cancel the stream; subsequent operations fall back to unary RPC.
        await streamSubscription.cancel();
        subscription
          ..modifyAckDeadline(message, 30)
          ..acknowledge(message);
        await subscription.close();

        expect(fakeSubscriber.modifyAckDeadlineCalled, isTrue);
        expect(fakeSubscriber.lastModifyAckDeadlineIds, ['a1']);
        expect(fakeSubscriber.lastModifyAckDeadlineSeconds, 30);
        expect(fakeSubscriber.acknowledgeCalled, isTrue);
        expect(fakeSubscriber.lastAckIds, ['a1']);
      });

      test('pause and resume propagate to underlying streams', () async {
        final subscription = client.subscription('test-sub');
        final received = <String>[];
        final streamSubscription = subscription.streamingPull().listen(
          (message) => received.add(String.fromCharCodes(message.data)),
        );

        await fakeSubscriber.waitForConnections(1);
        streamSubscription.pause();
        expect(streamSubscription.isPaused, isTrue);

        fakeSubscriber.responseControllers[0].add(
          _makeResponse('a1', 'paused-msg'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(received, isEmpty);

        streamSubscription.resume();
        expect(streamSubscription.isPaused, isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(received, ['paused-msg']);

        await streamSubscription.cancel();
      });

      test(
        'closing PubSub client terminates active streamingPull with StateError',
        () async {
          final subscription = client.subscription('test-sub');
          final errorCompleter = Completer<Object>();
          final streamSubscription = subscription.streamingPull().listen(
            (_) {},
            onError: errorCompleter.complete,
          );

          await fakeSubscriber.waitForConnections(1);
          await client.close();
          fakeSubscriber.responseControllers[0].addError(
            const grpc.GrpcError.unavailable('Channel shut down'),
          );

          final error = await errorCompleter.future;
          expect(error, isA<StateError>());
          expect(fakeSubscriber.responseControllers, hasLength(1));

          await streamSubscription.cancel();
        },
      );
    });
  });
}
