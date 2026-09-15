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
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pbgrpc.dart'
    as generated;
import 'package:grpc/grpc.dart' as grpc;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as protobuf;
import 'package:test/fake.dart';
import 'package:test/test.dart';

class FakeResponseFuture<T> extends Fake implements grpc.ResponseFuture<T> {
  final Future<T> _future;

  FakeResponseFuture(this._future);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class FakeResponseStream<T> extends StreamView<T>
    implements grpc.ResponseStream<T> {
  FakeResponseStream(super.stream);

  @override
  grpc.ResponseFuture<T> get single => FakeResponseFuture(super.single);

  @override
  Future<void> cancel() => Future<void>.value();

  @override
  Future<Map<String, String>> get headers => Future.value(const {});

  @override
  Future<Map<String, String>> get trailers => Future.value(const {});
}

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;
  bool publishCalled = false;
  final List<generated.PublishRequest> recordedRequests = [];

  @override
  grpc.ResponseFuture<generated.PublishResponse> publish(
    generated.PublishRequest request, {
    grpc.CallOptions? options,
  }) {
    publishCalled = true;
    recordedRequests.add(request);
    final completer = Completer<generated.PublishResponse>();
    if (publishBehavior case final publish?) {
      publish(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      final response = generated.PublishResponse()
        ..messageIds.addAll(
          List.generate(request.messages.length, (i) => 'msg-$i'),
        );
      completer.complete(response);
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<generated.Topic> createTopic(
    generated.Topic request, {
    grpc.CallOptions? options,
  }) => FakeResponseFuture(Future.value(request));
}

class FakeSubscriberClient extends Fake implements generated.SubscriberClient {
  Future<void> Function(List<String> ackIds)? acknowledgeBehavior;
  bool acknowledgeCalled = false;
  int acknowledgeCallCount = 0;
  List<String>? lastAckIds;

  Future<void> Function(List<String> ackIds, int seconds)?
  modifyAckDeadlineBehavior;
  bool modifyAckDeadlineCalled = false;
  int modifyAckDeadlineCallCount = 0;
  List<String>? lastModifyAckDeadlineIds;
  int? lastModifyAckDeadlineSeconds;

  bool pullCalled = false;
  int? lastMaxMessages;

  @override
  grpc.ResponseFuture<protobuf.Empty> acknowledge(
    generated.AcknowledgeRequest request, {
    grpc.CallOptions? options,
  }) {
    acknowledgeCalled = true;
    acknowledgeCallCount++;
    lastAckIds = request.ackIds;
    final completer = Completer<protobuf.Empty>();
    if (acknowledgeBehavior case final ack?) {
      ack(request.ackIds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> modifyAckDeadline(
    generated.ModifyAckDeadlineRequest request, {
    grpc.CallOptions? options,
  }) {
    modifyAckDeadlineCalled = true;
    modifyAckDeadlineCallCount++;
    lastModifyAckDeadlineIds = request.ackIds;
    lastModifyAckDeadlineSeconds = request.ackDeadlineSeconds;
    final completer = Completer<protobuf.Empty>();
    if (modifyAckDeadlineBehavior case final mod?) {
      mod(request.ackIds, request.ackDeadlineSeconds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  Future<generated.PullResponse> Function(generated.PullRequest)? pullBehavior;

  @override
  grpc.ResponseFuture<generated.PullResponse> pull(
    generated.PullRequest request, {
    grpc.CallOptions? options,
  }) {
    pullCalled = true;
    lastMaxMessages = request.maxMessages;
    if (pullBehavior case final behavior?) {
      return FakeResponseFuture(behavior(request));
    }
    return FakeResponseFuture(Future.value(generated.PullResponse()));
  }

  @override
  grpc.ResponseFuture<generated.Subscription> createSubscription(
    generated.Subscription request, {
    grpc.CallOptions? options,
  }) => FakeResponseFuture(Future.value(request));

  final List<StreamController<generated.StreamingPullResponse>>
  streamingPullControllers = [];

  @override
  grpc.ResponseStream<generated.StreamingPullResponse> streamingPull(
    Stream<generated.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    final controller = StreamController<generated.StreamingPullResponse>();
    streamingPullControllers.add(controller);
    request.listen((_) {});
    return FakeResponseStream(controller.stream);
  }
}

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {}
}

void main() {
  group('Subscription Lifecycle & Batcher', () {
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

    test(
      'Subscription.close() awaits in-flight batches before completing',
      () async {
        final ackCompleter = Completer<void>();
        fakeSubscriber.acknowledgeBehavior = (ackIds) async =>
            ackCompleter.future;

        final subscription = client.subscription(
          'my-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final message = ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1, 2, 3]),
        );

        subscription.acknowledge(message);

        var closeCompleted = false;
        final closeFuture = subscription.close().then((_) {
          closeCompleted = true;
        });

        // Batch starts on flush from close()
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.acknowledgeCalled, isTrue);
        expect(closeCompleted, isFalse);

        // Finish the ack RPC
        ackCompleter.complete();
        await closeFuture;

        expect(closeCompleted, isTrue);
      },
    );

    test(
      'Subscription.modifyAckDeadline() batches by deadline and close awaits '
      'in-flight RPCs',
      () async {
        final modCompleter = Completer<void>();
        fakeSubscriber.modifyAckDeadlineBehavior = (ackIds, seconds) async =>
            modCompleter.future;

        final subscription = client.subscription(
          'my-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final message1 = ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );
        final message2 = ReceivedMessage(
          ackId: 'ack-2',
          messageId: 'msg-2',
          publishTime: DateTime.now(),
          message: Message(data: [2]),
        );

        subscription
          ..modifyAckDeadline(message1, 30)
          ..modifyAckDeadline(message2, 30);

        var closeDone = false;
        final closeFuture = subscription.close().then((_) {
          closeDone = true;
        });

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.modifyAckDeadlineCalled, isTrue);
        expect(closeDone, isFalse);

        modCompleter.complete();
        await closeFuture;
        expect(closeDone, isTrue);
      },
    );

    test(
      'Subscription.acknowledge flushes when maxMessages threshold is reached',
      () async {
        final subscription = client.subscription(
          'my-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 2,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final message1 = ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );
        final message2 = ReceivedMessage(
          ackId: 'ack-2',
          messageId: 'msg-2',
          publishTime: DateTime.now(),
          message: Message(data: [2]),
        );

        subscription.acknowledge(message1);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.acknowledgeCalled, isFalse);

        subscription.acknowledge(message2);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.acknowledgeCalled, isTrue);

        await subscription.close();
      },
    );

    test('Subscription operations after close throw StateError', () async {
      final subscription = client.subscription('my-sub');
      await subscription.close();

      final message = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      expect(() => subscription.acknowledge(message), throwsStateError);
      expect(
        () => subscription.modifyAckDeadline(message, 10),
        throwsStateError,
      );
      expect(() => subscription.acknowledgeNow([message]), throwsStateError);
      expect(
        () => subscription.modifyAckDeadlineNow([message], 10),
        throwsStateError,
      );
      expect(subscription.pull, throwsStateError);
    });

    test('Subscription.pull validation and closed check', () async {
      final subscription = client.subscription('my-sub');

      expect(() => subscription.pull(maxMessages: 0), throwsArgumentError);
      expect(() => subscription.pull(maxMessages: -1), throwsArgumentError);
      expect(
        () => client.pull(
          'projects/test-project/subscriptions/my-sub',
          maxMessages: 0,
        ),
        throwsArgumentError,
      );

      await subscription.close();
      expect(subscription.pull, throwsStateError);
    });

    test(
      'empty list no-ops for acknowledgeNow and modifyAckDeadlineNow',
      () async {
        final subscription = client.subscription('my-sub');
        await subscription.acknowledgeNow([]);
        expect(fakeSubscriber.acknowledgeCalled, isFalse);

        await subscription.modifyAckDeadlineNow([], 10);
        expect(fakeSubscriber.modifyAckDeadlineCalled, isFalse);
      },
    );

    test(
      'Subscription.create() returns this and preserves ackSettings',
      () async {
        final customSettings = AckSettings(
          batching: BatchingSettings(maxMessages: 42),
        );
        final subscription = client.subscription(
          'my-sub',
          ackSettings: customSettings,
        );
        final created = await subscription.create(
          topic: 'projects/test-project/topics/my-topic',
        );
        expect(identical(created, subscription), isTrue);
        expect(created.ackSettings, same(customSettings));
        expect(created.ackSettings.batching.maxMessages, equals(42));
      },
    );
  });

  group('PubSub Client Empty List No-Ops & Parameter Validation', () {
    late FakePublisherClient fakePublisher;
    late FakeSubscriberClient fakeSubscriber;
    late PubSub client;

    setUp(() {
      fakePublisher = FakePublisherClient();
      fakeSubscriber = FakeSubscriberClient();
      client = PubSub.testing(
        projectId: 'test-project',
        channel: FakeClientChannel(),
        publisherClient: fakePublisher,
        subscriberClient: fakeSubscriber,
      );
    });

    tearDown(() async {
      await client.close();
    });

    test(
      'publishMessages with empty list returns empty without calling backend',
      () async {
        final result = await client.publishMessages(
          'projects/test-project/topics/my-topic',
          [],
        );
        expect(result, isEmpty);
        expect(fakePublisher.publishCalled, isFalse);
      },
    );

    test(
      'acknowledge with empty list returns without calling backend',
      () async {
        await client.acknowledge(
          'projects/test-project/subscriptions/my-sub',
          [],
        );
        expect(fakeSubscriber.acknowledgeCalled, isFalse);
      },
    );

    test(
      'modifyAckDeadline with empty list returns without calling backend',
      () async {
        await client.modifyAckDeadline(
          'projects/test-project/subscriptions/my-sub',
          [],
          10,
        );
        expect(fakeSubscriber.modifyAckDeadlineCalled, isFalse);
      },
    );

    test('modifyAckDeadline validates ackDeadlineSeconds >= 0', () {
      expect(
        () => client.modifyAckDeadline(
          'projects/test-project/subscriptions/my-sub',
          ['ack-1'],
          -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => client.modifyAckDeadline(
          'projects/test-project/subscriptions/my-sub',
          [],
          -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'streamingPull validates streamAckDeadlineSeconds between 10 and 600',
      () {
        expect(
          () => client.streamingPull(
            'projects/test-project/subscriptions/my-sub',
            streamAckDeadlineSeconds: 9,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => client.streamingPull(
            'projects/test-project/subscriptions/my-sub',
            streamAckDeadlineSeconds: 601,
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('PubSub._streamingPull handlers throw StateError when connection '
        'is closed', () async {
      final stream = client.streamingPull(
        'projects/test-project/subscriptions/my-sub',
      );
      ReceivedMessage? received;
      final streamSubscription = stream.listen((message) => received = message);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.streamingPullControllers.length, equals(1));
      final conn = fakeSubscriber.streamingPullControllers.first
        ..add(
          generated.StreamingPullResponse()
            ..receivedMessages.add(
              generated.ReceivedMessage()
                ..ackId = 'ack-closed'
                ..message = (generated.PubsubMessage()..messageId = 'msg-1'),
            ),
        );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, isNotNull);

      // Close response stream to complete pull and close requestController.
      await conn.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await streamSubscription.cancel();

      expect(
        () => received!.acknowledge(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
              'Cannot acknowledge message: '
              'streaming pull connection has closed.',
            ),
          ),
        ),
      );

      expect(
        () => received!.modifyAckDeadline(10),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains(
              'Cannot modify ack deadline: '
              'streaming pull connection has closed.',
            ),
          ),
        ),
      );
    });
    test('pull validates maxMessages > 0', () {
      expect(
        () => client.pull(
          'projects/test-project/subscriptions/my-sub',
          maxMessages: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => client.pull(
          'projects/test-project/subscriptions/my-sub',
          maxMessages: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('PubSub.pull defaults to maxMessages 1', () async {
      await client.pull('projects/test-project/subscriptions/my-sub');
      expect(fakeSubscriber.pullCalled, isTrue);
      expect(fakeSubscriber.lastMaxMessages, equals(1));
    });

    test('Subscription.pull defaults to maxMessages 1', () async {
      final subscription = client.subscription('my-sub');
      await subscription.pull();
      expect(fakeSubscriber.pullCalled, isTrue);
      expect(fakeSubscriber.lastMaxMessages, equals(1));
    });

    test('pull maps deliveryAttempt onto ReceivedMessage', () async {
      fakeSubscriber.pullBehavior = (request) async =>
          generated.PullResponse()
            ..receivedMessages.add(
              generated.ReceivedMessage()
                ..ackId = 'ack-test'
                ..deliveryAttempt = 5
                ..message = (generated.PubsubMessage()
                  ..messageId = 'msg-test'
                  ..data = [1, 2, 3]),
            );
      final messages = await client.pull(
        'projects/test-project/subscriptions/my-sub',
      );
      expect(messages.length, equals(1));
      expect(messages.first.deliveryAttempt, equals(5));
      expect(messages.first.ackId, equals('ack-test'));
      expect(messages.first.messageId, equals('msg-test'));
    });

    test('Subscription._onAckBatch deduplicates by ackId', () async {
      final subscription = client.subscription(
        'my-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final message = ReceivedMessage(
        ackId: 'ack-same',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      // Multiple ACKs for the same ackId in the same batch
      subscription
        ..acknowledge(message)
        ..acknowledge(message);

      await subscription.close();

      expect(fakeSubscriber.acknowledgeCalled, isTrue);
      expect(fakeSubscriber.acknowledgeCallCount, equals(1));
      expect(fakeSubscriber.lastAckIds, equals(['ack-same']));
    });

    test('Subscription._onModifyAckBatch deduplicates by ackId preserving '
        'latest deadline', () async {
      final subscription = client.subscription(
        'my-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final message = ReceivedMessage(
        ackId: 'ack-same',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      // Multiple modifications for the same ackId in the same batch
      subscription
        ..modifyAckDeadline(message, 30)
        ..modifyAckDeadline(message, 0);

      await subscription.close();

      expect(fakeSubscriber.modifyAckDeadlineCalled, isTrue);
      expect(fakeSubscriber.modifyAckDeadlineCallCount, equals(1));
      expect(fakeSubscriber.lastModifyAckDeadlineSeconds, equals(0));
    });

    test(
      'ReceivedMessage acknowledge and modifyAckDeadline call handlers',
      () async {
        var ackCalled = false;
        var modCalled = false;
        int? modSeconds;

        final message = ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
          ackHandler: (ids) {
            ackCalled = true;
            expect(ids, equals(['ack-1']));
          },
          modifyDeadlineHandler: (ids, seconds) {
            modCalled = true;
            modSeconds = seconds;
            expect(ids, equals(['ack-1']));
          },
        );

        await message.acknowledge();
        expect(ackCalled, isTrue);

        await message.modifyAckDeadline(42);
        expect(modCalled, isTrue);
        expect(modSeconds, equals(42));

        expect(() => message.modifyAckDeadline(-1), throwsArgumentError);
      },
    );

    test('ReceivedMessage without handlers throws StateError', () async {
      final message = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      await expectLater(message.acknowledge, throwsStateError);
      await expectLater(() => message.modifyAckDeadline(10), throwsStateError);
    });

    test('PublishSettings and AckSettings equality and toString', () {
      final pub1 = PublishSettings();
      final pub2 = PublishSettings();
      expect(pub1, equals(pub2));
      expect(pub1.hashCode, equals(pub2.hashCode));
      expect(pub1.toString(), contains('PublishSettings'));

      final pubDiff = PublishSettings(
        batching: BatchingSettings(maxMessages: 5),
      );
      expect(pub1, isNot(equals(pubDiff)));

      final ack1 = AckSettings();
      final ack2 = AckSettings();
      expect(ack1, equals(ack2));
      expect(ack1.hashCode, equals(ack2.hashCode));
      expect(ack1.toString(), contains('AckSettings'));

      final ackDiff = AckSettings(batching: BatchingSettings(maxBytes: 1024));
      expect(ack1, isNot(equals(ackDiff)));
    });

    test(
      'PubSub.publishMessages forwards non-empty message list and returns IDs',
      () async {
        fakePublisher.publishBehavior = (request) async =>
            generated.PublishResponse()
              ..messageIds.addAll(
                request.messages.map((m) => 'id-${m.data.length}'),
              );

        final ids = await client.publishMessages('my-topic', [
          Message(data: [1, 2, 3], attributes: {'k': 'v'}),
          Message(data: [4, 5]),
        ]);

        expect(ids, equals(['id-3', 'id-2']));
        expect(fakePublisher.publishCalled, isTrue);
        expect(fakePublisher.recordedRequests[0].messages.length, equals(2));
      },
    );

    test('Subscription.acknowledgeNow and modifyAckDeadlineNow forward '
        'non-empty message list', () async {
      final subscription = client.subscription('my-sub');
      final message1 = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );
      final message2 = ReceivedMessage(
        ackId: 'ack-2',
        messageId: 'msg-2',
        publishTime: DateTime.now(),
        message: Message(data: [2]),
      );

      await subscription.acknowledgeNow([message1, message2]);
      expect(fakeSubscriber.acknowledgeCalled, isTrue);
      expect(fakeSubscriber.lastAckIds, equals(['ack-1', 'ack-2']));

      await subscription.modifyAckDeadlineNow([message1, message2], 45);
      expect(fakeSubscriber.modifyAckDeadlineCalled, isTrue);
      expect(
        fakeSubscriber.lastModifyAckDeadlineIds,
        equals(['ack-1', 'ack-2']),
      );
      expect(fakeSubscriber.lastModifyAckDeadlineSeconds, equals(45));
    });

    test('Subscription._onModifyAckBatch partitions distinct deadlines into '
        'separate calls', () async {
      final recordedDeadlines = <int>[];
      fakeSubscriber.modifyAckDeadlineBehavior = (ackIds, seconds) async {
        recordedDeadlines.add(seconds);
      };

      final subscription = client.subscription(
        'my-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final message1 = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'm1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );
      final message2 = ReceivedMessage(
        ackId: 'ack-2',
        messageId: 'm2',
        publishTime: DateTime.now(),
        message: Message(data: [2]),
      );

      subscription
        ..modifyAckDeadline(message1, 10)
        ..modifyAckDeadline(message2, 30);

      await subscription.close();

      expect(fakeSubscriber.modifyAckDeadlineCallCount, equals(2));
      expect(recordedDeadlines..sort(), equals([10, 30]));
    });

    test('multiple concurrent calls to Subscription.close() await the same '
        'future', () async {
      final subscription = client.subscription('my-sub');
      final closeFuture1 = subscription.close();
      final closeFuture2 = subscription.close();
      expect(identical(closeFuture1, closeFuture2), isTrue);
      await closeFuture1;
    });

    test('createTopic forwards custom publishSettings', () async {
      final customSettings = PublishSettings(
        batching: BatchingSettings(maxMessages: 42),
      );
      final topic = await client.createTopic(
        'projects/test-project/topics/custom-topic',
        publishSettings: customSettings,
      );
      expect(topic.publishSettings.batching.maxMessages, equals(42));
    });

    test('createSubscription forwards custom ackSettings', () async {
      final customSettings = AckSettings(
        batching: BatchingSettings(maxBytes: 2048),
      );
      final subscription = await client.createSubscription(
        'projects/test-project/subscriptions/custom-sub',
        topic: 'projects/test-project/topics/custom-topic',
        ackSettings: customSettings,
      );
      expect(subscription.ackSettings.batching.maxBytes, equals(2048));
    });
  });
}
