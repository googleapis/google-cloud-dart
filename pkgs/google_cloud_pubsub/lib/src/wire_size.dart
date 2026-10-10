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

/// Helpers for calculating the serialized protocol buffer wire size of
/// Pub/Sub requests and messages without constructing and serializing
/// protocol buffer messages.
library;

import 'dart:convert';

import 'package:meta/meta.dart';

import 'message.dart';

/// The number of bytes the base-128 varint encoding of [value] occupies.
@internal
int varintSize(int value) {
  assert(value >= 0);
  var size = 1;
  while (value >= 128) {
    value >>= 7;
    size++;
  }
  return size;
}

/// The number of bytes the protobuf tag of [fieldNumber] occupies.
///
/// A tag is the varint `(fieldNumber << 3) | wireType`, where the low 3 bits
/// hold the wire type. The wire type never changes the varint's length, so it
/// is elided here.
@internal
int tagSize(int fieldNumber) => varintSize(fieldNumber << 3);

/// The number of bytes a length-delimited protobuf field occupies: its tag,
/// varint length prefix, and [payloadBytes] bytes of payload.
@internal
int lengthDelimitedSize(int fieldNumber, int payloadBytes) =>
    tagSize(fieldNumber) + varintSize(payloadBytes) + payloadBytes;

// Field numbers from `google/pubsub/v1/pubsub.proto`.
const _publishRequestTopicField = 1;
const _publishRequestMessagesField = 2;
const _pubsubMessageDataField = 1;
const _pubsubMessageAttributesField = 2;
const _mapEntryKeyField = 1;
const _mapEntryValueField = 2;
const _acknowledgeRequestSubscriptionField = 1;
const _acknowledgeRequestAckIdsField = 2;
const _modifyAckDeadlineRequestSubscriptionField = 1;
const _modifyAckDeadlineRequestAckDeadlineSecondsField = 3;
const _modifyAckDeadlineRequestAckIdsField = 4;

/// The number of bytes a serialized `PublishRequest` for [topic] occupies
/// before any message is added: its `topic` field.
@internal
int publishRequestBaseSize(String topic) =>
    lengthDelimitedSize(_publishRequestTopicField, utf8.encode(topic).length);

/// The exact number of bytes [message] adds to a serialized `PublishRequest`.
@internal
int publishRequestMessageSize(Message message) {
  var body = lengthDelimitedSize(_pubsubMessageDataField, message.data.length);
  for (final entry in message.attributes.entries) {
    final entrySize =
        lengthDelimitedSize(_mapEntryKeyField, utf8.encode(entry.key).length) +
        lengthDelimitedSize(
          _mapEntryValueField,
          utf8.encode(entry.value).length,
        );
    body += lengthDelimitedSize(_pubsubMessageAttributesField, entrySize);
  }
  return lengthDelimitedSize(_publishRequestMessagesField, body);
}

/// The number of bytes a serialized `AcknowledgeRequest` for [subscription]
/// occupies before any ack ID is added: its `subscription` field.
@internal
int acknowledgeRequestBaseSize(String subscription) => lengthDelimitedSize(
  _acknowledgeRequestSubscriptionField,
  utf8.encode(subscription).length,
);

/// The exact number of bytes [ackId] adds to a serialized
/// `AcknowledgeRequest`.
@internal
int acknowledgeRequestItemSize(String ackId) => lengthDelimitedSize(
  _acknowledgeRequestAckIdsField,
  utf8.encode(ackId).length,
);

/// The number of bytes a serialized `ModifyAckDeadlineRequest` for
/// [subscription] occupies before any item is added: its `subscription`
/// field plus the tag of `ackDeadlineSeconds`.
@internal
int modifyAckDeadlineRequestBaseSize(String subscription) =>
    lengthDelimitedSize(
      _modifyAckDeadlineRequestSubscriptionField,
      utf8.encode(subscription).length,
    ) +
    tagSize(_modifyAckDeadlineRequestAckDeadlineSecondsField);

/// The number of bytes an item with [ackId] and [ackDeadlineSeconds] adds to
/// a `ModifyAckDeadlineRequest` batch.
///
/// Charges the varint encoding of [ackDeadlineSeconds] on every item because
/// the deadline value is supplied per item rather than fixed when the batcher
/// is created. This is exact for a single-item `ModifyAckDeadlineRequest`
/// (with a non-zero deadline) and a conservative upper bound when multiple ack
/// IDs share a deadline.
@internal
int modifyAckDeadlineRequestItemSize(String ackId, int ackDeadlineSeconds) =>
    lengthDelimitedSize(
      _modifyAckDeadlineRequestAckIdsField,
      utf8.encode(ackId).length,
    ) +
    varintSize(ackDeadlineSeconds);
