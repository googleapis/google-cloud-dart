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

import 'package:protobuf/protobuf.dart' as $pb;

/// Possible states for ingestion from Amazon Kinesis Data Streams.
class IngestionDataSourceSettings_AwsKinesis_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const IngestionDataSourceSettings_AwsKinesis_State STATE_UNSPECIFIED =
      IngestionDataSourceSettings_AwsKinesis_State._(
          0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// Ingestion is active.
  static const IngestionDataSourceSettings_AwsKinesis_State ACTIVE =
      IngestionDataSourceSettings_AwsKinesis_State._(
          1, _omitEnumNames ? '' : 'ACTIVE');

  /// Permission denied encountered while consuming data from Kinesis.
  /// This can happen if:
  ///   - The provided `aws_role_arn` does not exist or does not have the
  ///     appropriate permissions attached.
  ///   - The provided `aws_role_arn` is not set up properly for Identity
  ///     Federation using `gcp_service_account`.
  ///   - The Pub/Sub SA is not granted the
  ///     `iam.serviceAccounts.getOpenIdToken` permission on
  ///     `gcp_service_account`.
  static const IngestionDataSourceSettings_AwsKinesis_State
      KINESIS_PERMISSION_DENIED =
      IngestionDataSourceSettings_AwsKinesis_State._(
          2, _omitEnumNames ? '' : 'KINESIS_PERMISSION_DENIED');

  /// Permission denied encountered while publishing to the topic. This can
  /// happen if the Pub/Sub SA has not been granted the [appropriate publish
  /// permissions](https://cloud.google.com/pubsub/docs/access-control#pubsub.publisher)
  static const IngestionDataSourceSettings_AwsKinesis_State
      PUBLISH_PERMISSION_DENIED =
      IngestionDataSourceSettings_AwsKinesis_State._(
          3, _omitEnumNames ? '' : 'PUBLISH_PERMISSION_DENIED');

  /// The Kinesis stream does not exist.
  static const IngestionDataSourceSettings_AwsKinesis_State STREAM_NOT_FOUND =
      IngestionDataSourceSettings_AwsKinesis_State._(
          4, _omitEnumNames ? '' : 'STREAM_NOT_FOUND');

  /// The Kinesis consumer does not exist.
  static const IngestionDataSourceSettings_AwsKinesis_State CONSUMER_NOT_FOUND =
      IngestionDataSourceSettings_AwsKinesis_State._(
          5, _omitEnumNames ? '' : 'CONSUMER_NOT_FOUND');

  static const $core.List<IngestionDataSourceSettings_AwsKinesis_State> values =
      <IngestionDataSourceSettings_AwsKinesis_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    KINESIS_PERMISSION_DENIED,
    PUBLISH_PERMISSION_DENIED,
    STREAM_NOT_FOUND,
    CONSUMER_NOT_FOUND,
  ];

  static final $core.List<IngestionDataSourceSettings_AwsKinesis_State?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 5);
  static IngestionDataSourceSettings_AwsKinesis_State? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IngestionDataSourceSettings_AwsKinesis_State._(super.value, super.name);
}

/// Possible states for ingestion from Cloud Storage.
class IngestionDataSourceSettings_CloudStorage_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const IngestionDataSourceSettings_CloudStorage_State
      STATE_UNSPECIFIED = IngestionDataSourceSettings_CloudStorage_State._(
          0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// Ingestion is active.
  static const IngestionDataSourceSettings_CloudStorage_State ACTIVE =
      IngestionDataSourceSettings_CloudStorage_State._(
          1, _omitEnumNames ? '' : 'ACTIVE');

  /// Permission denied encountered while calling the Cloud Storage API. This
  /// can happen if the Pub/Sub SA has not been granted the
  /// [appropriate
  /// permissions](https://cloud.google.com/storage/docs/access-control/iam-permissions):
  /// - storage.objects.list: to list the objects in a bucket.
  /// - storage.objects.get: to read the objects in a bucket.
  /// - storage.buckets.get: to verify the bucket exists.
  static const IngestionDataSourceSettings_CloudStorage_State
      CLOUD_STORAGE_PERMISSION_DENIED =
      IngestionDataSourceSettings_CloudStorage_State._(
          2, _omitEnumNames ? '' : 'CLOUD_STORAGE_PERMISSION_DENIED');

  /// Permission denied encountered while publishing to the topic. This can
  /// happen if the Pub/Sub SA has not been granted the [appropriate publish
  /// permissions](https://cloud.google.com/pubsub/docs/access-control#pubsub.publisher)
  static const IngestionDataSourceSettings_CloudStorage_State
      PUBLISH_PERMISSION_DENIED =
      IngestionDataSourceSettings_CloudStorage_State._(
          3, _omitEnumNames ? '' : 'PUBLISH_PERMISSION_DENIED');

  /// The provided Cloud Storage bucket doesn't exist.
  static const IngestionDataSourceSettings_CloudStorage_State BUCKET_NOT_FOUND =
      IngestionDataSourceSettings_CloudStorage_State._(
          4, _omitEnumNames ? '' : 'BUCKET_NOT_FOUND');

  /// The Cloud Storage bucket has too many objects, ingestion will be
  /// paused.
  static const IngestionDataSourceSettings_CloudStorage_State TOO_MANY_OBJECTS =
      IngestionDataSourceSettings_CloudStorage_State._(
          5, _omitEnumNames ? '' : 'TOO_MANY_OBJECTS');

  static const $core.List<IngestionDataSourceSettings_CloudStorage_State>
      values = <IngestionDataSourceSettings_CloudStorage_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    CLOUD_STORAGE_PERMISSION_DENIED,
    PUBLISH_PERMISSION_DENIED,
    BUCKET_NOT_FOUND,
    TOO_MANY_OBJECTS,
  ];

  static final $core.List<IngestionDataSourceSettings_CloudStorage_State?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 5);
  static IngestionDataSourceSettings_CloudStorage_State? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IngestionDataSourceSettings_CloudStorage_State._(
      super.value, super.name);
}

/// Possible states for managed ingestion from Event Hubs.
class IngestionDataSourceSettings_AzureEventHubs_State
    extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      STATE_UNSPECIFIED = IngestionDataSourceSettings_AzureEventHubs_State._(
          0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// Ingestion is active.
  static const IngestionDataSourceSettings_AzureEventHubs_State ACTIVE =
      IngestionDataSourceSettings_AzureEventHubs_State._(
          1, _omitEnumNames ? '' : 'ACTIVE');

  /// Permission denied encountered while consuming data from Event Hubs.
  /// This can happen when `client_id`, or `tenant_id` are invalid. Or the
  /// right permissions haven't been granted.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      EVENT_HUBS_PERMISSION_DENIED =
      IngestionDataSourceSettings_AzureEventHubs_State._(
          2, _omitEnumNames ? '' : 'EVENT_HUBS_PERMISSION_DENIED');

  /// Permission denied encountered while publishing to the topic.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      PUBLISH_PERMISSION_DENIED =
      IngestionDataSourceSettings_AzureEventHubs_State._(
          3, _omitEnumNames ? '' : 'PUBLISH_PERMISSION_DENIED');

  /// The provided Event Hubs namespace couldn't be found.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      NAMESPACE_NOT_FOUND = IngestionDataSourceSettings_AzureEventHubs_State._(
          4, _omitEnumNames ? '' : 'NAMESPACE_NOT_FOUND');

  /// The provided Event Hub couldn't be found.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      EVENT_HUB_NOT_FOUND = IngestionDataSourceSettings_AzureEventHubs_State._(
          5, _omitEnumNames ? '' : 'EVENT_HUB_NOT_FOUND');

  /// The provided Event Hubs subscription couldn't be found.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      SUBSCRIPTION_NOT_FOUND =
      IngestionDataSourceSettings_AzureEventHubs_State._(
          6, _omitEnumNames ? '' : 'SUBSCRIPTION_NOT_FOUND');

  /// The provided Event Hubs resource group couldn't be found.
  static const IngestionDataSourceSettings_AzureEventHubs_State
      RESOURCE_GROUP_NOT_FOUND =
      IngestionDataSourceSettings_AzureEventHubs_State._(
          7, _omitEnumNames ? '' : 'RESOURCE_GROUP_NOT_FOUND');

  static const $core.List<IngestionDataSourceSettings_AzureEventHubs_State>
      values = <IngestionDataSourceSettings_AzureEventHubs_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    EVENT_HUBS_PERMISSION_DENIED,
    PUBLISH_PERMISSION_DENIED,
    NAMESPACE_NOT_FOUND,
    EVENT_HUB_NOT_FOUND,
    SUBSCRIPTION_NOT_FOUND,
    RESOURCE_GROUP_NOT_FOUND,
  ];

  static final $core.List<IngestionDataSourceSettings_AzureEventHubs_State?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 7);
  static IngestionDataSourceSettings_AzureEventHubs_State? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IngestionDataSourceSettings_AzureEventHubs_State._(
      super.value, super.name);
}

/// Possible states for managed ingestion from Amazon MSK.
class IngestionDataSourceSettings_AwsMsk_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const IngestionDataSourceSettings_AwsMsk_State STATE_UNSPECIFIED =
      IngestionDataSourceSettings_AwsMsk_State._(
          0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// Ingestion is active.
  static const IngestionDataSourceSettings_AwsMsk_State ACTIVE =
      IngestionDataSourceSettings_AwsMsk_State._(
          1, _omitEnumNames ? '' : 'ACTIVE');

  /// Permission denied encountered while consuming data from Amazon MSK.
  static const IngestionDataSourceSettings_AwsMsk_State MSK_PERMISSION_DENIED =
      IngestionDataSourceSettings_AwsMsk_State._(
          2, _omitEnumNames ? '' : 'MSK_PERMISSION_DENIED');

  /// Permission denied encountered while publishing to the topic.
  static const IngestionDataSourceSettings_AwsMsk_State
      PUBLISH_PERMISSION_DENIED = IngestionDataSourceSettings_AwsMsk_State._(
          3, _omitEnumNames ? '' : 'PUBLISH_PERMISSION_DENIED');

  /// The provided MSK cluster wasn't found.
  static const IngestionDataSourceSettings_AwsMsk_State CLUSTER_NOT_FOUND =
      IngestionDataSourceSettings_AwsMsk_State._(
          4, _omitEnumNames ? '' : 'CLUSTER_NOT_FOUND');

  /// The provided topic wasn't found.
  static const IngestionDataSourceSettings_AwsMsk_State TOPIC_NOT_FOUND =
      IngestionDataSourceSettings_AwsMsk_State._(
          5, _omitEnumNames ? '' : 'TOPIC_NOT_FOUND');

  static const $core.List<IngestionDataSourceSettings_AwsMsk_State> values =
      <IngestionDataSourceSettings_AwsMsk_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    MSK_PERMISSION_DENIED,
    PUBLISH_PERMISSION_DENIED,
    CLUSTER_NOT_FOUND,
    TOPIC_NOT_FOUND,
  ];

  static final $core.List<IngestionDataSourceSettings_AwsMsk_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static IngestionDataSourceSettings_AwsMsk_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IngestionDataSourceSettings_AwsMsk_State._(super.value, super.name);
}

/// Possible states for managed ingestion from Confluent Cloud.
class IngestionDataSourceSettings_ConfluentCloud_State
    extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      STATE_UNSPECIFIED = IngestionDataSourceSettings_ConfluentCloud_State._(
          0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// Ingestion is active.
  static const IngestionDataSourceSettings_ConfluentCloud_State ACTIVE =
      IngestionDataSourceSettings_ConfluentCloud_State._(
          1, _omitEnumNames ? '' : 'ACTIVE');

  /// Permission denied encountered while consuming data from Confluent
  /// Cloud.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      CONFLUENT_CLOUD_PERMISSION_DENIED =
      IngestionDataSourceSettings_ConfluentCloud_State._(
          2, _omitEnumNames ? '' : 'CONFLUENT_CLOUD_PERMISSION_DENIED');

  /// Permission denied encountered while publishing to the topic.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      PUBLISH_PERMISSION_DENIED =
      IngestionDataSourceSettings_ConfluentCloud_State._(
          3, _omitEnumNames ? '' : 'PUBLISH_PERMISSION_DENIED');

  /// The provided bootstrap server address is unreachable.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      UNREACHABLE_BOOTSTRAP_SERVER =
      IngestionDataSourceSettings_ConfluentCloud_State._(
          4, _omitEnumNames ? '' : 'UNREACHABLE_BOOTSTRAP_SERVER');

  /// The provided cluster wasn't found.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      CLUSTER_NOT_FOUND = IngestionDataSourceSettings_ConfluentCloud_State._(
          5, _omitEnumNames ? '' : 'CLUSTER_NOT_FOUND');

  /// The provided topic wasn't found.
  static const IngestionDataSourceSettings_ConfluentCloud_State
      TOPIC_NOT_FOUND = IngestionDataSourceSettings_ConfluentCloud_State._(
          6, _omitEnumNames ? '' : 'TOPIC_NOT_FOUND');

  static const $core.List<IngestionDataSourceSettings_ConfluentCloud_State>
      values = <IngestionDataSourceSettings_ConfluentCloud_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    CONFLUENT_CLOUD_PERMISSION_DENIED,
    PUBLISH_PERMISSION_DENIED,
    UNREACHABLE_BOOTSTRAP_SERVER,
    CLUSTER_NOT_FOUND,
    TOPIC_NOT_FOUND,
  ];

  static final $core.List<IngestionDataSourceSettings_ConfluentCloud_State?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 6);
  static IngestionDataSourceSettings_ConfluentCloud_State? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const IngestionDataSourceSettings_ConfluentCloud_State._(
      super.value, super.name);
}

/// Severity levels of Platform Logs.
class PlatformLogsSettings_Severity extends $pb.ProtobufEnum {
  /// Default value. Logs level is unspecified. Logs will be disabled.
  static const PlatformLogsSettings_Severity SEVERITY_UNSPECIFIED =
      PlatformLogsSettings_Severity._(
          0, _omitEnumNames ? '' : 'SEVERITY_UNSPECIFIED');

  /// Logs will be disabled.
  static const PlatformLogsSettings_Severity DISABLED =
      PlatformLogsSettings_Severity._(1, _omitEnumNames ? '' : 'DISABLED');

  /// Debug logs and higher-severity logs will be written.
  static const PlatformLogsSettings_Severity DEBUG =
      PlatformLogsSettings_Severity._(2, _omitEnumNames ? '' : 'DEBUG');

  /// Info logs and higher-severity logs will be written.
  static const PlatformLogsSettings_Severity INFO =
      PlatformLogsSettings_Severity._(3, _omitEnumNames ? '' : 'INFO');

  /// Warning logs and higher-severity logs will be written.
  static const PlatformLogsSettings_Severity WARNING =
      PlatformLogsSettings_Severity._(4, _omitEnumNames ? '' : 'WARNING');

  /// Only error logs will be written.
  static const PlatformLogsSettings_Severity ERROR =
      PlatformLogsSettings_Severity._(5, _omitEnumNames ? '' : 'ERROR');

  static const $core.List<PlatformLogsSettings_Severity> values =
      <PlatformLogsSettings_Severity>[
    SEVERITY_UNSPECIFIED,
    DISABLED,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
  ];

  static final $core.List<PlatformLogsSettings_Severity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static PlatformLogsSettings_Severity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlatformLogsSettings_Severity._(super.value, super.name);
}

/// The state of the topic.
class Topic_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const Topic_State STATE_UNSPECIFIED =
      Topic_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// The topic does not have any persistent errors.
  static const Topic_State ACTIVE =
      Topic_State._(1, _omitEnumNames ? '' : 'ACTIVE');

  /// Ingestion from the data source has encountered a permanent error.
  /// See the more detailed error state in the corresponding ingestion
  /// source configuration.
  static const Topic_State INGESTION_RESOURCE_ERROR =
      Topic_State._(2, _omitEnumNames ? '' : 'INGESTION_RESOURCE_ERROR');

  static const $core.List<Topic_State> values = <Topic_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    INGESTION_RESOURCE_ERROR,
  ];

  static final $core.List<Topic_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Topic_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Topic_State._(super.value, super.name);
}

/// Possible states for a subscription.
class Subscription_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const Subscription_State STATE_UNSPECIFIED =
      Subscription_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// The subscription can actively receive messages
  static const Subscription_State ACTIVE =
      Subscription_State._(1, _omitEnumNames ? '' : 'ACTIVE');

  /// The subscription cannot receive messages because of an error with the
  /// resource to which it pushes messages. See the more detailed error state
  /// in the corresponding configuration.
  static const Subscription_State RESOURCE_ERROR =
      Subscription_State._(2, _omitEnumNames ? '' : 'RESOURCE_ERROR');

  static const $core.List<Subscription_State> values = <Subscription_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    RESOURCE_ERROR,
  ];

  static final $core.List<Subscription_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Subscription_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Subscription_State._(super.value, super.name);
}

/// Possible states for a BigQuery subscription.
class BigQueryConfig_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const BigQueryConfig_State STATE_UNSPECIFIED =
      BigQueryConfig_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// The subscription can actively send messages to BigQuery
  static const BigQueryConfig_State ACTIVE =
      BigQueryConfig_State._(1, _omitEnumNames ? '' : 'ACTIVE');

  /// Cannot write to the BigQuery table because of permission denied errors.
  /// This can happen if
  /// - Pub/Sub SA has not been granted the [appropriate BigQuery IAM
  /// permissions](https://cloud.google.com/pubsub/docs/create-subscription#assign_bigquery_service_account)
  /// - bigquery.googleapis.com API is not enabled for the project
  /// ([instructions](https://cloud.google.com/service-usage/docs/enable-disable))
  static const BigQueryConfig_State PERMISSION_DENIED =
      BigQueryConfig_State._(2, _omitEnumNames ? '' : 'PERMISSION_DENIED');

  /// Cannot write to the BigQuery table because it does not exist.
  static const BigQueryConfig_State NOT_FOUND =
      BigQueryConfig_State._(3, _omitEnumNames ? '' : 'NOT_FOUND');

  /// Cannot write to the BigQuery table due to a schema mismatch.
  static const BigQueryConfig_State SCHEMA_MISMATCH =
      BigQueryConfig_State._(4, _omitEnumNames ? '' : 'SCHEMA_MISMATCH');

  /// Cannot write to the destination because enforce_in_transit is set to true
  /// and the destination locations are not in the allowed regions.
  static const BigQueryConfig_State IN_TRANSIT_LOCATION_RESTRICTION =
      BigQueryConfig_State._(
          5, _omitEnumNames ? '' : 'IN_TRANSIT_LOCATION_RESTRICTION');

  /// Cannot write to the BigQuery table because the table is not in the same
  /// location as where Vertex AI models used in `message_transform`s are
  /// deployed.
  static const BigQueryConfig_State VERTEX_AI_LOCATION_RESTRICTION =
      BigQueryConfig_State._(
          6, _omitEnumNames ? '' : 'VERTEX_AI_LOCATION_RESTRICTION');

  static const $core.List<BigQueryConfig_State> values = <BigQueryConfig_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    PERMISSION_DENIED,
    NOT_FOUND,
    SCHEMA_MISMATCH,
    IN_TRANSIT_LOCATION_RESTRICTION,
    VERTEX_AI_LOCATION_RESTRICTION,
  ];

  static final $core.List<BigQueryConfig_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static BigQueryConfig_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BigQueryConfig_State._(super.value, super.name);
}

/// Possible states for a Bigtable subscription.
/// Note: more states could be added in the future. Please code accordingly.
class BigtableConfig_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const BigtableConfig_State STATE_UNSPECIFIED =
      BigtableConfig_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// The subscription can actively send messages to Bigtable.
  static const BigtableConfig_State ACTIVE =
      BigtableConfig_State._(1, _omitEnumNames ? '' : 'ACTIVE');

  /// Cannot write to Bigtable because the instance, table, or app profile
  /// does not exist.
  static const BigtableConfig_State NOT_FOUND =
      BigtableConfig_State._(2, _omitEnumNames ? '' : 'NOT_FOUND');

  /// Cannot write to Bigtable because the app profile is not configured for
  /// single-cluster routing.
  static const BigtableConfig_State APP_PROFILE_MISCONFIGURED =
      BigtableConfig_State._(
          3, _omitEnumNames ? '' : 'APP_PROFILE_MISCONFIGURED');

  /// Cannot write to Bigtable because of permission denied errors.
  /// This can happen if:
  /// - The Pub/Sub service agent has not been granted the
  ///   [appropriate Bigtable IAM permission
  ///   bigtable.tables.mutateRows]({$universe.dns_names.final_documentation_domain}/bigtable/docs/access-control#permissions)
  /// - The bigtable.googleapis.com API is not enabled for the project
  ///   ([instructions]({$universe.dns_names.final_documentation_domain}/service-usage/docs/enable-disable))
  static const BigtableConfig_State PERMISSION_DENIED =
      BigtableConfig_State._(4, _omitEnumNames ? '' : 'PERMISSION_DENIED');

  /// Cannot write to Bigtable because of a missing column family ("data") or
  /// if there is no structured row key for the subscription name + message ID.
  static const BigtableConfig_State SCHEMA_MISMATCH =
      BigtableConfig_State._(5, _omitEnumNames ? '' : 'SCHEMA_MISMATCH');

  /// Cannot write to the destination because enforce_in_transit is set to true
  /// and the destination locations are not in the allowed regions.
  static const BigtableConfig_State IN_TRANSIT_LOCATION_RESTRICTION =
      BigtableConfig_State._(
          6, _omitEnumNames ? '' : 'IN_TRANSIT_LOCATION_RESTRICTION');

  /// Cannot write to Bigtable because the table is not in the same location as
  /// where Vertex AI models used in `message_transform`s are deployed.
  static const BigtableConfig_State VERTEX_AI_LOCATION_RESTRICTION =
      BigtableConfig_State._(
          7, _omitEnumNames ? '' : 'VERTEX_AI_LOCATION_RESTRICTION');

  static const $core.List<BigtableConfig_State> values = <BigtableConfig_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    NOT_FOUND,
    APP_PROFILE_MISCONFIGURED,
    PERMISSION_DENIED,
    SCHEMA_MISMATCH,
    IN_TRANSIT_LOCATION_RESTRICTION,
    VERTEX_AI_LOCATION_RESTRICTION,
  ];

  static final $core.List<BigtableConfig_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static BigtableConfig_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BigtableConfig_State._(super.value, super.name);
}

/// Possible states for a Cloud Storage subscription.
class CloudStorageConfig_State extends $pb.ProtobufEnum {
  /// Default value. This value is unused.
  static const CloudStorageConfig_State STATE_UNSPECIFIED =
      CloudStorageConfig_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');

  /// The subscription can actively send messages to Cloud Storage.
  static const CloudStorageConfig_State ACTIVE =
      CloudStorageConfig_State._(1, _omitEnumNames ? '' : 'ACTIVE');

  /// Cannot write to the Cloud Storage bucket because of permission denied
  /// errors.
  static const CloudStorageConfig_State PERMISSION_DENIED =
      CloudStorageConfig_State._(2, _omitEnumNames ? '' : 'PERMISSION_DENIED');

  /// Cannot write to the Cloud Storage bucket because it does not exist.
  static const CloudStorageConfig_State NOT_FOUND =
      CloudStorageConfig_State._(3, _omitEnumNames ? '' : 'NOT_FOUND');

  /// Cannot write to the destination because enforce_in_transit is set to true
  /// and the destination locations are not in the allowed regions.
  static const CloudStorageConfig_State IN_TRANSIT_LOCATION_RESTRICTION =
      CloudStorageConfig_State._(
          4, _omitEnumNames ? '' : 'IN_TRANSIT_LOCATION_RESTRICTION');

  /// Cannot write to the Cloud Storage bucket due to an incompatibility
  /// between the topic schema and subscription settings.
  static const CloudStorageConfig_State SCHEMA_MISMATCH =
      CloudStorageConfig_State._(5, _omitEnumNames ? '' : 'SCHEMA_MISMATCH');

  /// Cannot write to the Cloud Storage bucket because the bucket is not in the
  /// same location as where Vertex AI models used in `message_transform`s are
  /// deployed.
  static const CloudStorageConfig_State VERTEX_AI_LOCATION_RESTRICTION =
      CloudStorageConfig_State._(
          6, _omitEnumNames ? '' : 'VERTEX_AI_LOCATION_RESTRICTION');

  static const $core.List<CloudStorageConfig_State> values =
      <CloudStorageConfig_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    PERMISSION_DENIED,
    NOT_FOUND,
    IN_TRANSIT_LOCATION_RESTRICTION,
    SCHEMA_MISMATCH,
    VERTEX_AI_LOCATION_RESTRICTION,
  ];

  static final $core.List<CloudStorageConfig_State?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static CloudStorageConfig_State? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CloudStorageConfig_State._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
