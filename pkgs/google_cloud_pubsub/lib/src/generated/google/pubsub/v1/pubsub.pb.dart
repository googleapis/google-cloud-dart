// This is a generated file - do not edit.
//
// Generated from google/pubsub/v1/pubsub.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../protobuf/duration.pb.dart' as $4;
import '../../protobuf/field_mask.pb.dart' as $5;
import '../../protobuf/struct.pb.dart' as $3;
import '../../protobuf/timestamp.pb.dart' as $2;
import 'pubsub.pbenum.dart';
import 'schema.pbenum.dart' as $6;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'pubsub.pbenum.dart';

/// A policy constraining the storage of messages published to the topic.
class MessageStoragePolicy extends $pb.GeneratedMessage {
  factory MessageStoragePolicy({
    $core.Iterable<$core.String>? allowedPersistenceRegions,
    $core.bool? enforceInTransit,
  }) {
    final result = create();
    if (allowedPersistenceRegions != null)
      result.allowedPersistenceRegions.addAll(allowedPersistenceRegions);
    if (enforceInTransit != null) result.enforceInTransit = enforceInTransit;
    return result;
  }

  MessageStoragePolicy._();

  factory MessageStoragePolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageStoragePolicy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageStoragePolicy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'allowedPersistenceRegions')
    ..aOB(2, _omitFieldNames ? '' : 'enforceInTransit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageStoragePolicy clone() =>
      MessageStoragePolicy()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageStoragePolicy copyWith(void Function(MessageStoragePolicy) updates) =>
      super.copyWith((message) => updates(message as MessageStoragePolicy))
          as MessageStoragePolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageStoragePolicy create() => MessageStoragePolicy._();
  @$core.override
  MessageStoragePolicy createEmptyInstance() => create();
  static $pb.PbList<MessageStoragePolicy> createRepeated() =>
      $pb.PbList<MessageStoragePolicy>();
  @$core.pragma('dart2js:noInline')
  static MessageStoragePolicy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageStoragePolicy>(create);
  static MessageStoragePolicy? _defaultInstance;

  /// Optional. A list of IDs of Google Cloud regions where messages that are
  /// published to the topic may be persisted in storage. Messages published by
  /// publishers running in non-allowed Google Cloud regions (or running outside
  /// of Google Cloud altogether) are routed for storage in one of the allowed
  /// regions. An empty list means that no regions are allowed, and is not a
  /// valid configuration.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get allowedPersistenceRegions => $_getList(0);

  /// Optional. If true, `allowed_persistence_regions` is also used to enforce
  /// in-transit guarantees for messages. That is, Pub/Sub will fail
  /// Publish operations on this topic and subscribe operations
  /// on any subscription attached to this topic in any region that is
  /// not in `allowed_persistence_regions`.
  @$pb.TagNumber(2)
  $core.bool get enforceInTransit => $_getBF(1);
  @$pb.TagNumber(2)
  set enforceInTransit($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnforceInTransit() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnforceInTransit() => $_clearField(2);
}

/// Settings for validating messages published against a schema.
class SchemaSettings extends $pb.GeneratedMessage {
  factory SchemaSettings({
    $core.String? schema,
    $6.Encoding? encoding,
    $core.String? firstRevisionId,
    $core.String? lastRevisionId,
  }) {
    final result = create();
    if (schema != null) result.schema = schema;
    if (encoding != null) result.encoding = encoding;
    if (firstRevisionId != null) result.firstRevisionId = firstRevisionId;
    if (lastRevisionId != null) result.lastRevisionId = lastRevisionId;
    return result;
  }

  SchemaSettings._();

  factory SchemaSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SchemaSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SchemaSettings',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'schema')
    ..e<$6.Encoding>(2, _omitFieldNames ? '' : 'encoding', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Encoding.ENCODING_UNSPECIFIED,
        valueOf: $6.Encoding.valueOf,
        enumValues: $6.Encoding.values)
    ..aOS(3, _omitFieldNames ? '' : 'firstRevisionId')
    ..aOS(4, _omitFieldNames ? '' : 'lastRevisionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaSettings clone() => SchemaSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SchemaSettings copyWith(void Function(SchemaSettings) updates) =>
      super.copyWith((message) => updates(message as SchemaSettings))
          as SchemaSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchemaSettings create() => SchemaSettings._();
  @$core.override
  SchemaSettings createEmptyInstance() => create();
  static $pb.PbList<SchemaSettings> createRepeated() =>
      $pb.PbList<SchemaSettings>();
  @$core.pragma('dart2js:noInline')
  static SchemaSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SchemaSettings>(create);
  static SchemaSettings? _defaultInstance;

  /// Required. The name of the schema that messages published should be
  /// validated against. Format is `projects/{project}/schemas/{schema}`. The
  /// value of this field will be `_deleted-schema_` if the schema has been
  /// deleted.
  @$pb.TagNumber(1)
  $core.String get schema => $_getSZ(0);
  @$pb.TagNumber(1)
  set schema($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSchema() => $_has(0);
  @$pb.TagNumber(1)
  void clearSchema() => $_clearField(1);

  /// Optional. The encoding of messages validated against `schema`.
  @$pb.TagNumber(2)
  $6.Encoding get encoding => $_getN(1);
  @$pb.TagNumber(2)
  set encoding($6.Encoding value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEncoding() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncoding() => $_clearField(2);

  /// Optional. The minimum (inclusive) revision allowed for validating messages.
  /// If empty or not present, allow any revision to be validated against
  /// last_revision or any revision created before.
  @$pb.TagNumber(3)
  $core.String get firstRevisionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set firstRevisionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFirstRevisionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFirstRevisionId() => $_clearField(3);

  /// Optional. The maximum (inclusive) revision allowed for validating messages.
  /// If empty or not present, allow any revision to be validated against
  /// first_revision or any revision created after.
  @$pb.TagNumber(4)
  $core.String get lastRevisionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set lastRevisionId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastRevisionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastRevisionId() => $_clearField(4);
}

/// Ingestion settings for Amazon Kinesis Data Streams.
class IngestionDataSourceSettings_AwsKinesis extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_AwsKinesis({
    IngestionDataSourceSettings_AwsKinesis_State? state,
    $core.String? streamArn,
    $core.String? consumerArn,
    $core.String? awsRoleArn,
    $core.String? gcpServiceAccount,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (streamArn != null) result.streamArn = streamArn;
    if (consumerArn != null) result.consumerArn = consumerArn;
    if (awsRoleArn != null) result.awsRoleArn = awsRoleArn;
    if (gcpServiceAccount != null) result.gcpServiceAccount = gcpServiceAccount;
    return result;
  }

  IngestionDataSourceSettings_AwsKinesis._();

  factory IngestionDataSourceSettings_AwsKinesis.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_AwsKinesis.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings.AwsKinesis',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..e<IngestionDataSourceSettings_AwsKinesis_State>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            IngestionDataSourceSettings_AwsKinesis_State.STATE_UNSPECIFIED,
        valueOf: IngestionDataSourceSettings_AwsKinesis_State.valueOf,
        enumValues: IngestionDataSourceSettings_AwsKinesis_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'streamArn')
    ..aOS(3, _omitFieldNames ? '' : 'consumerArn')
    ..aOS(4, _omitFieldNames ? '' : 'awsRoleArn')
    ..aOS(5, _omitFieldNames ? '' : 'gcpServiceAccount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AwsKinesis clone() =>
      IngestionDataSourceSettings_AwsKinesis()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AwsKinesis copyWith(
          void Function(IngestionDataSourceSettings_AwsKinesis) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionDataSourceSettings_AwsKinesis))
          as IngestionDataSourceSettings_AwsKinesis;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AwsKinesis create() =>
      IngestionDataSourceSettings_AwsKinesis._();
  @$core.override
  IngestionDataSourceSettings_AwsKinesis createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_AwsKinesis> createRepeated() =>
      $pb.PbList<IngestionDataSourceSettings_AwsKinesis>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AwsKinesis getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_AwsKinesis>(create);
  static IngestionDataSourceSettings_AwsKinesis? _defaultInstance;

  /// Output only. An output-only field that indicates the state of the Kinesis
  /// ingestion source.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_AwsKinesis_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(IngestionDataSourceSettings_AwsKinesis_State value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Required. The Kinesis stream ARN to ingest data from.
  @$pb.TagNumber(2)
  $core.String get streamArn => $_getSZ(1);
  @$pb.TagNumber(2)
  set streamArn($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStreamArn() => $_has(1);
  @$pb.TagNumber(2)
  void clearStreamArn() => $_clearField(2);

  /// Required. The Kinesis consumer ARN to used for ingestion in Enhanced
  /// Fan-Out mode. The consumer must be already created and ready to be used.
  @$pb.TagNumber(3)
  $core.String get consumerArn => $_getSZ(2);
  @$pb.TagNumber(3)
  set consumerArn($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConsumerArn() => $_has(2);
  @$pb.TagNumber(3)
  void clearConsumerArn() => $_clearField(3);

  /// Required. AWS role ARN to be used for Federated Identity authentication
  /// with Kinesis. Check the Pub/Sub docs for how to set up this role and the
  /// required permissions that need to be attached to it.
  @$pb.TagNumber(4)
  $core.String get awsRoleArn => $_getSZ(3);
  @$pb.TagNumber(4)
  set awsRoleArn($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAwsRoleArn() => $_has(3);
  @$pb.TagNumber(4)
  void clearAwsRoleArn() => $_clearField(4);

  /// Required. The GCP service account to be used for Federated Identity
  /// authentication with Kinesis (via a `AssumeRoleWithWebIdentity` call for
  /// the provided role). The `aws_role_arn` must be set up with
  /// `accounts.google.com:sub` equals to this service account number.
  @$pb.TagNumber(5)
  $core.String get gcpServiceAccount => $_getSZ(4);
  @$pb.TagNumber(5)
  set gcpServiceAccount($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGcpServiceAccount() => $_has(4);
  @$pb.TagNumber(5)
  void clearGcpServiceAccount() => $_clearField(5);
}

/// Configuration for reading Cloud Storage data in text format. Each line of
/// text as specified by the delimiter will be set to the `data` field of a
/// Pub/Sub message.
class IngestionDataSourceSettings_CloudStorage_TextFormat
    extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_CloudStorage_TextFormat({
    $core.String? delimiter,
  }) {
    final result = create();
    if (delimiter != null) result.delimiter = delimiter;
    return result;
  }

  IngestionDataSourceSettings_CloudStorage_TextFormat._();

  factory IngestionDataSourceSettings_CloudStorage_TextFormat.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_CloudStorage_TextFormat.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionDataSourceSettings.CloudStorage.TextFormat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'delimiter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_TextFormat clone() =>
      IngestionDataSourceSettings_CloudStorage_TextFormat()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_TextFormat copyWith(
          void Function(IngestionDataSourceSettings_CloudStorage_TextFormat)
              updates) =>
      super.copyWith((message) => updates(
              message as IngestionDataSourceSettings_CloudStorage_TextFormat))
          as IngestionDataSourceSettings_CloudStorage_TextFormat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_TextFormat create() =>
      IngestionDataSourceSettings_CloudStorage_TextFormat._();
  @$core.override
  IngestionDataSourceSettings_CloudStorage_TextFormat createEmptyInstance() =>
      create();
  static $pb.PbList<IngestionDataSourceSettings_CloudStorage_TextFormat>
      createRepeated() =>
          $pb.PbList<IngestionDataSourceSettings_CloudStorage_TextFormat>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_TextFormat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_CloudStorage_TextFormat>(create);
  static IngestionDataSourceSettings_CloudStorage_TextFormat? _defaultInstance;

  /// Optional. When unset, '\n' is used.
  @$pb.TagNumber(1)
  $core.String get delimiter => $_getSZ(0);
  @$pb.TagNumber(1)
  set delimiter($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDelimiter() => $_has(0);
  @$pb.TagNumber(1)
  void clearDelimiter() => $_clearField(1);
}

/// Configuration for reading Cloud Storage data in Avro binary format. The
/// bytes of each object will be set to the `data` field of a Pub/Sub
/// message.
class IngestionDataSourceSettings_CloudStorage_AvroFormat
    extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_CloudStorage_AvroFormat() => create();

  IngestionDataSourceSettings_CloudStorage_AvroFormat._();

  factory IngestionDataSourceSettings_CloudStorage_AvroFormat.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_CloudStorage_AvroFormat.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionDataSourceSettings.CloudStorage.AvroFormat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_AvroFormat clone() =>
      IngestionDataSourceSettings_CloudStorage_AvroFormat()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_AvroFormat copyWith(
          void Function(IngestionDataSourceSettings_CloudStorage_AvroFormat)
              updates) =>
      super.copyWith((message) => updates(
              message as IngestionDataSourceSettings_CloudStorage_AvroFormat))
          as IngestionDataSourceSettings_CloudStorage_AvroFormat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_AvroFormat create() =>
      IngestionDataSourceSettings_CloudStorage_AvroFormat._();
  @$core.override
  IngestionDataSourceSettings_CloudStorage_AvroFormat createEmptyInstance() =>
      create();
  static $pb.PbList<IngestionDataSourceSettings_CloudStorage_AvroFormat>
      createRepeated() =>
          $pb.PbList<IngestionDataSourceSettings_CloudStorage_AvroFormat>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_AvroFormat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_CloudStorage_AvroFormat>(create);
  static IngestionDataSourceSettings_CloudStorage_AvroFormat? _defaultInstance;
}

/// Configuration for reading Cloud Storage data written via [Cloud Storage
/// subscriptions](https://cloud.google.com/pubsub/docs/cloudstorage). The
/// data and attributes fields of the originally exported Pub/Sub message
/// will be restored when publishing.
class IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat
    extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat() =>
      create();

  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat._();

  factory IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionDataSourceSettings.CloudStorage.PubSubAvroFormat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat clone() =>
      IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat copyWith(
          void Function(
                  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat)
              updates) =>
      super.copyWith((message) => updates(message
              as IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat))
          as IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat create() =>
      IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat._();
  @$core.override
  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat
      createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat>
      createRepeated() => $pb.PbList<
          IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat>(create);
  static IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat?
      _defaultInstance;
}

enum IngestionDataSourceSettings_CloudStorage_InputFormat {
  textFormat,
  avroFormat,
  pubsubAvroFormat,
  notSet
}

/// Ingestion settings for Cloud Storage.
class IngestionDataSourceSettings_CloudStorage extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_CloudStorage({
    IngestionDataSourceSettings_CloudStorage_State? state,
    $core.String? bucket,
    IngestionDataSourceSettings_CloudStorage_TextFormat? textFormat,
    IngestionDataSourceSettings_CloudStorage_AvroFormat? avroFormat,
    IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat? pubsubAvroFormat,
    $2.Timestamp? minimumObjectCreateTime,
    $core.String? matchGlob,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (bucket != null) result.bucket = bucket;
    if (textFormat != null) result.textFormat = textFormat;
    if (avroFormat != null) result.avroFormat = avroFormat;
    if (pubsubAvroFormat != null) result.pubsubAvroFormat = pubsubAvroFormat;
    if (minimumObjectCreateTime != null)
      result.minimumObjectCreateTime = minimumObjectCreateTime;
    if (matchGlob != null) result.matchGlob = matchGlob;
    return result;
  }

  IngestionDataSourceSettings_CloudStorage._();

  factory IngestionDataSourceSettings_CloudStorage.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_CloudStorage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionDataSourceSettings_CloudStorage_InputFormat>
      _IngestionDataSourceSettings_CloudStorage_InputFormatByTag = {
    3: IngestionDataSourceSettings_CloudStorage_InputFormat.textFormat,
    4: IngestionDataSourceSettings_CloudStorage_InputFormat.avroFormat,
    5: IngestionDataSourceSettings_CloudStorage_InputFormat.pubsubAvroFormat,
    0: IngestionDataSourceSettings_CloudStorage_InputFormat.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings.CloudStorage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5])
    ..e<IngestionDataSourceSettings_CloudStorage_State>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            IngestionDataSourceSettings_CloudStorage_State.STATE_UNSPECIFIED,
        valueOf: IngestionDataSourceSettings_CloudStorage_State.valueOf,
        enumValues: IngestionDataSourceSettings_CloudStorage_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'bucket')
    ..aOM<IngestionDataSourceSettings_CloudStorage_TextFormat>(
        3, _omitFieldNames ? '' : 'textFormat',
        subBuilder: IngestionDataSourceSettings_CloudStorage_TextFormat.create)
    ..aOM<IngestionDataSourceSettings_CloudStorage_AvroFormat>(
        4, _omitFieldNames ? '' : 'avroFormat',
        subBuilder: IngestionDataSourceSettings_CloudStorage_AvroFormat.create)
    ..aOM<IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat>(
        5, _omitFieldNames ? '' : 'pubsubAvroFormat',
        subBuilder:
            IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat.create)
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'minimumObjectCreateTime',
        subBuilder: $2.Timestamp.create)
    ..aOS(9, _omitFieldNames ? '' : 'matchGlob')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage clone() =>
      IngestionDataSourceSettings_CloudStorage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_CloudStorage copyWith(
          void Function(IngestionDataSourceSettings_CloudStorage) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionDataSourceSettings_CloudStorage))
          as IngestionDataSourceSettings_CloudStorage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage create() =>
      IngestionDataSourceSettings_CloudStorage._();
  @$core.override
  IngestionDataSourceSettings_CloudStorage createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_CloudStorage>
      createRepeated() =>
          $pb.PbList<IngestionDataSourceSettings_CloudStorage>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_CloudStorage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_CloudStorage>(create);
  static IngestionDataSourceSettings_CloudStorage? _defaultInstance;

  IngestionDataSourceSettings_CloudStorage_InputFormat whichInputFormat() =>
      _IngestionDataSourceSettings_CloudStorage_InputFormatByTag[
          $_whichOneof(0)]!;
  void clearInputFormat() => $_clearField($_whichOneof(0));

  /// Output only. An output-only field that indicates the state of the Cloud
  /// Storage ingestion source.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_CloudStorage_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(IngestionDataSourceSettings_CloudStorage_State value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Optional. Cloud Storage bucket. The bucket name must be without any
  /// prefix like "gs://". See the [bucket naming requirements]
  /// (https://cloud.google.com/storage/docs/buckets#naming).
  @$pb.TagNumber(2)
  $core.String get bucket => $_getSZ(1);
  @$pb.TagNumber(2)
  set bucket($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBucket() => $_has(1);
  @$pb.TagNumber(2)
  void clearBucket() => $_clearField(2);

  /// Optional. Data from Cloud Storage will be interpreted as text.
  @$pb.TagNumber(3)
  IngestionDataSourceSettings_CloudStorage_TextFormat get textFormat =>
      $_getN(2);
  @$pb.TagNumber(3)
  set textFormat(IngestionDataSourceSettings_CloudStorage_TextFormat value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasTextFormat() => $_has(2);
  @$pb.TagNumber(3)
  void clearTextFormat() => $_clearField(3);
  @$pb.TagNumber(3)
  IngestionDataSourceSettings_CloudStorage_TextFormat ensureTextFormat() =>
      $_ensure(2);

  /// Optional. Data from Cloud Storage will be interpreted in Avro format.
  @$pb.TagNumber(4)
  IngestionDataSourceSettings_CloudStorage_AvroFormat get avroFormat =>
      $_getN(3);
  @$pb.TagNumber(4)
  set avroFormat(IngestionDataSourceSettings_CloudStorage_AvroFormat value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAvroFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvroFormat() => $_clearField(4);
  @$pb.TagNumber(4)
  IngestionDataSourceSettings_CloudStorage_AvroFormat ensureAvroFormat() =>
      $_ensure(3);

  /// Optional. It will be assumed data from Cloud Storage was written via
  /// [Cloud Storage
  /// subscriptions](https://cloud.google.com/pubsub/docs/cloudstorage).
  @$pb.TagNumber(5)
  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat
      get pubsubAvroFormat => $_getN(4);
  @$pb.TagNumber(5)
  set pubsubAvroFormat(
          IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPubsubAvroFormat() => $_has(4);
  @$pb.TagNumber(5)
  void clearPubsubAvroFormat() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionDataSourceSettings_CloudStorage_PubSubAvroFormat
      ensurePubsubAvroFormat() => $_ensure(4);

  /// Optional. Only objects with a larger or equal creation timestamp will be
  /// ingested.
  @$pb.TagNumber(6)
  $2.Timestamp get minimumObjectCreateTime => $_getN(5);
  @$pb.TagNumber(6)
  set minimumObjectCreateTime($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMinimumObjectCreateTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearMinimumObjectCreateTime() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureMinimumObjectCreateTime() => $_ensure(5);

  /// Optional. Glob pattern used to match objects that will be ingested. If
  /// unset, all objects will be ingested. See the [supported
  /// patterns](https://cloud.google.com/storage/docs/json_api/v1/objects/list#list-objects-and-prefixes-using-glob).
  @$pb.TagNumber(9)
  $core.String get matchGlob => $_getSZ(6);
  @$pb.TagNumber(9)
  set matchGlob($core.String value) => $_setString(6, value);
  @$pb.TagNumber(9)
  $core.bool hasMatchGlob() => $_has(6);
  @$pb.TagNumber(9)
  void clearMatchGlob() => $_clearField(9);
}

/// Ingestion settings for Azure Event Hubs.
class IngestionDataSourceSettings_AzureEventHubs extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_AzureEventHubs({
    IngestionDataSourceSettings_AzureEventHubs_State? state,
    $core.String? resourceGroup,
    $core.String? namespace,
    $core.String? eventHub,
    $core.String? clientId,
    $core.String? tenantId,
    $core.String? subscriptionId,
    $core.String? gcpServiceAccount,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (resourceGroup != null) result.resourceGroup = resourceGroup;
    if (namespace != null) result.namespace = namespace;
    if (eventHub != null) result.eventHub = eventHub;
    if (clientId != null) result.clientId = clientId;
    if (tenantId != null) result.tenantId = tenantId;
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (gcpServiceAccount != null) result.gcpServiceAccount = gcpServiceAccount;
    return result;
  }

  IngestionDataSourceSettings_AzureEventHubs._();

  factory IngestionDataSourceSettings_AzureEventHubs.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_AzureEventHubs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings.AzureEventHubs',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..e<IngestionDataSourceSettings_AzureEventHubs_State>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            IngestionDataSourceSettings_AzureEventHubs_State.STATE_UNSPECIFIED,
        valueOf: IngestionDataSourceSettings_AzureEventHubs_State.valueOf,
        enumValues: IngestionDataSourceSettings_AzureEventHubs_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'resourceGroup')
    ..aOS(3, _omitFieldNames ? '' : 'namespace')
    ..aOS(4, _omitFieldNames ? '' : 'eventHub')
    ..aOS(5, _omitFieldNames ? '' : 'clientId')
    ..aOS(6, _omitFieldNames ? '' : 'tenantId')
    ..aOS(7, _omitFieldNames ? '' : 'subscriptionId')
    ..aOS(8, _omitFieldNames ? '' : 'gcpServiceAccount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AzureEventHubs clone() =>
      IngestionDataSourceSettings_AzureEventHubs()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AzureEventHubs copyWith(
          void Function(IngestionDataSourceSettings_AzureEventHubs) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionDataSourceSettings_AzureEventHubs))
          as IngestionDataSourceSettings_AzureEventHubs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AzureEventHubs create() =>
      IngestionDataSourceSettings_AzureEventHubs._();
  @$core.override
  IngestionDataSourceSettings_AzureEventHubs createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_AzureEventHubs>
      createRepeated() =>
          $pb.PbList<IngestionDataSourceSettings_AzureEventHubs>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AzureEventHubs getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_AzureEventHubs>(create);
  static IngestionDataSourceSettings_AzureEventHubs? _defaultInstance;

  /// Output only. An output-only field that indicates the state of the Event
  /// Hubs ingestion source.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_AzureEventHubs_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(IngestionDataSourceSettings_AzureEventHubs_State value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Optional. Name of the resource group within the azure subscription.
  @$pb.TagNumber(2)
  $core.String get resourceGroup => $_getSZ(1);
  @$pb.TagNumber(2)
  set resourceGroup($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResourceGroup() => $_has(1);
  @$pb.TagNumber(2)
  void clearResourceGroup() => $_clearField(2);

  /// Optional. The name of the Event Hubs namespace.
  @$pb.TagNumber(3)
  $core.String get namespace => $_getSZ(2);
  @$pb.TagNumber(3)
  set namespace($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNamespace() => $_has(2);
  @$pb.TagNumber(3)
  void clearNamespace() => $_clearField(3);

  /// Optional. The name of the Event Hub.
  @$pb.TagNumber(4)
  $core.String get eventHub => $_getSZ(3);
  @$pb.TagNumber(4)
  set eventHub($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEventHub() => $_has(3);
  @$pb.TagNumber(4)
  void clearEventHub() => $_clearField(4);

  /// Optional. The client id of the Azure application that is being used to
  /// authenticate Pub/Sub.
  @$pb.TagNumber(5)
  $core.String get clientId => $_getSZ(4);
  @$pb.TagNumber(5)
  set clientId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClientId() => $_has(4);
  @$pb.TagNumber(5)
  void clearClientId() => $_clearField(5);

  /// Optional. The tenant id of the Azure application that is being used to
  /// authenticate Pub/Sub.
  @$pb.TagNumber(6)
  $core.String get tenantId => $_getSZ(5);
  @$pb.TagNumber(6)
  set tenantId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTenantId() => $_has(5);
  @$pb.TagNumber(6)
  void clearTenantId() => $_clearField(6);

  /// Optional. The Azure subscription id.
  @$pb.TagNumber(7)
  $core.String get subscriptionId => $_getSZ(6);
  @$pb.TagNumber(7)
  set subscriptionId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSubscriptionId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSubscriptionId() => $_clearField(7);

  /// Optional. The GCP service account to be used for Federated Identity
  /// authentication.
  @$pb.TagNumber(8)
  $core.String get gcpServiceAccount => $_getSZ(7);
  @$pb.TagNumber(8)
  set gcpServiceAccount($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasGcpServiceAccount() => $_has(7);
  @$pb.TagNumber(8)
  void clearGcpServiceAccount() => $_clearField(8);
}

/// Ingestion settings for Amazon MSK.
class IngestionDataSourceSettings_AwsMsk extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_AwsMsk({
    IngestionDataSourceSettings_AwsMsk_State? state,
    $core.String? clusterArn,
    $core.String? topic,
    $core.String? awsRoleArn,
    $core.String? gcpServiceAccount,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (clusterArn != null) result.clusterArn = clusterArn;
    if (topic != null) result.topic = topic;
    if (awsRoleArn != null) result.awsRoleArn = awsRoleArn;
    if (gcpServiceAccount != null) result.gcpServiceAccount = gcpServiceAccount;
    return result;
  }

  IngestionDataSourceSettings_AwsMsk._();

  factory IngestionDataSourceSettings_AwsMsk.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_AwsMsk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings.AwsMsk',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..e<IngestionDataSourceSettings_AwsMsk_State>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            IngestionDataSourceSettings_AwsMsk_State.STATE_UNSPECIFIED,
        valueOf: IngestionDataSourceSettings_AwsMsk_State.valueOf,
        enumValues: IngestionDataSourceSettings_AwsMsk_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'clusterArn')
    ..aOS(3, _omitFieldNames ? '' : 'topic')
    ..aOS(4, _omitFieldNames ? '' : 'awsRoleArn')
    ..aOS(5, _omitFieldNames ? '' : 'gcpServiceAccount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AwsMsk clone() =>
      IngestionDataSourceSettings_AwsMsk()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_AwsMsk copyWith(
          void Function(IngestionDataSourceSettings_AwsMsk) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionDataSourceSettings_AwsMsk))
          as IngestionDataSourceSettings_AwsMsk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AwsMsk create() =>
      IngestionDataSourceSettings_AwsMsk._();
  @$core.override
  IngestionDataSourceSettings_AwsMsk createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_AwsMsk> createRepeated() =>
      $pb.PbList<IngestionDataSourceSettings_AwsMsk>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_AwsMsk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IngestionDataSourceSettings_AwsMsk>(
          create);
  static IngestionDataSourceSettings_AwsMsk? _defaultInstance;

  /// Output only. An output-only field that indicates the state of the Amazon
  /// MSK ingestion source.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_AwsMsk_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(IngestionDataSourceSettings_AwsMsk_State value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Required. The Amazon Resource Name (ARN) that uniquely identifies the
  /// cluster.
  @$pb.TagNumber(2)
  $core.String get clusterArn => $_getSZ(1);
  @$pb.TagNumber(2)
  set clusterArn($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasClusterArn() => $_has(1);
  @$pb.TagNumber(2)
  void clearClusterArn() => $_clearField(2);

  /// Required. The name of the topic in the Amazon MSK cluster that Pub/Sub
  /// will import from.
  @$pb.TagNumber(3)
  $core.String get topic => $_getSZ(2);
  @$pb.TagNumber(3)
  set topic($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTopic() => $_has(2);
  @$pb.TagNumber(3)
  void clearTopic() => $_clearField(3);

  /// Required. AWS role ARN to be used for Federated Identity authentication
  /// with Amazon MSK. Check the Pub/Sub docs for how to set up this role and
  /// the required permissions that need to be attached to it.
  @$pb.TagNumber(4)
  $core.String get awsRoleArn => $_getSZ(3);
  @$pb.TagNumber(4)
  set awsRoleArn($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAwsRoleArn() => $_has(3);
  @$pb.TagNumber(4)
  void clearAwsRoleArn() => $_clearField(4);

  /// Required. The GCP service account to be used for Federated Identity
  /// authentication with Amazon MSK (via a `AssumeRoleWithWebIdentity` call
  /// for the provided role). The `aws_role_arn` must be set up with
  /// `accounts.google.com:sub` equals to this service account number.
  @$pb.TagNumber(5)
  $core.String get gcpServiceAccount => $_getSZ(4);
  @$pb.TagNumber(5)
  set gcpServiceAccount($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGcpServiceAccount() => $_has(4);
  @$pb.TagNumber(5)
  void clearGcpServiceAccount() => $_clearField(5);
}

/// Ingestion settings for Confluent Cloud.
class IngestionDataSourceSettings_ConfluentCloud extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings_ConfluentCloud({
    IngestionDataSourceSettings_ConfluentCloud_State? state,
    $core.String? bootstrapServer,
    $core.String? clusterId,
    $core.String? topic,
    $core.String? identityPoolId,
    $core.String? gcpServiceAccount,
  }) {
    final result = create();
    if (state != null) result.state = state;
    if (bootstrapServer != null) result.bootstrapServer = bootstrapServer;
    if (clusterId != null) result.clusterId = clusterId;
    if (topic != null) result.topic = topic;
    if (identityPoolId != null) result.identityPoolId = identityPoolId;
    if (gcpServiceAccount != null) result.gcpServiceAccount = gcpServiceAccount;
    return result;
  }

  IngestionDataSourceSettings_ConfluentCloud._();

  factory IngestionDataSourceSettings_ConfluentCloud.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings_ConfluentCloud.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings.ConfluentCloud',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..e<IngestionDataSourceSettings_ConfluentCloud_State>(
        1, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker:
            IngestionDataSourceSettings_ConfluentCloud_State.STATE_UNSPECIFIED,
        valueOf: IngestionDataSourceSettings_ConfluentCloud_State.valueOf,
        enumValues: IngestionDataSourceSettings_ConfluentCloud_State.values)
    ..aOS(2, _omitFieldNames ? '' : 'bootstrapServer')
    ..aOS(3, _omitFieldNames ? '' : 'clusterId')
    ..aOS(4, _omitFieldNames ? '' : 'topic')
    ..aOS(5, _omitFieldNames ? '' : 'identityPoolId')
    ..aOS(6, _omitFieldNames ? '' : 'gcpServiceAccount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_ConfluentCloud clone() =>
      IngestionDataSourceSettings_ConfluentCloud()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings_ConfluentCloud copyWith(
          void Function(IngestionDataSourceSettings_ConfluentCloud) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionDataSourceSettings_ConfluentCloud))
          as IngestionDataSourceSettings_ConfluentCloud;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_ConfluentCloud create() =>
      IngestionDataSourceSettings_ConfluentCloud._();
  @$core.override
  IngestionDataSourceSettings_ConfluentCloud createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings_ConfluentCloud>
      createRepeated() =>
          $pb.PbList<IngestionDataSourceSettings_ConfluentCloud>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings_ConfluentCloud getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionDataSourceSettings_ConfluentCloud>(create);
  static IngestionDataSourceSettings_ConfluentCloud? _defaultInstance;

  /// Output only. An output-only field that indicates the state of the
  /// Confluent Cloud ingestion source.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_ConfluentCloud_State get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(IngestionDataSourceSettings_ConfluentCloud_State value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  /// Required. The address of the bootstrap server. The format is url:port.
  @$pb.TagNumber(2)
  $core.String get bootstrapServer => $_getSZ(1);
  @$pb.TagNumber(2)
  set bootstrapServer($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBootstrapServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearBootstrapServer() => $_clearField(2);

  /// Required. The id of the cluster.
  @$pb.TagNumber(3)
  $core.String get clusterId => $_getSZ(2);
  @$pb.TagNumber(3)
  set clusterId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClusterId() => $_has(2);
  @$pb.TagNumber(3)
  void clearClusterId() => $_clearField(3);

  /// Required. The name of the topic in the Confluent Cloud cluster that
  /// Pub/Sub will import from.
  @$pb.TagNumber(4)
  $core.String get topic => $_getSZ(3);
  @$pb.TagNumber(4)
  set topic($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTopic() => $_has(3);
  @$pb.TagNumber(4)
  void clearTopic() => $_clearField(4);

  /// Required. The id of the identity pool to be used for Federated Identity
  /// authentication with Confluent Cloud. See
  /// https://docs.confluent.io/cloud/current/security/authenticate/workload-identities/identity-providers/oauth/identity-pools.html#add-oauth-identity-pools.
  @$pb.TagNumber(5)
  $core.String get identityPoolId => $_getSZ(4);
  @$pb.TagNumber(5)
  set identityPoolId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIdentityPoolId() => $_has(4);
  @$pb.TagNumber(5)
  void clearIdentityPoolId() => $_clearField(5);

  /// Required. The GCP service account to be used for Federated Identity
  /// authentication with `identity_pool_id`.
  @$pb.TagNumber(6)
  $core.String get gcpServiceAccount => $_getSZ(5);
  @$pb.TagNumber(6)
  set gcpServiceAccount($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGcpServiceAccount() => $_has(5);
  @$pb.TagNumber(6)
  void clearGcpServiceAccount() => $_clearField(6);
}

enum IngestionDataSourceSettings_Source {
  awsKinesis,
  cloudStorage,
  azureEventHubs,
  awsMsk,
  confluentCloud,
  notSet
}

/// Settings for an ingestion data source on a topic.
class IngestionDataSourceSettings extends $pb.GeneratedMessage {
  factory IngestionDataSourceSettings({
    IngestionDataSourceSettings_AwsKinesis? awsKinesis,
    IngestionDataSourceSettings_CloudStorage? cloudStorage,
    IngestionDataSourceSettings_AzureEventHubs? azureEventHubs,
    PlatformLogsSettings? platformLogsSettings,
    IngestionDataSourceSettings_AwsMsk? awsMsk,
    IngestionDataSourceSettings_ConfluentCloud? confluentCloud,
  }) {
    final result = create();
    if (awsKinesis != null) result.awsKinesis = awsKinesis;
    if (cloudStorage != null) result.cloudStorage = cloudStorage;
    if (azureEventHubs != null) result.azureEventHubs = azureEventHubs;
    if (platformLogsSettings != null)
      result.platformLogsSettings = platformLogsSettings;
    if (awsMsk != null) result.awsMsk = awsMsk;
    if (confluentCloud != null) result.confluentCloud = confluentCloud;
    return result;
  }

  IngestionDataSourceSettings._();

  factory IngestionDataSourceSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionDataSourceSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, IngestionDataSourceSettings_Source>
      _IngestionDataSourceSettings_SourceByTag = {
    1: IngestionDataSourceSettings_Source.awsKinesis,
    2: IngestionDataSourceSettings_Source.cloudStorage,
    3: IngestionDataSourceSettings_Source.azureEventHubs,
    5: IngestionDataSourceSettings_Source.awsMsk,
    6: IngestionDataSourceSettings_Source.confluentCloud,
    0: IngestionDataSourceSettings_Source.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionDataSourceSettings',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 5, 6])
    ..aOM<IngestionDataSourceSettings_AwsKinesis>(
        1, _omitFieldNames ? '' : 'awsKinesis',
        subBuilder: IngestionDataSourceSettings_AwsKinesis.create)
    ..aOM<IngestionDataSourceSettings_CloudStorage>(
        2, _omitFieldNames ? '' : 'cloudStorage',
        subBuilder: IngestionDataSourceSettings_CloudStorage.create)
    ..aOM<IngestionDataSourceSettings_AzureEventHubs>(
        3, _omitFieldNames ? '' : 'azureEventHubs',
        subBuilder: IngestionDataSourceSettings_AzureEventHubs.create)
    ..aOM<PlatformLogsSettings>(
        4, _omitFieldNames ? '' : 'platformLogsSettings',
        subBuilder: PlatformLogsSettings.create)
    ..aOM<IngestionDataSourceSettings_AwsMsk>(
        5, _omitFieldNames ? '' : 'awsMsk',
        subBuilder: IngestionDataSourceSettings_AwsMsk.create)
    ..aOM<IngestionDataSourceSettings_ConfluentCloud>(
        6, _omitFieldNames ? '' : 'confluentCloud',
        subBuilder: IngestionDataSourceSettings_ConfluentCloud.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings clone() =>
      IngestionDataSourceSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionDataSourceSettings copyWith(
          void Function(IngestionDataSourceSettings) updates) =>
      super.copyWith(
              (message) => updates(message as IngestionDataSourceSettings))
          as IngestionDataSourceSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings create() =>
      IngestionDataSourceSettings._();
  @$core.override
  IngestionDataSourceSettings createEmptyInstance() => create();
  static $pb.PbList<IngestionDataSourceSettings> createRepeated() =>
      $pb.PbList<IngestionDataSourceSettings>();
  @$core.pragma('dart2js:noInline')
  static IngestionDataSourceSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IngestionDataSourceSettings>(create);
  static IngestionDataSourceSettings? _defaultInstance;

  IngestionDataSourceSettings_Source whichSource() =>
      _IngestionDataSourceSettings_SourceByTag[$_whichOneof(0)]!;
  void clearSource() => $_clearField($_whichOneof(0));

  /// Optional. Amazon Kinesis Data Streams.
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_AwsKinesis get awsKinesis => $_getN(0);
  @$pb.TagNumber(1)
  set awsKinesis(IngestionDataSourceSettings_AwsKinesis value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAwsKinesis() => $_has(0);
  @$pb.TagNumber(1)
  void clearAwsKinesis() => $_clearField(1);
  @$pb.TagNumber(1)
  IngestionDataSourceSettings_AwsKinesis ensureAwsKinesis() => $_ensure(0);

  /// Optional. Cloud Storage.
  @$pb.TagNumber(2)
  IngestionDataSourceSettings_CloudStorage get cloudStorage => $_getN(1);
  @$pb.TagNumber(2)
  set cloudStorage(IngestionDataSourceSettings_CloudStorage value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasCloudStorage() => $_has(1);
  @$pb.TagNumber(2)
  void clearCloudStorage() => $_clearField(2);
  @$pb.TagNumber(2)
  IngestionDataSourceSettings_CloudStorage ensureCloudStorage() => $_ensure(1);

  /// Optional. Azure Event Hubs.
  @$pb.TagNumber(3)
  IngestionDataSourceSettings_AzureEventHubs get azureEventHubs => $_getN(2);
  @$pb.TagNumber(3)
  set azureEventHubs(IngestionDataSourceSettings_AzureEventHubs value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAzureEventHubs() => $_has(2);
  @$pb.TagNumber(3)
  void clearAzureEventHubs() => $_clearField(3);
  @$pb.TagNumber(3)
  IngestionDataSourceSettings_AzureEventHubs ensureAzureEventHubs() =>
      $_ensure(2);

  /// Optional. Platform Logs settings. If unset, no Platform Logs will be
  /// generated.
  @$pb.TagNumber(4)
  PlatformLogsSettings get platformLogsSettings => $_getN(3);
  @$pb.TagNumber(4)
  set platformLogsSettings(PlatformLogsSettings value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPlatformLogsSettings() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlatformLogsSettings() => $_clearField(4);
  @$pb.TagNumber(4)
  PlatformLogsSettings ensurePlatformLogsSettings() => $_ensure(3);

  /// Optional. Amazon MSK.
  @$pb.TagNumber(5)
  IngestionDataSourceSettings_AwsMsk get awsMsk => $_getN(4);
  @$pb.TagNumber(5)
  set awsMsk(IngestionDataSourceSettings_AwsMsk value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAwsMsk() => $_has(4);
  @$pb.TagNumber(5)
  void clearAwsMsk() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionDataSourceSettings_AwsMsk ensureAwsMsk() => $_ensure(4);

  /// Optional. Confluent Cloud.
  @$pb.TagNumber(6)
  IngestionDataSourceSettings_ConfluentCloud get confluentCloud => $_getN(5);
  @$pb.TagNumber(6)
  set confluentCloud(IngestionDataSourceSettings_ConfluentCloud value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasConfluentCloud() => $_has(5);
  @$pb.TagNumber(6)
  void clearConfluentCloud() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionDataSourceSettings_ConfluentCloud ensureConfluentCloud() =>
      $_ensure(5);
}

/// Settings for Platform Logs produced by Pub/Sub.
class PlatformLogsSettings extends $pb.GeneratedMessage {
  factory PlatformLogsSettings({
    PlatformLogsSettings_Severity? severity,
  }) {
    final result = create();
    if (severity != null) result.severity = severity;
    return result;
  }

  PlatformLogsSettings._();

  factory PlatformLogsSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlatformLogsSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlatformLogsSettings',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..e<PlatformLogsSettings_Severity>(
        1, _omitFieldNames ? '' : 'severity', $pb.PbFieldType.OE,
        defaultOrMaker: PlatformLogsSettings_Severity.SEVERITY_UNSPECIFIED,
        valueOf: PlatformLogsSettings_Severity.valueOf,
        enumValues: PlatformLogsSettings_Severity.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformLogsSettings clone() =>
      PlatformLogsSettings()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlatformLogsSettings copyWith(void Function(PlatformLogsSettings) updates) =>
      super.copyWith((message) => updates(message as PlatformLogsSettings))
          as PlatformLogsSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlatformLogsSettings create() => PlatformLogsSettings._();
  @$core.override
  PlatformLogsSettings createEmptyInstance() => create();
  static $pb.PbList<PlatformLogsSettings> createRepeated() =>
      $pb.PbList<PlatformLogsSettings>();
  @$core.pragma('dart2js:noInline')
  static PlatformLogsSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlatformLogsSettings>(create);
  static PlatformLogsSettings? _defaultInstance;

  /// Optional. The minimum severity level of Platform Logs that will be written.
  @$pb.TagNumber(1)
  PlatformLogsSettings_Severity get severity => $_getN(0);
  @$pb.TagNumber(1)
  set severity(PlatformLogsSettings_Severity value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSeverity() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeverity() => $_clearField(1);
}

/// Specifies the reason why some data may have been left out of
/// the desired Pub/Sub message due to the API message limits
/// (https://cloud.google.com/pubsub/quotas#resource_limits). For example,
/// when the number of attributes is larger than 100, the number of
/// attributes is truncated to 100 to respect the limit on the attribute count.
/// Other attribute limits are treated similarly. When the size of the desired
/// message would've been larger than 10MB, the message won't be published at
/// all, and ingestion of the subsequent messages will proceed as normal.
class IngestionFailureEvent_ApiViolationReason extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_ApiViolationReason() => create();

  IngestionFailureEvent_ApiViolationReason._();

  factory IngestionFailureEvent_ApiViolationReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_ApiViolationReason.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.ApiViolationReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_ApiViolationReason clone() =>
      IngestionFailureEvent_ApiViolationReason()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_ApiViolationReason copyWith(
          void Function(IngestionFailureEvent_ApiViolationReason) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_ApiViolationReason))
          as IngestionFailureEvent_ApiViolationReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_ApiViolationReason create() =>
      IngestionFailureEvent_ApiViolationReason._();
  @$core.override
  IngestionFailureEvent_ApiViolationReason createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_ApiViolationReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_ApiViolationReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_ApiViolationReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_ApiViolationReason>(create);
  static IngestionFailureEvent_ApiViolationReason? _defaultInstance;
}

/// Set when an Avro file is unsupported or its format is not valid. When this
/// occurs, one or more Avro objects won't be ingested.
class IngestionFailureEvent_AvroFailureReason extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_AvroFailureReason() => create();

  IngestionFailureEvent_AvroFailureReason._();

  factory IngestionFailureEvent_AvroFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_AvroFailureReason.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.AvroFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AvroFailureReason clone() =>
      IngestionFailureEvent_AvroFailureReason()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AvroFailureReason copyWith(
          void Function(IngestionFailureEvent_AvroFailureReason) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_AvroFailureReason))
          as IngestionFailureEvent_AvroFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AvroFailureReason create() =>
      IngestionFailureEvent_AvroFailureReason._();
  @$core.override
  IngestionFailureEvent_AvroFailureReason createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_AvroFailureReason> createRepeated() =>
      $pb.PbList<IngestionFailureEvent_AvroFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AvroFailureReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_AvroFailureReason>(create);
  static IngestionFailureEvent_AvroFailureReason? _defaultInstance;
}

/// Set when a Pub/Sub message fails to get published due to a schema
/// validation violation.
class IngestionFailureEvent_SchemaViolationReason extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_SchemaViolationReason() => create();

  IngestionFailureEvent_SchemaViolationReason._();

  factory IngestionFailureEvent_SchemaViolationReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_SchemaViolationReason.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.SchemaViolationReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_SchemaViolationReason clone() =>
      IngestionFailureEvent_SchemaViolationReason()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_SchemaViolationReason copyWith(
          void Function(IngestionFailureEvent_SchemaViolationReason) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_SchemaViolationReason))
          as IngestionFailureEvent_SchemaViolationReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_SchemaViolationReason create() =>
      IngestionFailureEvent_SchemaViolationReason._();
  @$core.override
  IngestionFailureEvent_SchemaViolationReason createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_SchemaViolationReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_SchemaViolationReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_SchemaViolationReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_SchemaViolationReason>(create);
  static IngestionFailureEvent_SchemaViolationReason? _defaultInstance;
}

/// Set when a Pub/Sub message fails to get published due to a message
/// transformation error.
class IngestionFailureEvent_MessageTransformationFailureReason
    extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_MessageTransformationFailureReason() =>
      create();

  IngestionFailureEvent_MessageTransformationFailureReason._();

  factory IngestionFailureEvent_MessageTransformationFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_MessageTransformationFailureReason.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionFailureEvent.MessageTransformationFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_MessageTransformationFailureReason clone() =>
      IngestionFailureEvent_MessageTransformationFailureReason()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_MessageTransformationFailureReason copyWith(
          void Function(
                  IngestionFailureEvent_MessageTransformationFailureReason)
              updates) =>
      super.copyWith((message) => updates(message
              as IngestionFailureEvent_MessageTransformationFailureReason))
          as IngestionFailureEvent_MessageTransformationFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_MessageTransformationFailureReason create() =>
      IngestionFailureEvent_MessageTransformationFailureReason._();
  @$core.override
  IngestionFailureEvent_MessageTransformationFailureReason
      createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_MessageTransformationFailureReason>
      createRepeated() => $pb.PbList<
          IngestionFailureEvent_MessageTransformationFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_MessageTransformationFailureReason
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_MessageTransformationFailureReason>(create);
  static IngestionFailureEvent_MessageTransformationFailureReason?
      _defaultInstance;
}

enum IngestionFailureEvent_CloudStorageFailure_Reason {
  avroFailureReason,
  apiViolationReason,
  schemaViolationReason,
  messageTransformationFailureReason,
  notSet
}

/// Failure when ingesting from a Cloud Storage source.
class IngestionFailureEvent_CloudStorageFailure extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_CloudStorageFailure({
    $core.String? bucket,
    $core.String? objectName,
    $fixnum.Int64? objectGeneration,
    IngestionFailureEvent_AvroFailureReason? avroFailureReason,
    IngestionFailureEvent_ApiViolationReason? apiViolationReason,
    IngestionFailureEvent_SchemaViolationReason? schemaViolationReason,
    IngestionFailureEvent_MessageTransformationFailureReason?
        messageTransformationFailureReason,
  }) {
    final result = create();
    if (bucket != null) result.bucket = bucket;
    if (objectName != null) result.objectName = objectName;
    if (objectGeneration != null) result.objectGeneration = objectGeneration;
    if (avroFailureReason != null) result.avroFailureReason = avroFailureReason;
    if (apiViolationReason != null)
      result.apiViolationReason = apiViolationReason;
    if (schemaViolationReason != null)
      result.schemaViolationReason = schemaViolationReason;
    if (messageTransformationFailureReason != null)
      result.messageTransformationFailureReason =
          messageTransformationFailureReason;
    return result;
  }

  IngestionFailureEvent_CloudStorageFailure._();

  factory IngestionFailureEvent_CloudStorageFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_CloudStorageFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionFailureEvent_CloudStorageFailure_Reason>
      _IngestionFailureEvent_CloudStorageFailure_ReasonByTag = {
    5: IngestionFailureEvent_CloudStorageFailure_Reason.avroFailureReason,
    6: IngestionFailureEvent_CloudStorageFailure_Reason.apiViolationReason,
    7: IngestionFailureEvent_CloudStorageFailure_Reason.schemaViolationReason,
    8: IngestionFailureEvent_CloudStorageFailure_Reason
        .messageTransformationFailureReason,
    0: IngestionFailureEvent_CloudStorageFailure_Reason.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.CloudStorageFailure',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [5, 6, 7, 8])
    ..aOS(1, _omitFieldNames ? '' : 'bucket')
    ..aOS(2, _omitFieldNames ? '' : 'objectName')
    ..aInt64(3, _omitFieldNames ? '' : 'objectGeneration')
    ..aOM<IngestionFailureEvent_AvroFailureReason>(
        5, _omitFieldNames ? '' : 'avroFailureReason',
        subBuilder: IngestionFailureEvent_AvroFailureReason.create)
    ..aOM<IngestionFailureEvent_ApiViolationReason>(
        6, _omitFieldNames ? '' : 'apiViolationReason',
        subBuilder: IngestionFailureEvent_ApiViolationReason.create)
    ..aOM<IngestionFailureEvent_SchemaViolationReason>(
        7, _omitFieldNames ? '' : 'schemaViolationReason',
        subBuilder: IngestionFailureEvent_SchemaViolationReason.create)
    ..aOM<IngestionFailureEvent_MessageTransformationFailureReason>(
        8, _omitFieldNames ? '' : 'messageTransformationFailureReason',
        subBuilder:
            IngestionFailureEvent_MessageTransformationFailureReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_CloudStorageFailure clone() =>
      IngestionFailureEvent_CloudStorageFailure()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_CloudStorageFailure copyWith(
          void Function(IngestionFailureEvent_CloudStorageFailure) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_CloudStorageFailure))
          as IngestionFailureEvent_CloudStorageFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_CloudStorageFailure create() =>
      IngestionFailureEvent_CloudStorageFailure._();
  @$core.override
  IngestionFailureEvent_CloudStorageFailure createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_CloudStorageFailure>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_CloudStorageFailure>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_CloudStorageFailure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_CloudStorageFailure>(create);
  static IngestionFailureEvent_CloudStorageFailure? _defaultInstance;

  IngestionFailureEvent_CloudStorageFailure_Reason whichReason() =>
      _IngestionFailureEvent_CloudStorageFailure_ReasonByTag[$_whichOneof(0)]!;
  void clearReason() => $_clearField($_whichOneof(0));

  /// Optional. Name of the Cloud Storage bucket used for ingestion.
  @$pb.TagNumber(1)
  $core.String get bucket => $_getSZ(0);
  @$pb.TagNumber(1)
  set bucket($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBucket() => $_clearField(1);

  /// Optional. Name of the Cloud Storage object which contained the section
  /// that couldn't be ingested.
  @$pb.TagNumber(2)
  $core.String get objectName => $_getSZ(1);
  @$pb.TagNumber(2)
  set objectName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasObjectName() => $_has(1);
  @$pb.TagNumber(2)
  void clearObjectName() => $_clearField(2);

  /// Optional. Generation of the Cloud Storage object which contained the
  /// section that couldn't be ingested.
  @$pb.TagNumber(3)
  $fixnum.Int64 get objectGeneration => $_getI64(2);
  @$pb.TagNumber(3)
  set objectGeneration($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasObjectGeneration() => $_has(2);
  @$pb.TagNumber(3)
  void clearObjectGeneration() => $_clearField(3);

  /// Optional. Failure encountered when parsing an Avro file.
  @$pb.TagNumber(5)
  IngestionFailureEvent_AvroFailureReason get avroFailureReason => $_getN(3);
  @$pb.TagNumber(5)
  set avroFailureReason(IngestionFailureEvent_AvroFailureReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAvroFailureReason() => $_has(3);
  @$pb.TagNumber(5)
  void clearAvroFailureReason() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_AvroFailureReason ensureAvroFailureReason() =>
      $_ensure(3);

  /// Optional. The Pub/Sub API limits prevented the desired message from
  /// being published.
  @$pb.TagNumber(6)
  IngestionFailureEvent_ApiViolationReason get apiViolationReason => $_getN(4);
  @$pb.TagNumber(6)
  set apiViolationReason(IngestionFailureEvent_ApiViolationReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasApiViolationReason() => $_has(4);
  @$pb.TagNumber(6)
  void clearApiViolationReason() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_ApiViolationReason ensureApiViolationReason() =>
      $_ensure(4);

  /// Optional. The Pub/Sub message failed schema validation.
  @$pb.TagNumber(7)
  IngestionFailureEvent_SchemaViolationReason get schemaViolationReason =>
      $_getN(5);
  @$pb.TagNumber(7)
  set schemaViolationReason(
          IngestionFailureEvent_SchemaViolationReason value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasSchemaViolationReason() => $_has(5);
  @$pb.TagNumber(7)
  void clearSchemaViolationReason() => $_clearField(7);
  @$pb.TagNumber(7)
  IngestionFailureEvent_SchemaViolationReason ensureSchemaViolationReason() =>
      $_ensure(5);

  /// Optional. Failure encountered when applying a message transformation to
  /// the Pub/Sub message.
  @$pb.TagNumber(8)
  IngestionFailureEvent_MessageTransformationFailureReason
      get messageTransformationFailureReason => $_getN(6);
  @$pb.TagNumber(8)
  set messageTransformationFailureReason(
          IngestionFailureEvent_MessageTransformationFailureReason value) =>
      $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMessageTransformationFailureReason() => $_has(6);
  @$pb.TagNumber(8)
  void clearMessageTransformationFailureReason() => $_clearField(8);
  @$pb.TagNumber(8)
  IngestionFailureEvent_MessageTransformationFailureReason
      ensureMessageTransformationFailureReason() => $_ensure(6);
}

enum IngestionFailureEvent_AwsMskFailureReason_Reason {
  apiViolationReason,
  schemaViolationReason,
  messageTransformationFailureReason,
  notSet
}

/// Failure when ingesting from an Amazon MSK source.
class IngestionFailureEvent_AwsMskFailureReason extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_AwsMskFailureReason({
    $core.String? clusterArn,
    $core.String? kafkaTopic,
    $fixnum.Int64? partitionId,
    $fixnum.Int64? offset,
    IngestionFailureEvent_ApiViolationReason? apiViolationReason,
    IngestionFailureEvent_SchemaViolationReason? schemaViolationReason,
    IngestionFailureEvent_MessageTransformationFailureReason?
        messageTransformationFailureReason,
  }) {
    final result = create();
    if (clusterArn != null) result.clusterArn = clusterArn;
    if (kafkaTopic != null) result.kafkaTopic = kafkaTopic;
    if (partitionId != null) result.partitionId = partitionId;
    if (offset != null) result.offset = offset;
    if (apiViolationReason != null)
      result.apiViolationReason = apiViolationReason;
    if (schemaViolationReason != null)
      result.schemaViolationReason = schemaViolationReason;
    if (messageTransformationFailureReason != null)
      result.messageTransformationFailureReason =
          messageTransformationFailureReason;
    return result;
  }

  IngestionFailureEvent_AwsMskFailureReason._();

  factory IngestionFailureEvent_AwsMskFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_AwsMskFailureReason.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionFailureEvent_AwsMskFailureReason_Reason>
      _IngestionFailureEvent_AwsMskFailureReason_ReasonByTag = {
    5: IngestionFailureEvent_AwsMskFailureReason_Reason.apiViolationReason,
    6: IngestionFailureEvent_AwsMskFailureReason_Reason.schemaViolationReason,
    7: IngestionFailureEvent_AwsMskFailureReason_Reason
        .messageTransformationFailureReason,
    0: IngestionFailureEvent_AwsMskFailureReason_Reason.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.AwsMskFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'clusterArn')
    ..aOS(2, _omitFieldNames ? '' : 'kafkaTopic')
    ..aInt64(3, _omitFieldNames ? '' : 'partitionId')
    ..aInt64(4, _omitFieldNames ? '' : 'offset')
    ..aOM<IngestionFailureEvent_ApiViolationReason>(
        5, _omitFieldNames ? '' : 'apiViolationReason',
        subBuilder: IngestionFailureEvent_ApiViolationReason.create)
    ..aOM<IngestionFailureEvent_SchemaViolationReason>(
        6, _omitFieldNames ? '' : 'schemaViolationReason',
        subBuilder: IngestionFailureEvent_SchemaViolationReason.create)
    ..aOM<IngestionFailureEvent_MessageTransformationFailureReason>(
        7, _omitFieldNames ? '' : 'messageTransformationFailureReason',
        subBuilder:
            IngestionFailureEvent_MessageTransformationFailureReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AwsMskFailureReason clone() =>
      IngestionFailureEvent_AwsMskFailureReason()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AwsMskFailureReason copyWith(
          void Function(IngestionFailureEvent_AwsMskFailureReason) updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_AwsMskFailureReason))
          as IngestionFailureEvent_AwsMskFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AwsMskFailureReason create() =>
      IngestionFailureEvent_AwsMskFailureReason._();
  @$core.override
  IngestionFailureEvent_AwsMskFailureReason createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent_AwsMskFailureReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_AwsMskFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AwsMskFailureReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_AwsMskFailureReason>(create);
  static IngestionFailureEvent_AwsMskFailureReason? _defaultInstance;

  IngestionFailureEvent_AwsMskFailureReason_Reason whichReason() =>
      _IngestionFailureEvent_AwsMskFailureReason_ReasonByTag[$_whichOneof(0)]!;
  void clearReason() => $_clearField($_whichOneof(0));

  /// Optional. The ARN of the cluster of the topic being ingested from.
  @$pb.TagNumber(1)
  $core.String get clusterArn => $_getSZ(0);
  @$pb.TagNumber(1)
  set clusterArn($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClusterArn() => $_has(0);
  @$pb.TagNumber(1)
  void clearClusterArn() => $_clearField(1);

  /// Optional. The name of the Kafka topic being ingested from.
  @$pb.TagNumber(2)
  $core.String get kafkaTopic => $_getSZ(1);
  @$pb.TagNumber(2)
  set kafkaTopic($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKafkaTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearKafkaTopic() => $_clearField(2);

  /// Optional. The partition ID of the message that failed to be ingested.
  @$pb.TagNumber(3)
  $fixnum.Int64 get partitionId => $_getI64(2);
  @$pb.TagNumber(3)
  set partitionId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPartitionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPartitionId() => $_clearField(3);

  /// Optional. The offset within the partition of the message that failed to
  /// be ingested.
  @$pb.TagNumber(4)
  $fixnum.Int64 get offset => $_getI64(3);
  @$pb.TagNumber(4)
  set offset($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);

  /// Optional. The Pub/Sub API limits prevented the desired message from
  /// being published.
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason get apiViolationReason => $_getN(4);
  @$pb.TagNumber(5)
  set apiViolationReason(IngestionFailureEvent_ApiViolationReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasApiViolationReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearApiViolationReason() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason ensureApiViolationReason() =>
      $_ensure(4);

  /// Optional. The Pub/Sub message failed schema validation.
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason get schemaViolationReason =>
      $_getN(5);
  @$pb.TagNumber(6)
  set schemaViolationReason(
          IngestionFailureEvent_SchemaViolationReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSchemaViolationReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearSchemaViolationReason() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason ensureSchemaViolationReason() =>
      $_ensure(5);

  /// Optional. Failure encountered when applying a message transformation to
  /// the Pub/Sub message.
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      get messageTransformationFailureReason => $_getN(6);
  @$pb.TagNumber(7)
  set messageTransformationFailureReason(
          IngestionFailureEvent_MessageTransformationFailureReason value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMessageTransformationFailureReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessageTransformationFailureReason() => $_clearField(7);
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      ensureMessageTransformationFailureReason() => $_ensure(6);
}

enum IngestionFailureEvent_AzureEventHubsFailureReason_Reason {
  apiViolationReason,
  schemaViolationReason,
  messageTransformationFailureReason,
  notSet
}

/// Failure when ingesting from an Azure Event Hubs source.
class IngestionFailureEvent_AzureEventHubsFailureReason
    extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_AzureEventHubsFailureReason({
    $core.String? namespace,
    $core.String? eventHub,
    $fixnum.Int64? partitionId,
    $fixnum.Int64? offset,
    IngestionFailureEvent_ApiViolationReason? apiViolationReason,
    IngestionFailureEvent_SchemaViolationReason? schemaViolationReason,
    IngestionFailureEvent_MessageTransformationFailureReason?
        messageTransformationFailureReason,
  }) {
    final result = create();
    if (namespace != null) result.namespace = namespace;
    if (eventHub != null) result.eventHub = eventHub;
    if (partitionId != null) result.partitionId = partitionId;
    if (offset != null) result.offset = offset;
    if (apiViolationReason != null)
      result.apiViolationReason = apiViolationReason;
    if (schemaViolationReason != null)
      result.schemaViolationReason = schemaViolationReason;
    if (messageTransformationFailureReason != null)
      result.messageTransformationFailureReason =
          messageTransformationFailureReason;
    return result;
  }

  IngestionFailureEvent_AzureEventHubsFailureReason._();

  factory IngestionFailureEvent_AzureEventHubsFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_AzureEventHubsFailureReason.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionFailureEvent_AzureEventHubsFailureReason_Reason>
      _IngestionFailureEvent_AzureEventHubsFailureReason_ReasonByTag = {
    5: IngestionFailureEvent_AzureEventHubsFailureReason_Reason
        .apiViolationReason,
    6: IngestionFailureEvent_AzureEventHubsFailureReason_Reason
        .schemaViolationReason,
    7: IngestionFailureEvent_AzureEventHubsFailureReason_Reason
        .messageTransformationFailureReason,
    0: IngestionFailureEvent_AzureEventHubsFailureReason_Reason.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionFailureEvent.AzureEventHubsFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'namespace')
    ..aOS(2, _omitFieldNames ? '' : 'eventHub')
    ..aInt64(3, _omitFieldNames ? '' : 'partitionId')
    ..aInt64(4, _omitFieldNames ? '' : 'offset')
    ..aOM<IngestionFailureEvent_ApiViolationReason>(
        5, _omitFieldNames ? '' : 'apiViolationReason',
        subBuilder: IngestionFailureEvent_ApiViolationReason.create)
    ..aOM<IngestionFailureEvent_SchemaViolationReason>(
        6, _omitFieldNames ? '' : 'schemaViolationReason',
        subBuilder: IngestionFailureEvent_SchemaViolationReason.create)
    ..aOM<IngestionFailureEvent_MessageTransformationFailureReason>(
        7, _omitFieldNames ? '' : 'messageTransformationFailureReason',
        subBuilder:
            IngestionFailureEvent_MessageTransformationFailureReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AzureEventHubsFailureReason clone() =>
      IngestionFailureEvent_AzureEventHubsFailureReason()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AzureEventHubsFailureReason copyWith(
          void Function(IngestionFailureEvent_AzureEventHubsFailureReason)
              updates) =>
      super.copyWith((message) => updates(
              message as IngestionFailureEvent_AzureEventHubsFailureReason))
          as IngestionFailureEvent_AzureEventHubsFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AzureEventHubsFailureReason create() =>
      IngestionFailureEvent_AzureEventHubsFailureReason._();
  @$core.override
  IngestionFailureEvent_AzureEventHubsFailureReason createEmptyInstance() =>
      create();
  static $pb.PbList<IngestionFailureEvent_AzureEventHubsFailureReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_AzureEventHubsFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AzureEventHubsFailureReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_AzureEventHubsFailureReason>(create);
  static IngestionFailureEvent_AzureEventHubsFailureReason? _defaultInstance;

  IngestionFailureEvent_AzureEventHubsFailureReason_Reason whichReason() =>
      _IngestionFailureEvent_AzureEventHubsFailureReason_ReasonByTag[
          $_whichOneof(0)]!;
  void clearReason() => $_clearField($_whichOneof(0));

  /// Optional. The namespace containing the event hub being ingested from.
  @$pb.TagNumber(1)
  $core.String get namespace => $_getSZ(0);
  @$pb.TagNumber(1)
  set namespace($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNamespace() => $_has(0);
  @$pb.TagNumber(1)
  void clearNamespace() => $_clearField(1);

  /// Optional. The name of the event hub being ingested from.
  @$pb.TagNumber(2)
  $core.String get eventHub => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventHub($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventHub() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventHub() => $_clearField(2);

  /// Optional. The partition ID of the message that failed to be ingested.
  @$pb.TagNumber(3)
  $fixnum.Int64 get partitionId => $_getI64(2);
  @$pb.TagNumber(3)
  set partitionId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPartitionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPartitionId() => $_clearField(3);

  /// Optional. The offset within the partition of the message that failed to
  /// be ingested.
  @$pb.TagNumber(4)
  $fixnum.Int64 get offset => $_getI64(3);
  @$pb.TagNumber(4)
  set offset($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);

  /// Optional. The Pub/Sub API limits prevented the desired message from
  /// being published.
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason get apiViolationReason => $_getN(4);
  @$pb.TagNumber(5)
  set apiViolationReason(IngestionFailureEvent_ApiViolationReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasApiViolationReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearApiViolationReason() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason ensureApiViolationReason() =>
      $_ensure(4);

  /// Optional. The Pub/Sub message failed schema validation.
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason get schemaViolationReason =>
      $_getN(5);
  @$pb.TagNumber(6)
  set schemaViolationReason(
          IngestionFailureEvent_SchemaViolationReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSchemaViolationReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearSchemaViolationReason() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason ensureSchemaViolationReason() =>
      $_ensure(5);

  /// Optional. Failure encountered when applying a message transformation to
  /// the Pub/Sub message.
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      get messageTransformationFailureReason => $_getN(6);
  @$pb.TagNumber(7)
  set messageTransformationFailureReason(
          IngestionFailureEvent_MessageTransformationFailureReason value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMessageTransformationFailureReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessageTransformationFailureReason() => $_clearField(7);
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      ensureMessageTransformationFailureReason() => $_ensure(6);
}

enum IngestionFailureEvent_ConfluentCloudFailureReason_Reason {
  apiViolationReason,
  schemaViolationReason,
  messageTransformationFailureReason,
  notSet
}

/// Failure when ingesting from a Confluent Cloud source.
class IngestionFailureEvent_ConfluentCloudFailureReason
    extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_ConfluentCloudFailureReason({
    $core.String? clusterId,
    $core.String? kafkaTopic,
    $fixnum.Int64? partitionId,
    $fixnum.Int64? offset,
    IngestionFailureEvent_ApiViolationReason? apiViolationReason,
    IngestionFailureEvent_SchemaViolationReason? schemaViolationReason,
    IngestionFailureEvent_MessageTransformationFailureReason?
        messageTransformationFailureReason,
  }) {
    final result = create();
    if (clusterId != null) result.clusterId = clusterId;
    if (kafkaTopic != null) result.kafkaTopic = kafkaTopic;
    if (partitionId != null) result.partitionId = partitionId;
    if (offset != null) result.offset = offset;
    if (apiViolationReason != null)
      result.apiViolationReason = apiViolationReason;
    if (schemaViolationReason != null)
      result.schemaViolationReason = schemaViolationReason;
    if (messageTransformationFailureReason != null)
      result.messageTransformationFailureReason =
          messageTransformationFailureReason;
    return result;
  }

  IngestionFailureEvent_ConfluentCloudFailureReason._();

  factory IngestionFailureEvent_ConfluentCloudFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_ConfluentCloudFailureReason.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionFailureEvent_ConfluentCloudFailureReason_Reason>
      _IngestionFailureEvent_ConfluentCloudFailureReason_ReasonByTag = {
    5: IngestionFailureEvent_ConfluentCloudFailureReason_Reason
        .apiViolationReason,
    6: IngestionFailureEvent_ConfluentCloudFailureReason_Reason
        .schemaViolationReason,
    7: IngestionFailureEvent_ConfluentCloudFailureReason_Reason
        .messageTransformationFailureReason,
    0: IngestionFailureEvent_ConfluentCloudFailureReason_Reason.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'IngestionFailureEvent.ConfluentCloudFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'clusterId')
    ..aOS(2, _omitFieldNames ? '' : 'kafkaTopic')
    ..aInt64(3, _omitFieldNames ? '' : 'partitionId')
    ..aInt64(4, _omitFieldNames ? '' : 'offset')
    ..aOM<IngestionFailureEvent_ApiViolationReason>(
        5, _omitFieldNames ? '' : 'apiViolationReason',
        subBuilder: IngestionFailureEvent_ApiViolationReason.create)
    ..aOM<IngestionFailureEvent_SchemaViolationReason>(
        6, _omitFieldNames ? '' : 'schemaViolationReason',
        subBuilder: IngestionFailureEvent_SchemaViolationReason.create)
    ..aOM<IngestionFailureEvent_MessageTransformationFailureReason>(
        7, _omitFieldNames ? '' : 'messageTransformationFailureReason',
        subBuilder:
            IngestionFailureEvent_MessageTransformationFailureReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_ConfluentCloudFailureReason clone() =>
      IngestionFailureEvent_ConfluentCloudFailureReason()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_ConfluentCloudFailureReason copyWith(
          void Function(IngestionFailureEvent_ConfluentCloudFailureReason)
              updates) =>
      super.copyWith((message) => updates(
              message as IngestionFailureEvent_ConfluentCloudFailureReason))
          as IngestionFailureEvent_ConfluentCloudFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_ConfluentCloudFailureReason create() =>
      IngestionFailureEvent_ConfluentCloudFailureReason._();
  @$core.override
  IngestionFailureEvent_ConfluentCloudFailureReason createEmptyInstance() =>
      create();
  static $pb.PbList<IngestionFailureEvent_ConfluentCloudFailureReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_ConfluentCloudFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_ConfluentCloudFailureReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_ConfluentCloudFailureReason>(create);
  static IngestionFailureEvent_ConfluentCloudFailureReason? _defaultInstance;

  IngestionFailureEvent_ConfluentCloudFailureReason_Reason whichReason() =>
      _IngestionFailureEvent_ConfluentCloudFailureReason_ReasonByTag[
          $_whichOneof(0)]!;
  void clearReason() => $_clearField($_whichOneof(0));

  /// Optional. The cluster ID containing the topic being ingested from.
  @$pb.TagNumber(1)
  $core.String get clusterId => $_getSZ(0);
  @$pb.TagNumber(1)
  set clusterId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasClusterId() => $_has(0);
  @$pb.TagNumber(1)
  void clearClusterId() => $_clearField(1);

  /// Optional. The name of the Kafka topic being ingested from.
  @$pb.TagNumber(2)
  $core.String get kafkaTopic => $_getSZ(1);
  @$pb.TagNumber(2)
  set kafkaTopic($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKafkaTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearKafkaTopic() => $_clearField(2);

  /// Optional. The partition ID of the message that failed to be ingested.
  @$pb.TagNumber(3)
  $fixnum.Int64 get partitionId => $_getI64(2);
  @$pb.TagNumber(3)
  set partitionId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPartitionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearPartitionId() => $_clearField(3);

  /// Optional. The offset within the partition of the message that failed to
  /// be ingested.
  @$pb.TagNumber(4)
  $fixnum.Int64 get offset => $_getI64(3);
  @$pb.TagNumber(4)
  set offset($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOffset() => $_has(3);
  @$pb.TagNumber(4)
  void clearOffset() => $_clearField(4);

  /// Optional. The Pub/Sub API limits prevented the desired message from
  /// being published.
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason get apiViolationReason => $_getN(4);
  @$pb.TagNumber(5)
  set apiViolationReason(IngestionFailureEvent_ApiViolationReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasApiViolationReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearApiViolationReason() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_ApiViolationReason ensureApiViolationReason() =>
      $_ensure(4);

  /// Optional. The Pub/Sub message failed schema validation.
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason get schemaViolationReason =>
      $_getN(5);
  @$pb.TagNumber(6)
  set schemaViolationReason(
          IngestionFailureEvent_SchemaViolationReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSchemaViolationReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearSchemaViolationReason() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_SchemaViolationReason ensureSchemaViolationReason() =>
      $_ensure(5);

  /// Optional. Failure encountered when applying a message transformation to
  /// the Pub/Sub message.
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      get messageTransformationFailureReason => $_getN(6);
  @$pb.TagNumber(7)
  set messageTransformationFailureReason(
          IngestionFailureEvent_MessageTransformationFailureReason value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMessageTransformationFailureReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearMessageTransformationFailureReason() => $_clearField(7);
  @$pb.TagNumber(7)
  IngestionFailureEvent_MessageTransformationFailureReason
      ensureMessageTransformationFailureReason() => $_ensure(6);
}

enum IngestionFailureEvent_AwsKinesisFailureReason_Reason {
  schemaViolationReason,
  messageTransformationFailureReason,
  apiViolationReason,
  notSet
}

/// Failure when ingesting from an AWS Kinesis source.
class IngestionFailureEvent_AwsKinesisFailureReason
    extends $pb.GeneratedMessage {
  factory IngestionFailureEvent_AwsKinesisFailureReason({
    $core.String? streamArn,
    $core.String? partitionKey,
    $core.String? sequenceNumber,
    IngestionFailureEvent_SchemaViolationReason? schemaViolationReason,
    IngestionFailureEvent_MessageTransformationFailureReason?
        messageTransformationFailureReason,
    IngestionFailureEvent_ApiViolationReason? apiViolationReason,
  }) {
    final result = create();
    if (streamArn != null) result.streamArn = streamArn;
    if (partitionKey != null) result.partitionKey = partitionKey;
    if (sequenceNumber != null) result.sequenceNumber = sequenceNumber;
    if (schemaViolationReason != null)
      result.schemaViolationReason = schemaViolationReason;
    if (messageTransformationFailureReason != null)
      result.messageTransformationFailureReason =
          messageTransformationFailureReason;
    if (apiViolationReason != null)
      result.apiViolationReason = apiViolationReason;
    return result;
  }

  IngestionFailureEvent_AwsKinesisFailureReason._();

  factory IngestionFailureEvent_AwsKinesisFailureReason.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent_AwsKinesisFailureReason.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, IngestionFailureEvent_AwsKinesisFailureReason_Reason>
      _IngestionFailureEvent_AwsKinesisFailureReason_ReasonByTag = {
    4: IngestionFailureEvent_AwsKinesisFailureReason_Reason
        .schemaViolationReason,
    5: IngestionFailureEvent_AwsKinesisFailureReason_Reason
        .messageTransformationFailureReason,
    6: IngestionFailureEvent_AwsKinesisFailureReason_Reason.apiViolationReason,
    0: IngestionFailureEvent_AwsKinesisFailureReason_Reason.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent.AwsKinesisFailureReason',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5, 6])
    ..aOS(1, _omitFieldNames ? '' : 'streamArn')
    ..aOS(2, _omitFieldNames ? '' : 'partitionKey')
    ..aOS(3, _omitFieldNames ? '' : 'sequenceNumber')
    ..aOM<IngestionFailureEvent_SchemaViolationReason>(
        4, _omitFieldNames ? '' : 'schemaViolationReason',
        subBuilder: IngestionFailureEvent_SchemaViolationReason.create)
    ..aOM<IngestionFailureEvent_MessageTransformationFailureReason>(
        5, _omitFieldNames ? '' : 'messageTransformationFailureReason',
        subBuilder:
            IngestionFailureEvent_MessageTransformationFailureReason.create)
    ..aOM<IngestionFailureEvent_ApiViolationReason>(
        6, _omitFieldNames ? '' : 'apiViolationReason',
        subBuilder: IngestionFailureEvent_ApiViolationReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AwsKinesisFailureReason clone() =>
      IngestionFailureEvent_AwsKinesisFailureReason()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent_AwsKinesisFailureReason copyWith(
          void Function(IngestionFailureEvent_AwsKinesisFailureReason)
              updates) =>
      super.copyWith((message) =>
              updates(message as IngestionFailureEvent_AwsKinesisFailureReason))
          as IngestionFailureEvent_AwsKinesisFailureReason;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AwsKinesisFailureReason create() =>
      IngestionFailureEvent_AwsKinesisFailureReason._();
  @$core.override
  IngestionFailureEvent_AwsKinesisFailureReason createEmptyInstance() =>
      create();
  static $pb.PbList<IngestionFailureEvent_AwsKinesisFailureReason>
      createRepeated() =>
          $pb.PbList<IngestionFailureEvent_AwsKinesisFailureReason>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent_AwsKinesisFailureReason getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          IngestionFailureEvent_AwsKinesisFailureReason>(create);
  static IngestionFailureEvent_AwsKinesisFailureReason? _defaultInstance;

  IngestionFailureEvent_AwsKinesisFailureReason_Reason whichReason() =>
      _IngestionFailureEvent_AwsKinesisFailureReason_ReasonByTag[
          $_whichOneof(0)]!;
  void clearReason() => $_clearField($_whichOneof(0));

  /// Optional. The stream ARN of the Kinesis stream being ingested from.
  @$pb.TagNumber(1)
  $core.String get streamArn => $_getSZ(0);
  @$pb.TagNumber(1)
  set streamArn($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStreamArn() => $_has(0);
  @$pb.TagNumber(1)
  void clearStreamArn() => $_clearField(1);

  /// Optional. The partition key of the message that failed to be ingested.
  @$pb.TagNumber(2)
  $core.String get partitionKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set partitionKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPartitionKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPartitionKey() => $_clearField(2);

  /// Optional. The sequence number of the message that failed to be ingested.
  @$pb.TagNumber(3)
  $core.String get sequenceNumber => $_getSZ(2);
  @$pb.TagNumber(3)
  set sequenceNumber($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequenceNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequenceNumber() => $_clearField(3);

  /// Optional. The Pub/Sub message failed schema validation.
  @$pb.TagNumber(4)
  IngestionFailureEvent_SchemaViolationReason get schemaViolationReason =>
      $_getN(3);
  @$pb.TagNumber(4)
  set schemaViolationReason(
          IngestionFailureEvent_SchemaViolationReason value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSchemaViolationReason() => $_has(3);
  @$pb.TagNumber(4)
  void clearSchemaViolationReason() => $_clearField(4);
  @$pb.TagNumber(4)
  IngestionFailureEvent_SchemaViolationReason ensureSchemaViolationReason() =>
      $_ensure(3);

  /// Optional. Failure encountered when applying a message transformation to
  /// the Pub/Sub message.
  @$pb.TagNumber(5)
  IngestionFailureEvent_MessageTransformationFailureReason
      get messageTransformationFailureReason => $_getN(4);
  @$pb.TagNumber(5)
  set messageTransformationFailureReason(
          IngestionFailureEvent_MessageTransformationFailureReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasMessageTransformationFailureReason() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessageTransformationFailureReason() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_MessageTransformationFailureReason
      ensureMessageTransformationFailureReason() => $_ensure(4);

  /// Optional. The message failed to be published due to an API violation.
  /// This is only set when the size of the data field of the Kinesis record
  /// is zero.
  @$pb.TagNumber(6)
  IngestionFailureEvent_ApiViolationReason get apiViolationReason => $_getN(5);
  @$pb.TagNumber(6)
  set apiViolationReason(IngestionFailureEvent_ApiViolationReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasApiViolationReason() => $_has(5);
  @$pb.TagNumber(6)
  void clearApiViolationReason() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_ApiViolationReason ensureApiViolationReason() =>
      $_ensure(5);
}

enum IngestionFailureEvent_Failure {
  cloudStorageFailure,
  awsMskFailure,
  azureEventHubsFailure,
  confluentCloudFailure,
  awsKinesisFailure,
  notSet
}

/// Payload of the Platform Log entry sent when a failure is encountered while
/// ingesting.
class IngestionFailureEvent extends $pb.GeneratedMessage {
  factory IngestionFailureEvent({
    $core.String? topic,
    $core.String? errorMessage,
    IngestionFailureEvent_CloudStorageFailure? cloudStorageFailure,
    IngestionFailureEvent_AwsMskFailureReason? awsMskFailure,
    IngestionFailureEvent_AzureEventHubsFailureReason? azureEventHubsFailure,
    IngestionFailureEvent_ConfluentCloudFailureReason? confluentCloudFailure,
    IngestionFailureEvent_AwsKinesisFailureReason? awsKinesisFailure,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    if (errorMessage != null) result.errorMessage = errorMessage;
    if (cloudStorageFailure != null)
      result.cloudStorageFailure = cloudStorageFailure;
    if (awsMskFailure != null) result.awsMskFailure = awsMskFailure;
    if (azureEventHubsFailure != null)
      result.azureEventHubsFailure = azureEventHubsFailure;
    if (confluentCloudFailure != null)
      result.confluentCloudFailure = confluentCloudFailure;
    if (awsKinesisFailure != null) result.awsKinesisFailure = awsKinesisFailure;
    return result;
  }

  IngestionFailureEvent._();

  factory IngestionFailureEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory IngestionFailureEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, IngestionFailureEvent_Failure>
      _IngestionFailureEvent_FailureByTag = {
    3: IngestionFailureEvent_Failure.cloudStorageFailure,
    4: IngestionFailureEvent_Failure.awsMskFailure,
    5: IngestionFailureEvent_Failure.azureEventHubsFailure,
    6: IngestionFailureEvent_Failure.confluentCloudFailure,
    7: IngestionFailureEvent_Failure.awsKinesisFailure,
    0: IngestionFailureEvent_Failure.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'IngestionFailureEvent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5, 6, 7])
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..aOS(2, _omitFieldNames ? '' : 'errorMessage')
    ..aOM<IngestionFailureEvent_CloudStorageFailure>(
        3, _omitFieldNames ? '' : 'cloudStorageFailure',
        subBuilder: IngestionFailureEvent_CloudStorageFailure.create)
    ..aOM<IngestionFailureEvent_AwsMskFailureReason>(
        4, _omitFieldNames ? '' : 'awsMskFailure',
        subBuilder: IngestionFailureEvent_AwsMskFailureReason.create)
    ..aOM<IngestionFailureEvent_AzureEventHubsFailureReason>(
        5, _omitFieldNames ? '' : 'azureEventHubsFailure',
        subBuilder: IngestionFailureEvent_AzureEventHubsFailureReason.create)
    ..aOM<IngestionFailureEvent_ConfluentCloudFailureReason>(
        6, _omitFieldNames ? '' : 'confluentCloudFailure',
        subBuilder: IngestionFailureEvent_ConfluentCloudFailureReason.create)
    ..aOM<IngestionFailureEvent_AwsKinesisFailureReason>(
        7, _omitFieldNames ? '' : 'awsKinesisFailure',
        subBuilder: IngestionFailureEvent_AwsKinesisFailureReason.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent clone() =>
      IngestionFailureEvent()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  IngestionFailureEvent copyWith(
          void Function(IngestionFailureEvent) updates) =>
      super.copyWith((message) => updates(message as IngestionFailureEvent))
          as IngestionFailureEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent create() => IngestionFailureEvent._();
  @$core.override
  IngestionFailureEvent createEmptyInstance() => create();
  static $pb.PbList<IngestionFailureEvent> createRepeated() =>
      $pb.PbList<IngestionFailureEvent>();
  @$core.pragma('dart2js:noInline')
  static IngestionFailureEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<IngestionFailureEvent>(create);
  static IngestionFailureEvent? _defaultInstance;

  IngestionFailureEvent_Failure whichFailure() =>
      _IngestionFailureEvent_FailureByTag[$_whichOneof(0)]!;
  void clearFailure() => $_clearField($_whichOneof(0));

  /// Required. Name of the import topic. Format is:
  /// projects/{project_name}/topics/{topic_name}.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);

  /// Required. Error details explaining why ingestion to Pub/Sub has failed.
  @$pb.TagNumber(2)
  $core.String get errorMessage => $_getSZ(1);
  @$pb.TagNumber(2)
  set errorMessage($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrorMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrorMessage() => $_clearField(2);

  /// Optional. Failure when ingesting from Cloud Storage.
  @$pb.TagNumber(3)
  IngestionFailureEvent_CloudStorageFailure get cloudStorageFailure =>
      $_getN(2);
  @$pb.TagNumber(3)
  set cloudStorageFailure(IngestionFailureEvent_CloudStorageFailure value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCloudStorageFailure() => $_has(2);
  @$pb.TagNumber(3)
  void clearCloudStorageFailure() => $_clearField(3);
  @$pb.TagNumber(3)
  IngestionFailureEvent_CloudStorageFailure ensureCloudStorageFailure() =>
      $_ensure(2);

  /// Optional. Failure when ingesting from Amazon MSK.
  @$pb.TagNumber(4)
  IngestionFailureEvent_AwsMskFailureReason get awsMskFailure => $_getN(3);
  @$pb.TagNumber(4)
  set awsMskFailure(IngestionFailureEvent_AwsMskFailureReason value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAwsMskFailure() => $_has(3);
  @$pb.TagNumber(4)
  void clearAwsMskFailure() => $_clearField(4);
  @$pb.TagNumber(4)
  IngestionFailureEvent_AwsMskFailureReason ensureAwsMskFailure() =>
      $_ensure(3);

  /// Optional. Failure when ingesting from Azure Event Hubs.
  @$pb.TagNumber(5)
  IngestionFailureEvent_AzureEventHubsFailureReason get azureEventHubsFailure =>
      $_getN(4);
  @$pb.TagNumber(5)
  set azureEventHubsFailure(
          IngestionFailureEvent_AzureEventHubsFailureReason value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAzureEventHubsFailure() => $_has(4);
  @$pb.TagNumber(5)
  void clearAzureEventHubsFailure() => $_clearField(5);
  @$pb.TagNumber(5)
  IngestionFailureEvent_AzureEventHubsFailureReason
      ensureAzureEventHubsFailure() => $_ensure(4);

  /// Optional. Failure when ingesting from Confluent Cloud.
  @$pb.TagNumber(6)
  IngestionFailureEvent_ConfluentCloudFailureReason get confluentCloudFailure =>
      $_getN(5);
  @$pb.TagNumber(6)
  set confluentCloudFailure(
          IngestionFailureEvent_ConfluentCloudFailureReason value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasConfluentCloudFailure() => $_has(5);
  @$pb.TagNumber(6)
  void clearConfluentCloudFailure() => $_clearField(6);
  @$pb.TagNumber(6)
  IngestionFailureEvent_ConfluentCloudFailureReason
      ensureConfluentCloudFailure() => $_ensure(5);

  /// Optional. Failure when ingesting from AWS Kinesis.
  @$pb.TagNumber(7)
  IngestionFailureEvent_AwsKinesisFailureReason get awsKinesisFailure =>
      $_getN(6);
  @$pb.TagNumber(7)
  set awsKinesisFailure(IngestionFailureEvent_AwsKinesisFailureReason value) =>
      $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAwsKinesisFailure() => $_has(6);
  @$pb.TagNumber(7)
  void clearAwsKinesisFailure() => $_clearField(7);
  @$pb.TagNumber(7)
  IngestionFailureEvent_AwsKinesisFailureReason ensureAwsKinesisFailure() =>
      $_ensure(6);
}

/// User-defined JavaScript function that can transform or filter a Pub/Sub
/// message.
class JavaScriptUDF extends $pb.GeneratedMessage {
  factory JavaScriptUDF({
    $core.String? functionName,
    $core.String? code,
  }) {
    final result = create();
    if (functionName != null) result.functionName = functionName;
    if (code != null) result.code = code;
    return result;
  }

  JavaScriptUDF._();

  factory JavaScriptUDF.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory JavaScriptUDF.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'JavaScriptUDF',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'functionName')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JavaScriptUDF clone() => JavaScriptUDF()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  JavaScriptUDF copyWith(void Function(JavaScriptUDF) updates) =>
      super.copyWith((message) => updates(message as JavaScriptUDF))
          as JavaScriptUDF;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static JavaScriptUDF create() => JavaScriptUDF._();
  @$core.override
  JavaScriptUDF createEmptyInstance() => create();
  static $pb.PbList<JavaScriptUDF> createRepeated() =>
      $pb.PbList<JavaScriptUDF>();
  @$core.pragma('dart2js:noInline')
  static JavaScriptUDF getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<JavaScriptUDF>(create);
  static JavaScriptUDF? _defaultInstance;

  /// Required. Name of the JavasScript function that should applied to Pub/Sub
  /// messages.
  @$pb.TagNumber(1)
  $core.String get functionName => $_getSZ(0);
  @$pb.TagNumber(1)
  set functionName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFunctionName() => $_has(0);
  @$pb.TagNumber(1)
  void clearFunctionName() => $_clearField(1);

  /// Required. JavaScript code that contains a function `function_name` with the
  /// below signature:
  ///
  /// ```
  ///   /**
  ///   * Transforms a Pub/Sub message.
  ///
  ///   * @return {(Object<string, (string | Object<string, string>)>|null)} - To
  ///   * filter a message, return `null`. To transform a message return a map
  ///   * with the following keys:
  ///   *   - (required) 'data' : {string}
  ///   *   - (optional) 'attributes' : {Object<string, string>}
  ///   * Returning empty `attributes` will remove all attributes from the
  ///   * message.
  ///   *
  ///   * @param  {(Object<string, (string | Object<string, string>)>} Pub/Sub
  ///   * message. Keys:
  ///   *   - (required) 'data' : {string}
  ///   *   - (required) 'attributes' : {Object<string, string>}
  ///   *
  ///   * @param  {Object<string, any>} metadata - Pub/Sub message metadata.
  ///   * Keys:
  ///   *   - (optional) 'message_id'  : {string}
  ///   *   - (optional) 'publish_time': {string} YYYY-MM-DDTHH:MM:SSZ format
  ///   *   - (optional) 'ordering_key': {string}
  ///   */
  ///
  ///   function <function_name>(message, metadata) {
  ///   }
  /// ```
  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);
}

/// Configuration for making inferences using arbitrary JSON payloads.
class AIInference_UnstructuredInference extends $pb.GeneratedMessage {
  factory AIInference_UnstructuredInference({
    $3.Struct? parameters,
  }) {
    final result = create();
    if (parameters != null) result.parameters = parameters;
    return result;
  }

  AIInference_UnstructuredInference._();

  factory AIInference_UnstructuredInference.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AIInference_UnstructuredInference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AIInference.UnstructuredInference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<$3.Struct>(1, _omitFieldNames ? '' : 'parameters',
        subBuilder: $3.Struct.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AIInference_UnstructuredInference clone() =>
      AIInference_UnstructuredInference()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AIInference_UnstructuredInference copyWith(
          void Function(AIInference_UnstructuredInference) updates) =>
      super.copyWith((message) =>
              updates(message as AIInference_UnstructuredInference))
          as AIInference_UnstructuredInference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AIInference_UnstructuredInference create() =>
      AIInference_UnstructuredInference._();
  @$core.override
  AIInference_UnstructuredInference createEmptyInstance() => create();
  static $pb.PbList<AIInference_UnstructuredInference> createRepeated() =>
      $pb.PbList<AIInference_UnstructuredInference>();
  @$core.pragma('dart2js:noInline')
  static AIInference_UnstructuredInference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AIInference_UnstructuredInference>(
          create);
  static AIInference_UnstructuredInference? _defaultInstance;

  /// Optional. A parameters object to be included in each inference request.
  /// The parameters object is combined with the data field of the Pub/Sub
  /// message to form the inference request.
  @$pb.TagNumber(1)
  $3.Struct get parameters => $_getN(0);
  @$pb.TagNumber(1)
  set parameters($3.Struct value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasParameters() => $_has(0);
  @$pb.TagNumber(1)
  void clearParameters() => $_clearField(1);
  @$pb.TagNumber(1)
  $3.Struct ensureParameters() => $_ensure(0);
}

enum AIInference_InferenceMode { unstructuredInference, notSet }

/// Configuration for making inference requests against Vertex AI models.
class AIInference extends $pb.GeneratedMessage {
  factory AIInference({
    $core.String? endpoint,
    AIInference_UnstructuredInference? unstructuredInference,
    $core.String? serviceAccountEmail,
  }) {
    final result = create();
    if (endpoint != null) result.endpoint = endpoint;
    if (unstructuredInference != null)
      result.unstructuredInference = unstructuredInference;
    if (serviceAccountEmail != null)
      result.serviceAccountEmail = serviceAccountEmail;
    return result;
  }

  AIInference._();

  factory AIInference.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AIInference.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, AIInference_InferenceMode>
      _AIInference_InferenceModeByTag = {
    2: AIInference_InferenceMode.unstructuredInference,
    0: AIInference_InferenceMode.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AIInference',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [2])
    ..aOS(1, _omitFieldNames ? '' : 'endpoint')
    ..aOM<AIInference_UnstructuredInference>(
        2, _omitFieldNames ? '' : 'unstructuredInference',
        subBuilder: AIInference_UnstructuredInference.create)
    ..aOS(3, _omitFieldNames ? '' : 'serviceAccountEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AIInference clone() => AIInference()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AIInference copyWith(void Function(AIInference) updates) =>
      super.copyWith((message) => updates(message as AIInference))
          as AIInference;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AIInference create() => AIInference._();
  @$core.override
  AIInference createEmptyInstance() => create();
  static $pb.PbList<AIInference> createRepeated() => $pb.PbList<AIInference>();
  @$core.pragma('dart2js:noInline')
  static AIInference getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AIInference>(create);
  static AIInference? _defaultInstance;

  AIInference_InferenceMode whichInferenceMode() =>
      _AIInference_InferenceModeByTag[$_whichOneof(0)]!;
  void clearInferenceMode() => $_clearField($_whichOneof(0));

  /// Required. An endpoint to a Vertex AI model of the form
  /// `projects/{project}/locations/{location}/endpoints/{endpoint}` or
  /// `projects/{project}/locations/{location}/publishers/{publisher}/models/{model}`.
  /// Vertex AI API requests will be sent to this endpoint.
  @$pb.TagNumber(1)
  $core.String get endpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set endpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearEndpoint() => $_clearField(1);

  /// Optional. Requests and responses can be any arbitrary JSON object.
  @$pb.TagNumber(2)
  AIInference_UnstructuredInference get unstructuredInference => $_getN(1);
  @$pb.TagNumber(2)
  set unstructuredInference(AIInference_UnstructuredInference value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUnstructuredInference() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnstructuredInference() => $_clearField(2);
  @$pb.TagNumber(2)
  AIInference_UnstructuredInference ensureUnstructuredInference() =>
      $_ensure(1);

  /// Optional. The service account to use to make prediction requests against
  /// endpoints. The resource creator or updater that specifies this field must
  /// have `iam.serviceAccounts.actAs` permission on the service account. If not
  /// specified, the Pub/Sub [service
  /// agent](https://cloud.google.com/iam/docs/service-agents),
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com, is used.
  @$pb.TagNumber(3)
  $core.String get serviceAccountEmail => $_getSZ(2);
  @$pb.TagNumber(3)
  set serviceAccountEmail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServiceAccountEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearServiceAccountEmail() => $_clearField(3);
}

enum MessageTransform_Transform { javascriptUdf, aiInference, notSet }

/// All supported message transforms types.
class MessageTransform extends $pb.GeneratedMessage {
  factory MessageTransform({
    JavaScriptUDF? javascriptUdf,
    @$core.Deprecated('This field is deprecated.') $core.bool? enabled,
    $core.bool? disabled,
    AIInference? aiInference,
  }) {
    final result = create();
    if (javascriptUdf != null) result.javascriptUdf = javascriptUdf;
    if (enabled != null) result.enabled = enabled;
    if (disabled != null) result.disabled = disabled;
    if (aiInference != null) result.aiInference = aiInference;
    return result;
  }

  MessageTransform._();

  factory MessageTransform.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageTransform.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, MessageTransform_Transform>
      _MessageTransform_TransformByTag = {
    2: MessageTransform_Transform.javascriptUdf,
    6: MessageTransform_Transform.aiInference,
    0: MessageTransform_Transform.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageTransform',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 6])
    ..aOM<JavaScriptUDF>(2, _omitFieldNames ? '' : 'javascriptUdf',
        subBuilder: JavaScriptUDF.create)
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..aOB(4, _omitFieldNames ? '' : 'disabled')
    ..aOM<AIInference>(6, _omitFieldNames ? '' : 'aiInference',
        subBuilder: AIInference.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTransform clone() => MessageTransform()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageTransform copyWith(void Function(MessageTransform) updates) =>
      super.copyWith((message) => updates(message as MessageTransform))
          as MessageTransform;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageTransform create() => MessageTransform._();
  @$core.override
  MessageTransform createEmptyInstance() => create();
  static $pb.PbList<MessageTransform> createRepeated() =>
      $pb.PbList<MessageTransform>();
  @$core.pragma('dart2js:noInline')
  static MessageTransform getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageTransform>(create);
  static MessageTransform? _defaultInstance;

  MessageTransform_Transform whichTransform() =>
      _MessageTransform_TransformByTag[$_whichOneof(0)]!;
  void clearTransform() => $_clearField($_whichOneof(0));

  /// Optional. JavaScript User Defined Function. If multiple JavaScriptUDF's
  /// are specified on a resource, each must have a unique `function_name`.
  @$pb.TagNumber(2)
  JavaScriptUDF get javascriptUdf => $_getN(0);
  @$pb.TagNumber(2)
  set javascriptUdf(JavaScriptUDF value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasJavascriptUdf() => $_has(0);
  @$pb.TagNumber(2)
  void clearJavascriptUdf() => $_clearField(2);
  @$pb.TagNumber(2)
  JavaScriptUDF ensureJavascriptUdf() => $_ensure(0);

  /// Optional. This field is deprecated, use the `disabled` field to disable
  /// transforms.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(1, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);

  /// Optional. If true, the transform is disabled and will not be applied to
  /// messages. Defaults to `false`.
  @$pb.TagNumber(4)
  $core.bool get disabled => $_getBF(2);
  @$pb.TagNumber(4)
  set disabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(4)
  $core.bool hasDisabled() => $_has(2);
  @$pb.TagNumber(4)
  void clearDisabled() => $_clearField(4);

  /// Optional. AI Inference. Specifies the Vertex AI endpoint that inference
  /// requests built from the Pub/Sub message data and provided parameters will
  /// be sent to.
  @$pb.TagNumber(6)
  AIInference get aiInference => $_getN(3);
  @$pb.TagNumber(6)
  set aiInference(AIInference value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasAiInference() => $_has(3);
  @$pb.TagNumber(6)
  void clearAiInference() => $_clearField(6);
  @$pb.TagNumber(6)
  AIInference ensureAiInference() => $_ensure(3);
}

/// A topic resource.
class Topic extends $pb.GeneratedMessage {
  factory Topic({
    $core.String? name,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? labels,
    MessageStoragePolicy? messageStoragePolicy,
    $core.String? kmsKeyName,
    SchemaSettings? schemaSettings,
    $core.bool? satisfiesPzs,
    $4.Duration? messageRetentionDuration,
    Topic_State? state,
    IngestionDataSourceSettings? ingestionDataSourceSettings,
    $core.Iterable<MessageTransform>? messageTransforms,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? tags,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (labels != null) result.labels.addEntries(labels);
    if (messageStoragePolicy != null)
      result.messageStoragePolicy = messageStoragePolicy;
    if (kmsKeyName != null) result.kmsKeyName = kmsKeyName;
    if (schemaSettings != null) result.schemaSettings = schemaSettings;
    if (satisfiesPzs != null) result.satisfiesPzs = satisfiesPzs;
    if (messageRetentionDuration != null)
      result.messageRetentionDuration = messageRetentionDuration;
    if (state != null) result.state = state;
    if (ingestionDataSourceSettings != null)
      result.ingestionDataSourceSettings = ingestionDataSourceSettings;
    if (messageTransforms != null)
      result.messageTransforms.addAll(messageTransforms);
    if (tags != null) result.tags.addEntries(tags);
    return result;
  }

  Topic._();

  factory Topic.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Topic.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Topic',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'labels',
        entryClassName: 'Topic.LabelsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..aOM<MessageStoragePolicy>(
        3, _omitFieldNames ? '' : 'messageStoragePolicy',
        subBuilder: MessageStoragePolicy.create)
    ..aOS(5, _omitFieldNames ? '' : 'kmsKeyName')
    ..aOM<SchemaSettings>(6, _omitFieldNames ? '' : 'schemaSettings',
        subBuilder: SchemaSettings.create)
    ..aOB(7, _omitFieldNames ? '' : 'satisfiesPzs')
    ..aOM<$4.Duration>(8, _omitFieldNames ? '' : 'messageRetentionDuration',
        subBuilder: $4.Duration.create)
    ..e<Topic_State>(9, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: Topic_State.STATE_UNSPECIFIED,
        valueOf: Topic_State.valueOf,
        enumValues: Topic_State.values)
    ..aOM<IngestionDataSourceSettings>(
        10, _omitFieldNames ? '' : 'ingestionDataSourceSettings',
        subBuilder: IngestionDataSourceSettings.create)
    ..pc<MessageTransform>(
        13, _omitFieldNames ? '' : 'messageTransforms', $pb.PbFieldType.PM,
        subBuilder: MessageTransform.create)
    ..m<$core.String, $core.String>(14, _omitFieldNames ? '' : 'tags',
        entryClassName: 'Topic.TagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Topic clone() => Topic()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Topic copyWith(void Function(Topic) updates) =>
      super.copyWith((message) => updates(message as Topic)) as Topic;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Topic create() => Topic._();
  @$core.override
  Topic createEmptyInstance() => create();
  static $pb.PbList<Topic> createRepeated() => $pb.PbList<Topic>();
  @$core.pragma('dart2js:noInline')
  static Topic getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Topic>(create);
  static Topic? _defaultInstance;

  /// Required. Identifier. The name of the topic. It must have the format
  /// `"projects/{project}/topics/{topic}"`. `{topic}` must start with a letter,
  /// and contain only letters (`[A-Za-z]`), numbers (`[0-9]`), dashes (`-`),
  /// underscores (`_`), periods (`.`), tildes (`~`), plus (`+`) or percent
  /// signs (`%`). It must be between 3 and 255 characters in length, and it
  /// must not start with `"goog"`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Optional. See [Creating and managing labels]
  /// (https://cloud.google.com/pubsub/docs/labels).
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get labels => $_getMap(1);

  /// Optional. Policy constraining the set of Google Cloud Platform regions
  /// where messages published to the topic may be stored. If not present, then
  /// no constraints are in effect.
  @$pb.TagNumber(3)
  MessageStoragePolicy get messageStoragePolicy => $_getN(2);
  @$pb.TagNumber(3)
  set messageStoragePolicy(MessageStoragePolicy value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageStoragePolicy() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageStoragePolicy() => $_clearField(3);
  @$pb.TagNumber(3)
  MessageStoragePolicy ensureMessageStoragePolicy() => $_ensure(2);

  /// Optional. The resource name of the Cloud KMS CryptoKey to be used to
  /// protect access to messages published on this topic.
  ///
  /// The expected format is `projects/*/locations/*/keyRings/*/cryptoKeys/*`.
  @$pb.TagNumber(5)
  $core.String get kmsKeyName => $_getSZ(3);
  @$pb.TagNumber(5)
  set kmsKeyName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(5)
  $core.bool hasKmsKeyName() => $_has(3);
  @$pb.TagNumber(5)
  void clearKmsKeyName() => $_clearField(5);

  /// Optional. Settings for validating messages published against a schema.
  @$pb.TagNumber(6)
  SchemaSettings get schemaSettings => $_getN(4);
  @$pb.TagNumber(6)
  set schemaSettings(SchemaSettings value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSchemaSettings() => $_has(4);
  @$pb.TagNumber(6)
  void clearSchemaSettings() => $_clearField(6);
  @$pb.TagNumber(6)
  SchemaSettings ensureSchemaSettings() => $_ensure(4);

  /// Optional. Reserved for future use. This field is set only in responses from
  /// the server; it is ignored if it is set in any requests.
  @$pb.TagNumber(7)
  $core.bool get satisfiesPzs => $_getBF(5);
  @$pb.TagNumber(7)
  set satisfiesPzs($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(7)
  $core.bool hasSatisfiesPzs() => $_has(5);
  @$pb.TagNumber(7)
  void clearSatisfiesPzs() => $_clearField(7);

  /// Optional. Indicates the minimum duration to retain a message after it is
  /// published to the topic. If this field is set, messages published to the
  /// topic in the last `message_retention_duration` are always available to
  /// subscribers. For instance, it allows any attached subscription to [seek to
  /// a
  /// timestamp](https://cloud.google.com/pubsub/docs/replay-overview#seek_to_a_time)
  /// that is up to `message_retention_duration` in the past. If this field is
  /// not set, message retention is controlled by settings on individual
  /// subscriptions. Cannot be more than 31 days or less than 10 minutes.
  @$pb.TagNumber(8)
  $4.Duration get messageRetentionDuration => $_getN(6);
  @$pb.TagNumber(8)
  set messageRetentionDuration($4.Duration value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMessageRetentionDuration() => $_has(6);
  @$pb.TagNumber(8)
  void clearMessageRetentionDuration() => $_clearField(8);
  @$pb.TagNumber(8)
  $4.Duration ensureMessageRetentionDuration() => $_ensure(6);

  /// Output only. An output-only field indicating the state of the topic.
  @$pb.TagNumber(9)
  Topic_State get state => $_getN(7);
  @$pb.TagNumber(9)
  set state(Topic_State value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasState() => $_has(7);
  @$pb.TagNumber(9)
  void clearState() => $_clearField(9);

  /// Optional. Settings for ingestion from a data source into this topic.
  @$pb.TagNumber(10)
  IngestionDataSourceSettings get ingestionDataSourceSettings => $_getN(8);
  @$pb.TagNumber(10)
  set ingestionDataSourceSettings(IngestionDataSourceSettings value) =>
      $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasIngestionDataSourceSettings() => $_has(8);
  @$pb.TagNumber(10)
  void clearIngestionDataSourceSettings() => $_clearField(10);
  @$pb.TagNumber(10)
  IngestionDataSourceSettings ensureIngestionDataSourceSettings() =>
      $_ensure(8);

  /// Optional. Transforms to be applied to messages published to the topic.
  /// Transforms are applied in the order specified.
  @$pb.TagNumber(13)
  $pb.PbList<MessageTransform> get messageTransforms => $_getList(9);

  /// Optional. Input only. Immutable. Tag keys/values directly bound to this
  /// resource. For example:
  ///   "123/environment": "production",
  ///   "123/costCenter": "marketing"
  /// See https://docs.cloud.google.com/pubsub/docs/tags for more information on
  /// using tags with Pub/Sub resources.
  @$pb.TagNumber(14)
  $pb.PbMap<$core.String, $core.String> get tags => $_getMap(10);
}

/// A message that is published by publishers and consumed by subscribers. The
/// message must contain either a non-empty data field or at least one attribute.
/// Note that client libraries represent this object differently
/// depending on the language. See the corresponding [client library
/// documentation](https://cloud.google.com/pubsub/docs/reference/libraries) for
/// more information. See [quotas and limits]
/// (https://cloud.google.com/pubsub/quotas) for more information about message
/// limits.
class PubsubMessage extends $pb.GeneratedMessage {
  factory PubsubMessage({
    $core.List<$core.int>? data,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attributes,
    $core.String? messageId,
    $2.Timestamp? publishTime,
    $core.String? orderingKey,
  }) {
    final result = create();
    if (data != null) result.data = data;
    if (attributes != null) result.attributes.addEntries(attributes);
    if (messageId != null) result.messageId = messageId;
    if (publishTime != null) result.publishTime = publishTime;
    if (orderingKey != null) result.orderingKey = orderingKey;
    return result;
  }

  PubsubMessage._();

  factory PubsubMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PubsubMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PubsubMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'attributes',
        entryClassName: 'PubsubMessage.AttributesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..aOS(3, _omitFieldNames ? '' : 'messageId')
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'publishTime',
        subBuilder: $2.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'orderingKey')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PubsubMessage clone() => PubsubMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PubsubMessage copyWith(void Function(PubsubMessage) updates) =>
      super.copyWith((message) => updates(message as PubsubMessage))
          as PubsubMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PubsubMessage create() => PubsubMessage._();
  @$core.override
  PubsubMessage createEmptyInstance() => create();
  static $pb.PbList<PubsubMessage> createRepeated() =>
      $pb.PbList<PubsubMessage>();
  @$core.pragma('dart2js:noInline')
  static PubsubMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PubsubMessage>(create);
  static PubsubMessage? _defaultInstance;

  /// Optional. The message data field. If this field is empty, the message must
  /// contain at least one attribute.
  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  /// Optional. Attributes for this message. If this field is empty, the message
  /// must contain non-empty data. This can be used to filter messages on the
  /// subscription.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get attributes => $_getMap(1);

  /// ID of this message, assigned by the server when the message is published.
  /// Guaranteed to be unique within the topic. This value may be read by a
  /// subscriber that receives a `PubsubMessage` via a `Pull` call or a push
  /// delivery. It must not be populated by the publisher in a `Publish` call.
  @$pb.TagNumber(3)
  $core.String get messageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set messageId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessageId() => $_clearField(3);

  /// The time at which the message was published, populated by the server when
  /// it receives the `Publish` call. It must not be populated by the
  /// publisher in a `Publish` call.
  @$pb.TagNumber(4)
  $2.Timestamp get publishTime => $_getN(3);
  @$pb.TagNumber(4)
  set publishTime($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPublishTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearPublishTime() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensurePublishTime() => $_ensure(3);

  /// Optional. If non-empty, identifies related messages for which publish order
  /// should be respected. If a `Subscription` has `enable_message_ordering` set
  /// to `true`, messages published with the same non-empty `ordering_key` value
  /// will be delivered to subscribers in the order in which they are received by
  /// the Pub/Sub system. All `PubsubMessage`s published in a given
  /// `PublishRequest` must specify the same `ordering_key` value. For more
  /// information, see [ordering
  /// messages](https://cloud.google.com/pubsub/docs/ordering).
  @$pb.TagNumber(5)
  $core.String get orderingKey => $_getSZ(4);
  @$pb.TagNumber(5)
  set orderingKey($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOrderingKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearOrderingKey() => $_clearField(5);
}

/// Request for the GetTopic method.
class GetTopicRequest extends $pb.GeneratedMessage {
  factory GetTopicRequest({
    $core.String? topic,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    return result;
  }

  GetTopicRequest._();

  factory GetTopicRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetTopicRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTopicRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTopicRequest clone() => GetTopicRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTopicRequest copyWith(void Function(GetTopicRequest) updates) =>
      super.copyWith((message) => updates(message as GetTopicRequest))
          as GetTopicRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTopicRequest create() => GetTopicRequest._();
  @$core.override
  GetTopicRequest createEmptyInstance() => create();
  static $pb.PbList<GetTopicRequest> createRepeated() =>
      $pb.PbList<GetTopicRequest>();
  @$core.pragma('dart2js:noInline')
  static GetTopicRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTopicRequest>(create);
  static GetTopicRequest? _defaultInstance;

  /// Required. The name of the topic to get.
  /// Format is `projects/{project}/topics/{topic}`.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);
}

/// Request for the UpdateTopic method.
class UpdateTopicRequest extends $pb.GeneratedMessage {
  factory UpdateTopicRequest({
    Topic? topic,
    $5.FieldMask? updateMask,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateTopicRequest._();

  factory UpdateTopicRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateTopicRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateTopicRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<Topic>(1, _omitFieldNames ? '' : 'topic', subBuilder: Topic.create)
    ..aOM<$5.FieldMask>(2, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $5.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTopicRequest clone() => UpdateTopicRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateTopicRequest copyWith(void Function(UpdateTopicRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateTopicRequest))
          as UpdateTopicRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateTopicRequest create() => UpdateTopicRequest._();
  @$core.override
  UpdateTopicRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateTopicRequest> createRepeated() =>
      $pb.PbList<UpdateTopicRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateTopicRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateTopicRequest>(create);
  static UpdateTopicRequest? _defaultInstance;

  /// Required. The updated topic object.
  @$pb.TagNumber(1)
  Topic get topic => $_getN(0);
  @$pb.TagNumber(1)
  set topic(Topic value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);
  @$pb.TagNumber(1)
  Topic ensureTopic() => $_ensure(0);

  /// Required. Indicates which fields in the provided topic to update. Must be
  /// specified and non-empty. Note that if `update_mask` contains
  /// "message_storage_policy" but the `message_storage_policy` is not set in
  /// the `topic` provided above, then the updated value is determined by the
  /// policy configured at the project or organization level.
  @$pb.TagNumber(2)
  $5.FieldMask get updateMask => $_getN(1);
  @$pb.TagNumber(2)
  set updateMask($5.FieldMask value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateMask() => $_clearField(2);
  @$pb.TagNumber(2)
  $5.FieldMask ensureUpdateMask() => $_ensure(1);
}

/// Request for the Publish method.
class PublishRequest extends $pb.GeneratedMessage {
  factory PublishRequest({
    $core.String? topic,
    $core.Iterable<PubsubMessage>? messages,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  PublishRequest._();

  factory PublishRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..pc<PubsubMessage>(
        2, _omitFieldNames ? '' : 'messages', $pb.PbFieldType.PM,
        subBuilder: PubsubMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishRequest clone() => PublishRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishRequest copyWith(void Function(PublishRequest) updates) =>
      super.copyWith((message) => updates(message as PublishRequest))
          as PublishRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishRequest create() => PublishRequest._();
  @$core.override
  PublishRequest createEmptyInstance() => create();
  static $pb.PbList<PublishRequest> createRepeated() =>
      $pb.PbList<PublishRequest>();
  @$core.pragma('dart2js:noInline')
  static PublishRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishRequest>(create);
  static PublishRequest? _defaultInstance;

  /// Required. The messages in the request will be published on this topic.
  /// Format is `projects/{project}/topics/{topic}`.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);

  /// Required. The messages to publish.
  @$pb.TagNumber(2)
  $pb.PbList<PubsubMessage> get messages => $_getList(1);
}

/// Response for the `Publish` method.
class PublishResponse extends $pb.GeneratedMessage {
  factory PublishResponse({
    $core.Iterable<$core.String>? messageIds,
  }) {
    final result = create();
    if (messageIds != null) result.messageIds.addAll(messageIds);
    return result;
  }

  PublishResponse._();

  factory PublishResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublishResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublishResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'messageIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishResponse clone() => PublishResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublishResponse copyWith(void Function(PublishResponse) updates) =>
      super.copyWith((message) => updates(message as PublishResponse))
          as PublishResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublishResponse create() => PublishResponse._();
  @$core.override
  PublishResponse createEmptyInstance() => create();
  static $pb.PbList<PublishResponse> createRepeated() =>
      $pb.PbList<PublishResponse>();
  @$core.pragma('dart2js:noInline')
  static PublishResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublishResponse>(create);
  static PublishResponse? _defaultInstance;

  /// Optional. The server-assigned ID of each published message, in the same
  /// order as the messages in the request. IDs are guaranteed to be unique
  /// within the topic.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get messageIds => $_getList(0);
}

/// Request for the `ListTopics` method.
class ListTopicsRequest extends $pb.GeneratedMessage {
  factory ListTopicsRequest({
    $core.String? project,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (project != null) result.project = project;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListTopicsRequest._();

  factory ListTopicsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicsRequest clone() => ListTopicsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicsRequest copyWith(void Function(ListTopicsRequest) updates) =>
      super.copyWith((message) => updates(message as ListTopicsRequest))
          as ListTopicsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicsRequest create() => ListTopicsRequest._();
  @$core.override
  ListTopicsRequest createEmptyInstance() => create();
  static $pb.PbList<ListTopicsRequest> createRepeated() =>
      $pb.PbList<ListTopicsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListTopicsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicsRequest>(create);
  static ListTopicsRequest? _defaultInstance;

  /// Required. The name of the project in which to list topics.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);

  /// Optional. Maximum number of topics to return.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// Optional. The value returned by the last `ListTopicsResponse`; indicates
  /// that this is a continuation of a prior `ListTopics` call, and that the
  /// system should return the next page of data.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Response for the `ListTopics` method.
class ListTopicsResponse extends $pb.GeneratedMessage {
  factory ListTopicsResponse({
    $core.Iterable<Topic>? topics,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (topics != null) result.topics.addAll(topics);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListTopicsResponse._();

  factory ListTopicsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<Topic>(1, _omitFieldNames ? '' : 'topics', $pb.PbFieldType.PM,
        subBuilder: Topic.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicsResponse clone() => ListTopicsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicsResponse copyWith(void Function(ListTopicsResponse) updates) =>
      super.copyWith((message) => updates(message as ListTopicsResponse))
          as ListTopicsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicsResponse create() => ListTopicsResponse._();
  @$core.override
  ListTopicsResponse createEmptyInstance() => create();
  static $pb.PbList<ListTopicsResponse> createRepeated() =>
      $pb.PbList<ListTopicsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListTopicsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicsResponse>(create);
  static ListTopicsResponse? _defaultInstance;

  /// Optional. The resulting topics.
  @$pb.TagNumber(1)
  $pb.PbList<Topic> get topics => $_getList(0);

  /// Optional. If not empty, indicates that there may be more topics that match
  /// the request; this value should be passed in a new `ListTopicsRequest`.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the `ListTopicSubscriptions` method.
class ListTopicSubscriptionsRequest extends $pb.GeneratedMessage {
  factory ListTopicSubscriptionsRequest({
    $core.String? topic,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListTopicSubscriptionsRequest._();

  factory ListTopicSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicSubscriptionsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSubscriptionsRequest clone() =>
      ListTopicSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSubscriptionsRequest copyWith(
          void Function(ListTopicSubscriptionsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListTopicSubscriptionsRequest))
          as ListTopicSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicSubscriptionsRequest create() =>
      ListTopicSubscriptionsRequest._();
  @$core.override
  ListTopicSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListTopicSubscriptionsRequest> createRepeated() =>
      $pb.PbList<ListTopicSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListTopicSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicSubscriptionsRequest>(create);
  static ListTopicSubscriptionsRequest? _defaultInstance;

  /// Required. The name of the topic that subscriptions are attached to.
  /// Format is `projects/{project}/topics/{topic}`.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);

  /// Optional. Maximum number of subscription names to return.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// Optional. The value returned by the last `ListTopicSubscriptionsResponse`;
  /// indicates that this is a continuation of a prior `ListTopicSubscriptions`
  /// call, and that the system should return the next page of data.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Response for the `ListTopicSubscriptions` method.
class ListTopicSubscriptionsResponse extends $pb.GeneratedMessage {
  factory ListTopicSubscriptionsResponse({
    $core.Iterable<$core.String>? subscriptions,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListTopicSubscriptionsResponse._();

  factory ListTopicSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicSubscriptionsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'subscriptions')
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSubscriptionsResponse clone() =>
      ListTopicSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSubscriptionsResponse copyWith(
          void Function(ListTopicSubscriptionsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListTopicSubscriptionsResponse))
          as ListTopicSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicSubscriptionsResponse create() =>
      ListTopicSubscriptionsResponse._();
  @$core.override
  ListTopicSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListTopicSubscriptionsResponse> createRepeated() =>
      $pb.PbList<ListTopicSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListTopicSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicSubscriptionsResponse>(create);
  static ListTopicSubscriptionsResponse? _defaultInstance;

  /// Optional. The names of subscriptions attached to the topic specified in the
  /// request.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get subscriptions => $_getList(0);

  /// Optional. If not empty, indicates that there may be more subscriptions that
  /// match the request; this value should be passed in a new
  /// `ListTopicSubscriptionsRequest` to get more subscriptions.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the `ListTopicSnapshots` method.
class ListTopicSnapshotsRequest extends $pb.GeneratedMessage {
  factory ListTopicSnapshotsRequest({
    $core.String? topic,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListTopicSnapshotsRequest._();

  factory ListTopicSnapshotsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicSnapshotsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicSnapshotsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSnapshotsRequest clone() =>
      ListTopicSnapshotsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSnapshotsRequest copyWith(
          void Function(ListTopicSnapshotsRequest) updates) =>
      super.copyWith((message) => updates(message as ListTopicSnapshotsRequest))
          as ListTopicSnapshotsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicSnapshotsRequest create() => ListTopicSnapshotsRequest._();
  @$core.override
  ListTopicSnapshotsRequest createEmptyInstance() => create();
  static $pb.PbList<ListTopicSnapshotsRequest> createRepeated() =>
      $pb.PbList<ListTopicSnapshotsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListTopicSnapshotsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicSnapshotsRequest>(create);
  static ListTopicSnapshotsRequest? _defaultInstance;

  /// Required. The name of the topic that snapshots are attached to.
  /// Format is `projects/{project}/topics/{topic}`.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);

  /// Optional. Maximum number of snapshot names to return.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// Optional. The value returned by the last `ListTopicSnapshotsResponse`;
  /// indicates that this is a continuation of a prior `ListTopicSnapshots` call,
  /// and that the system should return the next page of data.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Response for the `ListTopicSnapshots` method.
class ListTopicSnapshotsResponse extends $pb.GeneratedMessage {
  factory ListTopicSnapshotsResponse({
    $core.Iterable<$core.String>? snapshots,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addAll(snapshots);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListTopicSnapshotsResponse._();

  factory ListTopicSnapshotsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListTopicSnapshotsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTopicSnapshotsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'snapshots')
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSnapshotsResponse clone() =>
      ListTopicSnapshotsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTopicSnapshotsResponse copyWith(
          void Function(ListTopicSnapshotsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListTopicSnapshotsResponse))
          as ListTopicSnapshotsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTopicSnapshotsResponse create() => ListTopicSnapshotsResponse._();
  @$core.override
  ListTopicSnapshotsResponse createEmptyInstance() => create();
  static $pb.PbList<ListTopicSnapshotsResponse> createRepeated() =>
      $pb.PbList<ListTopicSnapshotsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListTopicSnapshotsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTopicSnapshotsResponse>(create);
  static ListTopicSnapshotsResponse? _defaultInstance;

  /// Optional. The names of the snapshots that match the request.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get snapshots => $_getList(0);

  /// Optional. If not empty, indicates that there may be more snapshots that
  /// match the request; this value should be passed in a new
  /// `ListTopicSnapshotsRequest` to get more snapshots.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the `DeleteTopic` method.
class DeleteTopicRequest extends $pb.GeneratedMessage {
  factory DeleteTopicRequest({
    $core.String? topic,
  }) {
    final result = create();
    if (topic != null) result.topic = topic;
    return result;
  }

  DeleteTopicRequest._();

  factory DeleteTopicRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteTopicRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTopicRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'topic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTopicRequest clone() => DeleteTopicRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTopicRequest copyWith(void Function(DeleteTopicRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteTopicRequest))
          as DeleteTopicRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteTopicRequest create() => DeleteTopicRequest._();
  @$core.override
  DeleteTopicRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteTopicRequest> createRepeated() =>
      $pb.PbList<DeleteTopicRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteTopicRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteTopicRequest>(create);
  static DeleteTopicRequest? _defaultInstance;

  /// Required. Name of the topic to delete.
  /// Format is `projects/{project}/topics/{topic}`.
  @$pb.TagNumber(1)
  $core.String get topic => $_getSZ(0);
  @$pb.TagNumber(1)
  set topic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearTopic() => $_clearField(1);
}

/// Request for the DetachSubscription method.
class DetachSubscriptionRequest extends $pb.GeneratedMessage {
  factory DetachSubscriptionRequest({
    $core.String? subscription,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    return result;
  }

  DetachSubscriptionRequest._();

  factory DetachSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetachSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetachSubscriptionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetachSubscriptionRequest clone() =>
      DetachSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetachSubscriptionRequest copyWith(
          void Function(DetachSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as DetachSubscriptionRequest))
          as DetachSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetachSubscriptionRequest create() => DetachSubscriptionRequest._();
  @$core.override
  DetachSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<DetachSubscriptionRequest> createRepeated() =>
      $pb.PbList<DetachSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static DetachSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetachSubscriptionRequest>(create);
  static DetachSubscriptionRequest? _defaultInstance;

  /// Required. The subscription to detach.
  /// Format is `projects/{project}/subscriptions/{subscription}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);
}

/// Response for the DetachSubscription method.
/// Reserved for future use.
class DetachSubscriptionResponse extends $pb.GeneratedMessage {
  factory DetachSubscriptionResponse() => create();

  DetachSubscriptionResponse._();

  factory DetachSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DetachSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DetachSubscriptionResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetachSubscriptionResponse clone() =>
      DetachSubscriptionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetachSubscriptionResponse copyWith(
          void Function(DetachSubscriptionResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DetachSubscriptionResponse))
          as DetachSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DetachSubscriptionResponse create() => DetachSubscriptionResponse._();
  @$core.override
  DetachSubscriptionResponse createEmptyInstance() => create();
  static $pb.PbList<DetachSubscriptionResponse> createRepeated() =>
      $pb.PbList<DetachSubscriptionResponse>();
  @$core.pragma('dart2js:noInline')
  static DetachSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetachSubscriptionResponse>(create);
  static DetachSubscriptionResponse? _defaultInstance;
}

/// Information about an associated [Analytics Hub
/// subscription](https://cloud.google.com/bigquery/docs/analytics-hub-manage-subscriptions).
class Subscription_AnalyticsHubSubscriptionInfo extends $pb.GeneratedMessage {
  factory Subscription_AnalyticsHubSubscriptionInfo({
    $core.String? listing,
    $core.String? subscription,
  }) {
    final result = create();
    if (listing != null) result.listing = listing;
    if (subscription != null) result.subscription = subscription;
    return result;
  }

  Subscription_AnalyticsHubSubscriptionInfo._();

  factory Subscription_AnalyticsHubSubscriptionInfo.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Subscription_AnalyticsHubSubscriptionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subscription.AnalyticsHubSubscriptionInfo',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'listing')
    ..aOS(2, _omitFieldNames ? '' : 'subscription')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription_AnalyticsHubSubscriptionInfo clone() =>
      Subscription_AnalyticsHubSubscriptionInfo()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription_AnalyticsHubSubscriptionInfo copyWith(
          void Function(Subscription_AnalyticsHubSubscriptionInfo) updates) =>
      super.copyWith((message) =>
              updates(message as Subscription_AnalyticsHubSubscriptionInfo))
          as Subscription_AnalyticsHubSubscriptionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Subscription_AnalyticsHubSubscriptionInfo create() =>
      Subscription_AnalyticsHubSubscriptionInfo._();
  @$core.override
  Subscription_AnalyticsHubSubscriptionInfo createEmptyInstance() => create();
  static $pb.PbList<Subscription_AnalyticsHubSubscriptionInfo>
      createRepeated() =>
          $pb.PbList<Subscription_AnalyticsHubSubscriptionInfo>();
  @$core.pragma('dart2js:noInline')
  static Subscription_AnalyticsHubSubscriptionInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          Subscription_AnalyticsHubSubscriptionInfo>(create);
  static Subscription_AnalyticsHubSubscriptionInfo? _defaultInstance;

  /// Optional. The name of the associated Analytics Hub listing resource.
  /// Pattern:
  /// "projects/{project}/locations/{location}/dataExchanges/{data_exchange}/listings/{listing}"
  @$pb.TagNumber(1)
  $core.String get listing => $_getSZ(0);
  @$pb.TagNumber(1)
  set listing($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasListing() => $_has(0);
  @$pb.TagNumber(1)
  void clearListing() => $_clearField(1);

  /// Optional. The name of the associated Analytics Hub subscription resource.
  /// Pattern:
  /// "projects/{project}/locations/{location}/subscriptions/{subscription}"
  @$pb.TagNumber(2)
  $core.String get subscription => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscription($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscription() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscription() => $_clearField(2);
}

/// A subscription resource. If none of `push_config`, `bigquery_config`, or
/// `cloud_storage_config` is set, then the subscriber will pull and ack messages
/// using API methods. At most one of these fields may be set.
class Subscription extends $pb.GeneratedMessage {
  factory Subscription({
    $core.String? name,
    $core.String? topic,
    PushConfig? pushConfig,
    $core.int? ackDeadlineSeconds,
    $core.bool? retainAckedMessages,
    $4.Duration? messageRetentionDuration,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? labels,
    $core.bool? enableMessageOrdering,
    ExpirationPolicy? expirationPolicy,
    $core.String? filter,
    DeadLetterPolicy? deadLetterPolicy,
    RetryPolicy? retryPolicy,
    $core.bool? detached,
    $core.bool? enableExactlyOnceDelivery,
    $4.Duration? topicMessageRetentionDuration,
    BigQueryConfig? bigqueryConfig,
    Subscription_State? state,
    CloudStorageConfig? cloudStorageConfig,
    Subscription_AnalyticsHubSubscriptionInfo? analyticsHubSubscriptionInfo,
    $core.Iterable<MessageTransform>? messageTransforms,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? tags,
    BigtableConfig? bigtableConfig,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (topic != null) result.topic = topic;
    if (pushConfig != null) result.pushConfig = pushConfig;
    if (ackDeadlineSeconds != null)
      result.ackDeadlineSeconds = ackDeadlineSeconds;
    if (retainAckedMessages != null)
      result.retainAckedMessages = retainAckedMessages;
    if (messageRetentionDuration != null)
      result.messageRetentionDuration = messageRetentionDuration;
    if (labels != null) result.labels.addEntries(labels);
    if (enableMessageOrdering != null)
      result.enableMessageOrdering = enableMessageOrdering;
    if (expirationPolicy != null) result.expirationPolicy = expirationPolicy;
    if (filter != null) result.filter = filter;
    if (deadLetterPolicy != null) result.deadLetterPolicy = deadLetterPolicy;
    if (retryPolicy != null) result.retryPolicy = retryPolicy;
    if (detached != null) result.detached = detached;
    if (enableExactlyOnceDelivery != null)
      result.enableExactlyOnceDelivery = enableExactlyOnceDelivery;
    if (topicMessageRetentionDuration != null)
      result.topicMessageRetentionDuration = topicMessageRetentionDuration;
    if (bigqueryConfig != null) result.bigqueryConfig = bigqueryConfig;
    if (state != null) result.state = state;
    if (cloudStorageConfig != null)
      result.cloudStorageConfig = cloudStorageConfig;
    if (analyticsHubSubscriptionInfo != null)
      result.analyticsHubSubscriptionInfo = analyticsHubSubscriptionInfo;
    if (messageTransforms != null)
      result.messageTransforms.addAll(messageTransforms);
    if (tags != null) result.tags.addEntries(tags);
    if (bigtableConfig != null) result.bigtableConfig = bigtableConfig;
    return result;
  }

  Subscription._();

  factory Subscription.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Subscription.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Subscription',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'topic')
    ..aOM<PushConfig>(4, _omitFieldNames ? '' : 'pushConfig',
        subBuilder: PushConfig.create)
    ..a<$core.int>(
        5, _omitFieldNames ? '' : 'ackDeadlineSeconds', $pb.PbFieldType.O3)
    ..aOB(7, _omitFieldNames ? '' : 'retainAckedMessages')
    ..aOM<$4.Duration>(8, _omitFieldNames ? '' : 'messageRetentionDuration',
        subBuilder: $4.Duration.create)
    ..m<$core.String, $core.String>(9, _omitFieldNames ? '' : 'labels',
        entryClassName: 'Subscription.LabelsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..aOB(10, _omitFieldNames ? '' : 'enableMessageOrdering')
    ..aOM<ExpirationPolicy>(11, _omitFieldNames ? '' : 'expirationPolicy',
        subBuilder: ExpirationPolicy.create)
    ..aOS(12, _omitFieldNames ? '' : 'filter')
    ..aOM<DeadLetterPolicy>(13, _omitFieldNames ? '' : 'deadLetterPolicy',
        subBuilder: DeadLetterPolicy.create)
    ..aOM<RetryPolicy>(14, _omitFieldNames ? '' : 'retryPolicy',
        subBuilder: RetryPolicy.create)
    ..aOB(15, _omitFieldNames ? '' : 'detached')
    ..aOB(16, _omitFieldNames ? '' : 'enableExactlyOnceDelivery')
    ..aOM<$4.Duration>(
        17, _omitFieldNames ? '' : 'topicMessageRetentionDuration',
        subBuilder: $4.Duration.create)
    ..aOM<BigQueryConfig>(18, _omitFieldNames ? '' : 'bigqueryConfig',
        subBuilder: BigQueryConfig.create)
    ..e<Subscription_State>(
        19, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: Subscription_State.STATE_UNSPECIFIED,
        valueOf: Subscription_State.valueOf,
        enumValues: Subscription_State.values)
    ..aOM<CloudStorageConfig>(22, _omitFieldNames ? '' : 'cloudStorageConfig',
        subBuilder: CloudStorageConfig.create)
    ..aOM<Subscription_AnalyticsHubSubscriptionInfo>(
        23, _omitFieldNames ? '' : 'analyticsHubSubscriptionInfo',
        subBuilder: Subscription_AnalyticsHubSubscriptionInfo.create)
    ..pc<MessageTransform>(
        25, _omitFieldNames ? '' : 'messageTransforms', $pb.PbFieldType.PM,
        subBuilder: MessageTransform.create)
    ..m<$core.String, $core.String>(26, _omitFieldNames ? '' : 'tags',
        entryClassName: 'Subscription.TagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..aOM<BigtableConfig>(27, _omitFieldNames ? '' : 'bigtableConfig',
        subBuilder: BigtableConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription clone() => Subscription()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Subscription copyWith(void Function(Subscription) updates) =>
      super.copyWith((message) => updates(message as Subscription))
          as Subscription;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Subscription create() => Subscription._();
  @$core.override
  Subscription createEmptyInstance() => create();
  static $pb.PbList<Subscription> createRepeated() =>
      $pb.PbList<Subscription>();
  @$core.pragma('dart2js:noInline')
  static Subscription getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Subscription>(create);
  static Subscription? _defaultInstance;

  /// Required. Identifier. The name of the subscription. It must have the format
  /// `"projects/{project}/subscriptions/{subscription}"`. `{subscription}` must
  /// start with a letter, and contain only letters (`[A-Za-z]`), numbers
  /// (`[0-9]`), dashes (`-`), underscores (`_`), periods (`.`), tildes (`~`),
  /// plus (`+`) or percent signs (`%`). It must be between 3 and 255 characters
  /// in length, and it must not start with `"goog"`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Required. The name of the topic from which this subscription is receiving
  /// messages. Format is `projects/{project}/topics/{topic}`. The value of this
  /// field will be `_deleted-topic_` if the topic has been deleted.
  @$pb.TagNumber(2)
  $core.String get topic => $_getSZ(1);
  @$pb.TagNumber(2)
  set topic($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearTopic() => $_clearField(2);

  /// Optional. If push delivery is used with this subscription, this field is
  /// used to configure it.
  @$pb.TagNumber(4)
  PushConfig get pushConfig => $_getN(2);
  @$pb.TagNumber(4)
  set pushConfig(PushConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPushConfig() => $_has(2);
  @$pb.TagNumber(4)
  void clearPushConfig() => $_clearField(4);
  @$pb.TagNumber(4)
  PushConfig ensurePushConfig() => $_ensure(2);

  /// Optional. The approximate amount of time (on a best-effort basis) Pub/Sub
  /// waits for the subscriber to acknowledge receipt before resending the
  /// message. In the interval after the message is delivered and before it is
  /// acknowledged, it is considered to be _outstanding_. During that time
  /// period, the message will not be redelivered (on a best-effort basis).
  ///
  /// For pull subscriptions, this value is used as the initial value for the ack
  /// deadline. To override this value for a given message, call
  /// `ModifyAckDeadline` with the corresponding `ack_id` if using
  /// non-streaming pull or send the `ack_id` in a
  /// `StreamingModifyAckDeadlineRequest` if using streaming pull.
  /// The minimum custom deadline you can specify is 10 seconds.
  /// The maximum custom deadline you can specify is 600 seconds (10 minutes).
  /// If this parameter is 0, a default value of 10 seconds is used.
  ///
  /// For push delivery, this value is also used to set the request timeout for
  /// the call to the push endpoint.
  ///
  /// If the subscriber never acknowledges the message, the Pub/Sub
  /// system will eventually redeliver the message.
  @$pb.TagNumber(5)
  $core.int get ackDeadlineSeconds => $_getIZ(3);
  @$pb.TagNumber(5)
  set ackDeadlineSeconds($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(5)
  $core.bool hasAckDeadlineSeconds() => $_has(3);
  @$pb.TagNumber(5)
  void clearAckDeadlineSeconds() => $_clearField(5);

  /// Optional. Indicates whether to retain acknowledged messages. If true, then
  /// messages are not expunged from the subscription's backlog, even if they are
  /// acknowledged, until they fall out of the `message_retention_duration`
  /// window. This must be true if you would like to [`Seek` to a timestamp]
  /// (https://cloud.google.com/pubsub/docs/replay-overview#seek_to_a_time) in
  /// the past to replay previously-acknowledged messages.
  @$pb.TagNumber(7)
  $core.bool get retainAckedMessages => $_getBF(4);
  @$pb.TagNumber(7)
  set retainAckedMessages($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(7)
  $core.bool hasRetainAckedMessages() => $_has(4);
  @$pb.TagNumber(7)
  void clearRetainAckedMessages() => $_clearField(7);

  /// Optional. How long to retain unacknowledged messages in the subscription's
  /// backlog, from the moment a message is published. If `retain_acked_messages`
  /// is true, then this also configures the retention of acknowledged messages,
  /// and thus configures how far back in time a `Seek` can be done. Defaults to
  /// 7 days. Cannot be more than 31 days or less than 10 minutes.
  @$pb.TagNumber(8)
  $4.Duration get messageRetentionDuration => $_getN(5);
  @$pb.TagNumber(8)
  set messageRetentionDuration($4.Duration value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasMessageRetentionDuration() => $_has(5);
  @$pb.TagNumber(8)
  void clearMessageRetentionDuration() => $_clearField(8);
  @$pb.TagNumber(8)
  $4.Duration ensureMessageRetentionDuration() => $_ensure(5);

  /// Optional. See [Creating and managing
  /// labels](https://cloud.google.com/pubsub/docs/labels).
  @$pb.TagNumber(9)
  $pb.PbMap<$core.String, $core.String> get labels => $_getMap(6);

  /// Optional. If true, messages published with the same `ordering_key` in
  /// `PubsubMessage` will be delivered to the subscribers in the order in which
  /// they are received by the Pub/Sub system. Otherwise, they may be delivered
  /// in any order.
  @$pb.TagNumber(10)
  $core.bool get enableMessageOrdering => $_getBF(7);
  @$pb.TagNumber(10)
  set enableMessageOrdering($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(10)
  $core.bool hasEnableMessageOrdering() => $_has(7);
  @$pb.TagNumber(10)
  void clearEnableMessageOrdering() => $_clearField(10);

  /// Optional. A policy that specifies the conditions for this subscription's
  /// expiration. A subscription is considered active as long as any connected
  /// subscriber is successfully consuming messages from the subscription or is
  /// issuing operations on the subscription. If `expiration_policy` is not set,
  /// a *default policy* with `ttl` of 31 days will be used. The minimum allowed
  /// value for `expiration_policy.ttl` is 1 day. If `expiration_policy` is set,
  /// but `expiration_policy.ttl` is not set, the subscription never expires.
  @$pb.TagNumber(11)
  ExpirationPolicy get expirationPolicy => $_getN(8);
  @$pb.TagNumber(11)
  set expirationPolicy(ExpirationPolicy value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasExpirationPolicy() => $_has(8);
  @$pb.TagNumber(11)
  void clearExpirationPolicy() => $_clearField(11);
  @$pb.TagNumber(11)
  ExpirationPolicy ensureExpirationPolicy() => $_ensure(8);

  /// Optional. An expression written in the Pub/Sub [filter
  /// language](https://cloud.google.com/pubsub/docs/filtering). If non-empty,
  /// then only `PubsubMessage`s whose `attributes` field matches the filter are
  /// delivered on this subscription. If empty, then no messages are filtered
  /// out.
  @$pb.TagNumber(12)
  $core.String get filter => $_getSZ(9);
  @$pb.TagNumber(12)
  set filter($core.String value) => $_setString(9, value);
  @$pb.TagNumber(12)
  $core.bool hasFilter() => $_has(9);
  @$pb.TagNumber(12)
  void clearFilter() => $_clearField(12);

  /// Optional. A policy that specifies the conditions for dead lettering
  /// messages in this subscription. If dead_letter_policy is not set, dead
  /// lettering is disabled.
  ///
  /// The Pub/Sub service account associated with this subscriptions's
  /// parent project (i.e.,
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com) must have
  /// permission to Acknowledge() messages on this subscription.
  @$pb.TagNumber(13)
  DeadLetterPolicy get deadLetterPolicy => $_getN(10);
  @$pb.TagNumber(13)
  set deadLetterPolicy(DeadLetterPolicy value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasDeadLetterPolicy() => $_has(10);
  @$pb.TagNumber(13)
  void clearDeadLetterPolicy() => $_clearField(13);
  @$pb.TagNumber(13)
  DeadLetterPolicy ensureDeadLetterPolicy() => $_ensure(10);

  /// Optional. A policy that specifies how Pub/Sub retries message delivery for
  /// this subscription.
  ///
  /// If not set, the default retry policy is applied. This generally implies
  /// that messages will be retried as soon as possible for healthy subscribers.
  /// RetryPolicy will be triggered on NACKs or acknowledgment deadline exceeded
  /// events for a given message.
  @$pb.TagNumber(14)
  RetryPolicy get retryPolicy => $_getN(11);
  @$pb.TagNumber(14)
  set retryPolicy(RetryPolicy value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasRetryPolicy() => $_has(11);
  @$pb.TagNumber(14)
  void clearRetryPolicy() => $_clearField(14);
  @$pb.TagNumber(14)
  RetryPolicy ensureRetryPolicy() => $_ensure(11);

  /// Optional. Indicates whether the subscription is detached from its topic.
  /// Detached subscriptions don't receive messages from their topic and don't
  /// retain any backlog. `Pull` and `StreamingPull` requests will return
  /// FAILED_PRECONDITION. If the subscription is a push subscription, pushes to
  /// the endpoint will not be made.
  @$pb.TagNumber(15)
  $core.bool get detached => $_getBF(12);
  @$pb.TagNumber(15)
  set detached($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(15)
  $core.bool hasDetached() => $_has(12);
  @$pb.TagNumber(15)
  void clearDetached() => $_clearField(15);

  /// Optional. If true, Pub/Sub provides the following guarantees for the
  /// delivery of a message with a given value of `message_id` on this
  /// subscription:
  ///
  /// * The message sent to a subscriber is guaranteed not to be resent
  /// before the message's acknowledgment deadline expires.
  /// * An acknowledged message will not be resent to a subscriber.
  ///
  /// Note that subscribers may still receive multiple copies of a message
  /// when `enable_exactly_once_delivery` is true if the message was published
  /// multiple times by a publisher client. These copies are  considered distinct
  /// by Pub/Sub and have distinct `message_id` values.
  @$pb.TagNumber(16)
  $core.bool get enableExactlyOnceDelivery => $_getBF(13);
  @$pb.TagNumber(16)
  set enableExactlyOnceDelivery($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(16)
  $core.bool hasEnableExactlyOnceDelivery() => $_has(13);
  @$pb.TagNumber(16)
  void clearEnableExactlyOnceDelivery() => $_clearField(16);

  /// Output only. Indicates the minimum duration for which a message is retained
  /// after it is published to the subscription's topic. If this field is set,
  /// messages published to the subscription's topic in the last
  /// `topic_message_retention_duration` are always available to subscribers. See
  /// the `message_retention_duration` field in `Topic`. This field is set only
  /// in responses from the server; it is ignored if it is set in any requests.
  @$pb.TagNumber(17)
  $4.Duration get topicMessageRetentionDuration => $_getN(14);
  @$pb.TagNumber(17)
  set topicMessageRetentionDuration($4.Duration value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasTopicMessageRetentionDuration() => $_has(14);
  @$pb.TagNumber(17)
  void clearTopicMessageRetentionDuration() => $_clearField(17);
  @$pb.TagNumber(17)
  $4.Duration ensureTopicMessageRetentionDuration() => $_ensure(14);

  /// Optional. If delivery to BigQuery is used with this subscription, this
  /// field is used to configure it.
  @$pb.TagNumber(18)
  BigQueryConfig get bigqueryConfig => $_getN(15);
  @$pb.TagNumber(18)
  set bigqueryConfig(BigQueryConfig value) => $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasBigqueryConfig() => $_has(15);
  @$pb.TagNumber(18)
  void clearBigqueryConfig() => $_clearField(18);
  @$pb.TagNumber(18)
  BigQueryConfig ensureBigqueryConfig() => $_ensure(15);

  /// Output only. An output-only field indicating whether or not the
  /// subscription can receive messages.
  @$pb.TagNumber(19)
  Subscription_State get state => $_getN(16);
  @$pb.TagNumber(19)
  set state(Subscription_State value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasState() => $_has(16);
  @$pb.TagNumber(19)
  void clearState() => $_clearField(19);

  /// Optional. If delivery to Google Cloud Storage is used with this
  /// subscription, this field is used to configure it.
  @$pb.TagNumber(22)
  CloudStorageConfig get cloudStorageConfig => $_getN(17);
  @$pb.TagNumber(22)
  set cloudStorageConfig(CloudStorageConfig value) => $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasCloudStorageConfig() => $_has(17);
  @$pb.TagNumber(22)
  void clearCloudStorageConfig() => $_clearField(22);
  @$pb.TagNumber(22)
  CloudStorageConfig ensureCloudStorageConfig() => $_ensure(17);

  /// Output only. Information about the associated Analytics Hub subscription.
  /// Only set if the subscription is created by Analytics Hub.
  @$pb.TagNumber(23)
  Subscription_AnalyticsHubSubscriptionInfo get analyticsHubSubscriptionInfo =>
      $_getN(18);
  @$pb.TagNumber(23)
  set analyticsHubSubscriptionInfo(
          Subscription_AnalyticsHubSubscriptionInfo value) =>
      $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasAnalyticsHubSubscriptionInfo() => $_has(18);
  @$pb.TagNumber(23)
  void clearAnalyticsHubSubscriptionInfo() => $_clearField(23);
  @$pb.TagNumber(23)
  Subscription_AnalyticsHubSubscriptionInfo
      ensureAnalyticsHubSubscriptionInfo() => $_ensure(18);

  /// Optional. Transforms to be applied to messages before they are delivered to
  /// subscribers. Transforms are applied in the order specified.
  @$pb.TagNumber(25)
  $pb.PbList<MessageTransform> get messageTransforms => $_getList(19);

  /// Optional. Input only. Immutable. Tag keys/values directly bound to this
  /// resource. For example:
  ///   "123/environment": "production",
  ///   "123/costCenter": "marketing"
  /// See https://docs.cloud.google.com/pubsub/docs/tags for more information on
  /// using tags with Pub/Sub resources.
  @$pb.TagNumber(26)
  $pb.PbMap<$core.String, $core.String> get tags => $_getMap(20);

  /// Optional. If delivery to Bigtable is used with this subscription, this
  /// field is used to configure it.
  @$pb.TagNumber(27)
  BigtableConfig get bigtableConfig => $_getN(21);
  @$pb.TagNumber(27)
  set bigtableConfig(BigtableConfig value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasBigtableConfig() => $_has(21);
  @$pb.TagNumber(27)
  void clearBigtableConfig() => $_clearField(27);
  @$pb.TagNumber(27)
  BigtableConfig ensureBigtableConfig() => $_ensure(21);
}

/// A policy that specifies how Pub/Sub retries message delivery.
///
/// Retry delay will be exponential based on provided minimum and maximum
/// backoffs. https://en.wikipedia.org/wiki/Exponential_backoff.
///
/// RetryPolicy will be triggered on NACKs or acknowledgment deadline exceeded
/// events for a given message.
///
/// Retry Policy is implemented on a best effort basis. At times, the delay
/// between consecutive deliveries may not match the configuration. That is,
/// delay can be more or less than configured backoff.
class RetryPolicy extends $pb.GeneratedMessage {
  factory RetryPolicy({
    $4.Duration? minimumBackoff,
    $4.Duration? maximumBackoff,
  }) {
    final result = create();
    if (minimumBackoff != null) result.minimumBackoff = minimumBackoff;
    if (maximumBackoff != null) result.maximumBackoff = maximumBackoff;
    return result;
  }

  RetryPolicy._();

  factory RetryPolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RetryPolicy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RetryPolicy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<$4.Duration>(1, _omitFieldNames ? '' : 'minimumBackoff',
        subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(2, _omitFieldNames ? '' : 'maximumBackoff',
        subBuilder: $4.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryPolicy clone() => RetryPolicy()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RetryPolicy copyWith(void Function(RetryPolicy) updates) =>
      super.copyWith((message) => updates(message as RetryPolicy))
          as RetryPolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RetryPolicy create() => RetryPolicy._();
  @$core.override
  RetryPolicy createEmptyInstance() => create();
  static $pb.PbList<RetryPolicy> createRepeated() => $pb.PbList<RetryPolicy>();
  @$core.pragma('dart2js:noInline')
  static RetryPolicy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RetryPolicy>(create);
  static RetryPolicy? _defaultInstance;

  /// Optional. The minimum delay between consecutive deliveries of a given
  /// message. Value should be between 0 and 600 seconds. Defaults to 10 seconds.
  @$pb.TagNumber(1)
  $4.Duration get minimumBackoff => $_getN(0);
  @$pb.TagNumber(1)
  set minimumBackoff($4.Duration value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMinimumBackoff() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinimumBackoff() => $_clearField(1);
  @$pb.TagNumber(1)
  $4.Duration ensureMinimumBackoff() => $_ensure(0);

  /// Optional. The maximum delay between consecutive deliveries of a given
  /// message. Value should be between 0 and 600 seconds. Defaults to 600
  /// seconds.
  @$pb.TagNumber(2)
  $4.Duration get maximumBackoff => $_getN(1);
  @$pb.TagNumber(2)
  set maximumBackoff($4.Duration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMaximumBackoff() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaximumBackoff() => $_clearField(2);
  @$pb.TagNumber(2)
  $4.Duration ensureMaximumBackoff() => $_ensure(1);
}

/// Dead lettering is done on a best effort basis. The same message might be
/// dead lettered multiple times.
///
/// If validation on any of the fields fails at subscription creation/updation,
/// the create/update subscription request will fail.
class DeadLetterPolicy extends $pb.GeneratedMessage {
  factory DeadLetterPolicy({
    $core.String? deadLetterTopic,
    $core.int? maxDeliveryAttempts,
  }) {
    final result = create();
    if (deadLetterTopic != null) result.deadLetterTopic = deadLetterTopic;
    if (maxDeliveryAttempts != null)
      result.maxDeliveryAttempts = maxDeliveryAttempts;
    return result;
  }

  DeadLetterPolicy._();

  factory DeadLetterPolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeadLetterPolicy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeadLetterPolicy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'deadLetterTopic')
    ..a<$core.int>(
        2, _omitFieldNames ? '' : 'maxDeliveryAttempts', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeadLetterPolicy clone() => DeadLetterPolicy()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeadLetterPolicy copyWith(void Function(DeadLetterPolicy) updates) =>
      super.copyWith((message) => updates(message as DeadLetterPolicy))
          as DeadLetterPolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeadLetterPolicy create() => DeadLetterPolicy._();
  @$core.override
  DeadLetterPolicy createEmptyInstance() => create();
  static $pb.PbList<DeadLetterPolicy> createRepeated() =>
      $pb.PbList<DeadLetterPolicy>();
  @$core.pragma('dart2js:noInline')
  static DeadLetterPolicy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeadLetterPolicy>(create);
  static DeadLetterPolicy? _defaultInstance;

  /// Optional. The name of the topic to which dead letter messages should be
  /// published. Format is `projects/{project}/topics/{topic}`.The Pub/Sub
  /// service account associated with the enclosing subscription's parent project
  /// (i.e., service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com) must
  /// have permission to Publish() to this topic.
  ///
  /// The operation will fail if the topic does not exist.
  /// Users should ensure that there is a subscription attached to this topic
  /// since messages published to a topic with no subscriptions are lost.
  @$pb.TagNumber(1)
  $core.String get deadLetterTopic => $_getSZ(0);
  @$pb.TagNumber(1)
  set deadLetterTopic($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeadLetterTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeadLetterTopic() => $_clearField(1);

  /// Optional. The maximum number of delivery attempts for any message. The
  /// value must be between 5 and 100.
  ///
  /// The number of delivery attempts is defined as 1 + (the sum of number of
  /// NACKs and number of times the acknowledgment deadline has been exceeded
  /// for the message).
  ///
  /// A NACK is any call to ModifyAckDeadline with a 0 deadline. Note that
  /// client libraries may automatically extend ack_deadlines.
  ///
  /// This field will be honored on a best effort basis.
  ///
  /// If this parameter is 0, a default value of 5 is used.
  @$pb.TagNumber(2)
  $core.int get maxDeliveryAttempts => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxDeliveryAttempts($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxDeliveryAttempts() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxDeliveryAttempts() => $_clearField(2);
}

/// A policy that specifies the conditions for resource expiration (i.e.,
/// automatic resource deletion).
class ExpirationPolicy extends $pb.GeneratedMessage {
  factory ExpirationPolicy({
    $4.Duration? ttl,
  }) {
    final result = create();
    if (ttl != null) result.ttl = ttl;
    return result;
  }

  ExpirationPolicy._();

  factory ExpirationPolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExpirationPolicy.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExpirationPolicy',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<$4.Duration>(1, _omitFieldNames ? '' : 'ttl',
        subBuilder: $4.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpirationPolicy clone() => ExpirationPolicy()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExpirationPolicy copyWith(void Function(ExpirationPolicy) updates) =>
      super.copyWith((message) => updates(message as ExpirationPolicy))
          as ExpirationPolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExpirationPolicy create() => ExpirationPolicy._();
  @$core.override
  ExpirationPolicy createEmptyInstance() => create();
  static $pb.PbList<ExpirationPolicy> createRepeated() =>
      $pb.PbList<ExpirationPolicy>();
  @$core.pragma('dart2js:noInline')
  static ExpirationPolicy getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExpirationPolicy>(create);
  static ExpirationPolicy? _defaultInstance;

  /// Optional. Specifies the "time-to-live" duration for an associated resource.
  /// The resource expires if it is not active for a period of `ttl`. The
  /// definition of "activity" depends on the type of the associated resource.
  /// The minimum and maximum allowed values for `ttl` depend on the type of the
  /// associated resource, as well. If `ttl` is not set, the associated resource
  /// never expires.
  @$pb.TagNumber(1)
  $4.Duration get ttl => $_getN(0);
  @$pb.TagNumber(1)
  set ttl($4.Duration value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTtl() => $_has(0);
  @$pb.TagNumber(1)
  void clearTtl() => $_clearField(1);
  @$pb.TagNumber(1)
  $4.Duration ensureTtl() => $_ensure(0);
}

/// Contains information needed for generating an
/// [OpenID Connect
/// token](https://developers.google.com/identity/protocols/OpenIDConnect).
class PushConfig_OidcToken extends $pb.GeneratedMessage {
  factory PushConfig_OidcToken({
    $core.String? serviceAccountEmail,
    $core.String? audience,
  }) {
    final result = create();
    if (serviceAccountEmail != null)
      result.serviceAccountEmail = serviceAccountEmail;
    if (audience != null) result.audience = audience;
    return result;
  }

  PushConfig_OidcToken._();

  factory PushConfig_OidcToken.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushConfig_OidcToken.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushConfig.OidcToken',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceAccountEmail')
    ..aOS(2, _omitFieldNames ? '' : 'audience')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_OidcToken clone() =>
      PushConfig_OidcToken()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_OidcToken copyWith(void Function(PushConfig_OidcToken) updates) =>
      super.copyWith((message) => updates(message as PushConfig_OidcToken))
          as PushConfig_OidcToken;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushConfig_OidcToken create() => PushConfig_OidcToken._();
  @$core.override
  PushConfig_OidcToken createEmptyInstance() => create();
  static $pb.PbList<PushConfig_OidcToken> createRepeated() =>
      $pb.PbList<PushConfig_OidcToken>();
  @$core.pragma('dart2js:noInline')
  static PushConfig_OidcToken getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushConfig_OidcToken>(create);
  static PushConfig_OidcToken? _defaultInstance;

  /// Optional. [Service account
  /// email](https://cloud.google.com/iam/docs/service-accounts)
  /// used for generating the OIDC token. For more information
  /// on setting up authentication, see
  /// [Push subscriptions](https://cloud.google.com/pubsub/docs/push).
  @$pb.TagNumber(1)
  $core.String get serviceAccountEmail => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceAccountEmail($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServiceAccountEmail() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceAccountEmail() => $_clearField(1);

  /// Optional. Audience to be used when generating OIDC token. The audience
  /// claim identifies the recipients that the JWT is intended for. The
  /// audience value is a single case-sensitive string. Having multiple values
  /// (array) for the audience field is not supported. More info about the OIDC
  /// JWT token audience here:
  /// https://tools.ietf.org/html/rfc7519#section-4.1.3 Note: if not specified,
  /// the Push endpoint URL will be used.
  @$pb.TagNumber(2)
  $core.String get audience => $_getSZ(1);
  @$pb.TagNumber(2)
  set audience($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAudience() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudience() => $_clearField(2);
}

/// The payload to the push endpoint is in the form of the JSON representation
/// of a PubsubMessage
/// (https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#pubsubmessage).
class PushConfig_PubsubWrapper extends $pb.GeneratedMessage {
  factory PushConfig_PubsubWrapper() => create();

  PushConfig_PubsubWrapper._();

  factory PushConfig_PubsubWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushConfig_PubsubWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushConfig.PubsubWrapper',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_PubsubWrapper clone() =>
      PushConfig_PubsubWrapper()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_PubsubWrapper copyWith(
          void Function(PushConfig_PubsubWrapper) updates) =>
      super.copyWith((message) => updates(message as PushConfig_PubsubWrapper))
          as PushConfig_PubsubWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushConfig_PubsubWrapper create() => PushConfig_PubsubWrapper._();
  @$core.override
  PushConfig_PubsubWrapper createEmptyInstance() => create();
  static $pb.PbList<PushConfig_PubsubWrapper> createRepeated() =>
      $pb.PbList<PushConfig_PubsubWrapper>();
  @$core.pragma('dart2js:noInline')
  static PushConfig_PubsubWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushConfig_PubsubWrapper>(create);
  static PushConfig_PubsubWrapper? _defaultInstance;
}

/// Sets the `data` field as the HTTP body for delivery.
class PushConfig_NoWrapper extends $pb.GeneratedMessage {
  factory PushConfig_NoWrapper({
    $core.bool? writeMetadata,
  }) {
    final result = create();
    if (writeMetadata != null) result.writeMetadata = writeMetadata;
    return result;
  }

  PushConfig_NoWrapper._();

  factory PushConfig_NoWrapper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushConfig_NoWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushConfig.NoWrapper',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'writeMetadata')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_NoWrapper clone() =>
      PushConfig_NoWrapper()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig_NoWrapper copyWith(void Function(PushConfig_NoWrapper) updates) =>
      super.copyWith((message) => updates(message as PushConfig_NoWrapper))
          as PushConfig_NoWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushConfig_NoWrapper create() => PushConfig_NoWrapper._();
  @$core.override
  PushConfig_NoWrapper createEmptyInstance() => create();
  static $pb.PbList<PushConfig_NoWrapper> createRepeated() =>
      $pb.PbList<PushConfig_NoWrapper>();
  @$core.pragma('dart2js:noInline')
  static PushConfig_NoWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushConfig_NoWrapper>(create);
  static PushConfig_NoWrapper? _defaultInstance;

  /// Optional. When true, writes the Pub/Sub message metadata to
  /// `x-goog-pubsub-<KEY>:<VAL>` headers of the HTTP request. Writes the
  /// Pub/Sub message attributes to `<KEY>:<VAL>` headers of the HTTP request.
  @$pb.TagNumber(1)
  $core.bool get writeMetadata => $_getBF(0);
  @$pb.TagNumber(1)
  set writeMetadata($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWriteMetadata() => $_has(0);
  @$pb.TagNumber(1)
  void clearWriteMetadata() => $_clearField(1);
}

enum PushConfig_AuthenticationMethod { oidcToken, notSet }

enum PushConfig_Wrapper { pubsubWrapper, noWrapper, notSet }

/// Configuration for a push delivery endpoint.
class PushConfig extends $pb.GeneratedMessage {
  factory PushConfig({
    $core.String? pushEndpoint,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? attributes,
    PushConfig_OidcToken? oidcToken,
    PushConfig_PubsubWrapper? pubsubWrapper,
    PushConfig_NoWrapper? noWrapper,
  }) {
    final result = create();
    if (pushEndpoint != null) result.pushEndpoint = pushEndpoint;
    if (attributes != null) result.attributes.addEntries(attributes);
    if (oidcToken != null) result.oidcToken = oidcToken;
    if (pubsubWrapper != null) result.pubsubWrapper = pubsubWrapper;
    if (noWrapper != null) result.noWrapper = noWrapper;
    return result;
  }

  PushConfig._();

  factory PushConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, PushConfig_AuthenticationMethod>
      _PushConfig_AuthenticationMethodByTag = {
    3: PushConfig_AuthenticationMethod.oidcToken,
    0: PushConfig_AuthenticationMethod.notSet
  };
  static const $core.Map<$core.int, PushConfig_Wrapper>
      _PushConfig_WrapperByTag = {
    4: PushConfig_Wrapper.pubsubWrapper,
    5: PushConfig_Wrapper.noWrapper,
    0: PushConfig_Wrapper.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [3])
    ..oo(1, [4, 5])
    ..aOS(1, _omitFieldNames ? '' : 'pushEndpoint')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'attributes',
        entryClassName: 'PushConfig.AttributesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..aOM<PushConfig_OidcToken>(3, _omitFieldNames ? '' : 'oidcToken',
        subBuilder: PushConfig_OidcToken.create)
    ..aOM<PushConfig_PubsubWrapper>(4, _omitFieldNames ? '' : 'pubsubWrapper',
        subBuilder: PushConfig_PubsubWrapper.create)
    ..aOM<PushConfig_NoWrapper>(5, _omitFieldNames ? '' : 'noWrapper',
        subBuilder: PushConfig_NoWrapper.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig clone() => PushConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushConfig copyWith(void Function(PushConfig) updates) =>
      super.copyWith((message) => updates(message as PushConfig)) as PushConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushConfig create() => PushConfig._();
  @$core.override
  PushConfig createEmptyInstance() => create();
  static $pb.PbList<PushConfig> createRepeated() => $pb.PbList<PushConfig>();
  @$core.pragma('dart2js:noInline')
  static PushConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushConfig>(create);
  static PushConfig? _defaultInstance;

  PushConfig_AuthenticationMethod whichAuthenticationMethod() =>
      _PushConfig_AuthenticationMethodByTag[$_whichOneof(0)]!;
  void clearAuthenticationMethod() => $_clearField($_whichOneof(0));

  PushConfig_Wrapper whichWrapper() =>
      _PushConfig_WrapperByTag[$_whichOneof(1)]!;
  void clearWrapper() => $_clearField($_whichOneof(1));

  /// Optional. A URL locating the endpoint to which messages should be pushed.
  /// For example, a Webhook endpoint might use `https://example.com/push`.
  @$pb.TagNumber(1)
  $core.String get pushEndpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set pushEndpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPushEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearPushEndpoint() => $_clearField(1);

  /// Optional. Endpoint configuration attributes that can be used to control
  /// different aspects of the message delivery.
  ///
  /// The only currently supported attribute is `x-goog-version`, which you can
  /// use to change the format of the pushed message. This attribute
  /// indicates the version of the data expected by the endpoint. This
  /// controls the shape of the pushed message (i.e., its fields and metadata).
  ///
  /// If not present during the `CreateSubscription` call, it will default to
  /// the version of the Pub/Sub API used to make such call. If not present in a
  /// `ModifyPushConfig` call, its value will not be changed. `GetSubscription`
  /// calls will always return a valid version, even if the subscription was
  /// created without this attribute.
  ///
  /// The only supported values for the `x-goog-version` attribute are:
  ///
  /// * `v1beta1`: uses the push format defined in the v1beta1 Pub/Sub API.
  /// * `v1` or `v1beta2`: uses the push format defined in the v1 Pub/Sub API.
  ///
  /// For example:
  /// `attributes { "x-goog-version": "v1" }`
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get attributes => $_getMap(1);

  /// Optional. If specified, Pub/Sub will generate and attach an OIDC JWT
  /// token as an `Authorization` header in the HTTP request for every pushed
  /// message.
  @$pb.TagNumber(3)
  PushConfig_OidcToken get oidcToken => $_getN(2);
  @$pb.TagNumber(3)
  set oidcToken(PushConfig_OidcToken value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOidcToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearOidcToken() => $_clearField(3);
  @$pb.TagNumber(3)
  PushConfig_OidcToken ensureOidcToken() => $_ensure(2);

  /// Optional. When set, the payload to the push endpoint is in the form of
  /// the JSON representation of a PubsubMessage
  /// (https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#pubsubmessage).
  @$pb.TagNumber(4)
  PushConfig_PubsubWrapper get pubsubWrapper => $_getN(3);
  @$pb.TagNumber(4)
  set pubsubWrapper(PushConfig_PubsubWrapper value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPubsubWrapper() => $_has(3);
  @$pb.TagNumber(4)
  void clearPubsubWrapper() => $_clearField(4);
  @$pb.TagNumber(4)
  PushConfig_PubsubWrapper ensurePubsubWrapper() => $_ensure(3);

  /// Optional. When set, the payload to the push endpoint is not wrapped.
  @$pb.TagNumber(5)
  PushConfig_NoWrapper get noWrapper => $_getN(4);
  @$pb.TagNumber(5)
  set noWrapper(PushConfig_NoWrapper value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasNoWrapper() => $_has(4);
  @$pb.TagNumber(5)
  void clearNoWrapper() => $_clearField(5);
  @$pb.TagNumber(5)
  PushConfig_NoWrapper ensureNoWrapper() => $_ensure(4);
}

/// Configuration for a BigQuery subscription.
class BigQueryConfig extends $pb.GeneratedMessage {
  factory BigQueryConfig({
    $core.String? table,
    $core.bool? useTopicSchema,
    $core.bool? writeMetadata,
    $core.bool? dropUnknownFields,
    BigQueryConfig_State? state,
    $core.bool? useTableSchema,
    $core.String? serviceAccountEmail,
  }) {
    final result = create();
    if (table != null) result.table = table;
    if (useTopicSchema != null) result.useTopicSchema = useTopicSchema;
    if (writeMetadata != null) result.writeMetadata = writeMetadata;
    if (dropUnknownFields != null) result.dropUnknownFields = dropUnknownFields;
    if (state != null) result.state = state;
    if (useTableSchema != null) result.useTableSchema = useTableSchema;
    if (serviceAccountEmail != null)
      result.serviceAccountEmail = serviceAccountEmail;
    return result;
  }

  BigQueryConfig._();

  factory BigQueryConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BigQueryConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BigQueryConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'table')
    ..aOB(2, _omitFieldNames ? '' : 'useTopicSchema')
    ..aOB(3, _omitFieldNames ? '' : 'writeMetadata')
    ..aOB(4, _omitFieldNames ? '' : 'dropUnknownFields')
    ..e<BigQueryConfig_State>(
        5, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: BigQueryConfig_State.STATE_UNSPECIFIED,
        valueOf: BigQueryConfig_State.valueOf,
        enumValues: BigQueryConfig_State.values)
    ..aOB(6, _omitFieldNames ? '' : 'useTableSchema')
    ..aOS(7, _omitFieldNames ? '' : 'serviceAccountEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BigQueryConfig clone() => BigQueryConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BigQueryConfig copyWith(void Function(BigQueryConfig) updates) =>
      super.copyWith((message) => updates(message as BigQueryConfig))
          as BigQueryConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BigQueryConfig create() => BigQueryConfig._();
  @$core.override
  BigQueryConfig createEmptyInstance() => create();
  static $pb.PbList<BigQueryConfig> createRepeated() =>
      $pb.PbList<BigQueryConfig>();
  @$core.pragma('dart2js:noInline')
  static BigQueryConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BigQueryConfig>(create);
  static BigQueryConfig? _defaultInstance;

  /// Optional. The name of the table to which to write data, of the form
  /// {projectId}.{datasetId}.{tableId}
  @$pb.TagNumber(1)
  $core.String get table => $_getSZ(0);
  @$pb.TagNumber(1)
  set table($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTable() => $_has(0);
  @$pb.TagNumber(1)
  void clearTable() => $_clearField(1);

  /// Optional. When true, use the topic's schema as the columns to write to in
  /// BigQuery, if it exists. `use_topic_schema` and `use_table_schema` cannot be
  /// enabled at the same time.
  @$pb.TagNumber(2)
  $core.bool get useTopicSchema => $_getBF(1);
  @$pb.TagNumber(2)
  set useTopicSchema($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUseTopicSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearUseTopicSchema() => $_clearField(2);

  /// Optional. When true, write the subscription name, message_id, publish_time,
  /// attributes, and ordering_key to additional columns in the table. The
  /// subscription name, message_id, and publish_time fields are put in their own
  /// columns while all other message properties (other than data) are written to
  /// a JSON object in the attributes column.
  @$pb.TagNumber(3)
  $core.bool get writeMetadata => $_getBF(2);
  @$pb.TagNumber(3)
  set writeMetadata($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWriteMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearWriteMetadata() => $_clearField(3);

  /// Optional. When true and use_topic_schema is true, any fields that are a
  /// part of the topic schema that are not part of the BigQuery table schema are
  /// dropped when writing to BigQuery. Otherwise, the schemas must be kept in
  /// sync and any messages with extra fields are not written and remain in the
  /// subscription's backlog.
  @$pb.TagNumber(4)
  $core.bool get dropUnknownFields => $_getBF(3);
  @$pb.TagNumber(4)
  set dropUnknownFields($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDropUnknownFields() => $_has(3);
  @$pb.TagNumber(4)
  void clearDropUnknownFields() => $_clearField(4);

  /// Output only. An output-only field that indicates whether or not the
  /// subscription can receive messages.
  @$pb.TagNumber(5)
  BigQueryConfig_State get state => $_getN(4);
  @$pb.TagNumber(5)
  set state(BigQueryConfig_State value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasState() => $_has(4);
  @$pb.TagNumber(5)
  void clearState() => $_clearField(5);

  /// Optional. When true, use the BigQuery table's schema as the columns to
  /// write to in BigQuery. `use_table_schema` and `use_topic_schema` cannot be
  /// enabled at the same time.
  @$pb.TagNumber(6)
  $core.bool get useTableSchema => $_getBF(5);
  @$pb.TagNumber(6)
  set useTableSchema($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUseTableSchema() => $_has(5);
  @$pb.TagNumber(6)
  void clearUseTableSchema() => $_clearField(6);

  /// Optional. The service account to use to write to BigQuery. The subscription
  /// creator or updater that specifies this field must have
  /// `iam.serviceAccounts.actAs` permission on the service account. If not
  /// specified, the Pub/Sub [service
  /// agent](https://cloud.google.com/iam/docs/service-agents),
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com, is used.
  @$pb.TagNumber(7)
  $core.String get serviceAccountEmail => $_getSZ(6);
  @$pb.TagNumber(7)
  set serviceAccountEmail($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasServiceAccountEmail() => $_has(6);
  @$pb.TagNumber(7)
  void clearServiceAccountEmail() => $_clearField(7);
}

/// Configuration for a Bigtable subscription. The Pub/Sub message will be
/// written to a Bigtable row as follows:
/// - row key: subscription name and message ID delimited by #.
/// - columns: message bytes written to a single column family "data" with an
///   empty-string column qualifier.
/// - cell timestamp: the message publish timestamp.
class BigtableConfig extends $pb.GeneratedMessage {
  factory BigtableConfig({
    $core.String? table,
    $core.String? appProfileId,
    $core.String? serviceAccountEmail,
    BigtableConfig_State? state,
    $core.bool? writeMetadata,
  }) {
    final result = create();
    if (table != null) result.table = table;
    if (appProfileId != null) result.appProfileId = appProfileId;
    if (serviceAccountEmail != null)
      result.serviceAccountEmail = serviceAccountEmail;
    if (state != null) result.state = state;
    if (writeMetadata != null) result.writeMetadata = writeMetadata;
    return result;
  }

  BigtableConfig._();

  factory BigtableConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BigtableConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BigtableConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'table')
    ..aOS(2, _omitFieldNames ? '' : 'appProfileId')
    ..aOS(3, _omitFieldNames ? '' : 'serviceAccountEmail')
    ..e<BigtableConfig_State>(
        4, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: BigtableConfig_State.STATE_UNSPECIFIED,
        valueOf: BigtableConfig_State.valueOf,
        enumValues: BigtableConfig_State.values)
    ..aOB(5, _omitFieldNames ? '' : 'writeMetadata')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BigtableConfig clone() => BigtableConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BigtableConfig copyWith(void Function(BigtableConfig) updates) =>
      super.copyWith((message) => updates(message as BigtableConfig))
          as BigtableConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BigtableConfig create() => BigtableConfig._();
  @$core.override
  BigtableConfig createEmptyInstance() => create();
  static $pb.PbList<BigtableConfig> createRepeated() =>
      $pb.PbList<BigtableConfig>();
  @$core.pragma('dart2js:noInline')
  static BigtableConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BigtableConfig>(create);
  static BigtableConfig? _defaultInstance;

  /// Optional. The unique name of the table to write messages to.
  ///
  /// Values are of the form
  /// `projects/<project>/instances/<instance>/tables/<table>`.
  @$pb.TagNumber(1)
  $core.String get table => $_getSZ(0);
  @$pb.TagNumber(1)
  set table($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTable() => $_has(0);
  @$pb.TagNumber(1)
  void clearTable() => $_clearField(1);

  /// Optional. The app profile to use for the Bigtable writes. If not specified,
  /// the "default" application profile will be used. The app profile must use
  /// single-cluster routing.
  @$pb.TagNumber(2)
  $core.String get appProfileId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appProfileId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppProfileId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppProfileId() => $_clearField(2);

  /// Optional. The service account to use to write to Bigtable. The subscription
  /// creator or updater that specifies this field must have
  /// `iam.serviceAccounts.actAs` permission on the service account. If not
  /// specified, the Pub/Sub [service
  /// agent](https://cloud.google.com/iam/docs/service-agents),
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com, is used.
  @$pb.TagNumber(3)
  $core.String get serviceAccountEmail => $_getSZ(2);
  @$pb.TagNumber(3)
  set serviceAccountEmail($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasServiceAccountEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearServiceAccountEmail() => $_clearField(3);

  /// Output only. An output-only field that indicates whether or not the
  /// subscription can receive messages.
  @$pb.TagNumber(4)
  BigtableConfig_State get state => $_getN(3);
  @$pb.TagNumber(4)
  set state(BigtableConfig_State value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  /// Optional. When true, write the subscription name, message_id, publish_time,
  /// attributes, and ordering_key to additional columns in the table under the
  /// pubsub_metadata column family. The subscription name, message_id, and
  /// publish_time fields are put in their own columns while all other message
  /// properties (other than data) are written to a JSON object in the attributes
  /// column.
  @$pb.TagNumber(5)
  $core.bool get writeMetadata => $_getBF(4);
  @$pb.TagNumber(5)
  set writeMetadata($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWriteMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearWriteMetadata() => $_clearField(5);
}

/// Configuration for writing message data in text format.
/// Message payloads will be written to files as raw text, separated by a
/// newline.
class CloudStorageConfig_TextConfig extends $pb.GeneratedMessage {
  factory CloudStorageConfig_TextConfig() => create();

  CloudStorageConfig_TextConfig._();

  factory CloudStorageConfig_TextConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloudStorageConfig_TextConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudStorageConfig.TextConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig_TextConfig clone() =>
      CloudStorageConfig_TextConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig_TextConfig copyWith(
          void Function(CloudStorageConfig_TextConfig) updates) =>
      super.copyWith(
              (message) => updates(message as CloudStorageConfig_TextConfig))
          as CloudStorageConfig_TextConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig_TextConfig create() =>
      CloudStorageConfig_TextConfig._();
  @$core.override
  CloudStorageConfig_TextConfig createEmptyInstance() => create();
  static $pb.PbList<CloudStorageConfig_TextConfig> createRepeated() =>
      $pb.PbList<CloudStorageConfig_TextConfig>();
  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig_TextConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudStorageConfig_TextConfig>(create);
  static CloudStorageConfig_TextConfig? _defaultInstance;
}

/// Configuration for writing message data in Avro format.
/// Message payloads and metadata will be written to files as an Avro binary.
class CloudStorageConfig_AvroConfig extends $pb.GeneratedMessage {
  factory CloudStorageConfig_AvroConfig({
    $core.bool? writeMetadata,
    $core.bool? useTopicSchema,
  }) {
    final result = create();
    if (writeMetadata != null) result.writeMetadata = writeMetadata;
    if (useTopicSchema != null) result.useTopicSchema = useTopicSchema;
    return result;
  }

  CloudStorageConfig_AvroConfig._();

  factory CloudStorageConfig_AvroConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloudStorageConfig_AvroConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudStorageConfig.AvroConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'writeMetadata')
    ..aOB(2, _omitFieldNames ? '' : 'useTopicSchema')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig_AvroConfig clone() =>
      CloudStorageConfig_AvroConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig_AvroConfig copyWith(
          void Function(CloudStorageConfig_AvroConfig) updates) =>
      super.copyWith(
              (message) => updates(message as CloudStorageConfig_AvroConfig))
          as CloudStorageConfig_AvroConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig_AvroConfig create() =>
      CloudStorageConfig_AvroConfig._();
  @$core.override
  CloudStorageConfig_AvroConfig createEmptyInstance() => create();
  static $pb.PbList<CloudStorageConfig_AvroConfig> createRepeated() =>
      $pb.PbList<CloudStorageConfig_AvroConfig>();
  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig_AvroConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudStorageConfig_AvroConfig>(create);
  static CloudStorageConfig_AvroConfig? _defaultInstance;

  /// Optional. When true, write the subscription name, message_id,
  /// publish_time, attributes, and ordering_key as additional fields in the
  /// output. The subscription name, message_id, and publish_time fields are
  /// put in their own fields while all other message properties other than
  /// data (for example, an ordering_key, if present) are added as entries in
  /// the attributes map.
  @$pb.TagNumber(1)
  $core.bool get writeMetadata => $_getBF(0);
  @$pb.TagNumber(1)
  set writeMetadata($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWriteMetadata() => $_has(0);
  @$pb.TagNumber(1)
  void clearWriteMetadata() => $_clearField(1);

  /// Optional. When true, the output Cloud Storage file will be serialized
  /// using the topic schema, if it exists.
  @$pb.TagNumber(2)
  $core.bool get useTopicSchema => $_getBF(1);
  @$pb.TagNumber(2)
  set useTopicSchema($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUseTopicSchema() => $_has(1);
  @$pb.TagNumber(2)
  void clearUseTopicSchema() => $_clearField(2);
}

enum CloudStorageConfig_OutputFormat { textConfig, avroConfig, notSet }

/// Configuration for a Cloud Storage subscription.
class CloudStorageConfig extends $pb.GeneratedMessage {
  factory CloudStorageConfig({
    $core.String? bucket,
    $core.String? filenamePrefix,
    $core.String? filenameSuffix,
    CloudStorageConfig_TextConfig? textConfig,
    CloudStorageConfig_AvroConfig? avroConfig,
    $4.Duration? maxDuration,
    $fixnum.Int64? maxBytes,
    $fixnum.Int64? maxMessages,
    CloudStorageConfig_State? state,
    $core.String? filenameDatetimeFormat,
    $core.String? serviceAccountEmail,
  }) {
    final result = create();
    if (bucket != null) result.bucket = bucket;
    if (filenamePrefix != null) result.filenamePrefix = filenamePrefix;
    if (filenameSuffix != null) result.filenameSuffix = filenameSuffix;
    if (textConfig != null) result.textConfig = textConfig;
    if (avroConfig != null) result.avroConfig = avroConfig;
    if (maxDuration != null) result.maxDuration = maxDuration;
    if (maxBytes != null) result.maxBytes = maxBytes;
    if (maxMessages != null) result.maxMessages = maxMessages;
    if (state != null) result.state = state;
    if (filenameDatetimeFormat != null)
      result.filenameDatetimeFormat = filenameDatetimeFormat;
    if (serviceAccountEmail != null)
      result.serviceAccountEmail = serviceAccountEmail;
    return result;
  }

  CloudStorageConfig._();

  factory CloudStorageConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloudStorageConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CloudStorageConfig_OutputFormat>
      _CloudStorageConfig_OutputFormatByTag = {
    4: CloudStorageConfig_OutputFormat.textConfig,
    5: CloudStorageConfig_OutputFormat.avroConfig,
    0: CloudStorageConfig_OutputFormat.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudStorageConfig',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [4, 5])
    ..aOS(1, _omitFieldNames ? '' : 'bucket')
    ..aOS(2, _omitFieldNames ? '' : 'filenamePrefix')
    ..aOS(3, _omitFieldNames ? '' : 'filenameSuffix')
    ..aOM<CloudStorageConfig_TextConfig>(4, _omitFieldNames ? '' : 'textConfig',
        subBuilder: CloudStorageConfig_TextConfig.create)
    ..aOM<CloudStorageConfig_AvroConfig>(5, _omitFieldNames ? '' : 'avroConfig',
        subBuilder: CloudStorageConfig_AvroConfig.create)
    ..aOM<$4.Duration>(6, _omitFieldNames ? '' : 'maxDuration',
        subBuilder: $4.Duration.create)
    ..aInt64(7, _omitFieldNames ? '' : 'maxBytes')
    ..aInt64(8, _omitFieldNames ? '' : 'maxMessages')
    ..e<CloudStorageConfig_State>(
        9, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: CloudStorageConfig_State.STATE_UNSPECIFIED,
        valueOf: CloudStorageConfig_State.valueOf,
        enumValues: CloudStorageConfig_State.values)
    ..aOS(10, _omitFieldNames ? '' : 'filenameDatetimeFormat')
    ..aOS(11, _omitFieldNames ? '' : 'serviceAccountEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig clone() => CloudStorageConfig()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudStorageConfig copyWith(void Function(CloudStorageConfig) updates) =>
      super.copyWith((message) => updates(message as CloudStorageConfig))
          as CloudStorageConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig create() => CloudStorageConfig._();
  @$core.override
  CloudStorageConfig createEmptyInstance() => create();
  static $pb.PbList<CloudStorageConfig> createRepeated() =>
      $pb.PbList<CloudStorageConfig>();
  @$core.pragma('dart2js:noInline')
  static CloudStorageConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudStorageConfig>(create);
  static CloudStorageConfig? _defaultInstance;

  CloudStorageConfig_OutputFormat whichOutputFormat() =>
      _CloudStorageConfig_OutputFormatByTag[$_whichOneof(0)]!;
  void clearOutputFormat() => $_clearField($_whichOneof(0));

  /// Required. User-provided name for the Cloud Storage bucket.
  /// The bucket must be created by the user. The bucket name must be without
  /// any prefix like "gs://". See the [bucket naming
  /// requirements] (https://cloud.google.com/storage/docs/buckets#naming).
  @$pb.TagNumber(1)
  $core.String get bucket => $_getSZ(0);
  @$pb.TagNumber(1)
  set bucket($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBucket() => $_clearField(1);

  /// Optional. User-provided prefix for Cloud Storage filename. See the [object
  /// naming requirements](https://cloud.google.com/storage/docs/objects#naming).
  @$pb.TagNumber(2)
  $core.String get filenamePrefix => $_getSZ(1);
  @$pb.TagNumber(2)
  set filenamePrefix($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFilenamePrefix() => $_has(1);
  @$pb.TagNumber(2)
  void clearFilenamePrefix() => $_clearField(2);

  /// Optional. User-provided suffix for Cloud Storage filename. See the [object
  /// naming requirements](https://cloud.google.com/storage/docs/objects#naming).
  /// Must not end in "/".
  @$pb.TagNumber(3)
  $core.String get filenameSuffix => $_getSZ(2);
  @$pb.TagNumber(3)
  set filenameSuffix($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilenameSuffix() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilenameSuffix() => $_clearField(3);

  /// Optional. If set, message data will be written to Cloud Storage in text
  /// format.
  @$pb.TagNumber(4)
  CloudStorageConfig_TextConfig get textConfig => $_getN(3);
  @$pb.TagNumber(4)
  set textConfig(CloudStorageConfig_TextConfig value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasTextConfig() => $_has(3);
  @$pb.TagNumber(4)
  void clearTextConfig() => $_clearField(4);
  @$pb.TagNumber(4)
  CloudStorageConfig_TextConfig ensureTextConfig() => $_ensure(3);

  /// Optional. If set, message data will be written to Cloud Storage in Avro
  /// format.
  @$pb.TagNumber(5)
  CloudStorageConfig_AvroConfig get avroConfig => $_getN(4);
  @$pb.TagNumber(5)
  set avroConfig(CloudStorageConfig_AvroConfig value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAvroConfig() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvroConfig() => $_clearField(5);
  @$pb.TagNumber(5)
  CloudStorageConfig_AvroConfig ensureAvroConfig() => $_ensure(4);

  /// Optional. The maximum duration that can elapse before a new Cloud Storage
  /// file is created. Min 1 minute, max 10 minutes, default 5 minutes. May not
  /// exceed the subscription's acknowledgment deadline.
  @$pb.TagNumber(6)
  $4.Duration get maxDuration => $_getN(5);
  @$pb.TagNumber(6)
  set maxDuration($4.Duration value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxDuration() => $_clearField(6);
  @$pb.TagNumber(6)
  $4.Duration ensureMaxDuration() => $_ensure(5);

  /// Optional. The maximum bytes that can be written to a Cloud Storage file
  /// before a new file is created. Min 1 KB, max 10 GiB. The max_bytes limit may
  /// be exceeded in cases where messages are larger than the limit.
  @$pb.TagNumber(7)
  $fixnum.Int64 get maxBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set maxBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxBytes() => $_clearField(7);

  /// Optional. The maximum number of messages that can be written to a Cloud
  /// Storage file before a new file is created. Min 1000 messages.
  @$pb.TagNumber(8)
  $fixnum.Int64 get maxMessages => $_getI64(7);
  @$pb.TagNumber(8)
  set maxMessages($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxMessages() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxMessages() => $_clearField(8);

  /// Output only. An output-only field that indicates whether or not the
  /// subscription can receive messages.
  @$pb.TagNumber(9)
  CloudStorageConfig_State get state => $_getN(8);
  @$pb.TagNumber(9)
  set state(CloudStorageConfig_State value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasState() => $_has(8);
  @$pb.TagNumber(9)
  void clearState() => $_clearField(9);

  /// Optional. User-provided format string specifying how to represent datetimes
  /// in Cloud Storage filenames. See the [datetime format
  /// guidance](https://cloud.google.com/pubsub/docs/create-cloudstorage-subscription#file_names).
  @$pb.TagNumber(10)
  $core.String get filenameDatetimeFormat => $_getSZ(9);
  @$pb.TagNumber(10)
  set filenameDatetimeFormat($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasFilenameDatetimeFormat() => $_has(9);
  @$pb.TagNumber(10)
  void clearFilenameDatetimeFormat() => $_clearField(10);

  /// Optional. The service account to use to write to Cloud Storage. The
  /// subscription creator or updater that specifies this field must have
  /// `iam.serviceAccounts.actAs` permission on the service account. If not
  /// specified, the Pub/Sub
  /// [service agent](https://cloud.google.com/iam/docs/service-agents),
  /// service-{project_number}@gcp-sa-pubsub.iam.gserviceaccount.com, is used.
  @$pb.TagNumber(11)
  $core.String get serviceAccountEmail => $_getSZ(10);
  @$pb.TagNumber(11)
  set serviceAccountEmail($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasServiceAccountEmail() => $_has(10);
  @$pb.TagNumber(11)
  void clearServiceAccountEmail() => $_clearField(11);
}

/// A message and its corresponding acknowledgment ID.
class ReceivedMessage extends $pb.GeneratedMessage {
  factory ReceivedMessage({
    $core.String? ackId,
    PubsubMessage? message,
    $core.int? deliveryAttempt,
  }) {
    final result = create();
    if (ackId != null) result.ackId = ackId;
    if (message != null) result.message = message;
    if (deliveryAttempt != null) result.deliveryAttempt = deliveryAttempt;
    return result;
  }

  ReceivedMessage._();

  factory ReceivedMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReceivedMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReceivedMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ackId')
    ..aOM<PubsubMessage>(2, _omitFieldNames ? '' : 'message',
        subBuilder: PubsubMessage.create)
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'deliveryAttempt', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceivedMessage clone() => ReceivedMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReceivedMessage copyWith(void Function(ReceivedMessage) updates) =>
      super.copyWith((message) => updates(message as ReceivedMessage))
          as ReceivedMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReceivedMessage create() => ReceivedMessage._();
  @$core.override
  ReceivedMessage createEmptyInstance() => create();
  static $pb.PbList<ReceivedMessage> createRepeated() =>
      $pb.PbList<ReceivedMessage>();
  @$core.pragma('dart2js:noInline')
  static ReceivedMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReceivedMessage>(create);
  static ReceivedMessage? _defaultInstance;

  /// Optional. This ID can be used to acknowledge the received message.
  @$pb.TagNumber(1)
  $core.String get ackId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ackId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAckId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAckId() => $_clearField(1);

  /// Optional. The message.
  @$pb.TagNumber(2)
  PubsubMessage get message => $_getN(1);
  @$pb.TagNumber(2)
  set message(PubsubMessage value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
  @$pb.TagNumber(2)
  PubsubMessage ensureMessage() => $_ensure(1);

  /// Optional. The approximate number of times that Pub/Sub has attempted to
  /// deliver the associated message to a subscriber.
  ///
  /// More precisely, this is 1 + (number of NACKs) +
  /// (number of ack_deadline exceeds) for this message.
  ///
  /// A NACK is any call to ModifyAckDeadline with a 0 deadline. An ack_deadline
  /// exceeds event is whenever a message is not acknowledged within
  /// ack_deadline. Note that ack_deadline is initially
  /// Subscription.ackDeadlineSeconds, but may get extended automatically by
  /// the client library.
  ///
  /// Upon the first delivery of a given message, `delivery_attempt` will have a
  /// value of 1. The value is calculated at best effort and is approximate.
  ///
  /// If a DeadLetterPolicy is not set on the subscription, this will be 0.
  @$pb.TagNumber(3)
  $core.int get deliveryAttempt => $_getIZ(2);
  @$pb.TagNumber(3)
  set deliveryAttempt($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDeliveryAttempt() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeliveryAttempt() => $_clearField(3);
}

/// Request for the GetSubscription method.
class GetSubscriptionRequest extends $pb.GeneratedMessage {
  factory GetSubscriptionRequest({
    $core.String? subscription,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    return result;
  }

  GetSubscriptionRequest._();

  factory GetSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSubscriptionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionRequest clone() =>
      GetSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSubscriptionRequest copyWith(
          void Function(GetSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as GetSubscriptionRequest))
          as GetSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSubscriptionRequest create() => GetSubscriptionRequest._();
  @$core.override
  GetSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<GetSubscriptionRequest> createRepeated() =>
      $pb.PbList<GetSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSubscriptionRequest>(create);
  static GetSubscriptionRequest? _defaultInstance;

  /// Required. The name of the subscription to get.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);
}

/// Request for the UpdateSubscription method.
class UpdateSubscriptionRequest extends $pb.GeneratedMessage {
  factory UpdateSubscriptionRequest({
    Subscription? subscription,
    $5.FieldMask? updateMask,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateSubscriptionRequest._();

  factory UpdateSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSubscriptionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<Subscription>(1, _omitFieldNames ? '' : 'subscription',
        subBuilder: Subscription.create)
    ..aOM<$5.FieldMask>(2, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $5.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRequest clone() =>
      UpdateSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSubscriptionRequest copyWith(
          void Function(UpdateSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSubscriptionRequest))
          as UpdateSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRequest create() => UpdateSubscriptionRequest._();
  @$core.override
  UpdateSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateSubscriptionRequest> createRepeated() =>
      $pb.PbList<UpdateSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSubscriptionRequest>(create);
  static UpdateSubscriptionRequest? _defaultInstance;

  /// Required. The updated subscription object.
  @$pb.TagNumber(1)
  Subscription get subscription => $_getN(0);
  @$pb.TagNumber(1)
  set subscription(Subscription value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);
  @$pb.TagNumber(1)
  Subscription ensureSubscription() => $_ensure(0);

  /// Required. Indicates which fields in the provided subscription to update.
  /// Must be specified and non-empty.
  @$pb.TagNumber(2)
  $5.FieldMask get updateMask => $_getN(1);
  @$pb.TagNumber(2)
  set updateMask($5.FieldMask value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateMask() => $_clearField(2);
  @$pb.TagNumber(2)
  $5.FieldMask ensureUpdateMask() => $_ensure(1);
}

/// Request for the `ListSubscriptions` method.
class ListSubscriptionsRequest extends $pb.GeneratedMessage {
  factory ListSubscriptionsRequest({
    $core.String? project,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (project != null) result.project = project;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListSubscriptionsRequest._();

  factory ListSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubscriptionsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest clone() =>
      ListSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest copyWith(
          void Function(ListSubscriptionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsRequest))
          as ListSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest create() => ListSubscriptionsRequest._();
  @$core.override
  ListSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListSubscriptionsRequest> createRepeated() =>
      $pb.PbList<ListSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsRequest>(create);
  static ListSubscriptionsRequest? _defaultInstance;

  /// Required. The name of the project in which to list subscriptions.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);

  /// Optional. Maximum number of subscriptions to return.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// Optional. The value returned by the last `ListSubscriptionsResponse`;
  /// indicates that this is a continuation of a prior `ListSubscriptions` call,
  /// and that the system should return the next page of data.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Response for the `ListSubscriptions` method.
class ListSubscriptionsResponse extends $pb.GeneratedMessage {
  factory ListSubscriptionsResponse({
    $core.Iterable<Subscription>? subscriptions,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListSubscriptionsResponse._();

  factory ListSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubscriptionsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<Subscription>(
        1, _omitFieldNames ? '' : 'subscriptions', $pb.PbFieldType.PM,
        subBuilder: Subscription.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse clone() =>
      ListSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse copyWith(
          void Function(ListSubscriptionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsResponse))
          as ListSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse create() => ListSubscriptionsResponse._();
  @$core.override
  ListSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListSubscriptionsResponse> createRepeated() =>
      $pb.PbList<ListSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsResponse>(create);
  static ListSubscriptionsResponse? _defaultInstance;

  /// Optional. The subscriptions that match the request.
  @$pb.TagNumber(1)
  $pb.PbList<Subscription> get subscriptions => $_getList(0);

  /// Optional. If not empty, indicates that there may be more subscriptions that
  /// match the request; this value should be passed in a new
  /// `ListSubscriptionsRequest` to get more subscriptions.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the DeleteSubscription method.
class DeleteSubscriptionRequest extends $pb.GeneratedMessage {
  factory DeleteSubscriptionRequest({
    $core.String? subscription,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    return result;
  }

  DeleteSubscriptionRequest._();

  factory DeleteSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSubscriptionRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionRequest clone() =>
      DeleteSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionRequest copyWith(
          void Function(DeleteSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSubscriptionRequest))
          as DeleteSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionRequest create() => DeleteSubscriptionRequest._();
  @$core.override
  DeleteSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSubscriptionRequest> createRepeated() =>
      $pb.PbList<DeleteSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSubscriptionRequest>(create);
  static DeleteSubscriptionRequest? _defaultInstance;

  /// Required. The subscription to delete.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);
}

/// Request for the ModifyPushConfig method.
class ModifyPushConfigRequest extends $pb.GeneratedMessage {
  factory ModifyPushConfigRequest({
    $core.String? subscription,
    PushConfig? pushConfig,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (pushConfig != null) result.pushConfig = pushConfig;
    return result;
  }

  ModifyPushConfigRequest._();

  factory ModifyPushConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModifyPushConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModifyPushConfigRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..aOM<PushConfig>(2, _omitFieldNames ? '' : 'pushConfig',
        subBuilder: PushConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModifyPushConfigRequest clone() =>
      ModifyPushConfigRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModifyPushConfigRequest copyWith(
          void Function(ModifyPushConfigRequest) updates) =>
      super.copyWith((message) => updates(message as ModifyPushConfigRequest))
          as ModifyPushConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModifyPushConfigRequest create() => ModifyPushConfigRequest._();
  @$core.override
  ModifyPushConfigRequest createEmptyInstance() => create();
  static $pb.PbList<ModifyPushConfigRequest> createRepeated() =>
      $pb.PbList<ModifyPushConfigRequest>();
  @$core.pragma('dart2js:noInline')
  static ModifyPushConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModifyPushConfigRequest>(create);
  static ModifyPushConfigRequest? _defaultInstance;

  /// Required. The name of the subscription.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Required. The push configuration for future deliveries.
  ///
  /// An empty `pushConfig` indicates that the Pub/Sub system should
  /// stop pushing messages from the given subscription and allow
  /// messages to be pulled and acknowledged - effectively pausing
  /// the subscription if `Pull` or `StreamingPull` is not called.
  @$pb.TagNumber(2)
  PushConfig get pushConfig => $_getN(1);
  @$pb.TagNumber(2)
  set pushConfig(PushConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPushConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearPushConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  PushConfig ensurePushConfig() => $_ensure(1);
}

/// Request for the `Pull` method.
class PullRequest extends $pb.GeneratedMessage {
  factory PullRequest({
    $core.String? subscription,
    @$core.Deprecated('This field is deprecated.')
    $core.bool? returnImmediately,
    $core.int? maxMessages,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (returnImmediately != null) result.returnImmediately = returnImmediately;
    if (maxMessages != null) result.maxMessages = maxMessages;
    return result;
  }

  PullRequest._();

  factory PullRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PullRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..aOB(2, _omitFieldNames ? '' : 'returnImmediately')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maxMessages', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullRequest clone() => PullRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullRequest copyWith(void Function(PullRequest) updates) =>
      super.copyWith((message) => updates(message as PullRequest))
          as PullRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullRequest create() => PullRequest._();
  @$core.override
  PullRequest createEmptyInstance() => create();
  static $pb.PbList<PullRequest> createRepeated() => $pb.PbList<PullRequest>();
  @$core.pragma('dart2js:noInline')
  static PullRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PullRequest>(create);
  static PullRequest? _defaultInstance;

  /// Required. The subscription from which messages should be pulled.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Optional. If this field set to true, the system will respond immediately
  /// even if it there are no messages available to return in the `Pull`
  /// response. Otherwise, the system may wait (for a bounded amount of time)
  /// until at least one message is available, rather than returning no messages.
  /// Warning: setting this field to `true` is discouraged because it adversely
  /// impacts the performance of `Pull` operations. We recommend that users do
  /// not set this field.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool get returnImmediately => $_getBF(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  set returnImmediately($core.bool value) => $_setBool(1, value);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool hasReturnImmediately() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  void clearReturnImmediately() => $_clearField(2);

  /// Required. The maximum number of messages to return for this request. Must
  /// be a positive integer. The Pub/Sub system may return fewer than the number
  /// specified.
  @$pb.TagNumber(3)
  $core.int get maxMessages => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxMessages($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxMessages() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxMessages() => $_clearField(3);
}

/// Response for the `Pull` method.
class PullResponse extends $pb.GeneratedMessage {
  factory PullResponse({
    $core.Iterable<ReceivedMessage>? receivedMessages,
  }) {
    final result = create();
    if (receivedMessages != null)
      result.receivedMessages.addAll(receivedMessages);
    return result;
  }

  PullResponse._();

  factory PullResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PullResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PullResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<ReceivedMessage>(
        1, _omitFieldNames ? '' : 'receivedMessages', $pb.PbFieldType.PM,
        subBuilder: ReceivedMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullResponse clone() => PullResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PullResponse copyWith(void Function(PullResponse) updates) =>
      super.copyWith((message) => updates(message as PullResponse))
          as PullResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PullResponse create() => PullResponse._();
  @$core.override
  PullResponse createEmptyInstance() => create();
  static $pb.PbList<PullResponse> createRepeated() =>
      $pb.PbList<PullResponse>();
  @$core.pragma('dart2js:noInline')
  static PullResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PullResponse>(create);
  static PullResponse? _defaultInstance;

  /// Optional. Received Pub/Sub messages. The list will be empty if there are no
  /// more messages available in the backlog, or if no messages could be returned
  /// before the request timeout. For JSON, the response can be entirely
  /// empty. The Pub/Sub system may return fewer than the `maxMessages` requested
  /// even if there are more messages available in the backlog.
  @$pb.TagNumber(1)
  $pb.PbList<ReceivedMessage> get receivedMessages => $_getList(0);
}

/// Request for the ModifyAckDeadline method.
class ModifyAckDeadlineRequest extends $pb.GeneratedMessage {
  factory ModifyAckDeadlineRequest({
    $core.String? subscription,
    $core.int? ackDeadlineSeconds,
    $core.Iterable<$core.String>? ackIds,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (ackDeadlineSeconds != null)
      result.ackDeadlineSeconds = ackDeadlineSeconds;
    if (ackIds != null) result.ackIds.addAll(ackIds);
    return result;
  }

  ModifyAckDeadlineRequest._();

  factory ModifyAckDeadlineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ModifyAckDeadlineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModifyAckDeadlineRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..a<$core.int>(
        3, _omitFieldNames ? '' : 'ackDeadlineSeconds', $pb.PbFieldType.O3)
    ..pPS(4, _omitFieldNames ? '' : 'ackIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModifyAckDeadlineRequest clone() =>
      ModifyAckDeadlineRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModifyAckDeadlineRequest copyWith(
          void Function(ModifyAckDeadlineRequest) updates) =>
      super.copyWith((message) => updates(message as ModifyAckDeadlineRequest))
          as ModifyAckDeadlineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ModifyAckDeadlineRequest create() => ModifyAckDeadlineRequest._();
  @$core.override
  ModifyAckDeadlineRequest createEmptyInstance() => create();
  static $pb.PbList<ModifyAckDeadlineRequest> createRepeated() =>
      $pb.PbList<ModifyAckDeadlineRequest>();
  @$core.pragma('dart2js:noInline')
  static ModifyAckDeadlineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModifyAckDeadlineRequest>(create);
  static ModifyAckDeadlineRequest? _defaultInstance;

  /// Required. The name of the subscription.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Required. The new ack deadline with respect to the time this request was
  /// sent to the Pub/Sub system. For example, if the value is 10, the new ack
  /// deadline will expire 10 seconds after the `ModifyAckDeadline` call was
  /// made. Specifying zero might immediately make the message available for
  /// delivery to another subscriber client. This typically results in an
  /// increase in the rate of message redeliveries (that is, duplicates).
  /// The minimum deadline you can specify is 0 seconds.
  /// The maximum deadline you can specify in a single request is 600 seconds
  /// (10 minutes).
  @$pb.TagNumber(3)
  $core.int get ackDeadlineSeconds => $_getIZ(1);
  @$pb.TagNumber(3)
  set ackDeadlineSeconds($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(3)
  $core.bool hasAckDeadlineSeconds() => $_has(1);
  @$pb.TagNumber(3)
  void clearAckDeadlineSeconds() => $_clearField(3);

  /// Required. List of acknowledgment IDs.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get ackIds => $_getList(2);
}

/// Request for the Acknowledge method.
class AcknowledgeRequest extends $pb.GeneratedMessage {
  factory AcknowledgeRequest({
    $core.String? subscription,
    $core.Iterable<$core.String>? ackIds,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (ackIds != null) result.ackIds.addAll(ackIds);
    return result;
  }

  AcknowledgeRequest._();

  factory AcknowledgeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AcknowledgeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcknowledgeRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..pPS(2, _omitFieldNames ? '' : 'ackIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeRequest clone() => AcknowledgeRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeRequest copyWith(void Function(AcknowledgeRequest) updates) =>
      super.copyWith((message) => updates(message as AcknowledgeRequest))
          as AcknowledgeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AcknowledgeRequest create() => AcknowledgeRequest._();
  @$core.override
  AcknowledgeRequest createEmptyInstance() => create();
  static $pb.PbList<AcknowledgeRequest> createRepeated() =>
      $pb.PbList<AcknowledgeRequest>();
  @$core.pragma('dart2js:noInline')
  static AcknowledgeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcknowledgeRequest>(create);
  static AcknowledgeRequest? _defaultInstance;

  /// Required. The subscription whose message is being acknowledged.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Required. The acknowledgment ID for the messages being acknowledged that
  /// was returned by the Pub/Sub system in the `Pull` response. Must not be
  /// empty.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get ackIds => $_getList(1);
}

/// Request for the `StreamingPull` streaming RPC method. This request is used to
/// establish the initial stream as well as to stream acknowledgments and ack
/// deadline modifications from the client to the server.
class StreamingPullRequest extends $pb.GeneratedMessage {
  factory StreamingPullRequest({
    $core.String? subscription,
    $core.Iterable<$core.String>? ackIds,
    $core.Iterable<$core.int>? modifyDeadlineSeconds,
    $core.Iterable<$core.String>? modifyDeadlineAckIds,
    $core.int? streamAckDeadlineSeconds,
    $core.String? clientId,
    $fixnum.Int64? maxOutstandingMessages,
    $fixnum.Int64? maxOutstandingBytes,
    $fixnum.Int64? protocolVersion,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (ackIds != null) result.ackIds.addAll(ackIds);
    if (modifyDeadlineSeconds != null)
      result.modifyDeadlineSeconds.addAll(modifyDeadlineSeconds);
    if (modifyDeadlineAckIds != null)
      result.modifyDeadlineAckIds.addAll(modifyDeadlineAckIds);
    if (streamAckDeadlineSeconds != null)
      result.streamAckDeadlineSeconds = streamAckDeadlineSeconds;
    if (clientId != null) result.clientId = clientId;
    if (maxOutstandingMessages != null)
      result.maxOutstandingMessages = maxOutstandingMessages;
    if (maxOutstandingBytes != null)
      result.maxOutstandingBytes = maxOutstandingBytes;
    if (protocolVersion != null) result.protocolVersion = protocolVersion;
    return result;
  }

  StreamingPullRequest._();

  factory StreamingPullRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamingPullRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamingPullRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..pPS(2, _omitFieldNames ? '' : 'ackIds')
    ..p<$core.int>(
        3, _omitFieldNames ? '' : 'modifyDeadlineSeconds', $pb.PbFieldType.K3)
    ..pPS(4, _omitFieldNames ? '' : 'modifyDeadlineAckIds')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'streamAckDeadlineSeconds',
        $pb.PbFieldType.O3)
    ..aOS(6, _omitFieldNames ? '' : 'clientId')
    ..aInt64(7, _omitFieldNames ? '' : 'maxOutstandingMessages')
    ..aInt64(8, _omitFieldNames ? '' : 'maxOutstandingBytes')
    ..aInt64(10, _omitFieldNames ? '' : 'protocolVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullRequest clone() =>
      StreamingPullRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullRequest copyWith(void Function(StreamingPullRequest) updates) =>
      super.copyWith((message) => updates(message as StreamingPullRequest))
          as StreamingPullRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamingPullRequest create() => StreamingPullRequest._();
  @$core.override
  StreamingPullRequest createEmptyInstance() => create();
  static $pb.PbList<StreamingPullRequest> createRepeated() =>
      $pb.PbList<StreamingPullRequest>();
  @$core.pragma('dart2js:noInline')
  static StreamingPullRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamingPullRequest>(create);
  static StreamingPullRequest? _defaultInstance;

  /// Required. The subscription for which to initialize the new stream. This
  /// must be provided in the first request on the stream, and must not be set in
  /// subsequent requests from client to server.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Optional. List of acknowledgment IDs for acknowledging previously received
  /// messages (received on this stream or a different stream). If an ack ID has
  /// expired, the corresponding message may be redelivered later. Acknowledging
  /// a message more than once will not result in an error. If the acknowledgment
  /// ID is malformed, the stream will be aborted with status `INVALID_ARGUMENT`.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get ackIds => $_getList(1);

  /// Optional. The list of new ack deadlines for the IDs listed in
  /// `modify_deadline_ack_ids`. The size of this list must be the same as the
  /// size of `modify_deadline_ack_ids`. If it differs the stream will be aborted
  /// with `INVALID_ARGUMENT`. Each element in this list is applied to the
  /// element in the same position in `modify_deadline_ack_ids`. The new ack
  /// deadline is with respect to the time this request was sent to the Pub/Sub
  /// system. Must be >= 0. For example, if the value is 10, the new ack deadline
  /// will expire 10 seconds after this request is received. If the value is 0,
  /// the message is immediately made available for another streaming or
  /// non-streaming pull request. If the value is < 0 (an error), the stream will
  /// be aborted with status `INVALID_ARGUMENT`.
  @$pb.TagNumber(3)
  $pb.PbList<$core.int> get modifyDeadlineSeconds => $_getList(2);

  /// Optional. List of acknowledgment IDs whose deadline will be modified based
  /// on the corresponding element in `modify_deadline_seconds`. This field can
  /// be used to indicate that more time is needed to process a message by the
  /// subscriber, or to make the message available for redelivery if the
  /// processing was interrupted.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get modifyDeadlineAckIds => $_getList(3);

  /// Required. The ack deadline to use for the stream. This must be provided in
  /// the first request on the stream, but it can also be updated on subsequent
  /// requests from client to server. The minimum deadline you can specify is 10
  /// seconds. The maximum deadline you can specify is 600 seconds (10 minutes).
  @$pb.TagNumber(5)
  $core.int get streamAckDeadlineSeconds => $_getIZ(4);
  @$pb.TagNumber(5)
  set streamAckDeadlineSeconds($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStreamAckDeadlineSeconds() => $_has(4);
  @$pb.TagNumber(5)
  void clearStreamAckDeadlineSeconds() => $_clearField(5);

  /// Optional. A unique identifier that is used to distinguish client instances
  /// from each other. Only needs to be provided on the initial request. When a
  /// stream disconnects and reconnects for the same stream, the client_id should
  /// be set to the same value so that state associated with the old stream can
  /// be transferred to the new stream. The same client_id should not be used for
  /// different client instances.
  @$pb.TagNumber(6)
  $core.String get clientId => $_getSZ(5);
  @$pb.TagNumber(6)
  set clientId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasClientId() => $_has(5);
  @$pb.TagNumber(6)
  void clearClientId() => $_clearField(6);

  /// Optional. Flow control settings for the maximum number of outstanding
  /// messages. When there are `max_outstanding_messages` currently sent to the
  /// streaming pull client that have not yet been acked or nacked, the server
  /// stops sending more messages. The sending of messages resumes once the
  /// number of outstanding messages is less than this value. If the value is
  /// <= 0, there is no limit to the number of outstanding messages. This
  /// property can only be set on the initial StreamingPullRequest. If it is set
  /// on a subsequent request, the stream will be aborted with status
  /// `INVALID_ARGUMENT`.
  @$pb.TagNumber(7)
  $fixnum.Int64 get maxOutstandingMessages => $_getI64(6);
  @$pb.TagNumber(7)
  set maxOutstandingMessages($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxOutstandingMessages() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxOutstandingMessages() => $_clearField(7);

  /// Optional. Flow control settings for the maximum number of outstanding
  /// bytes. When there are `max_outstanding_bytes` or more worth of messages
  /// currently sent to the streaming pull client that have not yet been acked or
  /// nacked, the server will stop sending more messages. The sending of messages
  /// resumes once the number of outstanding bytes is less than this value. If
  /// the value is <= 0, there is no limit to the number of outstanding bytes.
  /// This property can only be set on the initial StreamingPullRequest. If it is
  /// set on a subsequent request, the stream will be aborted with status
  /// `INVALID_ARGUMENT`.
  @$pb.TagNumber(8)
  $fixnum.Int64 get maxOutstandingBytes => $_getI64(7);
  @$pb.TagNumber(8)
  set maxOutstandingBytes($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMaxOutstandingBytes() => $_has(7);
  @$pb.TagNumber(8)
  void clearMaxOutstandingBytes() => $_clearField(8);

  /// Optional. The protocol version used by the client. This property can only
  /// be set on the initial StreamingPullRequest. If it is set on a subsequent
  /// request, the stream will be aborted with status `INVALID_ARGUMENT`.
  @$pb.TagNumber(10)
  $fixnum.Int64 get protocolVersion => $_getI64(8);
  @$pb.TagNumber(10)
  set protocolVersion($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(10)
  $core.bool hasProtocolVersion() => $_has(8);
  @$pb.TagNumber(10)
  void clearProtocolVersion() => $_clearField(10);
}

/// Acknowledgment IDs sent in one or more previous requests to acknowledge a
/// previously received message.
class StreamingPullResponse_AcknowledgeConfirmation
    extends $pb.GeneratedMessage {
  factory StreamingPullResponse_AcknowledgeConfirmation({
    $core.Iterable<$core.String>? ackIds,
    $core.Iterable<$core.String>? invalidAckIds,
    $core.Iterable<$core.String>? unorderedAckIds,
    $core.Iterable<$core.String>? temporaryFailedAckIds,
  }) {
    final result = create();
    if (ackIds != null) result.ackIds.addAll(ackIds);
    if (invalidAckIds != null) result.invalidAckIds.addAll(invalidAckIds);
    if (unorderedAckIds != null) result.unorderedAckIds.addAll(unorderedAckIds);
    if (temporaryFailedAckIds != null)
      result.temporaryFailedAckIds.addAll(temporaryFailedAckIds);
    return result;
  }

  StreamingPullResponse_AcknowledgeConfirmation._();

  factory StreamingPullResponse_AcknowledgeConfirmation.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamingPullResponse_AcknowledgeConfirmation.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamingPullResponse.AcknowledgeConfirmation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'ackIds')
    ..pPS(2, _omitFieldNames ? '' : 'invalidAckIds')
    ..pPS(3, _omitFieldNames ? '' : 'unorderedAckIds')
    ..pPS(4, _omitFieldNames ? '' : 'temporaryFailedAckIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_AcknowledgeConfirmation clone() =>
      StreamingPullResponse_AcknowledgeConfirmation()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_AcknowledgeConfirmation copyWith(
          void Function(StreamingPullResponse_AcknowledgeConfirmation)
              updates) =>
      super.copyWith((message) =>
              updates(message as StreamingPullResponse_AcknowledgeConfirmation))
          as StreamingPullResponse_AcknowledgeConfirmation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_AcknowledgeConfirmation create() =>
      StreamingPullResponse_AcknowledgeConfirmation._();
  @$core.override
  StreamingPullResponse_AcknowledgeConfirmation createEmptyInstance() =>
      create();
  static $pb.PbList<StreamingPullResponse_AcknowledgeConfirmation>
      createRepeated() =>
          $pb.PbList<StreamingPullResponse_AcknowledgeConfirmation>();
  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_AcknowledgeConfirmation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          StreamingPullResponse_AcknowledgeConfirmation>(create);
  static StreamingPullResponse_AcknowledgeConfirmation? _defaultInstance;

  /// Optional. Successfully processed acknowledgment IDs.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get ackIds => $_getList(0);

  /// Optional. List of acknowledgment IDs that were malformed or whose
  /// acknowledgment deadline has expired.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get invalidAckIds => $_getList(1);

  /// Optional. List of acknowledgment IDs that were out of order.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get unorderedAckIds => $_getList(2);

  /// Optional. List of acknowledgment IDs that failed processing with
  /// temporary issues.
  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get temporaryFailedAckIds => $_getList(3);
}

/// Acknowledgment IDs sent in one or more previous requests to modify the
/// deadline for a specific message.
class StreamingPullResponse_ModifyAckDeadlineConfirmation
    extends $pb.GeneratedMessage {
  factory StreamingPullResponse_ModifyAckDeadlineConfirmation({
    $core.Iterable<$core.String>? ackIds,
    $core.Iterable<$core.String>? invalidAckIds,
    $core.Iterable<$core.String>? temporaryFailedAckIds,
  }) {
    final result = create();
    if (ackIds != null) result.ackIds.addAll(ackIds);
    if (invalidAckIds != null) result.invalidAckIds.addAll(invalidAckIds);
    if (temporaryFailedAckIds != null)
      result.temporaryFailedAckIds.addAll(temporaryFailedAckIds);
    return result;
  }

  StreamingPullResponse_ModifyAckDeadlineConfirmation._();

  factory StreamingPullResponse_ModifyAckDeadlineConfirmation.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamingPullResponse_ModifyAckDeadlineConfirmation.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'StreamingPullResponse.ModifyAckDeadlineConfirmation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'ackIds')
    ..pPS(2, _omitFieldNames ? '' : 'invalidAckIds')
    ..pPS(3, _omitFieldNames ? '' : 'temporaryFailedAckIds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_ModifyAckDeadlineConfirmation clone() =>
      StreamingPullResponse_ModifyAckDeadlineConfirmation()
        ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_ModifyAckDeadlineConfirmation copyWith(
          void Function(StreamingPullResponse_ModifyAckDeadlineConfirmation)
              updates) =>
      super.copyWith((message) => updates(
              message as StreamingPullResponse_ModifyAckDeadlineConfirmation))
          as StreamingPullResponse_ModifyAckDeadlineConfirmation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_ModifyAckDeadlineConfirmation create() =>
      StreamingPullResponse_ModifyAckDeadlineConfirmation._();
  @$core.override
  StreamingPullResponse_ModifyAckDeadlineConfirmation createEmptyInstance() =>
      create();
  static $pb.PbList<StreamingPullResponse_ModifyAckDeadlineConfirmation>
      createRepeated() =>
          $pb.PbList<StreamingPullResponse_ModifyAckDeadlineConfirmation>();
  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_ModifyAckDeadlineConfirmation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          StreamingPullResponse_ModifyAckDeadlineConfirmation>(create);
  static StreamingPullResponse_ModifyAckDeadlineConfirmation? _defaultInstance;

  /// Optional. Successfully processed acknowledgment IDs.
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get ackIds => $_getList(0);

  /// Optional. List of acknowledgment IDs that were malformed or whose
  /// acknowledgment deadline has expired.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get invalidAckIds => $_getList(1);

  /// Optional. List of acknowledgment IDs that failed processing with
  /// temporary issues.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get temporaryFailedAckIds => $_getList(2);
}

/// Subscription properties sent as part of the response.
class StreamingPullResponse_SubscriptionProperties
    extends $pb.GeneratedMessage {
  factory StreamingPullResponse_SubscriptionProperties({
    $core.bool? exactlyOnceDeliveryEnabled,
    $core.bool? messageOrderingEnabled,
  }) {
    final result = create();
    if (exactlyOnceDeliveryEnabled != null)
      result.exactlyOnceDeliveryEnabled = exactlyOnceDeliveryEnabled;
    if (messageOrderingEnabled != null)
      result.messageOrderingEnabled = messageOrderingEnabled;
    return result;
  }

  StreamingPullResponse_SubscriptionProperties._();

  factory StreamingPullResponse_SubscriptionProperties.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamingPullResponse_SubscriptionProperties.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamingPullResponse.SubscriptionProperties',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'exactlyOnceDeliveryEnabled')
    ..aOB(2, _omitFieldNames ? '' : 'messageOrderingEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_SubscriptionProperties clone() =>
      StreamingPullResponse_SubscriptionProperties()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse_SubscriptionProperties copyWith(
          void Function(StreamingPullResponse_SubscriptionProperties)
              updates) =>
      super.copyWith((message) =>
              updates(message as StreamingPullResponse_SubscriptionProperties))
          as StreamingPullResponse_SubscriptionProperties;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_SubscriptionProperties create() =>
      StreamingPullResponse_SubscriptionProperties._();
  @$core.override
  StreamingPullResponse_SubscriptionProperties createEmptyInstance() =>
      create();
  static $pb.PbList<StreamingPullResponse_SubscriptionProperties>
      createRepeated() =>
          $pb.PbList<StreamingPullResponse_SubscriptionProperties>();
  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse_SubscriptionProperties getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          StreamingPullResponse_SubscriptionProperties>(create);
  static StreamingPullResponse_SubscriptionProperties? _defaultInstance;

  /// Optional. True iff exactly once delivery is enabled for this
  /// subscription.
  @$pb.TagNumber(1)
  $core.bool get exactlyOnceDeliveryEnabled => $_getBF(0);
  @$pb.TagNumber(1)
  set exactlyOnceDeliveryEnabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExactlyOnceDeliveryEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearExactlyOnceDeliveryEnabled() => $_clearField(1);

  /// Optional. True iff message ordering is enabled for this subscription.
  @$pb.TagNumber(2)
  $core.bool get messageOrderingEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set messageOrderingEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageOrderingEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageOrderingEnabled() => $_clearField(2);
}

/// Response for the `StreamingPull` method. This response is used to stream
/// messages from the server to the client.
class StreamingPullResponse extends $pb.GeneratedMessage {
  factory StreamingPullResponse({
    $core.Iterable<ReceivedMessage>? receivedMessages,
    StreamingPullResponse_ModifyAckDeadlineConfirmation?
        modifyAckDeadlineConfirmation,
    StreamingPullResponse_SubscriptionProperties? subscriptionProperties,
    StreamingPullResponse_AcknowledgeConfirmation? acknowledgeConfirmation,
  }) {
    final result = create();
    if (receivedMessages != null)
      result.receivedMessages.addAll(receivedMessages);
    if (modifyAckDeadlineConfirmation != null)
      result.modifyAckDeadlineConfirmation = modifyAckDeadlineConfirmation;
    if (subscriptionProperties != null)
      result.subscriptionProperties = subscriptionProperties;
    if (acknowledgeConfirmation != null)
      result.acknowledgeConfirmation = acknowledgeConfirmation;
    return result;
  }

  StreamingPullResponse._();

  factory StreamingPullResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamingPullResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamingPullResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<ReceivedMessage>(
        1, _omitFieldNames ? '' : 'receivedMessages', $pb.PbFieldType.PM,
        subBuilder: ReceivedMessage.create)
    ..aOM<StreamingPullResponse_ModifyAckDeadlineConfirmation>(
        3, _omitFieldNames ? '' : 'modifyAckDeadlineConfirmation',
        subBuilder: StreamingPullResponse_ModifyAckDeadlineConfirmation.create)
    ..aOM<StreamingPullResponse_SubscriptionProperties>(
        4, _omitFieldNames ? '' : 'subscriptionProperties',
        subBuilder: StreamingPullResponse_SubscriptionProperties.create)
    ..aOM<StreamingPullResponse_AcknowledgeConfirmation>(
        5, _omitFieldNames ? '' : 'acknowledgeConfirmation',
        subBuilder: StreamingPullResponse_AcknowledgeConfirmation.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse clone() =>
      StreamingPullResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamingPullResponse copyWith(
          void Function(StreamingPullResponse) updates) =>
      super.copyWith((message) => updates(message as StreamingPullResponse))
          as StreamingPullResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse create() => StreamingPullResponse._();
  @$core.override
  StreamingPullResponse createEmptyInstance() => create();
  static $pb.PbList<StreamingPullResponse> createRepeated() =>
      $pb.PbList<StreamingPullResponse>();
  @$core.pragma('dart2js:noInline')
  static StreamingPullResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamingPullResponse>(create);
  static StreamingPullResponse? _defaultInstance;

  /// Optional. Received Pub/Sub messages.
  @$pb.TagNumber(1)
  $pb.PbList<ReceivedMessage> get receivedMessages => $_getList(0);

  /// Optional. This field will only be set if `enable_exactly_once_delivery` is
  /// set to `true` and is not guaranteed to be populated.
  @$pb.TagNumber(3)
  StreamingPullResponse_ModifyAckDeadlineConfirmation
      get modifyAckDeadlineConfirmation => $_getN(1);
  @$pb.TagNumber(3)
  set modifyAckDeadlineConfirmation(
          StreamingPullResponse_ModifyAckDeadlineConfirmation value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasModifyAckDeadlineConfirmation() => $_has(1);
  @$pb.TagNumber(3)
  void clearModifyAckDeadlineConfirmation() => $_clearField(3);
  @$pb.TagNumber(3)
  StreamingPullResponse_ModifyAckDeadlineConfirmation
      ensureModifyAckDeadlineConfirmation() => $_ensure(1);

  /// Optional. Properties associated with this subscription.
  @$pb.TagNumber(4)
  StreamingPullResponse_SubscriptionProperties get subscriptionProperties =>
      $_getN(2);
  @$pb.TagNumber(4)
  set subscriptionProperties(
          StreamingPullResponse_SubscriptionProperties value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSubscriptionProperties() => $_has(2);
  @$pb.TagNumber(4)
  void clearSubscriptionProperties() => $_clearField(4);
  @$pb.TagNumber(4)
  StreamingPullResponse_SubscriptionProperties ensureSubscriptionProperties() =>
      $_ensure(2);

  /// Optional. This field will only be set if `enable_exactly_once_delivery` is
  /// set to `true` and is not guaranteed to be populated.
  @$pb.TagNumber(5)
  StreamingPullResponse_AcknowledgeConfirmation get acknowledgeConfirmation =>
      $_getN(3);
  @$pb.TagNumber(5)
  set acknowledgeConfirmation(
          StreamingPullResponse_AcknowledgeConfirmation value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAcknowledgeConfirmation() => $_has(3);
  @$pb.TagNumber(5)
  void clearAcknowledgeConfirmation() => $_clearField(5);
  @$pb.TagNumber(5)
  StreamingPullResponse_AcknowledgeConfirmation
      ensureAcknowledgeConfirmation() => $_ensure(3);
}

/// Request for the `CreateSnapshot` method.
class CreateSnapshotRequest extends $pb.GeneratedMessage {
  factory CreateSnapshotRequest({
    $core.String? name,
    $core.String? subscription,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? labels,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? tags,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (subscription != null) result.subscription = subscription;
    if (labels != null) result.labels.addEntries(labels);
    if (tags != null) result.tags.addEntries(tags);
    return result;
  }

  CreateSnapshotRequest._();

  factory CreateSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSnapshotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'subscription')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'labels',
        entryClassName: 'CreateSnapshotRequest.LabelsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'tags',
        entryClassName: 'CreateSnapshotRequest.TagsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSnapshotRequest clone() =>
      CreateSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSnapshotRequest copyWith(
          void Function(CreateSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSnapshotRequest))
          as CreateSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateSnapshotRequest create() => CreateSnapshotRequest._();
  @$core.override
  CreateSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<CreateSnapshotRequest> createRepeated() =>
      $pb.PbList<CreateSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSnapshotRequest>(create);
  static CreateSnapshotRequest? _defaultInstance;

  /// Required. User-provided name for this snapshot. If the name is not provided
  /// in the request, the server will assign a random name for this snapshot on
  /// the same project as the subscription. Note that for REST API requests, you
  /// must specify a name.  See the [resource name
  /// rules](https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names).
  /// Format is `projects/{project}/snapshots/{snap}`.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Required. The subscription whose backlog the snapshot retains.
  /// Specifically, the created snapshot is guaranteed to retain:
  ///  (a) The existing backlog on the subscription. More precisely, this is
  ///      defined as the messages in the subscription's backlog that are
  ///      unacknowledged upon the successful completion of the
  ///      `CreateSnapshot` request; as well as:
  ///  (b) Any messages published to the subscription's topic following the
  ///      successful completion of the CreateSnapshot request.
  /// Format is `projects/{project}/subscriptions/{sub}`.
  @$pb.TagNumber(2)
  $core.String get subscription => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscription($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscription() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscription() => $_clearField(2);

  /// Optional. See [Creating and managing
  /// labels](https://cloud.google.com/pubsub/docs/labels).
  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get labels => $_getMap(2);

  /// Optional. Input only. Immutable. Tag keys/values directly bound to this
  /// resource. For example:
  ///   "123/environment": "production",
  ///   "123/costCenter": "marketing"
  /// See https://docs.cloud.google.com/pubsub/docs/tags for more information on
  /// using tags with Pub/Sub resources.
  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get tags => $_getMap(3);
}

/// Request for the UpdateSnapshot method.
class UpdateSnapshotRequest extends $pb.GeneratedMessage {
  factory UpdateSnapshotRequest({
    Snapshot? snapshot,
    $5.FieldMask? updateMask,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    if (updateMask != null) result.updateMask = updateMask;
    return result;
  }

  UpdateSnapshotRequest._();

  factory UpdateSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateSnapshotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOM<Snapshot>(1, _omitFieldNames ? '' : 'snapshot',
        subBuilder: Snapshot.create)
    ..aOM<$5.FieldMask>(2, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $5.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSnapshotRequest clone() =>
      UpdateSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateSnapshotRequest copyWith(
          void Function(UpdateSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateSnapshotRequest))
          as UpdateSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateSnapshotRequest create() => UpdateSnapshotRequest._();
  @$core.override
  UpdateSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateSnapshotRequest> createRepeated() =>
      $pb.PbList<UpdateSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateSnapshotRequest>(create);
  static UpdateSnapshotRequest? _defaultInstance;

  /// Required. The updated snapshot object.
  @$pb.TagNumber(1)
  Snapshot get snapshot => $_getN(0);
  @$pb.TagNumber(1)
  set snapshot(Snapshot value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
  @$pb.TagNumber(1)
  Snapshot ensureSnapshot() => $_ensure(0);

  /// Required. Indicates which fields in the provided snapshot to update.
  /// Must be specified and non-empty.
  @$pb.TagNumber(2)
  $5.FieldMask get updateMask => $_getN(1);
  @$pb.TagNumber(2)
  set updateMask($5.FieldMask value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateMask() => $_clearField(2);
  @$pb.TagNumber(2)
  $5.FieldMask ensureUpdateMask() => $_ensure(1);
}

/// A snapshot resource. Snapshots are used in
/// [Seek](https://cloud.google.com/pubsub/docs/replay-overview)
/// operations, which allow you to manage message acknowledgments in bulk. That
/// is, you can set the acknowledgment state of messages in an existing
/// subscription to the state captured by a snapshot.
class Snapshot extends $pb.GeneratedMessage {
  factory Snapshot({
    $core.String? name,
    $core.String? topic,
    $2.Timestamp? expireTime,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? labels,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (topic != null) result.topic = topic;
    if (expireTime != null) result.expireTime = expireTime;
    if (labels != null) result.labels.addEntries(labels);
    return result;
  }

  Snapshot._();

  factory Snapshot.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Snapshot.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Snapshot',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'topic')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'expireTime',
        subBuilder: $2.Timestamp.create)
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'labels',
        entryClassName: 'Snapshot.LabelsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('google.pubsub.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Snapshot clone() => Snapshot()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Snapshot copyWith(void Function(Snapshot) updates) =>
      super.copyWith((message) => updates(message as Snapshot)) as Snapshot;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Snapshot create() => Snapshot._();
  @$core.override
  Snapshot createEmptyInstance() => create();
  static $pb.PbList<Snapshot> createRepeated() => $pb.PbList<Snapshot>();
  @$core.pragma('dart2js:noInline')
  static Snapshot getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Snapshot>(create);
  static Snapshot? _defaultInstance;

  /// Optional. The name of the snapshot.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// Optional. The name of the topic from which this snapshot is retaining
  /// messages.
  @$pb.TagNumber(2)
  $core.String get topic => $_getSZ(1);
  @$pb.TagNumber(2)
  set topic($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearTopic() => $_clearField(2);

  /// Optional. The snapshot is guaranteed to exist up until this time.
  /// A newly-created snapshot expires no later than 7 days from the time of its
  /// creation. Its exact lifetime is determined at creation by the existing
  /// backlog in the source subscription. Specifically, the lifetime of the
  /// snapshot is `7 days - (age of oldest unacked message in the subscription)`.
  /// For example, consider a subscription whose oldest unacked message is 3 days
  /// old. If a snapshot is created from this subscription, the snapshot -- which
  /// will always capture this 3-day-old backlog as long as the snapshot
  /// exists -- will expire in 4 days. The service will refuse to create a
  /// snapshot that would expire in less than 1 hour after creation.
  @$pb.TagNumber(3)
  $2.Timestamp get expireTime => $_getN(2);
  @$pb.TagNumber(3)
  set expireTime($2.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasExpireTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpireTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureExpireTime() => $_ensure(2);

  /// Optional. See [Creating and managing labels]
  /// (https://cloud.google.com/pubsub/docs/labels).
  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get labels => $_getMap(3);
}

/// Request for the GetSnapshot method.
class GetSnapshotRequest extends $pb.GeneratedMessage {
  factory GetSnapshotRequest({
    $core.String? snapshot,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  GetSnapshotRequest._();

  factory GetSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSnapshotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshot')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotRequest clone() => GetSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotRequest copyWith(void Function(GetSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as GetSnapshotRequest))
          as GetSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSnapshotRequest create() => GetSnapshotRequest._();
  @$core.override
  GetSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<GetSnapshotRequest> createRepeated() =>
      $pb.PbList<GetSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotRequest>(create);
  static GetSnapshotRequest? _defaultInstance;

  /// Required. The name of the snapshot to get.
  /// Format is `projects/{project}/snapshots/{snap}`.
  @$pb.TagNumber(1)
  $core.String get snapshot => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshot($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
}

/// Request for the `ListSnapshots` method.
class ListSnapshotsRequest extends $pb.GeneratedMessage {
  factory ListSnapshotsRequest({
    $core.String? project,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final result = create();
    if (project != null) result.project = project;
    if (pageSize != null) result.pageSize = pageSize;
    if (pageToken != null) result.pageToken = pageToken;
    return result;
  }

  ListSnapshotsRequest._();

  factory ListSnapshotsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSnapshotsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSnapshotsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSnapshotsRequest clone() =>
      ListSnapshotsRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSnapshotsRequest copyWith(void Function(ListSnapshotsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSnapshotsRequest))
          as ListSnapshotsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSnapshotsRequest create() => ListSnapshotsRequest._();
  @$core.override
  ListSnapshotsRequest createEmptyInstance() => create();
  static $pb.PbList<ListSnapshotsRequest> createRepeated() =>
      $pb.PbList<ListSnapshotsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSnapshotsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSnapshotsRequest>(create);
  static ListSnapshotsRequest? _defaultInstance;

  /// Required. The name of the project in which to list snapshots.
  /// Format is `projects/{project-id}`.
  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => $_clearField(1);

  /// Optional. Maximum number of snapshots to return.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => $_clearField(2);

  /// Optional. The value returned by the last `ListSnapshotsResponse`; indicates
  /// that this is a continuation of a prior `ListSnapshots` call, and that the
  /// system should return the next page of data.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => $_clearField(3);
}

/// Response for the `ListSnapshots` method.
class ListSnapshotsResponse extends $pb.GeneratedMessage {
  factory ListSnapshotsResponse({
    $core.Iterable<Snapshot>? snapshots,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (snapshots != null) result.snapshots.addAll(snapshots);
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  ListSnapshotsResponse._();

  factory ListSnapshotsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListSnapshotsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSnapshotsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..pc<Snapshot>(1, _omitFieldNames ? '' : 'snapshots', $pb.PbFieldType.PM,
        subBuilder: Snapshot.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSnapshotsResponse clone() =>
      ListSnapshotsResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSnapshotsResponse copyWith(
          void Function(ListSnapshotsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSnapshotsResponse))
          as ListSnapshotsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSnapshotsResponse create() => ListSnapshotsResponse._();
  @$core.override
  ListSnapshotsResponse createEmptyInstance() => create();
  static $pb.PbList<ListSnapshotsResponse> createRepeated() =>
      $pb.PbList<ListSnapshotsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSnapshotsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSnapshotsResponse>(create);
  static ListSnapshotsResponse? _defaultInstance;

  /// Optional. The resulting snapshots.
  @$pb.TagNumber(1)
  $pb.PbList<Snapshot> get snapshots => $_getList(0);

  /// Optional. If not empty, indicates that there may be more snapshot that
  /// match the request; this value should be passed in a new
  /// `ListSnapshotsRequest`.
  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => $_clearField(2);
}

/// Request for the `DeleteSnapshot` method.
class DeleteSnapshotRequest extends $pb.GeneratedMessage {
  factory DeleteSnapshotRequest({
    $core.String? snapshot,
  }) {
    final result = create();
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  DeleteSnapshotRequest._();

  factory DeleteSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteSnapshotRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'snapshot')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSnapshotRequest clone() =>
      DeleteSnapshotRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSnapshotRequest copyWith(
          void Function(DeleteSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSnapshotRequest))
          as DeleteSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSnapshotRequest create() => DeleteSnapshotRequest._();
  @$core.override
  DeleteSnapshotRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSnapshotRequest> createRepeated() =>
      $pb.PbList<DeleteSnapshotRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSnapshotRequest>(create);
  static DeleteSnapshotRequest? _defaultInstance;

  /// Required. The name of the snapshot to delete.
  /// Format is `projects/{project}/snapshots/{snap}`.
  @$pb.TagNumber(1)
  $core.String get snapshot => $_getSZ(0);
  @$pb.TagNumber(1)
  set snapshot($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSnapshot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSnapshot() => $_clearField(1);
}

enum SeekRequest_Target { time, snapshot, notSet }

/// Request for the `Seek` method.
class SeekRequest extends $pb.GeneratedMessage {
  factory SeekRequest({
    $core.String? subscription,
    $2.Timestamp? time,
    $core.String? snapshot,
  }) {
    final result = create();
    if (subscription != null) result.subscription = subscription;
    if (time != null) result.time = time;
    if (snapshot != null) result.snapshot = snapshot;
    return result;
  }

  SeekRequest._();

  factory SeekRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SeekRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SeekRequest_Target>
      _SeekRequest_TargetByTag = {
    2: SeekRequest_Target.time,
    3: SeekRequest_Target.snapshot,
    0: SeekRequest_Target.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeekRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'subscription')
    ..aOM<$2.Timestamp>(2, _omitFieldNames ? '' : 'time',
        subBuilder: $2.Timestamp.create)
    ..aOS(3, _omitFieldNames ? '' : 'snapshot')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekRequest clone() => SeekRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekRequest copyWith(void Function(SeekRequest) updates) =>
      super.copyWith((message) => updates(message as SeekRequest))
          as SeekRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SeekRequest create() => SeekRequest._();
  @$core.override
  SeekRequest createEmptyInstance() => create();
  static $pb.PbList<SeekRequest> createRepeated() => $pb.PbList<SeekRequest>();
  @$core.pragma('dart2js:noInline')
  static SeekRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SeekRequest>(create);
  static SeekRequest? _defaultInstance;

  SeekRequest_Target whichTarget() =>
      _SeekRequest_TargetByTag[$_whichOneof(0)]!;
  void clearTarget() => $_clearField($_whichOneof(0));

  /// Required. The subscription to affect.
  @$pb.TagNumber(1)
  $core.String get subscription => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscription($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscription() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscription() => $_clearField(1);

  /// Optional. The time to seek to.
  /// Messages retained in the subscription that were published before this
  /// time are marked as acknowledged, and messages retained in the
  /// subscription that were published after this time are marked as
  /// unacknowledged. Note that this operation affects only those messages
  /// retained in the subscription (configured by the combination of
  /// `message_retention_duration` and `retain_acked_messages`). For example,
  /// if `time` corresponds to a point before the message retention
  /// window (or to a point before the system's notion of the subscription
  /// creation time), only retained messages will be marked as unacknowledged,
  /// and already-expunged messages will not be restored.
  @$pb.TagNumber(2)
  $2.Timestamp get time => $_getN(1);
  @$pb.TagNumber(2)
  set time($2.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.Timestamp ensureTime() => $_ensure(1);

  /// Optional. The snapshot to seek to. The snapshot's topic must be the same
  /// as that of the provided subscription. Format is
  /// `projects/{project}/snapshots/{snap}`.
  @$pb.TagNumber(3)
  $core.String get snapshot => $_getSZ(2);
  @$pb.TagNumber(3)
  set snapshot($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSnapshot() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnapshot() => $_clearField(3);
}

/// Response for the `Seek` method (this response is empty).
class SeekResponse extends $pb.GeneratedMessage {
  factory SeekResponse() => create();

  SeekResponse._();

  factory SeekResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SeekResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeekResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'google.pubsub.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekResponse clone() => SeekResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeekResponse copyWith(void Function(SeekResponse) updates) =>
      super.copyWith((message) => updates(message as SeekResponse))
          as SeekResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SeekResponse create() => SeekResponse._();
  @$core.override
  SeekResponse createEmptyInstance() => create();
  static $pb.PbList<SeekResponse> createRepeated() =>
      $pb.PbList<SeekResponse>();
  @$core.pragma('dart2js:noInline')
  static SeekResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SeekResponse>(create);
  static SeekResponse? _defaultInstance;
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
