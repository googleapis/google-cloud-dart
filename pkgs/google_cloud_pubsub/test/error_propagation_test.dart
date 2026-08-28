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

  @override
  grpc.ResponseFuture<generated.Subscription> createSubscription(
    generated.Subscription request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<generated.Subscription>();
    if (createSubscriptionBehavior case final createSubscription?) {
      createSubscription(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      completer.complete(request);
    }
    return FakeResponseFuture(completer.future);
  }

  Future<generated.Subscription> Function(generated.Subscription request)?
  createSubscriptionBehavior;

  @override
  grpc.ResponseFuture<protobuf.Empty> deleteSubscription(
    generated.DeleteSubscriptionRequest request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<protobuf.Empty>();
    if (deleteSubscriptionBehavior case final deleteSubscription?) {
      deleteSubscription(request)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  Future<void> Function(generated.DeleteSubscriptionRequest request)?
  deleteSubscriptionBehavior;

  @override
  grpc.ResponseFuture<generated.PullResponse> pull(
    generated.PullRequest request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<generated.PullResponse>();
    if (pullBehavior case final pull?) {
      pull(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      completer.complete(generated.PullResponse());
    }
    return FakeResponseFuture(completer.future);
  }

  Future<generated.PullResponse> Function(generated.PullRequest request)?
  pullBehavior;
}

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.Topic> Function(generated.Topic request)?
  createTopicBehavior;
  Future<void> Function(generated.DeleteTopicRequest request)?
  deleteTopicBehavior;
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;

  @override
  grpc.ResponseFuture<generated.Topic> createTopic(
    generated.Topic request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<generated.Topic>();
    if (createTopicBehavior case final createTopic?) {
      createTopic(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      completer.complete(request);
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> deleteTopic(
    generated.DeleteTopicRequest request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<protobuf.Empty>();
    if (deleteTopicBehavior case final deleteTopic?) {
      deleteTopic(request)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<generated.PublishResponse> publish(
    generated.PublishRequest request, {
    grpc.CallOptions? options,
  }) {
    final completer = Completer<generated.PublishResponse>();
    if (publishBehavior case final publish?) {
      publish(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      completer.complete(generated.PublishResponse()..messageIds.add('msg-1'));
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
    late FakePublisherClient fakePublisher;
    late PubSub client;

    setUp(() {
      fakeSubscriber = FakeSubscriberClient();
      fakePublisher = FakePublisherClient();
      client = PubSub.testing(
        projectId: 'test-project',
        channel: FakeClientChannel(),
        subscriberClient: fakeSubscriber,
        publisherClient: fakePublisher,
      );
    });

    tearDown(() async {
      await client.close();
    });

    test('createTopic error propagates as ConflictException', () async {
      fakePublisher.createTopicBehavior = (request) async {
        throw const grpc.GrpcError.alreadyExists('Topic already exists');
      };

      await expectLater(
        client.createTopic('projects/test-project/topics/top'),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'Topic already exists',
          ),
        ),
      );
    });

    test('deleteTopic error propagates as NotFoundException', () async {
      fakePublisher.deleteTopicBehavior = (request) async {
        throw const grpc.GrpcError.notFound('Topic not found');
      };

      await expectLater(
        client.deleteTopic('projects/test-project/topics/top'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Topic not found',
          ),
        ),
      );
    });

    test('publish error propagates as NotFoundException', () async {
      fakePublisher.publishBehavior = (request) async {
        throw const grpc.GrpcError.notFound('Topic not found');
      };

      await expectLater(
        client.publish('projects/test-project/topics/top', [1, 2, 3]),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Topic not found',
          ),
        ),
      );
    });

    test('createSubscription error propagates as ConflictException', () async {
      fakeSubscriber.createSubscriptionBehavior = (request) async {
        throw const grpc.GrpcError.alreadyExists('Sub already exists');
      };

      await expectLater(
        client.createSubscription(
          'projects/test-project/subscriptions/sub',
          topic: 'projects/test-project/topics/top',
        ),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            'Sub already exists',
          ),
        ),
      );
    });

    test('deleteSubscription error propagates as NotFoundException', () async {
      fakeSubscriber.deleteSubscriptionBehavior = (request) async {
        throw const grpc.GrpcError.notFound('Sub not found');
      };

      await expectLater(
        client.deleteSubscription('projects/test-project/subscriptions/sub'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Sub not found',
          ),
        ),
      );
    });

    test('pull error propagates as NotFoundException', () async {
      fakeSubscriber.pullBehavior = (request) async {
        throw const grpc.GrpcError.notFound('Sub not found');
      };

      await expectLater(
        client.pull('projects/test-project/subscriptions/sub'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Sub not found',
          ),
        ),
      );
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
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Subscription not found',
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
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            'Subscription not found',
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

    test(
      'gRPC status codes map to canonical ServiceException subclasses',
      () async {
        final mappings = <int, Type>{
          grpc.StatusCode.invalidArgument: BadRequestException,
          grpc.StatusCode.unauthenticated: UnauthorizedException,
          grpc.StatusCode.permissionDenied: ForbiddenException,
          grpc.StatusCode.notFound: NotFoundException,
          grpc.StatusCode.alreadyExists: ConflictException,
          grpc.StatusCode.aborted: ConflictException,
          grpc.StatusCode.failedPrecondition: PreconditionFailedException,
          grpc.StatusCode.outOfRange: RequestRangeNotSatisfiableException,
          grpc.StatusCode.resourceExhausted: TooManyRequestsException,
          grpc.StatusCode.cancelled: CancelledException,
          grpc.StatusCode.deadlineExceeded: GatewayTimeoutException,
          grpc.StatusCode.internal: InternalServerErrorException,
          grpc.StatusCode.unimplemented: NotImplementedException,
          grpc.StatusCode.unavailable: ServiceUnavailableException,
          grpc.StatusCode.dataLoss: InternalServerErrorException,
          grpc.StatusCode.unknown: InternalServerErrorException,
        };

        for (final entry in mappings.entries) {
          fakePublisher.deleteTopicBehavior = (request) async {
            throw grpc.GrpcError.custom(
              entry.key,
              'Test error for code ${entry.key}',
            );
          };

          try {
            await client.deleteTopic('projects/test-project/topics/top');
            fail('Should have thrown');
          } on ServiceException catch (e) {
            expect(
              e.runtimeType,
              equals(entry.value),
              reason: 'StatusCode ${entry.key} should map to ${entry.value}',
            );
            expect(e.message, equals('Test error for code ${entry.key}'));
          }
        }
      },
    );

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
                ..message = (pb.PubsubMessage()..messageId = 'msg-1'),
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
                ..message = (pb.PubsubMessage()..messageId = 'msg-2'),
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
