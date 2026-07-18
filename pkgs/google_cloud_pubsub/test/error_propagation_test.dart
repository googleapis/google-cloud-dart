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

// A fake ResponseFuture that delegates to a standard Future.
class FakeResponseFuture<T> extends Fake implements grpc.ResponseFuture<T> {
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
  Future<void> cancel() => Future<void>.value();
}

// A fake ResponseStream that delegates to a standard Stream.
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

class FakeSubscriberClient extends Fake implements generated.SubscriberClient {
  final StreamController<generated.StreamingPullResponse>
  streamingPullController = StreamController();

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
    // Listen to request stream to prevent sender from hanging on close()
    unawaited(request.drain());
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
    if (acknowledgeBehavior case final acknowledge?) {
      acknowledge(request.ackIds)
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
    if (modifyAckDeadlineBehavior case final modifyAckDeadline?) {
      modifyAckDeadline(request.ackIds, request.ackDeadlineSeconds)
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
  Future<void> shutdown() async {
    // No-op for testing
  }
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

    test('streamingPull ack error propagates', () async {
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

    test('streamingPull modifyAckDeadline error propagates', () async {
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
