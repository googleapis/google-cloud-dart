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

/// Pins the predicted protobuf sizes to what `package:protobuf` actually
/// encodes.
///
/// Batching compares its running total against the Pub/Sub server's request
/// size limits, and the server measures the serialized request. If these
/// predictions drift from reality, batches silently become either oversized
/// (rejected outright by the server, failing every message in the batch) or
/// needlessly small.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as grpc;
import 'package:google_cloud_pubsub/src/wire_size.dart';
import 'package:test/test.dart';

/// Field numbers from `google/pubsub/v1/pubsub.proto`.
const publishRequestTopicField = 1;
const acknowledgeRequestSubscriptionField = 1;
const acknowledgeRequestAckIdsField = 2;
const modifyAckDeadlineRequestSubscriptionField = 1;
const modifyAckDeadlineRequestSecondsField = 3;
const modifyAckDeadlineRequestAckIdsField = 4;

/// The size the production code predicts for one published message.
///
/// This calls the real [publishRequestMessageSize] rather than a copy of it,
/// so that a change to the prediction that is not also a change to the wire
/// format fails these tests.
int predictedMessageSize(List<int> data, Map<String, String> attributes) =>
    publishRequestMessageSize(
      Message(data: Uint8List.fromList(data), attributes: attributes),
    );

int actualMessageSize(List<int> data, Map<String, String> attributes) {
  final message = grpc.PubsubMessage()..data = Uint8List.fromList(data);
  if (attributes.isNotEmpty) message.attributes.addAll(attributes);
  return (grpc.PublishRequest()..messages.add(message)).writeToBuffer().length;
}

void main() {
  group('varintSize', () {
    test('matches the base 128 encoding boundaries', () {
      expect(varintSize(0), 1);
      expect(varintSize(1), 1);
      expect(varintSize(127), 1);
      expect(varintSize(128), 2);
      expect(varintSize(16383), 2);
      expect(varintSize(16384), 3);
      expect(varintSize(2097151), 3);
      expect(varintSize(2097152), 4);
      expect(varintSize(268435455), 4);
      expect(varintSize(268435456), 5);
    });
  });

  group('tagSize', () {
    test('is one byte for field numbers below 16', () {
      expect(tagSize(1), 1);
      expect(tagSize(15), 1);
      expect(tagSize(16), 2);
    });
  });

  group('predicted message size', () {
    test('matches protobuf across payload length boundaries', () {
      // Lengths that straddle every varint width boundary, so a wrong length
      // prefix cannot hide.
      for (final length in [
        0,
        1,
        2,
        126,
        127,
        128,
        129,
        16382,
        16383,
        16384,
        16385,
      ]) {
        final data = List<int>.filled(length, 0);
        expect(
          predictedMessageSize(data, const {}),
          actualMessageSize(data, const {}),
          reason: 'payload of $length bytes',
        );
      }
    });

    test('counts an empty payload, which is still written', () {
      // `PubSub.publishMessages` always assigns `data`, so an empty payload
      // costs a tag and a zero length prefix rather than nothing at all.
      expect(
        predictedMessageSize(const [], const {}),
        actualMessageSize(const [], const {}),
      );
      expect(predictedMessageSize(const [], const {}), greaterThan(0));
    });

    test('counts empty attribute keys and values, which are still written', () {
      // A protobuf map entry always writes both fields.
      const attributes = {'': ''};
      expect(
        predictedMessageSize(const [], attributes),
        actualMessageSize(const [], attributes),
      );
      expect(
        predictedMessageSize(const [], attributes),
        greaterThan(predictedMessageSize(const [], const {})),
      );
    });

    test('matches protobuf for multi-byte UTF-8 attributes', () {
      const attributes = {'kéy': 'välué', 'emoji': '😀😀😀'};
      expect(
        predictedMessageSize(const [1, 2, 3], attributes),
        actualMessageSize(const [1, 2, 3], attributes),
      );
    });

    test('matches protobuf for attributes long enough to need a two byte '
        'length prefix', () {
      final attributes = {'k' * 200: 'v' * 300};
      expect(
        predictedMessageSize(const [], attributes),
        actualMessageSize(const [], attributes),
      );
    });

    test('matches protobuf across 2000 random messages', () {
      final random = Random(20260914);
      for (var i = 0; i < 2000; i++) {
        final data = List<int>.filled(random.nextInt(5000), 0);
        final attributes = <String, String>{};
        for (var a = 0; a < random.nextInt(6); a++) {
          attributes['k' * random.nextInt(300)] = 'v' * random.nextInt(300);
        }
        expect(
          predictedMessageSize(data, attributes),
          actualMessageSize(data, attributes),
          reason: 'data=${data.length} attributes=${attributes.length}',
        );
      }
    });
  });

  group('predicted request size', () {
    test('base size plus item sizes equals the serialized request', () {
      const topic = 'projects/example-project/topics/example-topic';
      final random = Random(7);
      final messages = <grpc.PubsubMessage>[];
      var predicted = lengthDelimitedSize(
        publishRequestTopicField,
        utf8.encode(topic).length,
      );

      for (var i = 0; i < 200; i++) {
        final data = List<int>.filled(random.nextInt(3000), 0);
        final attributes = {'index': '$i'};
        messages.add(
          grpc.PubsubMessage()
            ..data = Uint8List.fromList(data)
            ..attributes.addAll(attributes),
        );
        predicted += predictedMessageSize(data, attributes);
      }

      final actual =
          (grpc.PublishRequest()
                ..topic = topic
                ..messages.addAll(messages))
              .writeToBuffer()
              .length;

      expect(predicted, actual);
    });

    test('ack id size matches a serialized AcknowledgeRequest', () {
      const subscription =
          'projects/example-project/subscriptions/example-subscription';
      final ackIds = [for (var i = 0; i < 50; i++) 'ack-id-${'x' * i}-$i'];

      var predicted = lengthDelimitedSize(
        acknowledgeRequestSubscriptionField,
        utf8.encode(subscription).length,
      );
      for (final ackId in ackIds) {
        predicted += lengthDelimitedSize(
          acknowledgeRequestAckIdsField,
          ackId.length,
        );
      }

      final actual =
          (grpc.AcknowledgeRequest()
                ..subscription = subscription
                ..ackIds.addAll(ackIds))
              .writeToBuffer()
              .length;

      expect(predicted, actual);
    });

    test('modack size covers a serialized ModifyAckDeadlineRequest', () {
      const subscription =
          'projects/example-project/subscriptions/example-subscription';

      // Mirrors how `Subscription._initBatchers` sizes the modack batcher: the
      // subscription plus the shared deadline's tag up front, then each ack ID
      // charged for its own deadline varint.
      int predict(List<String> ackIds, int deadline) {
        var size =
            lengthDelimitedSize(
              modifyAckDeadlineRequestSubscriptionField,
              utf8.encode(subscription).length,
            ) +
            tagSize(modifyAckDeadlineRequestSecondsField);
        for (final ackId in ackIds) {
          size +=
              lengthDelimitedSize(
                modifyAckDeadlineRequestAckIdsField,
                ackId.length,
              ) +
              varintSize(deadline);
        }
        return size;
      }

      int actual(List<String> ackIds, int deadline) =>
          (grpc.ModifyAckDeadlineRequest()
                ..subscription = subscription
                ..ackDeadlineSeconds = deadline
                ..ackIds.addAll(ackIds))
              .writeToBuffer()
              .length;

      // A unary request carries one shared deadline, so the prediction is an
      // over-estimate that grows with the number of ack IDs — but it must
      // never be an under-estimate, including for a single ack ID, which is
      // the tightest case.
      for (final deadline in [0, 10, 600, 65536]) {
        for (final count in [1, 2, 3, 50]) {
          final ackIds = [for (var i = 0; i < count; i++) 'ack-id-$i'];
          expect(
            predict(ackIds, deadline),
            greaterThanOrEqualTo(actual(ackIds, deadline)),
            reason: 'count: $count, deadline: $deadline',
          );
        }
      }

      // For one ack ID the prediction is exact: the shared deadline and the
      // per-ack-ID deadline are the same single value.
      expect(predict(['ack-id-0'], 600), actual(['ack-id-0'], 600));
    });
  });
}
