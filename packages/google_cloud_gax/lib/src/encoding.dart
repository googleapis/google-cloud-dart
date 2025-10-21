// Copyright 2025 Google LLC
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

/// Utility methods for JSON encoding and decoding from [ProtoMessage] objects.
///
/// See https://protobuf.dev/programming-guides/json/ for docs on the JSON
/// encoding of many of these types.
library;

import 'dart:convert';

import '../gax.dart';

/// Decode an `int64` value.
int? decodeInt64(Object? value) =>
    value is String ? int.parse(value) : value as int?;

/// Decode a `double` value.
double? decodeDouble(Object? value) {
  if (value is String) {
    if (value == 'NaN' || value == 'Infinity' || value == '-Infinity') {
      return double.parse(value);
    } else {
      throw const FormatException(
        'String value is not NaN, Infinity, or -Infinity',
      );
    }
  } else {
    return (value as num?)?.toDouble();
  }
}

/// Decode a `bytes` value.
Uint8List? decodeBytes(String? value) =>
    value == null ? null : base64Decode(value);

/// Decode an [ProtoEnum].
T? decodeEnum<T extends ProtoEnum>(String? value, T Function(String) decoder) =>
    value == null ? null : decoder(value);

/// Decode a [ProtoMessage].
T? decode<T extends ProtoMessage>(
  Map<String, dynamic>? value,
  T Function(Map<String, dynamic>) decoder,
) => value != null ? decoder(value) : null;

/// Decode a [ProtoMessage] which uses a custom JSON encoding.
T? decodeCustom<T extends ProtoMessage>(
  Object? value,
  T Function(Object) decoder,
) => value == null ? null : decoder(value);

/// Decode a list of primitives types.
List<T>? decodeList<T>(Object? value) => (value as List?)?.cast();

/// Decode a list of `bytes`.
List<Uint8List>? decodeListBytes(Object? value) =>
    (value as List?)?.cast<String>().map(base64Decode).toList();

/// Decode a list of [ProtoEnum]s.
List<T>? decodeListEnum<T extends ProtoEnum>(
  Object? value,
  T Function(String) decoder,
) => (value as List?)?.map((item) => decoder(item as String)).toList();

/// Decode a list of [ProtoMessage]s.
List<T>? decodeListMessage<T extends ProtoMessage>(
  Object? value,
  T Function(Map<String, dynamic>) decoder,
) => (value as List?)
    ?.cast<Map<String, dynamic>>()
    .map((item) => decoder(item))
    .toList();

/// Decode a list of [ProtoMessage]s which use custom JSON encodings.
List<T>? decodeListMessageCustom<T extends ProtoMessage>(
  Object? value,
  T Function(Object) decoder,
) => (value as List?)?.map((item) => decoder(item as Object)).toList();

/// Decode a map of primitives types.
Map<K, V>? decodeMap<K, V>(Object? value) => (value as Map?)?.cast();

/// Decode a map of [ProtoEnum]s.
Map<K, V>? decodeMapEnum<K, V extends ProtoEnum>(
  Object? value,
  V Function(String) decoder,
) => (value as Map?)
    ?.map((key, value) => MapEntry(key, decoder(value as String)))
    .cast();

/// Decode a map of `bytes`.
Map<K, Uint8List>? decodeMapBytes<K>(Object? value) => (value as Map?)
    ?.map((key, value) => MapEntry(key, base64Decode(value as String)))
    .cast();

/// Decode a map of [ProtoMessage]s.
Map<K, V>? decodeMapMessage<K, V extends ProtoMessage>(
  Object? value,
  V Function(Map<String, dynamic>) decoder,
) => (value as Map?)
    ?.map((key, value) => MapEntry(key, decoder(value as Map<String, dynamic>)))
    .cast();

/// Decode a map of [ProtoMessage]s which use custom JSON encodings.
Map<K, V>? decodeMapMessageCustom<K, V extends ProtoMessage>(
  Object? value,
  V Function(Object) decoder,
) => (value as Map?)
    ?.map((key, value) => MapEntry(key, decoder(value as Object)))
    .cast();

/// Encode an `int64` value into JSON.
String? encodeInt64(int? value) => value == null ? null : '$value';

/// Encode 'float` and `double` values into JSON.
Object? encodeDouble(double? value) {
  if (value == null) {
    return null;
  }

  return value.isNaN || value.isInfinite ? '$value' : value;
}

/// Encode a `bytes` value into JSON.
String? encodeBytes(Uint8List? value) =>
    value == null ? null : base64Encode(value);

/// Encode a list of [JsonEncodable] values into JSON.
List<Object?>? encodeList(List<JsonEncodable>? value) =>
    value?.map((item) => item.toJson()).toList();

/// Encode a list of `bytes` into JSON.
List<Object?>? encodeListBytes(List<Uint8List>? value) =>
    value?.map(base64Encode).toList();

/// Encode a map of [JsonEncodable] values into JSON.
Map<T, Object?>? encodeMap<T>(Map<T, JsonEncodable>? value) =>
    value?.map((key, value) => MapEntry(key, value.toJson()));

/// Encode a list of `bytes` values into JSON.
Map<T, String>? encodeMapBytes<T>(Map<T, Uint8List>? value) =>
    value?.map((key, value) => MapEntry(key, base64Encode(value)));
