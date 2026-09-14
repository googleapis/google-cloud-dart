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

import 'package:meta/meta.dart';

/// The number of bytes the base 128 varint encoding of [value] occupies.
///
/// [value] must be non-negative. Every varint is at least one byte long, and
/// each byte carries seven bits of payload.
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
