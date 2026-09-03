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
    final conn = StreamConnection();
    connections.add(conn);
    request.listen(conn.recordedRequests.add);
    onNewConnection.add(conn);
    return FakeResponseStream(conn.responseController.stream);
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
      final msg = ReceivedMessage(
        ackId: 'ack-123',
        messageId: 'msg-456',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      await expectLater(msg.acknowledge, throwsStateError);
      await expectLater(() => msg.modifyAckDeadline(10), throwsStateError);
      expect(() => msg.modifyAckDeadline(-1), throwsArgumentError);
    });

    test(
      'message.acknowledge() on streamingPull actually sends ACK over stream',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: const AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: Duration(milliseconds: 10),
            ),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final sub = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));
        final conn = fakeSubscriber.connections.first
          ..emitMessage('ack-stream-1', 'msg-stream-1');

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;
        expect(message.ackId, equals('ack-stream-1'));

        await message.acknowledge();

        await Future<void>.delayed(const Duration(milliseconds: 50));

        final ackRequests = conn.recordedRequests
            .where((req) => req.ackIds.contains('ack-stream-1'))
            .toList();
        expect(
          ackRequests.isNotEmpty,
          isTrue,
          reason: 'ACK should be sent over streaming pull request stream',
        );

        await sub.cancel();
        await subscription.close();
      },
    );

    test('message.modifyAckDeadline() on streamingPull sends deadline update '
        'over stream', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: const AckSettings(
          batching: BatchingSettings(
            maxMessages: 1,
            maxDelay: Duration(milliseconds: 10),
          ),
        ),
      );

      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final sub = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      final conn = fakeSubscriber.connections.first
        ..emitMessage('ack-mod-1', 'msg-mod-1');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));

      final message = receivedList.first;
      await message.modifyAckDeadline(30);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final modRequests = conn.recordedRequests
          .where((req) => req.modifyDeadlineAckIds.contains('ack-mod-1'))
          .toList();
      expect(modRequests.isNotEmpty, isTrue);
      expect(modRequests.first.modifyDeadlineSeconds.first, equals(30));

      await sub.cancel();
      await subscription.close();
    });

    test(
      'PubSub.streamingPull wires ack and modify deadline handlers',
      () async {
        final stream = client.streamingPull(
          'projects/test-project/subscriptions/test-sub',
        );
        final receivedList = <ReceivedMessage>[];
        final sub = stream.listen(receivedList.add);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));
        final conn = fakeSubscriber.connections.first
          ..emitMessage('raw-ack-1', 'raw-msg-1');

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(receivedList.length, equals(1));

        final message = receivedList.first;
        await message.acknowledge();

        await Future<void>.delayed(const Duration(milliseconds: 20));
        final ackRequests = conn.recordedRequests
            .where((req) => req.ackIds.contains('raw-ack-1'))
            .toList();
        expect(ackRequests.isNotEmpty, isTrue);

        await sub.cancel();
      },
    );

    test('non-retryable errors (NotFoundException, ForbiddenException) fail '
        'immediately', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: const AckSettings(retry: RetrySettings(maxRetries: 10)),
      );

      final stream = subscription.streamingPull();
      Object? streamError;
      var streamDone = false;

      final sub = stream.listen(
        (_) {},
        onError: (Object e) {
          streamError = e;
        },
        onDone: () {
          streamDone = true;
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final conn = fakeSubscriber.connections.first;

      conn.responseController.addError(
        const grpc.GrpcError.notFound('Subscription not found'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeSubscriber.connections.length, equals(1));
      expect(streamError, isA<NotFoundException>());
      expect(streamDone, isTrue);

      await sub.cancel();
      await subscription.close();
    });

    test('idle streaming pull reconnects cleanly after disconnect', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: const AckSettings(
          retry: RetrySettings(
            initialDelay: Duration(milliseconds: 10),
            maxDelay: Duration(milliseconds: 20),
          ),
        ),
      );

      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final sub = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final conn1 = fakeSubscriber.connections[0];

      conn1.responseController.addError(
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

      await sub.cancel();
      await subscription.close();
    });

    test(
      'onDone applies backoff and delay instead of microtask loop',
      () async {
        final subscription = client.subscription(
          'test-sub',
          ackSettings: const AckSettings(
            retry: RetrySettings(
              initialDelay: Duration(milliseconds: 50),
              maxDelay: Duration(milliseconds: 100),
            ),
          ),
        );

        final stream = subscription.streamingPull();
        final sub = stream.listen((_) {});

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakeSubscriber.connections.length, equals(1));

        await fakeSubscriber.connections[0].responseController.close();

        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(fakeSubscriber.connections.length, equals(1));

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(fakeSubscriber.connections.length, equals(2));

        await sub.cancel();
        await subscription.close();
      },
    );

    test('multi-stream concurrency: dropping one stream does not close '
        'controller while other streams active', () async {
      final subscription = client.subscription(
        'test-sub',
        ackSettings: const AckSettings(
          retry: RetrySettings(
            initialDelay: Duration(milliseconds: 10),
            maxDelay: Duration(milliseconds: 20),
          ),
        ),
      );

      final stream = subscription.streamingPull(maxConcurrentStreams: 2);
      final receivedList = <ReceivedMessage>[];
      var isStreamDone = false;
      final sub = stream.listen(
        receivedList.add,
        onDone: () => isStreamDone = true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fakeSubscriber.connections.length, equals(2));
      final conn1 = fakeSubscriber.connections[0];
      final conn2 = fakeSubscriber.connections[1];

      conn1.responseController.addError(
        const grpc.GrpcError.unavailable('Transient stream 1 drop'),
      );

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(isStreamDone, isFalse);

      conn2.emitMessage('ack-conn2', 'msg-conn2');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.ackId, equals('ack-conn2'));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fakeSubscriber.connections.length, equals(3));
      expect(isStreamDone, isFalse);

      await sub.cancel();
      await subscription.close();
    });

    test('backpressure pause and resume on stream controller', () async {
      final subscription = client.subscription('test-sub');
      final stream = subscription.streamingPull();

      final receivedList = <ReceivedMessage>[];
      final sub = stream.listen(receivedList.add);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));
      final conn = fakeSubscriber.connections.first;

      sub.pause();
      expect(sub.isPaused, isTrue);

      conn.emitMessage('ack-p1', 'msg-p1');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.isEmpty, isTrue);

      sub.resume();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedList.length, equals(1));
      expect(receivedList.first.ackId, equals('ack-p1'));

      await sub.cancel();
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
          ackSettings: const AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: Duration(seconds: 10),
            ),
          ),
        );

        final msg = ReceivedMessage(
          ackId: 'ack-batch-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );

        subscription.acknowledge(msg);

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
          ackSettings: const AckSettings(
            batching: BatchingSettings(
              maxMessages: 10,
              maxDelay: Duration(seconds: 10),
            ),
          ),
        );

        final msg = ReceivedMessage(
          ackId: 'ack-batch-1',
          messageId: 'msg-1',
          publishTime: DateTime.now(),
          message: Message(data: [1]),
        );
        subscription.acknowledge(msg);

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

      final msg = ReceivedMessage(
        ackId: 'ack-1',
        messageId: 'msg-1',
        publishTime: DateTime.now(),
        message: Message(data: [1]),
      );

      expect(() => subscription.acknowledge(msg), throwsStateError);
      expect(() => subscription.acknowledgeNow([msg]), throwsStateError);
      expect(() => subscription.modifyAckDeadline(msg, 10), throwsStateError);
      expect(
        () => subscription.modifyAckDeadlineNow([msg], 10),
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
          ackSettings: const AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: Duration(milliseconds: 1),
            ),
            retry: RetrySettings(maxRetries: 0),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final sub = stream.listen(receivedList.add);

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
        await sub.cancel();

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
          ackSettings: const AckSettings(
            batching: BatchingSettings(
              maxMessages: 1,
              maxDelay: Duration(milliseconds: 1),
            ),
            retry: RetrySettings(maxRetries: 0),
          ),
        );

        final stream = subscription.streamingPull();
        final receivedList = <ReceivedMessage>[];
        final sub = stream.listen(receivedList.add);

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
        await sub.cancel();

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
        ackSettings: const AckSettings(
          retry: RetrySettings(
            maxRetries: 10,
            initialDelay: Duration(milliseconds: 10),
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

      final sub = stream.listen((_) {});
      // Cancel immediately while _callOptions is in-flight
      await sub.cancel();

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
        ackSettings: const AckSettings(
          batching: BatchingSettings(
            maxMessages: 1,
            maxDelay: Duration(milliseconds: 1),
          ),
          retry: RetrySettings(maxRetries: 0),
        ),
      );

      // Start streaming pull to establish active stream
      final stream = subscription.streamingPull();
      final receivedList = <ReceivedMessage>[];
      final sub = stream.listen(receivedList.add);

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
      await sub.cancel();

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

    test('custom RetrySettings without explicit totalTimeout defaults '
        'totalTimeout to null', () async {
      final subscription = client.subscription('test-sub');

      // Without explicit totalTimeout, totalTimeout defaults to null
      const customRetry = RetrySettings(
        maxRetries: 5,
        initialDelay: Duration(milliseconds: 10),
      );
      expect(customRetry.hasExplicitTotalTimeout, isFalse);

      final stream = subscription.streamingPull(retry: customRetry);
      final sub = stream.listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeSubscriber.connections.length, equals(1));

      // When explicit totalTimeout is provided, hasExplicitTotalTimeout is true
      const explicitTimeoutRetry = RetrySettings(
        maxRetries: 5,
        totalTimeout: Duration(minutes: 5),
      );
      expect(explicitTimeoutRetry.hasExplicitTotalTimeout, isTrue);

      await sub.cancel();
      await subscription.close();
    });
  });
}
