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

import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as grpc;
import 'package:google_cloud_pubsub/src/wire_size.dart';
import 'package:test/test.dart';

/// Field numbers from `google/pubsub/v1/pubsub.proto`.
const publishRequestTopicField = 1;
const publishRequestMessagesField = 2;
const pubsubMessageDataField = 1;
const pubsubMessageAttributesField = 2;
const mapEntryKeyField = 1;
const mapEntryValueField = 2;
const acknowledgeRequestSubscriptionField = 1;
const acknowledgeRequestAckIdsField = 2;

/// Mirrors `Topic._publishedMessageSize`.
int predictedMessageSize(List<int> data, Map<String, String> attributes) {
  var body = lengthDelimitedSize(pubsubMessageDataField, data.length);
  for (final entry in attributes.entries) {
    final entrySize =
        lengthDelimitedSize(mapEntryKeyField, utf8.encode(entry.key).length) +
        lengthDelimitedSize(
          mapEntryValueField,
          utf8.encode(entry.value).length,
        );
    body += lengthDelimitedSize(pubsubMessageAttributesField, entrySize);
  }
  return lengthDelimitedSize(publishRequestMessagesField, body);
}

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
  });
}
