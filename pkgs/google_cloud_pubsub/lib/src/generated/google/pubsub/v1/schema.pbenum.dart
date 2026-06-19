// This is a generated file - do not edit.
//
// Generated from google/pubsub/v1/schema.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// View of Schema object fields to be returned by GetSchema and ListSchemas.
class SchemaView extends $pb.ProtobufEnum {
  /// The default / unset value.
  /// The API will default to the BASIC view.
  static const SchemaView SCHEMA_VIEW_UNSPECIFIED =
      SchemaView._(0, _omitEnumNames ? '' : 'SCHEMA_VIEW_UNSPECIFIED');

  /// Include the name and type of the schema, but not the definition.
  static const SchemaView BASIC =
      SchemaView._(1, _omitEnumNames ? '' : 'BASIC');

  /// Include all Schema object fields.
  static const SchemaView FULL = SchemaView._(2, _omitEnumNames ? '' : 'FULL');

  static const $core.List<SchemaView> values = <SchemaView>[
    SCHEMA_VIEW_UNSPECIFIED,
    BASIC,
    FULL,
  ];

  static final $core.List<SchemaView?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static SchemaView? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SchemaView._(super.value, super.name);
}

/// Possible encoding types for messages.
class Encoding extends $pb.ProtobufEnum {
  /// Unspecified
  static const Encoding ENCODING_UNSPECIFIED =
      Encoding._(0, _omitEnumNames ? '' : 'ENCODING_UNSPECIFIED');

  /// JSON encoding
  static const Encoding JSON = Encoding._(1, _omitEnumNames ? '' : 'JSON');

  /// Binary encoding, as defined by the schema type. For some schema types,
  /// binary encoding may not be available.
  static const Encoding BINARY = Encoding._(2, _omitEnumNames ? '' : 'BINARY');

  static const $core.List<Encoding> values = <Encoding>[
    ENCODING_UNSPECIFIED,
    JSON,
    BINARY,
  ];

  static final $core.List<Encoding?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Encoding? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Encoding._(super.value, super.name);
}

/// Possible schema definition types.
class Schema_Type extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const Schema_Type TYPE_UNSPECIFIED =
      Schema_Type._(0, _omitEnumNames ? '' : 'TYPE_UNSPECIFIED');

  /// A Protocol Buffer schema definition.
  static const Schema_Type PROTOCOL_BUFFER =
      Schema_Type._(1, _omitEnumNames ? '' : 'PROTOCOL_BUFFER');

  /// An Avro schema definition.
  static const Schema_Type AVRO =
      Schema_Type._(2, _omitEnumNames ? '' : 'AVRO');

  static const $core.List<Schema_Type> values = <Schema_Type>[
    TYPE_UNSPECIFIED,
    PROTOCOL_BUFFER,
    AVRO,
  ];

  static final $core.List<Schema_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Schema_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Schema_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
