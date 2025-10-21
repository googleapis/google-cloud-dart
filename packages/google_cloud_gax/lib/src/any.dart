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

import 'proto.dart';

/// `Any` contains an arbitrary serialized message along with a URL that
/// describes the type of the serialized message.
// This class logically belongs in `package:google_cloud_protobuf` but is here
// because it is used by the `Status` class and we don't want to have circular
// dependencies between `package:google_cloud_gax` and
// `package:google_cloud_protobuf`.
class Any extends ProtoMessage {
  static const String fullyQualifiedName = 'google.protobuf.Any';

  // This list needs to be kept in sync with generator/internal/dart/dart.go.
  static const Set<String> _customEncodedTypes = {
    'google.protobuf.BoolValue',
    'google.protobuf.BytesValue',
    'google.protobuf.DoubleValue',
    'google.protobuf.Duration',
    'google.protobuf.FieldMask',
    'google.protobuf.FloatValue',
    'google.protobuf.Int32Value',
    'google.protobuf.Int64Value',
    'google.protobuf.ListValue',
    'google.protobuf.StringValue',
    'google.protobuf.Struct',
    'google.protobuf.Timestamp',
    'google.protobuf.UInt32Value',
    'google.protobuf.UInt64Value',
    'google.protobuf.Value',
  };

  /// The raw JSON encoding of the underlying value.
  final Map<String, dynamic> json;

  Any({Map<String, dynamic>? json})
    : json = json ?? {},
      super(fullyQualifiedName);

  /// Create an [Any] from an existing [message].
  Any.from(ProtoMessage message) : json = {}, super(fullyQualifiedName) {
    packInto(message);
  }

  factory Any.fromJson(Map<String, dynamic> json) => Any(json: json);

  /// '@type' will be something like
  /// `type.googleapis.com/google.protobuf.Duration`, or
  /// `type.googleapis.com/google.rpc.ErrorInfo`.
  String get _type => json['@type'] as String;

  /// Return the fully qualified name of the contained type.
  ///
  /// For example, `google.protobuf.Duration`, or `google.rpc.ErrorInfo`.
  String get typeName {
    const prefix = 'type.googleapis.com/';

    final type = _type;

    // Only extract the type name if we recognize the prefix.
    if (type.startsWith(prefix)) {
      return type.substring(prefix.length);
    } else {
      return type;
    }
  }

  /// Returns whether the type represented by this `Any` is the same as [name].
  ///
  /// [name] should be a fully qualified type name, for example,
  /// `google.protobuf.Duration` or `google.rpc.ErrorInfo`.
  bool isType(String name) => typeName == name;

  /// Deserialize a message from this `Any` object.
  ///
  /// For most message types, you should pass the `<type>.fromJson` constructor
  /// into this method. Eg.:
  ///
  /// ```dart
  /// if (any.isType(Status.fullyQualifiedName)) {
  ///   final status = any.unpackFrom(Status.fromJson);
  ///   ...
  /// }
  /// ```
  T unpackFrom<T extends ProtoMessage, S>(T Function(S) decoder) {
    final name = typeName;

    if (_customEncodedTypes.contains(name)) {
      // Handle custom types:
      //   { "@type": "type.googl...obuf.Duration", "value": "1.212s" }
      return decoder(json['value'] as S);
    } else {
      return decoder(json as S);
    }
  }

  /// Serialize the given message into this `Any` instance.
  void packInto(ProtoMessage message) {
    final qualifiedName = message.qualifiedName;

    // @type
    json['@type'] = 'type.googleapis.com/$qualifiedName';

    // values
    final encoded = message.toJson();
    if (_customEncodedTypes.contains(qualifiedName)) {
      json['value'] = encoded;
    } else {
      for (final key in (encoded as Map<String, dynamic>).keys) {
        json[key] = encoded[key];
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => json;

  @override
  String toString() => 'Any($typeName)';
}
