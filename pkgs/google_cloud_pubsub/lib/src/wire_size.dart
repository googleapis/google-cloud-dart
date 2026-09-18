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
/// Pub/Sub requests and messages without allocating intermediate buffers.
library;

import 'dart:convert';

import 'package:meta/meta.dart';

import 'message.dart';

/// The number of bytes the base-128 varint encoding of [value] occupies.
@internal
int varintSize(int value) {
  assert(value >= 0);
  if (value < 0) return 10;
  var size = 1;
  while (value >= 128) {
    value >>= 7;
    size++;
  }
  return size;
}

/// The number of bytes the protobuf tag of [fieldNumber] occupies.
@internal
int tagSize(int fieldNumber) => varintSize(fieldNumber << 3);

/// The number of bytes a length-delimited protobuf field occupies: its tag,
/// varint length prefix, and [payloadBytes] bytes of payload.
@internal
int lengthDelimitedSize(int fieldNumber, int payloadBytes) =>
    tagSize(fieldNumber) + varintSize(payloadBytes) + payloadBytes;

// Field numbers from `google/pubsub/v1/pubsub.proto`.
const _publishRequestMessagesField = 2;
const _pubsubMessageDataField = 1;
const _pubsubMessageAttributesField = 2;
const _mapEntryKeyField = 1;
const _mapEntryValueField = 2;

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
