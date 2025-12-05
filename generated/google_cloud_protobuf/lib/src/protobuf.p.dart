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

// ignore_for_file: avoid_classes_with_only_static_members

part of '../protobuf.dart';

/// An abstract class that can return a JSON representation of itself.
///
/// Classes that implement [JsonEncodable] will often have a `fromJson()`
/// constructor.
abstract class JsonEncodable {
  Object? toJson();
}

/// The abstract common superclass of all messages.
abstract class ProtoMessage implements JsonEncodable {
  /// The fully qualified name of this message, i.e., `google.protobuf.Duration`
  /// or `google.rpc.ErrorInfo`.
  final String qualifiedName;

  ProtoMessage(this.qualifiedName);
}

/// The abstract common superclass of all enum values.
abstract class ProtoEnum implements JsonEncodable {
  final String value;

  const ProtoEnum(this.value);

  @override
  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is ProtoEnum &&
      other.runtimeType == runtimeType &&
      value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// `Any` contains an arbitrary serialized message along with a URL that
/// describes the type of the serialized message.
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

  Any({required this.json}) : super(fullyQualifiedName);

  /// Create an [Any] from an existing [message].
  Any.from(ProtoMessage message) : json = {}, super(fullyQualifiedName) {
    packInto(message);
  }

  factory Any.fromJson(Object? json) => Any(json: json as Map<String, dynamic>);

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
      for (final key in (encoded as Map).cast<String, dynamic>().keys) {
        json[key] = encoded[key];
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => json;

  @override
  String toString() => 'Any($typeName)';
}

/// `Value` represents a dynamically typed value which can be either
/// null, a number, a string, a boolean, a recursive struct value, or a
/// list of values. A producer of value is expected to set one of these
/// variants. Absence of any variant indicates an error.
///
/// The JSON representation for `Value` is JSON value.
class Value extends ProtoMessage {
  static const String fullyQualifiedName = 'google.protobuf.Value';

  /// Represents a null value.
  final NullValue? nullValue;

  /// Represents a double value.
  final double? numberValue;

  /// Represents a string value.
  final String? stringValue;

  /// Represents a boolean value.
  final bool? boolValue;

  /// Represents a structured value.
  final Struct? structValue;

  /// Represents a repeated `Value`.
  final ListValue? listValue;

  Value({
    this.nullValue,
    this.numberValue,
    this.stringValue,
    this.boolValue,
    this.structValue,
    this.listValue,
  }) : super(fullyQualifiedName);

  factory Value.fromJson(Object? json) {
    switch (json) {
      case null:
        return Value(nullValue: NullValue.nullValue);
      case double d:
        return Value(numberValue: d);
      case int i:
        return Value(numberValue: i.toDouble());
      case String s:
        return Value(stringValue: s);
      case bool b:
        return Value(boolValue: b);
      case List<dynamic> l:
        return Value(listValue: ListValue.fromJson(l));
      case Map<dynamic, dynamic> m:
        return Value(structValue: Struct.fromJson(m));
      default:
        return Value(nullValue: NullValue.nullValue);
    }
  }

  @override
  Object? toJson() =>
      numberValue ??
      stringValue ??
      boolValue ??
      listValue?.toJson() ??
      structValue?.toJson();

  @override
  String toString() {
    final contents = [
      if (nullValue != null) 'nullValue=$nullValue',
      if (numberValue != null) 'numberValue=$numberValue',
      if (stringValue != null) 'stringValue=$stringValue',
      if (boolValue != null) 'boolValue=$boolValue',
    ].join(',');
    return 'Value($contents)';
  }
}

/// Called from the Duration constructor to validate the construction
/// parameters.
extension DurationExtension on Duration {
  void _validate() {
    // For durations of one second or more, a non-zero value for the `nanos`
    // field must be of the same sign as the `seconds` field.
    if ((seconds < 0 && nanos > 0) || (seconds > 0 && nanos < 0)) {
      throw ArgumentError('seconds and nanos must have the same sign');
    }

    // Nanos must be from -999,999,999 to +999,999,999 inclusive.
    if (nanos < -999_999_999 || nanos > 999_999_999) {
      throw ArgumentError('nanos out of range');
    }
  }
}

class _DurationHelper {
  /// Encode into a decimal representation of the seconds and nanos, suffixed
  /// with 's'.
  ///
  /// E.g., 3 seconds with 0 nanoseconds would be '3s'; 3 seconds with 70
  /// nanosecond would be '3.00000007s'.
  static String encode(Duration duration) {
    if (duration.nanos == 0) {
      return '${duration.seconds}s';
    } else {
      final rhs = duration.nanos.abs().toString().padLeft(9, '0');

      var result = duration.seconds == 0
          ? '${duration.nanos < 0 ? '-' : ''}0.$rhs'
          : '${duration.seconds}.$rhs';
      while (result.endsWith('0')) {
        result = result.substring(0, result.length - 1);
      }

      return '${result}s';
    }
  }

  /// Decode a string representation of the duration.
  ///
  /// This is a decimal value suffixed with 's'. 3 seconds with 0 nanoseconds
  /// would be '3s'; 3 seconds with 70 nanosecond would be '3.00000007s'.
  static Duration decode(Object? format) {
    if (!(format as String).endsWith('s')) {
      throw const FormatException("duration value should end in 's'");
    }

    // '-123.456s'
    format = format.substring(0, format.length - 1);
    final negative = format.startsWith('-');

    final parts = format.split('.');
    if (parts.length > 2) {
      throw const FormatException('too many periods');
    }

    final seconds = int.parse(parts[0]);
    if (parts.length == 1) {
      return Duration(seconds: seconds, nanos: 0);
    }

    final nanos = int.parse(parts[1].padRight(9, '0'));
    return Duration(seconds: seconds, nanos: negative ? -nanos : nanos);
  }
}

class _FieldMaskHelper {
  /// Encode the field mask as a single comma-separated string.
  static String encode(FieldMask fieldMask) => fieldMask.paths.join(',');

  /// Decode the field mask from a single comma-separated string.
  static FieldMask decode(Object? format) =>
      FieldMask(paths: (format as String).split(','));
}

/// Called from the Timestamp constructor to validate construction parameters.
extension TimestampExtension on Timestamp {
  /// The minimum value for [seconds]; corresponds to `'0001-01-01T00:00:00Z'`.
  static const int minSeconds = -62135596800;

  /// The maximum value for [seconds]; corresponds to `'9999-12-31T23:59:59Z'`.
  static const int maxSeconds = 253402300799;

  void _validate() {
    if (seconds < minSeconds || seconds > maxSeconds) {
      throw ArgumentError('seconds out of range');
    }
    if (nanos < 0 || nanos >= 1_000_000_000) {
      throw ArgumentError('nanos out of range');
    }
  }
}

class _TimestampHelper {
  static final RegExp _rfc3339 = RegExp(
    //
    r'^(\d{4})-' // year
    r'(\d{2})-' // month
    r'(\d{2})T' // day
    r'(\d{2}):' // hour
    r'(\d{2}):' // minute
    r'(\d{2})' // second
    r'(\.\d+)?' // fractional seconds
    r'Z?', // timezone
  );

  /// Encode the timestamp in RFC3339/UTC format.
  static String encode(Timestamp timestamp) {
    final nanos = timestamp.nanos;

    // 0:0 is 1970-01-01T00:00:00Z.
    final dateTime = DateTime.utc(1970, 1, 1, 0, 0, timestamp.seconds, 0, 0);

    String two(int value) => value.toString().padLeft(2, '0');

    final year = dateTime.year.toString().padLeft(4, '0');
    final month = two(dateTime.month);
    final day = two(dateTime.day);
    final hour = two(dateTime.hour);
    final minute = two(dateTime.minute);
    final second = two(dateTime.second);

    String nanosStr;
    if (nanos == 0) {
      nanosStr = '';
    } else {
      nanosStr = '.${nanos.toString().padLeft(9, '0')}';

      while (nanosStr.endsWith('000')) {
        nanosStr = nanosStr.substring(0, nanosStr.length - 3);
      }
    }

    // construct "2017-01-15T01:30:15.01Z"
    return '$year-$month-${day}T$hour:$minute:$second${nanosStr}Z';
  }

  /// Decode the timestamp from a RFC3339/UTC format string.
  static Timestamp decode(Object? value) {
    // DateTime will throw a FormatException on parse issues.
    final dateTime = DateTime.parse(value as String);
    final seconds = dateTime.millisecondsSinceEpoch ~/ 1_000;

    // Parse nanos separately as DateTime only has microseconds resolution.
    var nanos = 0;
    final match = _rfc3339.firstMatch(value)!;
    final fractionalSeconds = match.group(7);
    if (fractionalSeconds != null) {
      nanos = int.parse(fractionalSeconds.substring(1).padRight(9, '0'));
    }

    // If seconds is negative adjust for a positive nanos value.
    return Timestamp(
      seconds: seconds < 0 && nanos > 0 ? seconds - 1 : seconds,
      nanos: nanos,
    );
  }
}

class _DoubleValueHelper {
  static Object encode(DoubleValue value) => encodeDouble(value.value)!;

  static DoubleValue decode(Object? value) =>
      DoubleValue(value: decodeDouble(value));
}

class _FloatValueHelper {
  static Object encode(FloatValue value) => encodeDouble(value.value)!;

  static FloatValue decode(Object? value) =>
      FloatValue(value: decodeDouble(value));
}

class _Int64ValueHelper {
  static String encode(Int64Value value) => encodeInt64(value.value)!;

  static Int64Value decode(Object? value) =>
      Int64Value(value: decodeInt64(value));
}

class _Uint64ValueHelper {
  static String encode(Uint64Value value) => encodeUint64(value.value)!;

  static Uint64Value decode(Object? value) =>
      Uint64Value(value: decodeUint64(value));
}

class _Int32ValueHelper {
  static int encode(Int32Value value) => value.value;

  static Int32Value decode(Object? value) => Int32Value(value: value as int);
}

class _Uint32ValueHelper {
  static int encode(Uint32Value value) => value.value;

  static Uint32Value decode(Object? value) => Uint32Value(value: value as int);
}

class _BoolValueHelper {
  static bool encode(BoolValue value) => value.value;

  static BoolValue decode(Object? value) => BoolValue(value: value as bool);
}

class _StringValueHelper {
  static String encode(StringValue value) => value.value;

  static StringValue decode(Object? value) =>
      StringValue(value: value as String);
}

class _BytesValueHelper {
  static String encode(BytesValue value) => encodeBytes(value.value)!;

  static BytesValue decode(Object? value) =>
      BytesValue(value: decodeBytes(value as String));
}

class _StructHelper {
  static Map<String, Object?> encode(Struct value) =>
      value.fields.map((key, value) => MapEntry(key, value.toJson()));

  static Struct decode(Object? value) {
    final fields = (value as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, Value.fromJson(value)),
    );
    return Struct(fields: fields);
  }
}

class _ListValueHelper {
  static List<Object?> encode(ListValue value) =>
      value.values.map((v) => v.toJson()).toList();

  static ListValue decode(Object? value) {
    final values = (value as List).map(Value.fromJson).toList();
    return ListValue(values: values);
  }
}
