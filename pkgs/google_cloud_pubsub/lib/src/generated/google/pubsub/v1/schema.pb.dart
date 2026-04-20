// This is a generated file - do not edit.
//
// Generated from google/pubsub/v1/schema.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../protobuf/timestamp.pb.dart' as $2;
import 'schema.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'schema.pbenum.dart';

/// A schema resource.
class Schema extends $pb.GeneratedMessage {
  factory Schema({
    $core.String? name,
    Schema_Type? type,
    $core.String? definition,
    $core.String? revisionId,
    $2.Timestamp? revisionCreateTime,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (definition != null) result.definition = definition;
    if (revisionId != null) result.revisionId = revisionId;
    if (revisionCreateTime != null)
      result.revisionCreateTime = revisionCreateTime;
    return result;
  }

  Schema._();

  factory Schema.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Schema.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Schema',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<Schema_Type>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: Schema_Type.TYPE_UNSPECIFIED,
        valueOf: Schema_Type.valueOf,
        enumValues: Schema_Type.values)
    ..aOS(3, _omitFieldNames ? '' : 'definition')
    ..aOS(4, _omitFieldNames ? '' : 'revisionId')
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'revisionCreateTime',
        subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Schema clone() => Schema()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Schema copyWith(void Function(Schema) updates) =>
      super.copyWith((message) => updates(message as Schema)) as Schema;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Schema create() => Schema._();
  @$core.override
  Schema createEmptyInstance() => create();
  static $pb.PbList<Schema> createRepeated() => $pb.PbList<Schema>();
  @$core.pragma('dart2js:noInline')
  static Schema getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Schema>(create);
  static Schema? _defaultInstance;

  /// Required. Name of the schema.
  /// Format is `projects/{project}/schemas/{schema}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// The type of the schema definition.
  @$pb.TagNumber(2)
  Schema_Type get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(Schema_Type value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// The definition of the schema. This should contain a string representing
  /// the full definition of the schema that is a valid schema definition of
  /// the type specified in `type`.
  @$pb.TagNumber(3)
  $core.String get definition => $_getSZ(2);
  @$pb.TagNumber(3)
  set definition($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDefinition() => $_has(2);
  @$pb.TagNumber(3)
  void clearDefinition() => $_clearField(3);

  /// Output only. Immutable. The revision ID of the schema.
  @$pb.TagNumber(4)
  $core.String get revisionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set revisionId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRevisionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRevisionId() => $_clearField(4);

  /// Output only. The timestamp that the revision was created.
  @$pb.TagNumber(6)
  $2.Timestamp get revisionCreateTime => $_getN(4);
  @$pb.TagNumber(6)
  set revisionCreateTime($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRevisionCreateTime() => $_has(4);
  @$pb.TagNumber(6)
  void clearRevisionCreateTime() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureRevisionCreateTime() => $_ensure(4);
}

/// Request for the CreateSchema method.
class CreateSchemaRequest extends $pb.GeneratedMessage {
  factory CreateSchemaRequest({
    $core.String? parent,
    Schema? schema,
    $core.String? schemaId,
  }) {
    final result = create();
    if (parent != null) result.parent = parent;
    if (schema != null) result.schema = schema;
    if (schemaId != null) result.schemaId = schemaId;
    return result;
  }

  CreateSchemaRequest._();

  factory CreateSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parent')
    ..aOM<Schema>(2, _omitFieldNames ? '' : 'schema', subBuilder: Schema.create)
    ..aOS(3, _omitFieldNames ? '' : 'schemaId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSchemaRequest clone() => CreateSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSchemaRequest copyWith(void Function(CreateSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSchemaRequest))
          as CreateSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSchemaRequest create() => CreateSchemaRequest._();
  @$core.override
  CreateSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<CreateSchemaRequest> createRepeated() =>
      $pb.PbList<CreateSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSchemaRequest>(create);
  static CreateSchemaRequest? _defaultInstance;

  /// Required. The name of the project in which to create the schema.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get parent => $_getSZ(0);
  @$pb.TagNumber(1)
  set parent($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => $_clearField(1);

  /// Required. The schema object to create.
  ///
  /// This schema's `name` parameter is ignored. The schema object returned
  /// by CreateSchema will have a `name` made using the given `parent` and
  /// `schema_id`.
  @$pb.TagNumber(2)
  Schema get schema => $_getN(1);
  @$pb.TagNumber(2)
  set schema(Schema value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchema() => $_clearField(2);
  @$pb.TagNumber(2)
  Schema ensureSchema() => $_ensure(1);

  /// The ID to use for the schema, which will become the final component of
  /// the schema's resource name.
  ///
  /// See https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names for
  /// resource name constraints.
  @$pb.TagNumber(3)
  $core.String get schemaId => $_getSZ(2);
  @$pb.TagNumber(3)
  set schemaId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSchemaId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchemaId() => $_clearField(3);
}

/// Request for the GetSchema method.
class GetSchemaRequest extends $pb.GeneratedMessage {
  factory GetSchemaRequest({
    $core.String? name,
    SchemaView? view,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (view != null) result.view = view;
    return result;
  }

  GetSchemaRequest._();

  factory GetSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<SchemaView>(2, _omitFieldNames ? '' : 'view', $pb.PbFieldType.OE,
        defaultOrMaker: SchemaView.SCHEMA_VIEW_UNSPECIFIED,
        valueOf: SchemaView.valueOf,
        enumValues: SchemaView.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaRequest clone() => GetSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSchemaRequest copyWith(void Function(GetSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as GetSchemaRequest))
          as GetSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSchemaRequest create() => GetSchemaRequest._();
  @$core.override
  GetSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<GetSchemaRequest> createRepeated() =>
      $pb.PbList<GetSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSchemaRequest>(create);
  static GetSchemaRequest? _defaultInstance;

  /// Required. The name of the schema to get.
  /// Format is `projects/{project}/schemas/{schema}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// The set of fields to return in the response. If not set, returns a Schema
  /// with all fields filled out. Set to `BASIC` to omit the `definition`.
  @$pb.TagNumber(2)
  SchemaView get view => $_getN(1);
  @$pb.TagNumber(2)
  set view(SchemaView value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasView() => $_has(1);
  @$pb.TagNumber(2)
  void clearView() => $_clearField(2);
}

/// Request for the `ListSchemas` method.
class ListSchemasRequest extends $pb.GeneratedMessage {
  factory ListSchemasRequest({
    $core.String? parent,
    SchemaView? view,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (parent != null) result.parent = parent;
    if (view != null) result.view = view;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListSchemasRequest._();

  factory ListSchemasRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemasRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemasRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parent')
    ..e<SchemaView>(2, _omitFieldNames ? '' : 'view', $pb.PbFieldType.OE,
        defaultOrMaker: SchemaView.SCHEMA_VIEW_UNSPECIFIED,
        valueOf: SchemaView.valueOf,
        enumValues: SchemaView.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasRequest clone() => ListSchemasRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasRequest copyWith(void Function(ListSchemasRequest) updates) =>
      super.copyWith((message) => updates(message as ListSchemasRequest))
          as ListSchemasRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemasRequest create() => ListSchemasRequest._();
  @$core.override
  ListSchemasRequest createEmptyInstance() => create();
  static $pb.PbList<ListSchemasRequest> createRepeated() =>
      $pb.PbList<ListSchemasRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSchemasRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemasRequest>(create);
  static ListSchemasRequest? _defaultInstance;

  /// Required. The name of the project in which to list schemas.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get parent => $_getSZ(0);
  @$pb.TagNumber(1)
  set parent($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => $_clearField(1);

  /// The set of Schema fields to return in the response. If not set, returns
  /// Schemas with `name` and `type`, but not `definition`. Set to `FULL` to
  /// retrieve all fields.
  @$pb.TagNumber(2)
  SchemaView get view => $_getN(1);
  @$pb.TagNumber(2)
  set view(SchemaView value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasView() => $_has(1);
  @$pb.TagNumber(2)
  void clearView() => $_clearField(2);

  /// Maximum number of schemas to return.
  @$pb.TagNumber(3)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set pageSize($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageSize() => $_clearField(3);

  /// The value returned by the last `ListSchemasResponse`; indicates that
  /// this is a continuation of a prior `ListSchemas` call, and that the
  /// system should return the next page of data.
  @$pb.TagNumber(4)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set pageToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageToken() => $_clearField(4);
}

/// Response for the `ListSchemas` method.
class ListSchemasResponse extends $pb.GeneratedMessage {
  factory ListSchemasResponse({
    $core.Iterable<Schema>? schemas,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (schemas != null) result.schemas.addAll(schemas);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListSchemasResponse._();

  factory ListSchemasResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemasResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemasResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<Schema>(1, _omitFieldNames ? '' : 'schemas', $pb.PbFieldType.PM,
        subBuilder: Schema.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasResponse clone() => ListSchemasResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemasResponse copyWith(void Function(ListSchemasResponse) updates) =>
      super.copyWith((message) => updates(message as ListSchemasResponse))
          as ListSchemasResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemasResponse create() => ListSchemasResponse._();
  @$core.override
  ListSchemasResponse createEmptyInstance() => create();
  static $pb.PbList<ListSchemasResponse> createRepeated() =>
      $pb.PbList<ListSchemasResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSchemasResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemasResponse>(create);
  static ListSchemasResponse? _defaultInstance;

  /// The resulting schemas.
  @$pb.TagNumber(1)
  $pb.PbList<Schema> get schemas => $_getList(0);

  /// If not empty, indicates that there may be more schemas that match the
  /// request; this value should be passed in a new `ListSchemasRequest`.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the `ListSchemaRevisions` method.
class ListSchemaRevisionsRequest extends $pb.GeneratedMessage {
  factory ListSchemaRevisionsRequest({
    $core.String? name,
    SchemaView? view,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (view != null) result.view = view;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListSchemaRevisionsRequest._();

  factory ListSchemaRevisionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemaRevisionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemaRevisionsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<SchemaView>(2, _omitFieldNames ? '' : 'view', $pb.PbFieldType.OE,
        defaultOrMaker: SchemaView.SCHEMA_VIEW_UNSPECIFIED,
        valueOf: SchemaView.valueOf,
        enumValues: SchemaView.values)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemaRevisionsRequest clone() =>
      ListSchemaRevisionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemaRevisionsRequest copyWith(
          void Function(ListSchemaRevisionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListSchemaRevisionsRequest))
          as ListSchemaRevisionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemaRevisionsRequest create() => ListSchemaRevisionsRequest._();
  @$core.override
  ListSchemaRevisionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListSchemaRevisionsRequest> createRepeated() =>
      $pb.PbList<ListSchemaRevisionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSchemaRevisionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemaRevisionsRequest>(create);
  static ListSchemaRevisionsRequest? _defaultInstance;

  /// Required. The name of the schema to list revisions for.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// The set of Schema fields to return in the response. If not set, returns
  /// Schemas with `name` and `type`, but not `definition`. Set to `FULL` to
  /// retrieve all fields.
  @$pb.TagNumber(2)
  SchemaView get view => $_getN(1);
  @$pb.TagNumber(2)
  set view(SchemaView value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasView() => $_has(1);
  @$pb.TagNumber(2)
  void clearView() => $_clearField(2);

  /// The maximum number of revisions to return per page.
  @$pb.TagNumber(3)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set pageSize($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageSize() => $_clearField(3);

  /// The page token, received from a previous ListSchemaRevisions call.
  /// Provide this to retrieve the subsequent page.
  @$pb.TagNumber(4)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set pageToken($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageToken() => $_clearField(4);
}

/// Response for the `ListSchemaRevisions` method.
class ListSchemaRevisionsResponse extends $pb.GeneratedMessage {
  factory ListSchemaRevisionsResponse({
    $core.Iterable<Schema>? schemas,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (schemas != null) result.schemas.addAll(schemas);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListSchemaRevisionsResponse._();

  factory ListSchemaRevisionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSchemaRevisionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSchemaRevisionsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<Schema>(1, _omitFieldNames ? '' : 'schemas', $pb.PbFieldType.PM,
        subBuilder: Schema.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemaRevisionsResponse clone() =>
      ListSchemaRevisionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSchemaRevisionsResponse copyWith(
          void Function(ListSchemaRevisionsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListSchemaRevisionsResponse))
          as ListSchemaRevisionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSchemaRevisionsResponse create() =>
      ListSchemaRevisionsResponse._();
  @$core.override
  ListSchemaRevisionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListSchemaRevisionsResponse> createRepeated() =>
      $pb.PbList<ListSchemaRevisionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSchemaRevisionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSchemaRevisionsResponse>(create);
  static ListSchemaRevisionsResponse? _defaultInstance;

  /// The revisions of the schema.
  @$pb.TagNumber(1)
  $pb.PbList<Schema> get schemas => $_getList(0);

  /// A token that can be sent as `page_token` to retrieve the next page.
  /// If this field is empty, there are no subsequent pages.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for CommitSchema method.
class CommitSchemaRequest extends $pb.GeneratedMessage {
  factory CommitSchemaRequest({
    $core.String? name,
    Schema? schema,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (schema != null) result.schema = schema;
    return result;
  }

  CommitSchemaRequest._();

  factory CommitSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CommitSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommitSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<Schema>(2, _omitFieldNames ? '' : 'schema', subBuilder: Schema.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommitSchemaRequest clone() => CommitSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CommitSchemaRequest copyWith(void Function(CommitSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as CommitSchemaRequest))
          as CommitSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitSchemaRequest create() => CommitSchemaRequest._();
  @$core.override
  CommitSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<CommitSchemaRequest> createRepeated() =>
      $pb.PbList<CommitSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static CommitSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommitSchemaRequest>(create);
  static CommitSchemaRequest? _defaultInstance;

  /// Required. The name of the schema we are revising.
  /// Format is `projects/{project}/schemas/{schema}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Required. The schema revision to commit.
  @$pb.TagNumber(2)
  Schema get schema => $_getN(1);
  @$pb.TagNumber(2)
  set schema(Schema value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchema() => $_clearField(2);
  @$pb.TagNumber(2)
  Schema ensureSchema() => $_ensure(1);
}

/// Request for the `RollbackSchema` method.
class RollbackSchemaRequest extends $pb.GeneratedMessage {
  factory RollbackSchemaRequest({
    $core.String? name,
    $core.String? revisionId,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (revisionId != null) result.revisionId = revisionId;
    return result;
  }

  RollbackSchemaRequest._();

  factory RollbackSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RollbackSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RollbackSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'revisionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RollbackSchemaRequest clone() =>
      RollbackSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RollbackSchemaRequest copyWith(
          void Function(RollbackSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as RollbackSchemaRequest))
          as RollbackSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RollbackSchemaRequest create() => RollbackSchemaRequest._();
  @$core.override
  RollbackSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<RollbackSchemaRequest> createRepeated() =>
      $pb.PbList<RollbackSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static RollbackSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RollbackSchemaRequest>(create);
  static RollbackSchemaRequest? _defaultInstance;

  /// Required. The schema being rolled back with revision id.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Required. The revision ID to roll back to.
  /// It must be a revision of the same schema.
  ///
  ///   Example: c7cfa2a8
  @$pb.TagNumber(2)
  $core.String get revisionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set revisionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRevisionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRevisionId() => $_clearField(2);
}

/// Request for the `DeleteSchemaRevision` method.
class DeleteSchemaRevisionRequest extends $pb.GeneratedMessage {
  factory DeleteSchemaRevisionRequest({
    $core.String? name,
    @$core.Deprecated('This field is deprecated.') $core.String? revisionId,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (revisionId != null) result.revisionId = revisionId;
    return result;
  }

  DeleteSchemaRevisionRequest._();

  factory DeleteSchemaRevisionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSchemaRevisionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSchemaRevisionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'revisionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSchemaRevisionRequest clone() =>
      DeleteSchemaRevisionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSchemaRevisionRequest copyWith(
          void Function(DeleteSchemaRevisionRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteSchemaRevisionRequest))
          as DeleteSchemaRevisionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSchemaRevisionRequest create() =>
      DeleteSchemaRevisionRequest._();
  @$core.override
  DeleteSchemaRevisionRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSchemaRevisionRequest> createRepeated() =>
      $pb.PbList<DeleteSchemaRevisionRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSchemaRevisionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSchemaRevisionRequest>(create);
  static DeleteSchemaRevisionRequest? _defaultInstance;

  /// Required. The name of the schema revision to be deleted, with a revision ID
  /// explicitly included.
  ///
  /// Example: `projects/123/schemas/my-schema@c7cfa2a8`
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Optional. This field is deprecated and should not be used for specifying
  /// the revision ID. The revision ID should be specified via the `name`
  /// parameter.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.String get revisionId => $_getSZ(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  set revisionId($core.String value) => $_setString(1, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool hasRevisionId() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  void clearRevisionId() => $_clearField(2);
}

/// Request for the `DeleteSchema` method.
class DeleteSchemaRequest extends $pb.GeneratedMessage {
  factory DeleteSchemaRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  DeleteSchemaRequest._();

  factory DeleteSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSchemaRequest clone() => DeleteSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSchemaRequest copyWith(void Function(DeleteSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSchemaRequest))
          as DeleteSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSchemaRequest create() => DeleteSchemaRequest._();
  @$core.override
  DeleteSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSchemaRequest> createRepeated() =>
      $pb.PbList<DeleteSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSchemaRequest>(create);
  static DeleteSchemaRequest? _defaultInstance;

  /// Required. Name of the schema to delete.
  /// Format is `projects/{project}/schemas/{schema}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

/// Request for the `ValidateSchema` method.
class ValidateSchemaRequest extends $pb.GeneratedMessage {
  factory ValidateSchemaRequest({
    $core.String? parent,
    Schema? schema,
  }) {
    final result = create();
    if (parent != null) result.parent = parent;
    if (schema != null) result.schema = schema;
    return result;
  }

  ValidateSchemaRequest._();

  factory ValidateSchemaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateSchemaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateSchemaRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parent')
    ..aOM<Schema>(2, _omitFieldNames ? '' : 'schema', subBuilder: Schema.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSchemaRequest clone() =>
      ValidateSchemaRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSchemaRequest copyWith(
          void Function(ValidateSchemaRequest) updates) =>
      super.copyWith((message) => updates(message as ValidateSchemaRequest))
          as ValidateSchemaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateSchemaRequest create() => ValidateSchemaRequest._();
  @$core.override
  ValidateSchemaRequest createEmptyInstance() => create();
  static $pb.PbList<ValidateSchemaRequest> createRepeated() =>
      $pb.PbList<ValidateSchemaRequest>();
  @$core.pragma('dart2js:noInline')
  static ValidateSchemaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateSchemaRequest>(create);
  static ValidateSchemaRequest? _defaultInstance;

  /// Required. The name of the project in which to validate schemas.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get parent => $_getSZ(0);
  @$pb.TagNumber(1)
  set parent($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => $_clearField(1);

  /// Required. The schema object to validate.
  @$pb.TagNumber(2)
  Schema get schema => $_getN(1);
  @$pb.TagNumber(2)
  set schema(Schema value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearSchema() => $_clearField(2);
  @$pb.TagNumber(2)
  Schema ensureSchema() => $_ensure(1);
}

/// Response for the `ValidateSchema` method.
/// Empty for now.
class ValidateSchemaResponse extends $pb.GeneratedMessage {
  factory ValidateSchemaResponse() => create();

  ValidateSchemaResponse._();

  factory ValidateSchemaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateSchemaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateSchemaResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSchemaResponse clone() =>
      ValidateSchemaResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateSchemaResponse copyWith(
          void Function(ValidateSchemaResponse) updates) =>
      super.copyWith((message) => updates(message as ValidateSchemaResponse))
          as ValidateSchemaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateSchemaResponse create() => ValidateSchemaResponse._();
  @$core.override
  ValidateSchemaResponse createEmptyInstance() => create();
  static $pb.PbList<ValidateSchemaResponse> createRepeated() =>
      $pb.PbList<ValidateSchemaResponse>();
  @$core.pragma('dart2js:noInline')
  static ValidateSchemaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateSchemaResponse>(create);
  static ValidateSchemaResponse? _defaultInstance;
}

enum ValidateMessageRequest_SchemaSpec { name, schema, notSet }

/// Request for the `ValidateMessage` method.
class ValidateMessageRequest extends $pb.GeneratedMessage {
  factory ValidateMessageRequest({
    $core.String? parent,
    $core.String? name,
    Schema? schema,
    $core.List<$core.int>? message,
    Encoding? encoding,
  }) {
    final result = create();
    if (parent != null) result.parent = parent;
    if (name != null) result.name = name;
    if (schema != null) result.schema = schema;
    if (message != null) result.message = message;
    if (encoding != null) result.encoding = encoding;
    return result;
  }

  ValidateMessageRequest._();

  factory ValidateMessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateMessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ValidateMessageRequest_SchemaSpec>
      _ValidateMessageRequest_SchemaSpecByTag = {
    2: ValidateMessageRequest_SchemaSpec.name,
    3: ValidateMessageRequest_SchemaSpec.schema,
    0: ValidateMessageRequest_SchemaSpec.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateMessageRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'parent')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOM<Schema>(3, _omitFieldNames ? '' : 'schema', subBuilder: Schema.create)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'message', $pb.PbFieldType.OY)
    ..e<Encoding>(5, _omitFieldNames ? '' : 'encoding', $pb.PbFieldType.OE,
        defaultOrMaker: Encoding.ENCODING_UNSPECIFIED,
        valueOf: Encoding.valueOf,
        enumValues: Encoding.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateMessageRequest clone() =>
      ValidateMessageRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateMessageRequest copyWith(
          void Function(ValidateMessageRequest) updates) =>
      super.copyWith((message) => updates(message as ValidateMessageRequest))
          as ValidateMessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateMessageRequest create() => ValidateMessageRequest._();
  @$core.override
  ValidateMessageRequest createEmptyInstance() => create();
  static $pb.PbList<ValidateMessageRequest> createRepeated() =>
      $pb.PbList<ValidateMessageRequest>();
  @$core.pragma('dart2js:noInline')
  static ValidateMessageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateMessageRequest>(create);
  static ValidateMessageRequest? _defaultInstance;

  ValidateMessageRequest_SchemaSpec whichSchemaSpec() =>
      _ValidateMessageRequest_SchemaSpecByTag[$_whichOneof(0)]!;
  void clearSchemaSpec() => $_clearField($_whichOneof(0));

  /// Required. The name of the project in which to validate schemas.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get parent => $_getSZ(0);
  @$pb.TagNumber(1)
  set parent($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => $_clearField(1);

  /// Name of the schema against which to validate.
  ///
  /// Format is `projects/{project}/schemas/{schema}`.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// Ad-hoc schema against which to validate
  @$pb.TagNumber(3)
  Schema get schema => $_getN(2);
  @$pb.TagNumber(3)
  set schema(Schema value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSchema() => $_has(2);
  @$pb.TagNumber(3)
  void clearSchema() => $_clearField(3);
  @$pb.TagNumber(3)
  Schema ensureSchema() => $_ensure(2);

  /// Message to validate against the provided `schema_spec`.
  @$pb.TagNumber(4)
  $core.List<$core.int> get message => $_getN(3);
  @$pb.TagNumber(4)
  set message($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);

  /// The encoding expected for messages
  @$pb.TagNumber(5)
  Encoding get encoding => $_getN(4);
  @$pb.TagNumber(5)
  set encoding(Encoding value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasEncoding() => $_has(4);
  @$pb.TagNumber(5)
  void clearEncoding() => $_clearField(5);
}

/// Response for the `ValidateMessage` method.
/// Empty for now.
class ValidateMessageResponse extends $pb.GeneratedMessage {
  factory ValidateMessageResponse() => create();

  ValidateMessageResponse._();

  factory ValidateMessageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ValidateMessageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ValidateMessageResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateMessageResponse clone() =>
      ValidateMessageResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ValidateMessageResponse copyWith(
          void Function(ValidateMessageResponse) updates) =>
      super.copyWith((message) => updates(message as ValidateMessageResponse))
          as ValidateMessageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ValidateMessageResponse create() => ValidateMessageResponse._();
  @$core.override
  ValidateMessageResponse createEmptyInstance() => create();
  static $pb.PbList<ValidateMessageResponse> createRepeated() =>
      $pb.PbList<ValidateMessageResponse>();
  @$core.pragma('dart2js:noInline')
  static ValidateMessageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ValidateMessageResponse>(create);
  static ValidateMessageResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
