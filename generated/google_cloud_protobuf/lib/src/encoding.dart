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

/// Utility methods for JSON encoding and decoding.
///
/// See https://protobuf.dev/programming-guides/json/ for docs on the JSON
/// encoding of many of these types.
///
/// Must be kept in sync with
/// [`dart/annotate.go`](https://github.com/googleapis/librarian/blob/main/internal/sidekick/dart/annotate.go).
library;

import 'dart:convert';
import 'dart:typed_data';

import '../protobuf.dart';

export 'dart:typed_data' show Uint8List;

/// Decodes: `BOOL_TYPE`.
bool decodeBool(Object? value) => value as bool;

/// Decodes: `BYTES_TYPE`.
Uint8List decodeBytes(Object? value) => base64Decode(value as String);

/// Decodes: `FLOAT_TYPE`, `DOUBLE_TYPE`.
double decodeDouble(Object? value) {
  if (value is String) {
    if (value == 'NaN' || value == 'Infinity' || value == '-Infinity') {
      return double.parse(value);
    } else {
      throw const FormatException(
        'String value is not NaN, Infinity, or -Infinity',
      );
    }
  } else {
    return (value as num).toDouble();
  }
}

/// Decodes: `INT32_TYPE`, `FIXED32_TYPE`, `SFIXED32_TYPE`, `SINT32_TYPE`,
/// `UINT32_TYPE`.
int decodeInt(Object? value) => value as int;

/// Decodes: `INT64_TYPE`, `SINT64_TYPE`, `SFIXED64_TYPE`.
int decodeInt64(Object? value) =>
    value is String ? int.parse(value) : value as int;

/// Decodes: `STRING_TYPE`.
String decodeString(Object? value) => value as String;

/// Decodes: `FIXED64_TYPE`, `UINT64_TYPE`.
BigInt decodeUint64(Object? value) =>
    value is String ? BigInt.parse(value) : BigInt.from(value as int);

/// Encode an `int64` value into JSON.
String? encodeInt64(int? value) => value == null ? null : '$value';

String? encodeUint64(BigInt? value) => value == null ? null : '$value';

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

/// Extensions methods used for comparing to proto default values.
extension BigIntProtoDefault on BigInt {
  bool get isNotDefault => this != BigInt.zero;
}

/// Extensions methods used for comparing to proto default values.
extension BoolProtoDefault on bool {
  /// Whether this is the proto default value for [bool] (`false`).
  bool get isNotDefault => this != false;
}

/// Extensions methods used for comparing to proto default values.
extension IntProtoDefault on int {
  /// Whether this is the proto default value for [int] (`0`).
  bool get isNotDefault => this != 0;
}

/// Extensions methods used for comparing to proto default values.
extension DoubleProtoDefault on double {
  /// Whether this is the proto default value for [double] (`0`).
  bool get isNotDefault => this != 0;
}

/// Extensions methods used for comparing to proto default values.
extension StringProtoDefault on String {
  /// Whether this is the proto default value for [String] (an empty string).
  bool get isNotDefault => isNotEmpty;
}

/// Extensions methods used for comparing to proto default values.
extension ListProtoDefault on List<dynamic> {
  /// Whether this is the proto default value for [List] (an empty list).
  bool get isNotDefault => isNotEmpty;
}

/// Extensions methods used for comparing to proto default values.
extension MapProtoDefault on Map<dynamic, dynamic> {
  /// Whether this is the proto default value for [Map] (an empty map).
  bool get isNotDefault => isNotEmpty;
}

extension Uint8ListDefault on Uint8List {
  bool get isNotDefault => isNotEmpty;
}
