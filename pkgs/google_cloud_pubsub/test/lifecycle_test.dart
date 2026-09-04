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
  }) => _future.then(
    onValue,
    onError: (Object e, StackTrace s) {
      if (onError != null) {
        if (onError is FutureOr<S> Function(Object, StackTrace)) {
          onError(e, s);
        } else if (onError is FutureOr<S> Function(Object)) {
          onError(e);
        } else {
          // ignore: avoid_dynamic_calls
          (onError as dynamic)(e, s);
        }
      }
    },
  );

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;
  bool publishCalled = false;

  @override
  grpc.ResponseFuture<generated.PublishResponse> publish(
    generated.PublishRequest request, {
    grpc.CallOptions? options,
  }) {
    publishCalled = true;
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
  List<String>? lastAckIds;

  bool modifyAckDeadlineCalled = false;
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
    lastModifyAckDeadlineIds = request.ackIds;
    lastModifyAckDeadlineSeconds = request.ackDeadlineSeconds;
    return FakeResponseFuture(Future.value(protobuf.Empty()));
  }

  @override
  grpc.ResponseFuture<generated.PullResponse> pull(
    generated.PullRequest request, {
    grpc.CallOptions? options,
  }) {
    pullCalled = true;
    lastMaxMessages = request.maxMessages;
    return FakeResponseFuture(Future.value(generated.PullResponse()));
  }

  @override
  grpc.ResponseFuture<generated.Subscription> createSubscription(
    generated.Subscription request, {
    grpc.CallOptions? options,
  }) => FakeResponseFuture(Future.value(request));
}

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {}
}

void main() {
  group('Topic Lifecycle & Batcher', () {
    late FakePublisherClient fakePublisher;
    late PubSub client;

    setUp(() {
      fakePublisher = FakePublisherClient();
      client = PubSub.testing(
        projectId: 'test-project',
        channel: FakeClientChannel(),
        publisherClient: fakePublisher,
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('Topic.close() awaits in-flight batches before completing', () async {
      final publishCompleter = Completer<generated.PublishResponse>();
      fakePublisher.publishBehavior = (request) async =>
          publishCompleter.future;

      final topic = client.topic(
        'my-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final pubFuture = topic.publish([1, 2, 3]);

      var closeCompleted = false;
      final closeFuture = topic.close().then((_) {
        closeCompleted = true;
      });

      // Allow flush to start the RPC
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(closeCompleted, isFalse);

      // Complete the in-flight publish RPC
      publishCompleter.complete(
        generated.PublishResponse()..messageIds.add('id-123'),
      );

      final messageId = await pubFuture;
      expect(messageId, equals('id-123'));

      await closeFuture;
      expect(closeCompleted, isTrue);
    });

    test('Topic.publish after close throws StateError', () async {
      final topic = client.topic('my-topic');
      await topic.close();

      expect(() => topic.publish([1, 2, 3]), throwsStateError);
    });

    test('Topic._onBatch handles fewer message IDs without hanging', () async {
      fakePublisher.publishBehavior =
          // Backend returns only 1 message ID when 3 messages were sent
          (request) async =>
              generated.PublishResponse()..messageIds.add('id-only-one');

      final topic = client.topic(
        'my-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 3,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final f1 = topic.publish([1]);
      final f2 = topic.publish([2]);
      final f3 = topic.publish([3]);

      // First should succeed
      expect(await f1, equals('id-only-one'));

      // Remaining should fail with StateError, not hang
      await expectLater(f2, throwsStateError);
      await expectLater(f3, throwsStateError);
    });

    test('Topic._onBatch completes all with error if backend fails', () async {
      fakePublisher.publishBehavior = (request) async {
        throw const grpc.GrpcError.notFound('Topic not found');
      };

      final topic = client.topic(
        'my-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 2,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final f1 = topic.publish([1]);
      final f2 = topic.publish([2]);

      await expectLater(f1, throwsA(isA<NotFoundException>()));
      await expectLater(f2, throwsA(isA<NotFoundException>()));
    });

    test(
      'Topic._initBatcher calculates message size with attribute byte lengths',
      () async {
        final completer = Completer<void>();
        fakePublisher.publishBehavior = (request) async {
          completer.complete();
          return generated.PublishResponse()
            ..messageIds.addAll(
              List.generate(request.messages.length, (i) => 'msg-$i'),
            );
        };

        // Set maxBytes to 12. If attributes are included, 1 message flushes.
        // Data = 5 bytes, key = 3 ("abc"), value = 4 ("1234") -> 12 bytes.
        final topic = client.topic(
          'my-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxBytes: 12,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        unawaited(topic.publish([1, 2, 3, 4, 5], attributes: {'abc': '1234'}));

        await expectLater(
          completer.future.timeout(const Duration(milliseconds: 500)),
          completes,
        );

        await topic.close();
      },
    );

    test(
      'PubSub.publishMessages with empty list returns immediately',
      () async {
        final messageIds = await client.publishMessages(
          'projects/test-project/topics/my-topic',
          [],
        );
        expect(messageIds, isEmpty);
        expect(fakePublisher.publishCalled, isFalse);
      },
    );

    test('Topic.create() returns this and preserves publishSettings', () async {
      final customSettings = PublishSettings(
        batching: BatchingSettings(maxMessages: 42),
      );
      final topic = client.topic('my-topic', publishSettings: customSettings);
      final created = await topic.create();
      expect(identical(created, topic), isTrue);
      expect(created.publishSettings, same(customSettings));
      expect(created.publishSettings.batching.maxMessages, equals(42));
    });
  });

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

        final sub = client.subscription(
          'my-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final msg = ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1, 2, 3]),
        );

        sub.acknowledge(msg);

        var closeCompleted = false;
        final closeFuture = sub.close().then((_) {
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

    test('Subscription operations after close throw StateError', () async {
      final sub = client.subscription('my-sub');
      await sub.close();

      final msg = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      expect(() => sub.acknowledge(msg), throwsStateError);
      expect(() => sub.modifyAckDeadline(msg, 10), throwsStateError);
      expect(() => sub.acknowledgeNow([msg]), throwsStateError);
      expect(() => sub.modifyAckDeadlineNow([msg], 10), throwsStateError);
      expect(sub.pull, throwsStateError);
    });

    test('Subscription.pull validation and closed check', () async {
      final sub = client.subscription('my-sub');

      expect(() => sub.pull(maxMessages: 0), throwsArgumentError);
      expect(() => sub.pull(maxMessages: -1), throwsArgumentError);
      expect(
        () => client.pull(
          'projects/test-project/subscriptions/my-sub',
          maxMessages: 0,
        ),
        throwsArgumentError,
      );

      await sub.close();
      expect(sub.pull, throwsStateError);
    });

    test(
      'empty list no-ops for acknowledgeNow and modifyAckDeadlineNow',
      () async {
        final sub = client.subscription('my-sub');
        await sub.acknowledgeNow([]);
        expect(fakeSubscriber.acknowledgeCalled, isFalse);

        await sub.modifyAckDeadlineNow([], 10);
        expect(fakeSubscriber.modifyAckDeadlineCalled, isFalse);
      },
    );

    test(
      'Subscription.create() returns this and preserves ackSettings',
      () async {
        final customSettings = AckSettings(
          batching: BatchingSettings(maxMessages: 42),
        );
        final sub = client.subscription('my-sub', ackSettings: customSettings);
        final created = await sub.create(
          topic: 'projects/test-project/topics/my-topic',
        );
        expect(identical(created, sub), isTrue);
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

    test('PubSub.pull defaults to maxMessages 100', () async {
      await client.pull('projects/test-project/subscriptions/my-sub');
      expect(fakeSubscriber.pullCalled, isTrue);
      expect(fakeSubscriber.lastMaxMessages, equals(100));
    });

    test('Subscription.pull defaults to maxMessages 100', () async {
      final sub = client.subscription('my-sub');
      await sub.pull();
      expect(fakeSubscriber.pullCalled, isTrue);
      expect(fakeSubscriber.lastMaxMessages, equals(100));
    });
  });
}
