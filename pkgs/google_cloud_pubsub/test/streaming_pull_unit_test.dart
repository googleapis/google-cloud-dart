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
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pbgrpc.dart'
    as generated;
import 'package:grpc/grpc.dart' as grpc;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as protobuf;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as pb_ts;
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
    onError: (Object error, StackTrace stackTrace) {
      if (onError != null) {
        if (onError is FutureOr<S> Function(Object, StackTrace)) {
          onError(error, stackTrace);
        } else if (onError is FutureOr<S> Function(Object)) {
          onError(error);
        } else {
          // ignore: avoid_dynamic_calls
          (onError as dynamic)(error, stackTrace);
        }
      }
    },
  );
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

class StreamConnection {
  final StreamController<generated.StreamingPullResponse> responseController =
      StreamController<generated.StreamingPullResponse>();
  final List<generated.StreamingPullRequest> recordedRequests = [];

  void emitMessage(String ackId, String messageId) {
    responseController.add(
      generated.StreamingPullResponse()
        ..receivedMessages.add(
          generated.ReceivedMessage()
            ..ackId = ackId
            ..message = (pb.PubsubMessage()
              ..messageId = messageId
              ..publishTime = pb_ts.Timestamp.fromDateTime(DateTime.now())),
        ),
    );
  }
}

class FakeSubscriberClient extends Fake implements generated.SubscriberClient {
  final List<StreamConnection> connections = [];
  final StreamController<StreamConnection> onNewConnection =
      StreamController<StreamConnection>.broadcast();

  final List<List<String>> unaryAckCalls = [];
  final List<(List<String>, int)> unaryModifyDeadlineCalls = [];
  Future<void> Function(List<String> ackIds)? acknowledgeBehavior;
  bool get acknowledgeCalled => unaryAckCalls.isNotEmpty;

  @override
  grpc.ResponseStream<generated.StreamingPullResponse> streamingPull(
    Stream<generated.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    final connection = StreamConnection();
    connections.add(connection);
    request.listen(connection.recordedRequests.add);
    onNewConnection.add(connection);
    return FakeResponseStream(connection.responseController.stream);
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> acknowledge(
    generated.AcknowledgeRequest request, {
    grpc.CallOptions? options,
  }) {
    unaryAckCalls.add(request.ackIds);
    final completer = Completer<protobuf.Empty>();
    if (acknowledgeBehavior case final behavior?) {
      behavior(request.ackIds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  Future<void> Function(List<String> ackIds, int seconds)?
  modifyAckDeadlineBehavior;

  @override
  grpc.ResponseFuture<protobuf.Empty> modifyAckDeadline(
    generated.ModifyAckDeadlineRequest request, {
    grpc.CallOptions? options,
  }) {
    unaryModifyDeadlineCalls.add((request.ackIds, request.ackDeadlineSeconds));
    final completer = Completer<protobuf.Empty>();
    if (modifyAckDeadlineBehavior case final behavior?) {
      behavior(request.ackIds, request.ackDeadlineSeconds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }
}

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {}
}

class DelayedAuthenticator extends Fake implements grpc.BaseAuthenticator {
  final Completer<void> completer = Completer<void>();

  @override
  Future<void> authenticate(Map<String, String> metadata, String uri) async {
    await completer.future;
  }
}

class ThrowingSubscriberClient extends Fake
    implements generated.SubscriberClient {
  @override
  grpc.ResponseStream<generated.StreamingPullResponse> streamingPull(
    Stream<generated.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    throw StateError('setup failure');
  }
}

class ThrowingAuthenticator extends Fake implements grpc.BaseAuthenticator {
  @override
  grpc.CallOptions get toCallOptions => throw Exception('auth failure');
}

void main() {
  group('Streaming Pull & ReceivedMessage', () {
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

    test('ReceivedMessage with null handlers throws StateError', () async {
      final message = ReceivedMessage(
        ackId: 'ack-123',
        messageId: 'msg-456',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      await expectLater(message.acknowledge, throwsStateError);
      await expectLater(() => message.modifyAckDeadline(10), throwsStateError);
      expect(() => message.modifyAckDeadline(-1), throwsArgumentError);
    });

    test(
      'message.acknowledge() on streamingPull actually sends ACK over stream',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(milliseconds: 10),
            ),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final streamSubscription = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));
        final connection = fakeSubscriber.connections.first
          ..emitMessage('ack-stream-1', 'msg-stream-1');

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;
        expect(message.ackId, equals('ack-stream-1'));

        await message.acknowledge();

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final ackRequests = connection.recordedRequests
            .where((request) => request.ackIds.contains('ack-stream-1'))
            .toList();
        expect(
          ackRequests.isNotEmpty,
          isTrue,
          reason: 'ACK should be sent over streaming pull request stream',
        );

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test('message.modifyAckDeadline() on streamingPull sends deadline update '
        'over stream', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 1,
            maxDelay: const Duration(milliseconds: 10),
          ),
        ),
      );

      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final streamSubscription = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final connection = fakeSubscriber.connections.first
        ..emitMessage('ack-mod-1', 'msg-mod-1');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));

      final message = receivedList.first;
      await message.modifyAckDeadline(30);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final modRequests = connection.recordedRequests
          .where(
            (request) => request.modifyDeadlineAckIds.contains('ack-mod-1'),
          )
          .toList();
      expect(modRequests.isNotEmpty, isTrue);
      expect(modRequests.first.modifyDeadlineSeconds.first, equals(30));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test(
      'PubSub.streamingPull wires ack and modify deadline handlers',
      () async {
        final stream = client.streamingPull(
          'projects/test-project/subscriptions/test-sub',
        );
        final receivedList = <ReceivedMessage>[];
        final streamSubscription = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));
        final connection = fakeSubscriber.connections.first
          ..emitMessage('raw-ack-1', 'raw-msg-1');

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;
        await message.acknowledge();

        await Future<void>.delayed(const Duration(milliseconds: 20));
        final ackRequests = connection.recordedRequests
            .where((request) => request.ackIds.contains('raw-ack-1'))
            .toList();
        expect(ackRequests.isNotEmpty, isTrue);

        await streamSubscription.cancel();
      },
    );

    test('PubSub.streamingPull validates non-empty subscription name', () {
      expect(
        () => client.streamingPull(''),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Must not be empty'),
          ),
        ),
      );
    });

    test('PubSub.streamingPull handlers validate arguments', () async {
      final stream = client.streamingPull(
        'projects/test-project/subscriptions/test-sub',
      );
      ReceivedMessage? message;
      final streamSubscription = stream.listen(
        (incomingMessage) => message = incomingMessage,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeSubscriber.connections.first.emitMessage('v-ack', 'v-msg');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(message, isNotNull);
      expect(() => message!.modifyAckDeadline(-1), throwsArgumentError);

      await streamSubscription.cancel();
    });

    test('non-retryable errors (NotFoundException, ForbiddenException) fail '
        'immediately', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(retry: RetrySettings(maxRetries: 10)),
      );

      final stream = subscription.streamingPull();
      Object? streamError;
      var streamDone = false;

      final streamSubscription = stream.listen(
        (_) {},
        onError: (Object error) {
          streamError = error;
        },
        onDone: () {
          streamDone = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final connection = fakeSubscriber.connections.first;

      connection.responseController.addError(
        const grpc.GrpcError.notFound('Subscription not found'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeSubscriber.connections.length, equals(1));
      expect(streamError, isA<NotFoundException>());
      expect(streamDone, isTrue);

      await streamSubscription.cancel();
      await subscription.close();

      // Verify ForbiddenException (permissionDenied) also fails immediately.
      final forbiddenSub = client.subscription(
        'forbidden-sub',
        ackSettings: AckSettings(retry: RetrySettings(maxRetries: 10)),
      );
      Object? forbiddenError;
      var forbiddenDone = false;
      final sub2 = forbiddenSub.streamingPull().listen(
        (_) {},
        onError: (Object error) {
          forbiddenError = error;
        },
        onDone: () {
          forbiddenDone = true;
        },
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      fakeSubscriber.connections.last.responseController.addError(
        const grpc.GrpcError.permissionDenied('Permission denied'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(forbiddenError, isA<ForbiddenException>());
      expect(forbiddenDone, isTrue);
      await sub2.cancel();
      await forbiddenSub.close();
    });

    test('idle streaming pull reconnects cleanly after disconnect', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          retry: RetrySettings(
            initialDelay: const Duration(milliseconds: 10),
            maxDelay: const Duration(milliseconds: 20),
          ),
        ),
      );

      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final streamSubscription = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final connection1 = fakeSubscriber.connections[0];

      connection1.responseController.addError(
        const grpc.GrpcError.unavailable('Server disconnected idle stream'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        fakeSubscriber.connections.length,
        equals(2),
        reason: 'Should have cleanly reconnected to a new stream',
      );

      fakeSubscriber.connections[1].emitMessage(
        'ack-reconnect-1',
        'msg-reconnect-1',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.messageId, equals('msg-reconnect-1'));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test(
      'onDone applies backoff and delay instead of microtask loop',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            retry: RetrySettings(
              initialDelay: const Duration(milliseconds: 50),
              maxDelay: const Duration(milliseconds: 100),
            ),
          ),
        );

        final stream = subscription.streamingPull();
        final streamSubscription = stream.listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));

        await fakeSubscriber.connections[0].responseController.close();

        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(fakeSubscriber.connections.length, equals(1));

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(fakeSubscriber.connections.length, equals(2));

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test('multi-stream concurrency: dropping one stream does not close '
        'controller while other streams active', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          retry: RetrySettings(
            initialDelay: const Duration(milliseconds: 10),
            maxDelay: const Duration(milliseconds: 20),
          ),
        ),
      );

      final stream = subscription.streamingPull(maxConcurrentStreams: 2);
      final receivedList = <ReceivedMessage>[];
      var isStreamDone = false;
      final streamSubscription = stream.listen(
        receivedList.add,
        onDone: () => isStreamDone = true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(2));
      final connection1 = fakeSubscriber.connections[0];
      final connection2 = fakeSubscriber.connections[1];

      connection1.responseController.addError(
        const grpc.GrpcError.unavailable('Transient stream 1 drop'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(isStreamDone, isFalse);

      connection2.emitMessage('ack-conn2', 'msg-conn2');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.ackId, equals('ack-conn2'));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fakeSubscriber.connections.length, equals(3));
      expect(isStreamDone, isFalse);

      await streamSubscription.cancel();
      await subscription.close();
    });

    test('backpressure pause and resume on stream controller', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();

      final receivedList = <ReceivedMessage>[];
      final streamSubscription = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final connection = fakeSubscriber.connections.first;

      streamSubscription.pause();
      expect(streamSubscription.isPaused, isTrue);

      connection.emitMessage('ack-p1', 'msg-p1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.isEmpty, isTrue);

      streamSubscription.resume();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.ackId, equals('ack-p1'));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test('stream reconnected while paused starts paused and buffers messages '
        'until resumed', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          retry: RetrySettings(
            initialDelay: const Duration(milliseconds: 20),
            maxDelay: const Duration(milliseconds: 50),
          ),
        ),
      );
      final stream = subscription.streamingPull();

      final receivedList = <ReceivedMessage>[];
      final streamSubscription = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final connection1 = fakeSubscriber.connections.first;

      // Pause while stream is healthy
      streamSubscription.pause();
      expect(streamSubscription.isPaused, isTrue);

      // Disconnect stream 1 while paused
      final nextConnectionFuture = fakeSubscriber.onNewConnection.stream.first;
      connection1.responseController.addError(
        const grpc.GrpcError.unavailable(
          'Simulated transient drop while paused',
        ),
      );

      // While paused, the stream subscription buffers the error and does
      // not dispatch.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(1));
      expect(receivedList.isEmpty, isTrue);

      // Resume stream: buffered error is dispatched, triggering reconnection
      streamSubscription.resume();
      final connection2 = await nextConnectionFuture.timeout(
        const Duration(seconds: 3),
      );
      expect(fakeSubscriber.connections.length, equals(2));

      // Emit message on reconnected stream
      connection2.emitMessage('ack-reconnected', 'msg-reconnected');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.ackId, equals('ack-reconnected'));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test(
      'Subscription.close() flushes and awaits in-flight batch operations',
      () async {
        final ackCompleter = Completer<void>();
        var ackCompleted = false;

        fakeSubscriber.acknowledgeBehavior = (ackIds) async {
          await ackCompleter.future;
          ackCompleted = true;
        };

        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final message = ReceivedMessage(
          ackId: 'ack-batch-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );

        subscription.acknowledge(message);

        var closeCompleted = false;
        final closeFuture = subscription.close().then((_) {
          closeCompleted = true;
        });

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(closeCompleted, isFalse);
        expect(fakeSubscriber.acknowledgeCalled, isTrue);

        ackCompleter.complete();
        await closeFuture;

        expect(closeCompleted, isTrue);
        expect(ackCompleted, isTrue);
      },
    );

    test(
      'multiple concurrent calls to Subscription.close() await same future',
      () async {
        final ackCompleter = Completer<void>();
        fakeSubscriber.acknowledgeBehavior = (ackIds) async =>
            ackCompleter.future;

        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final message = ReceivedMessage(
          ackId: 'ack-batch-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );
        subscription.acknowledge(message);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        var c1Done = false;
        var c2Done = false;
        final c1 = subscription.close().then((_) => c1Done = true);
        final c2 = subscription.close().then((_) => c2Done = true);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(c1Done, isFalse);
        expect(c2Done, isFalse);

        ackCompleter.complete();
        await Future.wait([c1, c2]);
        expect(c1Done, isTrue);
        expect(c2Done, isTrue);
      },
    );

    test('operations on closed subscription throw StateError', () async {
      final subscription = client.subscription('test-sub');
      await subscription.close();

      final message = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      expect(() => subscription.acknowledge(message), throwsStateError);
      expect(() => subscription.acknowledgeNow([message]), throwsStateError);
      expect(
        () => subscription.modifyAckDeadline(message, 10),
        throwsStateError,
      );
      expect(
        () => subscription.modifyAckDeadlineNow([message], 10),
        throwsStateError,
      );
    });

    test(
      'message.acknowledge() propagates error when unary fallback fails',
      () async {
        fakeSubscriber.acknowledgeBehavior = (ackIds) async {
          throw const grpc.GrpcError.internal('Unary ack failure');
        };

        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(milliseconds: 1),
            ),
            retry: RetrySettings(maxRetries: 0),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final streamSubscription = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        fakeSubscriber.connections.first.emitMessage(
          'ack-fail-1',
          'msg-fail-1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;

        // Cancel the stream first so _activeStreams is empty and ACK
        // must use unary fallback.
        await streamSubscription.cancel();

        await expectLater(
          message.acknowledge(),
          throwsA(isA<InternalServerErrorException>()),
        );

        await subscription.close();
      },
    );

    test(
      'message.modifyAckDeadline() propagates error when unary fallback fails',
      () async {
        fakeSubscriber.modifyAckDeadlineBehavior = (ackIds, seconds) async {
          throw const grpc.GrpcError.internal('Unary mod failure');
        };

        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(milliseconds: 1),
            ),
            retry: RetrySettings(maxRetries: 0),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final streamSubscription = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        fakeSubscriber.connections.first.emitMessage(
          'ack-fail-2',
          'msg-fail-2',
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;

        // Cancel the stream first so _activeStreams is empty and modify
        // must use unary fallback.
        await streamSubscription.cancel();

        await expectLater(
          message.modifyAckDeadline(10),
          throwsA(isA<InternalServerErrorException>()),
        );

        await subscription.close();
      },
    );

    test('Subscription.close() stops active streaming pull controllers '
        'and prevents reconnects', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          retry: RetrySettings(
            maxRetries: 10,
            initialDelay: const Duration(milliseconds: 10),
          ),
        ),
      );

      final stream = subscription.streamingPull();
      var isDone = false;
      stream.listen(
        (_) {},
        onDone: () {
          isDone = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));

      await subscription.close();
      await Future<void>.delayed(Duration.zero);

      expect(isDone, isTrue);
      final countAfterClose = fakeSubscriber.connections.length;

      // Simulate error on the previous connection response controller
      fakeSubscriber.connections.first.responseController.addError(
        const grpc.GrpcError.unavailable('Simulated connection dropped'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      // No new connections should be spawned after close
      expect(fakeSubscriber.connections.length, equals(countAfterClose));
    });

    test('cancellation during stream initialization (_callOptions) '
        'does not leak connections', () async {
      final delayedAuth = DelayedAuthenticator();
      final clientWithDelayedAuth = PubSub.testing(
        projectId: 'test-project',
        channel: FakeClientChannel(),
        subscriberClient: fakeSubscriber,
        authenticator: delayedAuth,
      );

      final requestController =
          StreamController<generated.StreamingPullRequest>();
      final stream = clientWithDelayedAuth.streamingPullWithStream(
        requestController.stream,
      );

      final streamSubscription = stream.listen((_) {});
      // Cancel immediately while _callOptions is in-flight
      await streamSubscription.cancel();

      // Now complete the authenticator
      delayedAuth.completer.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Fake subscriber should not have received a streamingPull call
      expect(fakeSubscriber.connections.isEmpty, isTrue);

      if (!requestController.hasListener) {
        unawaited(requestController.stream.drain<void>());
      }
      await requestController.close();
      await clientWithDelayedAuth.close();
    });

    test('stream without listener is skipped during ACK batching and '
        'falls back to unary', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 1,
            maxDelay: const Duration(milliseconds: 1),
          ),
          retry: RetrySettings(maxRetries: 0),
        ),
      );

      // Start streaming pull to establish active stream
      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final streamSubscription = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      fakeSubscriber.connections.first.emitMessage(
        'ack-stream-skip',
        'msg-stream-skip',
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      final message = receivedList.first;

      // Cancel stream listener so controller hasListener == false
      await streamSubscription.cancel();

      // Acknowledge should skip unlistened stream and invoke unary ack
      await message.acknowledge();

      expect(fakeSubscriber.acknowledgeCalled, isTrue);
      expect(
        fakeSubscriber.unaryAckCalls.any(
          (call) => call.contains('ack-stream-skip'),
        ),
        isTrue,
      );

      await subscription.close();
    });

    test(
      'custom RetrySettings is respected directly in streamingPull',
      () async {
        final subscription = client.subscription('test-sub');

        final customRetry = RetrySettings(
          maxRetries: 5,
          totalTimeout: const Duration(minutes: 5),
          initialDelay: const Duration(milliseconds: 10),
        );
        expect(customRetry.totalTimeout, equals(const Duration(minutes: 5)));

        final stream = subscription.streamingPull(retry: customRetry);
        final streamSubscription = stream.listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test(
      'streamingPullWithStream closes controller when setup fails',
      () async {
        final clientWithFailure = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          subscriberClient: ThrowingSubscriberClient(),
        );
        final reqController =
            StreamController<generated.StreamingPullRequest>();
        final stream = clientWithFailure.streamingPullWithStream(
          reqController.stream,
        );

        final errors = <Object>[];
        var isDone = false;
        stream.listen((_) {}, onError: errors.add, onDone: () => isDone = true);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(errors.length, equals(1));
        expect(errors.first, isA<StateError>());
        expect(isDone, isTrue);

        unawaited(reqController.close());
        await clientWithFailure.close();
      },
    );

    test(
      'streamingPullWithStream closes controller when _callOptions fails',
      () async {
        final clientWithAuthFailure = PubSub.testing(
          projectId: 'test-project',
          channel: FakeClientChannel(),
          subscriberClient: fakeSubscriber,
          authenticator: ThrowingAuthenticator(),
        );
        final reqController =
            StreamController<generated.StreamingPullRequest>();
        final stream = clientWithAuthFailure.streamingPullWithStream(
          reqController.stream,
        );

        final errors = <Object>[];
        var isDone = false;
        stream.listen((_) {}, onError: errors.add, onDone: () => isDone = true);

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(errors.length, equals(1));
        expect(isDone, isTrue);

        unawaited(reqController.close());
        await clientWithAuthFailure.close();
      },
    );

    test(
      'Subscription batchers flush over active stream during normal operation',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: const Duration(seconds: 10),
            ),
            retry: RetrySettings(maxRetries: 0),
          ),
        );

        final stream = subscription.streamingPull();
        final streamSubscription = stream.listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.connections.length, equals(1));

        final message = ReceivedMessage(
          ackId: 'ack-stream-test',
          messageId: 'msg-stream-test',
          publishTime: DateTime.now(),
          message: Message(data: [1, 2, 3]),
        );

        subscription.acknowledge(message);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final connection = fakeSubscriber.connections.first;
        final streamAckedIds = connection.recordedRequests
            .expand((request) => request.ackIds)
            .toList();

        expect(streamAckedIds, contains('ack-stream-test'));
        expect(fakeSubscriber.unaryAckCalls, isEmpty);

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test('Subscription.close() flushes batchers via unary RPC during shutdown '
        'to guarantee server confirmation', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 100,
            maxDelay: const Duration(seconds: 10),
          ),
          retry: RetrySettings(maxRetries: 0),
        ),
      );

      final stream = subscription.streamingPull();
      final streamSubscription = stream.listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(1));

      final message = ReceivedMessage(
        ackId: 'ack-close-test',
        messageId: 'msg-close-test',
        publishTime: DateTime.now(),
        message: Message(data: [1, 2, 3]),
      );

      subscription.acknowledge(message);

      // Close the subscription. During shutdown, streams are cancelled and
      // batchers are flushed via unary RPC to ensure server confirmation.
      await subscription.close();

      expect(fakeSubscriber.unaryAckCalls.single, contains('ack-close-test'));

      await streamSubscription.cancel();
    });

    test('streamingPullWithStream emits error and closes controller on '
        'mid-stream error', () async {
      final reqController = StreamController<generated.StreamingPullRequest>();
      final stream = client.streamingPullWithStream(reqController.stream);

      final errors = <Object>[];
      final items = <ReceivedMessage>[];
      var isDone = false;
      final streamSubscription = stream.listen(
        items.add,
        onError: errors.add,
        onDone: () => isDone = true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final connection = fakeSubscriber.connections.first
        ..emitMessage('ack-mid-stream', 'msg-mid-stream');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(items.length, equals(1));
      expect(items.first.ackId, equals('ack-mid-stream'));

      // Emit mid-stream gRPC error on response stream
      connection.responseController.addError(
        const grpc.GrpcError.unavailable('Transient mid-stream drop'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(errors.length, equals(1));
      expect(errors.first, isA<ServiceException>());
      expect(isDone, isTrue);

      await streamSubscription.cancel();
      unawaited(reqController.close());
    });

    test('multi-stream teardown on non-retryable error does not emit duplicate '
        'errors or leave orphaned timers', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull(
        maxConcurrentStreams: 4,
        retry: RetrySettings(
          maxRetries: 5,
          initialDelay: const Duration(milliseconds: 20),
        ),
      );

      final errors = <Object>[];
      var isDone = false;
      final streamSubscription = stream.listen(
        (_) {},
        onError: errors.add,
        onDone: () => isDone = true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(4));

      // Inject non-retryable error on connection[0], concurrent
      // non-retryable error on connection[1] (tests duplicate error
      // suppression), concurrent transient retryable error on connection[2]
      // (tests orphaned timer suppression), and concurrent normal closure
      // on connection[3] (tests onDone).
      fakeSubscriber.connections[0].responseController.addError(
        const grpc.GrpcError.notFound('Subscription not found'),
      );
      fakeSubscriber.connections[1].responseController.addError(
        const grpc.GrpcError.notFound('Subscription not found'),
      );
      fakeSubscriber.connections[2].responseController.addError(
        const grpc.GrpcError.unavailable('Transient drop'),
      );
      unawaited(fakeSubscriber.connections[3].responseController.close());

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errors.length, equals(1));
      expect(errors.first, isA<NotFoundException>());
      expect(isDone, isTrue);

      // Wait beyond the retry backoff duration (20ms) to verify that no
      // orphaned reconnect timers fired.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fakeSubscriber.connections.length, equals(4));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test(
      'idle streaming pull reconnects cleanly on onDone without messages',
      () async {
        final subscription = client.subscription('test-sub');
        final stream = subscription.streamingPull(
          retry: RetrySettings(
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 10),
            maxDelay: const Duration(milliseconds: 20),
          ),
        );

        final streamSubscription = stream.listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(fakeSubscriber.connections.length, equals(1));

        // Server closes idle connection without any messages or errors.
        await fakeSubscriber.connections.first.responseController.close();

        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Should have reconnected cleanly.
        expect(fakeSubscriber.connections.length, equals(2));

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test('concurrent message.acknowledge and modifyAckDeadline calls for '
        'duplicate ackId resolve all completers', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();
      ReceivedMessage? received;
      final streamSubscription = stream.listen((message) {
        received = message;
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(1));

      final connection = fakeSubscriber.connections.first;
      connection.responseController.add(
        generated.StreamingPullResponse()
          ..receivedMessages.add(
            generated.ReceivedMessage()
              ..ackId = 'duplicate-ack'
              ..message = (generated.PubsubMessage()..messageId = 'm1'),
          ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, isNotNull);

      // Multiple calls on the same ackId
      final a1 = received!.acknowledge();
      final a2 = received!.acknowledge();
      await Future.wait([a1, a2]).timeout(const Duration(seconds: 2));

      final m1 = received!.modifyAckDeadline(30);
      final m2 = received!.modifyAckDeadline(0);
      await Future.wait([m1, m2]).timeout(const Duration(seconds: 2));

      await streamSubscription.cancel();
      await subscription.close();
    });

    test('Subscription.close() completes without hanging when stream consumer '
        'is paused', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();
      final streamSubscription = stream.listen((_) {})..pause();

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Should complete quickly despite the stream subscription being paused.
      await subscription.close().timeout(const Duration(seconds: 2));
      await streamSubscription.cancel();
    });

    test(
      'multi-stream preserves fatal error when peer completes via onDone',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(retry: RetrySettings(maxRetries: 0)),
        );

        final stream = subscription.streamingPull(maxConcurrentStreams: 2);
        final errors = <Object>[];
        var isDone = false;
        final streamSubscription = stream.listen(
          (_) {},
          onError: errors.add,
          onDone: () => isDone = true,
        );

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.connections.length, equals(2));

        final connection1 = fakeSubscriber.connections[0];
        final connection2 = fakeSubscriber.connections[1];

        // connection1 fails with retryable error which exhausts retries
        // (maxRetries: 0)
        connection1.responseController.addError(
          const grpc.GrpcError.unavailable('transient error'),
        );

        // connection2 closes cleanly via onDone
        await connection2.responseController.close();

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(errors, hasLength(1));
        expect(errors.first, isA<ServiceException>());
        expect(isDone, isTrue);

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test(
      'streamingPull exhausts maxRetries on repeated rapid clean onDone drops',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: AckSettings(
            retry: RetrySettings(
              maxRetries: 2,
              initialDelay: const Duration(milliseconds: 1),
            ),
          ),
        );

        final stream = subscription.streamingPull();
        var isDone = false;
        final streamSubscription = stream.listen(
          (_) {},
          onDone: () {
            isDone = true;
          },
        );

        // Connection 0: close immediately without messages
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));
        await fakeSubscriber.connections[0].responseController.close();

        // Connection 1 (retry 1): close immediately
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.connections.length, equals(2));
        await fakeSubscriber.connections[1].responseController.close();

        // Connection 2 (retry 2): close immediately
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fakeSubscriber.connections.length, equals(3));
        await fakeSubscriber.connections[2].responseController.close();

        // Retries should be exhausted and stream should complete
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(isDone, isTrue);
        expect(fakeSubscriber.connections.length, equals(3));

        await streamSubscription.cancel();
        await subscription.close();
      },
    );

    test('Subscription.close() called from within stream listener callback '
        'completes without deadlock', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();

      final closed = Completer<void>();
      late StreamSubscription<ReceivedMessage> streamSubscription;
      streamSubscription = stream.listen((message) async {
        await subscription.close().timeout(const Duration(seconds: 2));
        closed.complete();
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      fakeSubscriber.connections.first.emitMessage('ack-1', 'msg-1');

      await closed.future.timeout(const Duration(seconds: 3));
      expect(subscription.isClosed, isTrue);
      await streamSubscription.cancel();
    });

    test('message.acknowledge() and modifyAckDeadline() on received message '
        'succeed via unary RPC during or after Subscription.close()', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();

      final receivedMessageCompleter = Completer<ReceivedMessage>();
      final streamSubscription = stream.listen(
        receivedMessageCompleter.complete,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      fakeSubscriber.connections.first.emitMessage('ack-drain', 'msg-drain');

      final message = await receivedMessageCompleter.future;

      // Close the subscription.
      await subscription.close();
      expect(subscription.isClosed, isTrue);

      // Direct calls on the Subscription instance throw StateError.
      expect(() => subscription.acknowledge(message), throwsStateError);
      expect(
        () => subscription.modifyAckDeadline(message, 30),
        throwsStateError,
      );

      // But calling message.acknowledge() and message.modifyAckDeadline()
      // on the already-delivered message succeeds via unary fallback.
      await message.acknowledge();
      expect(fakeSubscriber.unaryAckCalls.single, contains('ack-drain'));

      await message.modifyAckDeadline(30);
      expect(
        fakeSubscriber.unaryModifyDeadlineCalls.single.$1,
        contains('ack-drain'),
      );
      expect(fakeSubscriber.unaryModifyDeadlineCalls.single.$2, equals(30));

      await streamSubscription.cancel();
    });

    test('streamingPull round-robins ACKs across active streams and '
        'advances past closed streams', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: AckSettings(batching: BatchingSettings(maxMessages: 1)),
      );
      final stream = subscription.streamingPull(maxConcurrentStreams: 3);
      final streamSubscription = stream.listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(3));

      final connection0 = fakeSubscriber.connections[0];
      final connection1 = fakeSubscriber.connections[1];
      final connection2 = fakeSubscriber.connections[2];

      // Send ACK 1 -> routes to connection0
      subscription.acknowledge(
        ReceivedMessage(
          ackId: 'ack-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
          deliveryAttempt: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Send ACK 2 -> routes to connection1
      subscription.acknowledge(
        ReceivedMessage(
          ackId: 'ack-2',
          messageId: 'msg-2',
          publishTime: DateTime.now(),
          message: Message(data: [2]),
          deliveryAttempt: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Close connection2 so only connection0 and connection1 remain active
      await connection2.responseController.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Send ACK 3 -> starts at index 2 (closed connection2), skips to
      // connection0.
      // nextStreamIndex must advance to (0 + 1) = 1, not re-hit connection0!
      subscription.acknowledge(
        ReceivedMessage(
          ackId: 'ack-3',
          messageId: 'msg-3',
          publishTime: DateTime.now(),
          message: Message(data: [3]),
          deliveryAttempt: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Send ACK 4 -> routes to connection1
      subscription.acknowledge(
        ReceivedMessage(
          ackId: 'ack-4',
          messageId: 'msg-4',
          publishTime: DateTime.now(),
          message: Message(data: [4]),
          deliveryAttempt: 1,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final acks0 = connection0.recordedRequests
          .expand((request) => request.ackIds)
          .toList();
      final acks1 = connection1.recordedRequests
          .expand((request) => request.ackIds)
          .toList();

      expect(acks0, equals(['ack-1', 'ack-3']));
      expect(acks1, equals(['ack-2', 'ack-4']));

      await streamSubscription.cancel();
      await subscription.close();
    });
  });
}
