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

/// Checks that acknowledgment batches respect [BatchingSettings.maxBytes]
/// measured the way the server measures a request.
///
/// The publish path is covered by `topic_test.dart`. This is the other half:
/// `Acknowledge` and `ModifyAckDeadline` have a 512,000 byte limit of their
/// own, and because acknowledgments are fire-and-forget an oversized request
/// would not surface as an exception — the batch would simply fail and every
/// message in it would be redelivered.
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

/// Records the requests it is sent, so tests can measure them on the wire.
class RecordingSubscriberClient extends Fake
    implements generated.SubscriberClient {
  final List<generated.AcknowledgeRequest> acknowledgeRequests = [];
  final List<generated.ModifyAckDeadlineRequest> modifyAckDeadlineRequests = [];

  @override
  grpc.ResponseFuture<protobuf.Empty> acknowledge(
    generated.AcknowledgeRequest request, {
    grpc.CallOptions? options,
  }) {
    acknowledgeRequests.add(request);
    return FakeResponseFuture(Future.value(protobuf.Empty()));
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> modifyAckDeadline(
    generated.ModifyAckDeadlineRequest request, {
    grpc.CallOptions? options,
  }) {
    modifyAckDeadlineRequests.add(request);
    return FakeResponseFuture(Future.value(protobuf.Empty()));
  }
}

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  @override
  Future<void> shutdown() async {}
}

ReceivedMessage receivedMessage(String ackId) => ReceivedMessage(
  ackId: ackId,
  messageId: 'message-id',
  publishTime: DateTime.utc(2026),
  message: Message(data: []),
);

void main() {
  group('Subscription acknowledgment batching', () {
    late RecordingSubscriberClient fakeSubscriber;
    late PubSub client;

    setUp(() {
      fakeSubscriber = RecordingSubscriberClient();
      client = PubSub.testing(
        projectId: 'test-project',
        channel: FakeClientChannel(),
        subscriberClient: fakeSubscriber,
      );
    });

    // Ack IDs from the real service are long opaque strings; exactly 180
    // characters here, which makes the arithmetic below concrete.
    String ackId(int i) => 'ack-id-${'$i'.padLeft(6, '0')}-${'x' * 166}';

    // The subscription name costs 55 bytes on the wire, and each ack ID costs
    // 183: its 180 bytes plus a field tag and a two byte length prefix. A
    // limit of 600 therefore admits two ack IDs (55 + 366 = 421) and not three
    // (55 + 549 = 604). Counting only the raw ack IDs, as this client used to,
    // would admit three (540 <= 600) and produce a 604 byte request. The limit
    // is deliberately small so that the fixed per-request cost is a large
    // enough share of it to make that mistake visible.
    const maxBytes = 600;

    test('never sends an Acknowledge request larger than maxBytes', () async {
      final subscription = client.subscription(
        'test-subscription',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxBytes: maxBytes,
            maxMessages: 1000000,
            maxDelay: const Duration(milliseconds: 5),
          ),
        ),
      );

      for (var i = 0; i < 60; i++) {
        subscription.acknowledge(receivedMessage(ackId(i)));
      }
      await subscription.close();

      expect(
        fakeSubscriber.acknowledgeRequests,
        isNotEmpty,
        reason: 'the acknowledgments should have been flushed',
      );
      // The byte limit, not the message limit, must be what split these.
      expect(
        fakeSubscriber.acknowledgeRequests.length,
        greaterThan(1),
        reason: 'maxBytes should have forced several batches',
      );
      for (final request in fakeSubscriber.acknowledgeRequests) {
        expect(
          request.writeToBuffer().length,
          lessThanOrEqualTo(maxBytes),
          reason: 'a request exceeded maxBytes on the wire',
        );
      }
      // Nothing was dropped along the way.
      final sent = [
        for (final request in fakeSubscriber.acknowledgeRequests)
          ...request.ackIds,
      ];
      expect(sent.toSet(), {for (var i = 0; i < 60; i++) ackId(i)});
    });

    test(
      'never sends a ModifyAckDeadline request larger than maxBytes',
      () async {
        final subscription = client.subscription(
          'test-subscription',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              maxBytes: maxBytes,
              maxMessages: 1000000,
              maxDelay: const Duration(milliseconds: 5),
            ),
          ),
        );

        // A single shared deadline, so the batch is not split by deadline and
        // the byte accounting is the only thing bounding the request.
        for (var i = 0; i < 60; i++) {
          subscription.modifyAckDeadline(receivedMessage(ackId(i)), 600);
        }
        await subscription.close();

        expect(fakeSubscriber.modifyAckDeadlineRequests, isNotEmpty);
        expect(
          fakeSubscriber.modifyAckDeadlineRequests.length,
          greaterThan(1),
          reason: 'maxBytes should have forced several batches',
        );
        for (final request in fakeSubscriber.modifyAckDeadlineRequests) {
          expect(
            request.writeToBuffer().length,
            lessThanOrEqualTo(maxBytes),
            reason: 'a request exceeded maxBytes on the wire',
          );
        }
        final sent = [
          for (final request in fakeSubscriber.modifyAckDeadlineRequests)
            ...request.ackIds,
        ];
        expect(sent.toSet(), {for (var i = 0; i < 60; i++) ackId(i)});
      },
    );

    test('splitting by deadline keeps every request within maxBytes', () async {
      final subscription = client.subscription(
        'test-subscription',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxBytes: maxBytes,
            maxMessages: 1000000,
            maxDelay: const Duration(milliseconds: 5),
          ),
        ),
      );

      // Several distinct deadlines, so `_onModifyAckBatch` fans one batch out
      // into several requests. Each of those re-pays the subscription name,
      // which the batch only counted once.
      for (var i = 0; i < 60; i++) {
        subscription.modifyAckDeadline(receivedMessage(ackId(i)), 10 + i % 7);
      }
      await subscription.close();

      expect(fakeSubscriber.modifyAckDeadlineRequests, isNotEmpty);
      for (final request in fakeSubscriber.modifyAckDeadlineRequests) {
        expect(
          request.writeToBuffer().length,
          lessThanOrEqualTo(maxBytes),
          reason: 'a request exceeded maxBytes on the wire',
        );
      }
    });

    test('rejects a maxBytes above the acknowledge request limit', () {
      expect(
        () => client.subscription(
          'test-subscription',
          ackSettings: AckSettings(
            batching: BatchingSettings(
              // Fine for publishing, far above what an `Acknowledge` request
              // accepts.
              maxBytes: 8 * 1000 * 1000,
            ),
          ),
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'batching.maxBytes')
              .having((e) => e.invalidValue, 'invalidValue', 8 * 1000 * 1000),
        ),
      );
    });

    test('narrows a maxBytes that was never set', () async {
      // Setting only maxMessages must not be rejected for inheriting a default
      // byte limit that suits publishing.
      final subscription = client.subscription(
        'test-subscription',
        ackSettings: AckSettings(
          batching: BatchingSettings(
            maxMessages: 1000000,
            maxDelay: const Duration(milliseconds: 5),
          ),
        ),
      );

      // Enough ack IDs to pass 512,000 bytes were the default not narrowed.
      for (var i = 0; i < 6000; i++) {
        subscription.acknowledge(receivedMessage(ackId(i)));
      }
      await subscription.close();

      expect(fakeSubscriber.acknowledgeRequests, isNotEmpty);
      for (final request in fakeSubscriber.acknowledgeRequests) {
        expect(
          request.writeToBuffer().length,
          lessThanOrEqualTo(512 * 1000),
          reason: 'the server limit should have bounded the batch',
        );
      }
    });

    test('the default ack settings stay within the server limit', () async {
      final subscription = client.subscription('test-subscription');

      for (var i = 0; i < 6000; i++) {
        subscription.acknowledge(receivedMessage(ackId(i)));
      }
      await subscription.close();

      expect(fakeSubscriber.acknowledgeRequests, isNotEmpty);
      for (final request in fakeSubscriber.acknowledgeRequests) {
        expect(
          request.writeToBuffer().length,
          lessThanOrEqualTo(512 * 1000),
          reason: 'the default must not exceed the acknowledge request limit',
        );
      }
    });
  });
}
