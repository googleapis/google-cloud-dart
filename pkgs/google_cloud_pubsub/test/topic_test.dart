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
import 'dart:typed_data';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pbgrpc.dart'
    as generated;
import 'package:grpc/grpc.dart' as grpc;
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

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;
  int publishCallCount = 0;
  bool get publishCalled => publishCallCount > 0;
  final List<generated.PublishRequest> recordedRequests = [];

  @override
  grpc.ResponseFuture<generated.PublishResponse> publish(
    generated.PublishRequest request, {
    grpc.CallOptions? options,
  }) {
    publishCallCount++;
    recordedRequests.add(request);
    final completer = Completer<generated.PublishResponse>();
    if (publishBehavior case final behavior?) {
      behavior(
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

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {}
}

void main() {
  group('Topic', () {
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

    test('close flushes pending messages and awaits in-flight batch', () async {
      final inFlightCompleter = Completer<generated.PublishResponse>();
      fakePublisher.publishBehavior = (request) => inFlightCompleter.future;

      final topic = client.topic(
        'test-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final publishFuture = topic.publish([1, 2, 3]);

      var closeCompleted = false;
      final closeFuture = topic.close().then((_) {
        closeCompleted = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(closeCompleted, isFalse);
      expect(fakePublisher.publishCallCount, equals(1));

      inFlightCompleter.complete(
        generated.PublishResponse()..messageIds.add('id-1'),
      );

      final publishedId = await publishFuture;
      expect(publishedId, equals('id-1'));

      await closeFuture;
      expect(closeCompleted, isTrue);
    });

    test('multiple concurrent calls to close() await same future', () async {
      final inFlightCompleter = Completer<generated.PublishResponse>();
      fakePublisher.publishBehavior = (request) => inFlightCompleter.future;

      final topic = client.topic(
        'test-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      unawaited(topic.publish([1]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      var close1Done = false;
      var close2Done = false;
      final c1 = topic.close().then((_) => close1Done = true);
      final c2 = topic.close().then((_) => close2Done = true);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(close1Done, isFalse);
      expect(close2Done, isFalse);

      inFlightCompleter.complete(
        generated.PublishResponse()..messageIds.add('id-1'),
      );

      await Future.wait([c1, c2]);
      expect(close1Done, isTrue);
      expect(close2Done, isTrue);
    });

    test('publish after close throws StateError', () async {
      final topic = client.topic('test-topic');
      expect(topic.isClosed, isFalse);
      await topic.close();
      expect(topic.isClosed, isTrue);

      expect(() => topic.publish([1, 2, 3]), throwsStateError);
    });

    test('Topic._onBatch handles fewer message IDs than batch size safely '
        'without hanging', () async {
      // Backend returns only 1 message ID for 2 messages
      fakePublisher.publishBehavior = (request) async =>
          generated.PublishResponse()..messageIds.add('only-one-id');

      final topic = client.topic(
        'test-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxMessages: 2,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final fut1 = topic.publish([1]);
      final fut2 = topic.publish([2]);

      expect(await fut1, equals('only-one-id'));

      await expectLater(
        fut2,
        throwsA(
          isA<InternalServerErrorException>().having(
            (e) => e.message,
            'message',
            contains(
              'Server returned fewer message IDs (1) '
              'than published messages (2)',
            ),
          ),
        ),
      );

      await topic.close();
    });

    test(
      'Topic._onBatch completes all completers on backend failure',
      () async {
        fakePublisher.publishBehavior = (request) async {
          throw const grpc.GrpcError.notFound('Topic does not exist');
        };

        final topic = client.topic(
          'test-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxMessages: 2,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final fut1 = topic.publish([1]);
        final fut2 = topic.publish([2]);

        await expectLater(fut1, throwsA(isA<NotFoundException>()));
        await expectLater(fut2, throwsA(isA<NotFoundException>()));

        await topic.close();
      },
    );

    test(
      'batches on the serialized size of the request, attributes included',
      () async {
        // The thresholds come from what protobuf actually produces, so this
        // test pins the batcher to real serialized sizes rather than to
        // hand-computed arithmetic that can drift away from the encoding.
        int serializedSize(int messageCount) {
          final request = generated.PublishRequest()
            ..topic = 'projects/test-project/topics/test-topic';
          for (var i = 0; i < messageCount; i++) {
            request.messages.add(
              generated.PubsubMessage()
                ..data = Uint8List.fromList([1, 2, 3, 4])
                ..attributes.addAll({'k': 'v'}),
            );
          }
          return request.writeToBuffer().length;
        }

        // Room for exactly three messages, but not for a fourth.
        final maxBytes = serializedSize(4) - 1;
        expect(serializedSize(3), lessThan(maxBytes));

        final topic = client.topic(
          'test-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxBytes: maxBytes,
              maxMessages: 100,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        unawaited(topic.publish([1, 2, 3, 4], attributes: {'k': 'v'}));
        unawaited(topic.publish([1, 2, 3, 4], attributes: {'k': 'v'}));
        unawaited(topic.publish([1, 2, 3, 4], attributes: {'k': 'v'}));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakePublisher.publishCallCount, equals(0));

        // The fourth message would take the request past maxBytes, so the
        // three buffered messages are flushed first.
        unawaited(topic.publish([1, 2, 3, 4], attributes: {'k': 'v'}));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakePublisher.publishCallCount, equals(1));
        expect(fakePublisher.recordedRequests[0].messages.length, equals(3));

        await topic.close();
        expect(fakePublisher.publishCallCount, equals(2));
        expect(fakePublisher.recordedRequests[1].messages.length, equals(1));

        // The point of all of the above: what actually went on the wire fits.
        for (final request in fakePublisher.recordedRequests) {
          expect(request.writeToBuffer().length, lessThanOrEqualTo(maxBytes));
        }
      },
    );

    test('never sends a request larger than maxBytes, even for many small '
        'messages carrying attributes', () async {
      // Small messages with several attributes are the worst case for
      // framing overhead: the tags and length prefixes are a large fraction
      // of the total. Counting only payload and attribute bytes used to
      // overshoot here by around 20%, which the server rejects outright.
      const maxBytes = 50000;
      final topic = client.topic(
        'test-topic',
        publishSettings: PublishSettings(
          batching: BatchingSettings(
            maxBytes: maxBytes,
            // The most Pub/Sub allows, so that maxBytes is what binds.
            maxMessages: 1000,
            maxDelay: const Duration(seconds: 10),
          ),
        ),
      );

      final published = <Future<String>>[];
      for (var i = 0; i < 4000; i++) {
        published.add(
          topic.publish(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            attributes: {
              'attribute-key-0': 'attribute-value-0',
              'attribute-key-1': 'attribute-value-1',
              'attribute-key-2': 'attribute-value-2',
              'attribute-key-3': 'attribute-value-3',
              'attribute-key-4': 'attribute-value-4',
            },
          ),
        );
      }
      await topic.close();
      await Future.wait(published);

      expect(fakePublisher.recordedRequests, isNotEmpty);
      for (final request in fakePublisher.recordedRequests) {
        expect(request.writeToBuffer().length, lessThanOrEqualTo(maxBytes));
      }
      // Sanity check that the batches are not trivially small, which would
      // make the assertion above vacuous.
      expect(
        fakePublisher.recordedRequests.first.messages.length,
        greaterThan(100),
      );
    });

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

    test('close awaits in-flight batch and completes cleanly when in-flight '
        'batch fails', () async {
      final inFlightCompleter = Completer<generated.PublishResponse>();
      fakePublisher.publishBehavior = (request) => inFlightCompleter.future;

      final topic = client.topic(
        'test-topic',
        publishSettings: PublishSettings(retry: RetrySettings(maxRetries: 0)),
      );
      final publishFuture = topic.publish([1, 2, 3]);

      final closeFuture = topic.close();
      inFlightCompleter.completeError(
        const grpc.GrpcError.unavailable('Server down'),
      );

      await expectLater(
        publishFuture,
        throwsA(isA<ServiceUnavailableException>()),
      );
      await expectLater(closeFuture, completes);
    });

    test('PubSub.publish throws InternalServerErrorException if server returns '
        'empty list', () async {
      fakePublisher.publishBehavior = (request) async =>
          generated.PublishResponse();
      await expectLater(
        client.publish('projects/test-project/topics/my-topic', [1, 2]),
        throwsA(
          isA<InternalServerErrorException>().having(
            (e) => e.message,
            'message',
            contains('Server returned no message ID'),
          ),
        ),
      );
    });

    test(
      'Topic batching calculates multi-byte UTF-8 attribute byte size',
      () async {
        // '🎉' is 4 bytes in UTF-8 but 2 code units in UTF-16. Measuring it as
        // 2 would make each message two bytes smaller, the second message
        // would still appear to fit, and no flush would happen.
        int serializedSize(int messageCount) {
          final request = generated.PublishRequest()
            ..topic = 'projects/test-project/topics/test-topic';
          for (var i = 0; i < messageCount; i++) {
            request.messages.add(
              generated.PubsubMessage()
                ..data = Uint8List.fromList([1])
                ..attributes.addAll({'k': '🎉'}),
            );
          }
          return request.writeToBuffer().length;
        }

        // Room for exactly one message, but not for a second.
        final maxBytes = serializedSize(2) - 1;
        expect(serializedSize(1), lessThan(maxBytes));

        final topic = client.topic(
          'test-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxBytes: maxBytes,
              maxDelay: const Duration(seconds: 10),
            ),
          ),
        );

        final f1 = topic.publish([1], attributes: {'k': '🎉'});
        await Future<void>.delayed(Duration.zero);
        expect(fakePublisher.publishCalled, isFalse);

        // The second message no longer fits, so the first one is flushed.
        final f2 = topic.publish([2], attributes: {'k': '🎉'});
        await Future<void>.delayed(Duration.zero);
        expect(fakePublisher.publishCalled, isTrue);

        await topic.close();
        await f1;
        await f2;
      },
    );
  });

  group('Message and ReceivedMessage toString', () {
    test('Message toString returns informative string', () {
      final message = Message(data: [1, 2, 3], attributes: {'env': 'test'});
      expect(
        message.toString(),
        equals('Message(data: 3 bytes, attributes: {env: test})'),
      );
    });

    test('ReceivedMessage toString returns informative string', () {
      final now = DateTime.now();
      final rMsg = ReceivedMessage(
        ackId: 'ack-123',
        messageId: 'msg-456',
        publishTime: now,
        deliveryAttempt: 3,
        message: Message(data: [1, 2], attributes: {'a': 'b'}),
      );
      expect(
        rMsg.toString(),
        equals(
          'ReceivedMessage('
          'messageId: msg-456, '
          'ackId: ack-123, '
          'publishTime: $now, '
          'deliveryAttempt: 3, '
          'message: Message(data: 2 bytes, attributes: {a: b}))',
        ),
      );
    });
  });
}
