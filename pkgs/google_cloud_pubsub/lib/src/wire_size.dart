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

/// Helpers for predicting how many bytes a value occupies once it has been
/// encoded in the protocol buffer wire format.
///
/// Pub/Sub enforces its request size limits against the *serialized* request,
/// so batching has to measure the same thing the server does. Serializing a
/// message just to measure it would be wasteful — these sizes are needed for
/// every message added to a batch — and `package:protobuf` exposes no cached
/// size, only `writeToBuffer`, which allocates and encodes the whole message.
/// The sizes are therefore computed arithmetically from the lengths of the
/// values involved.
///
/// See the [protocol buffer encoding reference](https://protobuf.dev/programming-guides/encoding/).
library;

import 'dart:convert';

import 'package:meta/meta.dart';

import 'message.dart';

/// The number of bytes the base 128 varint encoding of [value] occupies.
///
/// Every varint is at least one byte long, and each byte carries seven bits of
/// payload.
///
/// [value] is expected to be non-negative. A negative value is sign extended
/// to 64 bits by `package:protobuf` and always occupies ten bytes; returning
/// that rather than tripping only an assert keeps a release build
/// over-estimating instead of under-estimating, which is the safe direction
/// for a size limit.
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

/// The number of bytes the tag of [fieldNumber] occupies.
///
/// A tag is a varint holding the field number shifted left by the three bits
/// that carry the wire type.
@internal
int tagSize(int fieldNumber) => varintSize(fieldNumber << 3);

/// The number of bytes a length-delimited field occupies in full: its tag, the
/// varint length prefix, and [payloadBytes] bytes of payload.
///
/// Length-delimited is the wire type used for `string`, `bytes`, embedded
/// messages, and packed repeated fields.
@internal
int lengthDelimitedSize(int fieldNumber, int payloadBytes) =>
    tagSize(fieldNumber) + varintSize(payloadBytes) + payloadBytes;

// Field numbers from `google/pubsub/v1/pubsub.proto`.
const _publishRequestMessagesField = 2;
const _pubsubMessageDataField = 1;
const _pubsubMessageAttributesField = 2;

// Protobuf encodes a map entry as a submessage with the key in field 1 and the
// value in field 2.
const _mapEntryKeyField = 1;
const _mapEntryValueField = 2;

/// The number of bytes [message] adds to a serialized `PublishRequest`.
///
/// This is the exact contribution of one entry of the repeated `messages`
/// field: the entry's own tag and length prefix, plus the encoding of the
/// `PubsubMessage` itself.
///
/// Two details are easy to get wrong here, and both are covered by
/// `test/wire_size_test.dart`:
///
/// - `data` is written even when empty, because `PubSub.publishMessages`
///   always assigns it. An empty `bytes` field still costs its tag and a zero
///   length prefix.
/// - A map entry always writes both its key and its value, so an attribute
///   with an empty key or value is not free.
///
/// `messageId`, `publishTime` and `orderingKey` are never set on the publish
/// path, so they contribute nothing.
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
