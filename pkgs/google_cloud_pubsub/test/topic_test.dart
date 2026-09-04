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

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;
  int publishCallCount = 0;
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
      fakePublisher.publishBehavior = (req) => inFlightCompleter.future;

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
      fakePublisher.publishBehavior = (req) => inFlightCompleter.future;

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
      await topic.close();

      expect(() => topic.publish([1, 2, 3]), throwsStateError);
    });

    test('Topic._onBatch handles fewer message IDs than batch size safely '
        'without hanging or StateError', () async {
      // Backend returns only 1 message ID for 2 messages
      fakePublisher.publishBehavior = (req) async =>
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
          isA<StateError>().having(
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
        fakePublisher.publishBehavior = (req) async {
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
      'calculates message size including attribute key and value lengths',
      () async {
        // Configure maxBytes to 20.
        // data length = 4.
        // attribute 'k': 'v' length = 1 + 1 = 2.
        // Total size per message = 6.
        // 3 messages = 18 bytes (does not trigger flush).
        // 4th message = 24 bytes >= 20 bytes (triggers flush!).
        final topic = client.topic(
          'test-topic',
          publishSettings: PublishSettings(
            batching: BatchingSettings(
              maxBytes: 20,
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

        unawaited(topic.publish([1, 2, 3, 4], attributes: {'k': 'v'}));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(fakePublisher.publishCallCount, equals(1));
        expect(fakePublisher.recordedRequests[0].messages.length, equals(4));

        await topic.close();
      },
    );
  });
}
