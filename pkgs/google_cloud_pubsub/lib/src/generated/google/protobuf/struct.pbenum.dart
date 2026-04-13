//
//  Generated code. Do not modify.
//  source: google/protobuf/struct.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Represents a JSON `null`.
///
/// `NullValue` is a sentinel, using an enum with only one value to represent
/// the null value for the `Value` type union.
///
/// A field of type `NullValue` with any value other than `0` is considered
/// invalid. Most ProtoJSON serializers will emit a Value with a `null_value` set
/// as a JSON `null` regardless of the integer value, and so will round trip to
/// a `0` value.
class NullValue extends $pb.ProtobufEnum {
  /// Null value.
  static const NullValue NULL_VALUE =
      NullValue._(0, _omitEnumNames ? '' : 'NULL_VALUE');

  static const $core.List<NullValue> values = <NullValue>[
    NULL_VALUE,
  ];

  static final $core.List<NullValue?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static NullValue? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NullValue._(super.v, super.n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
