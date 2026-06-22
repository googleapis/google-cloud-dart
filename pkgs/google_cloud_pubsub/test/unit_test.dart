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
import 'package:test/test.dart';

// A fake ResponseFuture that delegates to a standard Future.
class FakeResponseFuture<T> implements grpc.ResponseFuture<T> {
  final Future<T> _future;

  FakeResponseFuture(this._future);

  @override
  Stream<T> asStream() => _future.asStream();

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

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
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #cancel) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

// A fake ResponseStream that delegates to a standard Stream.
class FakeResponseStream<T> extends Stream<T>
    implements grpc.ResponseStream<T> {
  final Stream<T> _stream;

  FakeResponseStream(this._stream);

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _stream.listen(
    onData,
    onError: (Object e, StackTrace s) {
      if (onError != null) {
        if (onError is void Function(Object, StackTrace)) {
          onError(e, s);
        } else if (onError is void Function(Object)) {
          onError(e);
        } else {
          // ignore: avoid_dynamic_calls
          (onError as dynamic)(e, s);
        }
      }
    },
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  grpc.ResponseFuture<T> get single => FakeResponseFuture(_stream.single);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #cancel) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeSubscriberClient implements generated.SubscriberClient {
  final StreamController<generated.StreamingPullResponse>
  streamingPullController = StreamController.broadcast();
  int streamingPullCallCount = 0;

  bool acknowledgeCalled = false;
  List<String>? lastAckIds;
  Future<void> Function(List<String> ackIds)? acknowledgeBehavior;

  bool modifyAckDeadlineCalled = false;
  List<String>? lastModifyAckDeadlineIds;
  int? lastModifyAckDeadlineSeconds;
  Future<void> Function(List<String> ackIds, int seconds)?
  modifyAckDeadlineBehavior;

  @override
  grpc.ResponseStream<generated.StreamingPullResponse> streamingPull(
    Stream<generated.StreamingPullRequest> request, {
    grpc.CallOptions? options,
  }) {
    streamingPullCallCount++;
    request.listen((_) {});
    return FakeResponseStream(streamingPullController.stream);
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> acknowledge(
    generated.AcknowledgeRequest request, {
    grpc.CallOptions? options,
  }) {
    acknowledgeCalled = true;
    lastAckIds = request.ackIds;

    final completer = Completer<protobuf.Empty>();
    if (acknowledgeBehavior != null) {
      acknowledgeBehavior!(request.ackIds)
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

    final completer = Completer<protobuf.Empty>();
    if (modifyAckDeadlineBehavior != null) {
      modifyAckDeadlineBehavior!(request.ackIds, request.ackDeadlineSeconds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeClientChannel implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {
    // No-op for testing
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PubSub Unit Tests (Error Propagation)', () {
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

    test('acknowledgeNow error propagates', () async {
      final subscription = client.subscription('sub');
      final stream = subscription.streamingPull();

      // Configure acknowledge to fail
      fakeSubscriber.acknowledgeBehavior = (ackIds) async {
        throw const grpc.GrpcError.notFound('Subscription not found');
      };

      // Push a fake message to the stream
      Timer(const Duration(milliseconds: 10), () {
        final fakeResponse = generated.StreamingPullResponse()
          ..receivedMessages.add(
            generated.ReceivedMessage()
              ..ackId = 'ack-1'
              ..message = (pb.PubsubMessage()..messageId = 'msg-1'),
          );
        fakeSubscriber.streamingPullController.add(fakeResponse);
      });

      final receivedMessage = await stream.first;
      expect(receivedMessage.ackId, equals('ack-1'));

      final ackFuture = subscription.acknowledgeNow([receivedMessage]);

      await expectLater(
        ackFuture,
        throwsA(
          isA<SubscriptionNotFoundException>().having(
            (e) => e.name,
            'name',
            'projects/test-project/subscriptions/sub',
          ),
        ),
      );

      expect(fakeSubscriber.acknowledgeCalled, isTrue);
      expect(fakeSubscriber.lastAckIds, equals(['ack-1']));
    });

    test('modifyAckDeadlineNow error propagates', () async {
      final subscription = client.subscription('sub');
      final stream = subscription.streamingPull();

      // Configure modifyAckDeadline to fail
      fakeSubscriber.modifyAckDeadlineBehavior = (ackIds, seconds) async {
        throw const grpc.GrpcError.notFound('Subscription not found');
      };

      // Push a fake message to the stream
      Timer(const Duration(milliseconds: 10), () {
        final fakeResponse = generated.StreamingPullResponse()
          ..receivedMessages.add(
            generated.ReceivedMessage()
              ..ackId = 'ack-2'
              ..message = (pb.PubsubMessage()..messageId = 'msg-2'),
          );
        fakeSubscriber.streamingPullController.add(fakeResponse);
      });

      final receivedMessage = await stream.first;
      expect(receivedMessage.ackId, equals('ack-2'));

      final modifyDeadlineFuture = subscription.modifyAckDeadlineNow([
        receivedMessage,
      ], 10);

      await expectLater(
        modifyDeadlineFuture,
        throwsA(
          isA<SubscriptionNotFoundException>().having(
            (e) => e.name,
            'name',
            'projects/test-project/subscriptions/sub',
          ),
        ),
      );

      expect(fakeSubscriber.modifyAckDeadlineCalled, isTrue);
      expect(fakeSubscriber.lastModifyAckDeadlineIds, equals(['ack-2']));
      expect(fakeSubscriber.lastModifyAckDeadlineSeconds, equals(10));
    });

    test('message mapping works correctly', () async {
      final stream = client.subscription('sub').streamingPull();

      final publishTime = DateTime.utc(2026, 6, 9, 12, 0, 0);

      Timer(const Duration(milliseconds: 10), () {
        final fakeResponse = generated.StreamingPullResponse()
          ..receivedMessages.add(
            generated.ReceivedMessage()
              ..ackId = 'ack-1'
              ..message = (pb.PubsubMessage()
                ..messageId = 'msg-1'
                ..publishTime = pb_ts.Timestamp.fromDateTime(publishTime)
                ..data = [1, 2, 3]
                ..attributes.addAll({'key': 'value'})),
          );
        fakeSubscriber.streamingPullController.add(fakeResponse);
      });

      final receivedMessage = await stream.first;
      expect(receivedMessage.ackId, equals('ack-1'));
      expect(receivedMessage.messageId, equals('msg-1'));
      expect(receivedMessage.publishTime, equals(publishTime));

      // Test delegation
      expect(receivedMessage.data, equals([1, 2, 3]));
      expect(receivedMessage.attributes, equals({'key': 'value'}));

      // Test message composition
      expect(receivedMessage.message.data, equals([1, 2, 3]));
      expect(receivedMessage.message.attributes, equals({'key': 'value'}));
    });
    test('streamingPull auto-reconnects on transient error', () async {
      final subscription = client.subscription('sub');
      final stream = subscription.streamingPull();

      final results = <ReceivedMessage>[];
      final sub = stream.listen(results.add);

      // Push first message
      Timer(const Duration(milliseconds: 10), () {
        fakeSubscriber.streamingPullController.add(
          generated.StreamingPullResponse()
            ..receivedMessages.add(
              generated.ReceivedMessage()
                ..message = (generated.PubsubMessage()..messageId = 'msg-1'),
            ),
        );
      });

      // Push a retryable error
      Timer(const Duration(milliseconds: 20), () {
        fakeSubscriber.streamingPullController.addError(
          const grpc.GrpcError.unavailable('Transient error'),
        );
      });

      // Push second message after reconnect
      Timer(const Duration(milliseconds: 1500), () {
        fakeSubscriber.streamingPullController.add(
          generated.StreamingPullResponse()
            ..receivedMessages.add(
              generated.ReceivedMessage()
                ..message = (generated.PubsubMessage()..messageId = 'msg-2'),
            ),
        );
      });

      // Wait enough time for reconnect and second message
      await Future<void>.delayed(const Duration(seconds: 2));

      await sub.cancel();

      expect(results.length, equals(2));
      expect(results[0].messageId, equals('msg-1'));
      expect(results[1].messageId, equals('msg-2'));
    });

    test('streamingPull maxConcurrentStreams parameter validation', () {
      final subscription = client.subscription('sub');
      expect(
        () => subscription.streamingPull(maxConcurrentStreams: 0),
        throwsArgumentError,
      );
    });

    test('streamingPull opens maxConcurrentStreams', () async {
      final subscription = client.subscription('sub');
      final sub = subscription
          .streamingPull(maxConcurrentStreams: 3)
          .listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(fakeSubscriber.streamingPullCallCount, equals(3));

      await sub.cancel();
    });
  });

  group('ReceivedMessage composition and delegation', () {
    test('properties are correctly mapped and delegated', () {
      final publishTime = DateTime.now();
      final message = Message(data: [1, 2, 3], attributes: {'key': 'value'});
      final receivedMessage = ReceivedMessage(
        ackId: 'ack-123',
        messageId: 'msg-456',
        publishTime: publishTime,
        message: message,
      );

      expect(receivedMessage.ackId, equals('ack-123'));
      expect(receivedMessage.messageId, equals('msg-456'));
      expect(receivedMessage.publishTime, equals(publishTime));
      expect(receivedMessage.message, equals(message));

      // Delegation getters
      expect(receivedMessage.data, equals([1, 2, 3]));
      expect(receivedMessage.attributes, equals({'key': 'value'}));
    });
  });
}
