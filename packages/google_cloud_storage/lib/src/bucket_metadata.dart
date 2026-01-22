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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'object_access_controls.dart';
import 'object_metadata.dart';

/// The bucket's
/// [Autoclass](https://docs.cloud.google.com/storage/docs/autoclass)
/// configuration.
///
/// When enabled, controls the storage class of objects based on how and when
/// the objects are accessed.
final class BucketAutoclass {
  /// Whether or not Autoclass is enabled on this bucket.
  ///
  /// By default, this boolean is not set, and Autoclass is disabled.
  final bool? enabled;

  /// The storage class that objects in the bucket eventually transition to if
  /// they are not accessed for a certain period of time.
  ///
  /// Can be `"NEARLINE"` or `"ARCHIVE"`. The default value is `"NEARLINE"`.
  final String? terminalStorageClass;

  /// The time at which the terminal storage class was updated.
  final Timestamp? terminalStorageClassUpdateTime;

  /// The time at which Autoclass was last enabled or disabled.
  final Timestamp? toggleTime;

  BucketAutoclass({
    this.enabled,
    this.terminalStorageClass,
    this.terminalStorageClassUpdateTime,
    this.toggleTime,
  });

  @override
  String toString() =>
      'BucketAutoclass(enabled: $enabled, '
      'terminalStorageClass: $terminalStorageClass, '
      'terminalStorageClassUpdateTime: $terminalStorageClassUpdateTime, '
      'toggleTime: $toggleTime)';

  BucketAutoclass copyWith({
    bool? enabled,
    String? terminalStorageClass,
    Timestamp? terminalStorageClassUpdateTime,
    Timestamp? toggleTime,
  }) => BucketAutoclass(
    enabled: enabled ?? this.enabled,
    terminalStorageClass: terminalStorageClass ?? this.terminalStorageClass,
    terminalStorageClassUpdateTime:
        terminalStorageClassUpdateTime ?? this.terminalStorageClassUpdateTime,
    toggleTime: toggleTime ?? this.toggleTime,
  );

  BucketAutoclass copyWithout({
    bool enabled = false,
    bool terminalStorageClass = false,
    bool terminalStorageClassUpdateTime = false,
    bool toggleTime = false,
  }) => BucketAutoclass(
    enabled: enabled ? null : this.enabled,
    terminalStorageClass: terminalStorageClass
        ? null
        : this.terminalStorageClass,
    terminalStorageClassUpdateTime: terminalStorageClassUpdateTime
        ? null
        : this.terminalStorageClassUpdateTime,
    toggleTime: toggleTime ? null : this.toggleTime,
  );
}

/// The bucket's billing configuration.
final class BucketBilling {
  /// Whether [Requester Pays](https://docs.cloud.google.com/storage/docs/requester-pays)
  /// is enabled for this bucket.
  final bool? requesterPays;

  BucketBilling({this.requesterPays});

  @override
  String toString() => 'BucketBilling(requesterPays: $requesterPays)';

  BucketBilling copyWith({bool? requesterPays}) =>
      BucketBilling(requesterPays: requesterPays ?? this.requesterPays);

  BucketBilling copyWithout({bool requesterPays = false}) =>
      BucketBilling(requesterPays: requesterPays ? null : this.requesterPays);
}

/// An Access Control List (ACL) entry for a bucket.
///
/// There are three roles that can be assigned to an entity:
/// 1. `READER`s can get the bucket, though no acl property will be returned,
///    and list the bucket's objects.
/// 2. `WRITER`s are `READER`s, and they can insert objects into the bucket and
///    delete the bucket's objects.
/// 3. `OWNER`s are `WRITER`s, and they can get the acl property of a bucket,
///    update a bucket, and call all [BucketAccessControl]-related methods on
///    the bucket.
///
/// For more information, see
/// [Access Control](https://cloud.google.com/storage/docs/access-control), with
/// the caveat that this API uses `READER`, `WRITER`, and `OWNER` instead of
/// `READ`, `WRITE`, and `FULL_CONTROL`.
///
/// See [BucketAccessControls](https://docs.cloud.google.com/storage/docs/json_api/v1/bucketAccessControls).
final class BucketAccessControl {
  /// The name of the bucket.
  final String? bucket;

  /// The domain associated with the entity, if any.
  final String? domain;

  /// The email address associated with the entity, if any.
  final String? email;

  /// The entity holding the permission.
  ///
  /// Must be either a tag followed by a dash and a value, or one of the
  /// non-parameterized tag.
  ///
  /// - `user-<userId>`
  /// - `user-<email>`
  /// - `group-<groupId>`
  /// - `group-<email>`
  /// - `domain-<domain>`
  /// - `project-team-<projectId>`
  /// - `allUsers`
  /// - `allAuthenticatedUsers`
  ///
  /// For example:
  /// - The user `liz@example.com` would be `"user-liz@example.com"`.
  /// - The group `example@googlegroups.com` would be
  ///   `"group-example@googlegroups.com"`.
  /// - To refer to all members of the domain `example.com`, the entity would
  ///   be `"domain-example.com"`.
  final String? entity;

  /// The ID for the entity, if any.
  final String? entityId;

  /// [HTTP 1.1 Entity tag](https://tools.ietf.org/html/rfc7232#section-2.3)
  /// for the access-control entry.
  final String? etag;

  /// The ID of the access-control entry.
  final String? id;

  /// The kind of item this is. For bucket access control entries, this is
  /// always `"storage#bucketAccessControl"`.
  final String? kind;

  /// The project team associated with the entity, if any.
  final ProjectTeam? projectTeam;

  /// The access permission for the entity.
  ///
  /// Acceptable values are `"OWNER"`, `"READER"`, and `"WRITER"`.
  final String? role;

  /// The link to this access-control entry.
  final Uri? selfLink;

  BucketAccessControl({
    this.bucket,
    this.domain,
    this.email,
    this.entity,
    this.entityId,
    this.etag,
    this.id,
    this.kind,
    this.projectTeam,
    this.role,
    this.selfLink,
  });

  @override
  String toString() =>
      'BucketAccessControl(bucket: $bucket, domain: $domain, '
      'email: $email, entity: $entity, entityId: $entityId, etag: $etag, '
      'id: $id, kind: $kind, projectTeam: $projectTeam, role: $role, '
      'selfLink: $selfLink)';

  BucketAccessControl copyWith({
    String? bucket,
    String? domain,
    String? email,
    String? entity,
    String? entityId,
    String? etag,
    String? id,
    String? kind,
    ProjectTeam? projectTeam,
    String? role,
    Uri? selfLink,
  }) => BucketAccessControl(
    bucket: bucket ?? this.bucket,
    domain: domain ?? this.domain,
    email: email ?? this.email,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    etag: etag ?? this.etag,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    projectTeam: projectTeam ?? this.projectTeam,
    role: role ?? this.role,
    selfLink: selfLink ?? this.selfLink,
  );

  BucketAccessControl copyWithout({
    bool bucket = false,
    bool domain = false,
    bool email = false,
    bool entity = false,
    bool entityId = false,
    bool etag = false,
    bool id = false,
    bool kind = false,
    bool projectTeam = false,
    bool role = false,
    bool selfLink = false,
  }) => BucketAccessControl(
    bucket: bucket ? null : this.bucket,
    domain: domain ? null : this.domain,
    email: email ? null : this.email,
    entity: entity ? null : this.entity,
    entityId: entityId ? null : this.entityId,
    etag: etag ? null : this.etag,
    id: id ? null : this.id,
    kind: kind ? null : this.kind,
    projectTeam: projectTeam ? null : this.projectTeam,
    role: role ? null : this.role,
    selfLink: selfLink ? null : this.selfLink,
  );
}

/// Encryption configuration for a bucket.
final class BucketEncryption {
  /// The [Cloud KMS key](https://docs.cloud.google.com/kms/docs/resource-hierarchy#keys)
  /// that will be used to encrypt objects inserted into this bucket, if no
  /// object encryption method is specified.
  final String? defaultKmsKeyName;

  BucketEncryption({this.defaultKmsKeyName});

  @override
  String toString() =>
      'BucketEncryption(defaultKmsKeyName: $defaultKmsKeyName)';

  BucketEncryption copyWith({String? defaultKmsKeyName}) => BucketEncryption(
    defaultKmsKeyName: defaultKmsKeyName ?? this.defaultKmsKeyName,
  );

  BucketEncryption copyWithout({bool defaultKmsKeyName = false}) =>
      BucketEncryption(
        defaultKmsKeyName: defaultKmsKeyName ? null : this.defaultKmsKeyName,
      );
}

/// The bucket's
/// [object retention configuration](https://docs.cloud.google.com/storage/docs/object-lock).
final class BucketObjectRetention {
  /// When set to `"Enabled"`, retention configurations can be set on objects
  /// in the bucket.
  final String? mode;

  BucketObjectRetention({this.mode});

  @override
  String toString() => 'BucketObjectRetention(mode: $mode)';

  BucketObjectRetention copyWith({String? mode}) =>
      BucketObjectRetention(mode: mode ?? this.mode);

  BucketObjectRetention copyWithout({bool mode = false}) =>
      BucketObjectRetention(mode: mode ? null : this.mode);
}

/// The [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
/// configuration for a bucket.
final class BucketCorsConfiguration {
  /// The value, in seconds, to return in the
  /// [`Access-Control-Max-Age`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Max-Age)
  /// header used in preflight responses.
  final int? maxAgeSeconds;

  /// The list of HTTP methods on which to include CORS response headers,
  ///
  /// You can specify methods explicitly (`"GET"`, `"OPTIONS"`, `"POST"`, etc)
  /// or use `"*"` to permit all methods.
  final List<String>? method;

  /// The list of [Origins](https://datatracker.ietf.org/doc/html/rfc6454)
  /// eligible to receive CORS response headers.
  ///
  /// You can specify origins explicitly or use `"*"` to permit all origins.
  final List<String>? origin;

  /// The list of HTTP headers, other than the
  /// [safe response headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_response_headers),
  /// to give permission to the user-agent to share across domains.
  final List<String>? responseHeader;

  BucketCorsConfiguration({
    this.maxAgeSeconds,
    this.method,
    this.origin,
    this.responseHeader,
  });

  @override
  String toString() =>
      'BucketCorsConfiguration(maxAgeSeconds: $maxAgeSeconds, method: $method, '
      'origin: $origin, responseHeader: $responseHeader)';

  BucketCorsConfiguration copyWith({
    int? maxAgeSeconds,
    List<String>? method,
    List<String>? origin,
    List<String>? responseHeader,
  }) => BucketCorsConfiguration(
    maxAgeSeconds: maxAgeSeconds ?? this.maxAgeSeconds,
    method: method ?? this.method,
    origin: origin ?? this.origin,
    responseHeader: responseHeader ?? this.responseHeader,
  );

  BucketCorsConfiguration copyWithout({
    bool maxAgeSeconds = false,
    bool method = false,
    bool origin = false,
    bool responseHeader = false,
  }) => BucketCorsConfiguration(
    maxAgeSeconds: maxAgeSeconds ? null : this.maxAgeSeconds,
    method: method ? null : this.method,
    origin: origin ? null : this.origin,
    responseHeader: responseHeader ? null : this.responseHeader,
  );
}

/// The bucket's custom placement configuration.
///
/// This is only relevant for
/// [Configurable dual regions](https://docs.cloud.google.com/storage/docs/locations#location-dr).
final class BucketCustomPlacementConfig {
  /// The list of individual regions that comprise a configurable dual-region
  /// bucket.
  ///
  /// See [Cloud Storage bucket locations](https://docs.cloud.google.com/storage/docs/locations#configurable)
  /// for a list of acceptable regions.
  final List<String>? dataLocations;

  BucketCustomPlacementConfig({this.dataLocations});

  @override
  String toString() =>
      'BucketCustomPlacementConfig(dataLocations: $dataLocations)';

  BucketCustomPlacementConfig copyWith({List<String>? dataLocations}) =>
      BucketCustomPlacementConfig(
        dataLocations: dataLocations ?? this.dataLocations,
      );

  BucketCustomPlacementConfig copyWithout({bool dataLocations = false}) =>
      BucketCustomPlacementConfig(
        dataLocations: dataLocations ? null : this.dataLocations,
      );
}

/// The bucket's hierarchical namespace configuration.
final class BucketHierarchicalNamespace {
  /// Whether or not
  /// [Hierarchical namespace](https://docs.cloud.google.com/storage/docs/hns-overview)
  /// is enabled on this bucket.
  final bool? enabled;

  BucketHierarchicalNamespace({this.enabled});

  @override
  String toString() => 'BucketHierarchicalNamespace(enabled: $enabled)';

  BucketHierarchicalNamespace copyWith({bool? enabled}) =>
      BucketHierarchicalNamespace(enabled: enabled ?? this.enabled);

  BucketHierarchicalNamespace copyWithout({bool enabled = false}) =>
      BucketHierarchicalNamespace(enabled: enabled ? null : this.enabled);
}

/// The bucket's IAM configuration.
final class BucketIamConfiguration {
  /// The bucket's
  /// [Public access prevention](https://docs.cloud.google.com/storage/docs/public-access-prevention)
  /// configuration.
  ///
  /// Must be `"inherited"` or `"enforced"`. If `"inherited"`, the bucket uses
  /// public access prevention only if the bucket is subject to the
  /// [public access prevention organization policy constraint](https://docs.cloud.google.com/storage/docs/org-policy-constraints#public-access-prevention).
  /// Defaults to `"inherited"`.
  final String? publicAccessPrevention;

  /// The bucket's
  /// [Uniform bucket-level access](https://cloud.google.com/storage/docs/uniform-bucket-level-access)
  /// configuration.
  final UniformBucketLevelAccess? uniformBucketLevelAccess;

  BucketIamConfiguration({
    this.publicAccessPrevention,
    this.uniformBucketLevelAccess,
  });

  @override
  String toString() =>
      'BucketIamConfiguration(publicAccessPrevention: $publicAccessPrevention, '
      'uniformBucketLevelAccess: $uniformBucketLevelAccess)';

  BucketIamConfiguration copyWith({
    String? publicAccessPrevention,
    UniformBucketLevelAccess? uniformBucketLevelAccess,
  }) => BucketIamConfiguration(
    publicAccessPrevention:
        publicAccessPrevention ?? this.publicAccessPrevention,
    uniformBucketLevelAccess:
        uniformBucketLevelAccess ?? this.uniformBucketLevelAccess,
  );

  BucketIamConfiguration copyWithout({
    bool publicAccessPrevention = false,
    bool uniformBucketLevelAccess = false,
  }) => BucketIamConfiguration(
    publicAccessPrevention: publicAccessPrevention
        ? null
        : this.publicAccessPrevention,
    uniformBucketLevelAccess: uniformBucketLevelAccess
        ? null
        : this.uniformBucketLevelAccess,
  );
}

/// The bucket's
/// [Uniform bucket-level access](https://cloud.google.com/storage/docs/uniform-bucket-level-access)
/// configuration.
final class UniformBucketLevelAccess {
  /// Whether or not the bucket uses uniform bucket-level access.
  ///
  /// If set, access checks only use bucket-level IAM policies or above.
  final bool? enabled;

  /// The deadline for changing
  /// `iamConfiguration.uniformBucketLevelAccess.enabled` from `true` to
  /// `false`.
  ///
  /// If the current time is after this deadline, the field is immutable.
  final Timestamp? lockedTime;

  UniformBucketLevelAccess({this.enabled, this.lockedTime});

  @override
  String toString() =>
      'UniformBucketLevelAccess(enabled: $enabled, lockedTime: $lockedTime)';

  UniformBucketLevelAccess copyWith({bool? enabled, Timestamp? lockedTime}) =>
      UniformBucketLevelAccess(
        enabled: enabled ?? this.enabled,
        lockedTime: lockedTime ?? this.lockedTime,
      );

  UniformBucketLevelAccess copyWithout({
    bool enabled = false,
    bool lockedTime = false,
  }) => UniformBucketLevelAccess(
    enabled: enabled ? null : this.enabled,
    lockedTime: lockedTime ? null : this.lockedTime,
  );
}

/// The bucket's
/// [IP filter](https://docs.cloud.google.com/storage/docs/ip-filtering-overview)
/// configuration.
///
/// Specifies the network sources that can access the bucket, as well as its
/// underlying objects.
final class BucketIpFilter {
  /// Whether to allow
  /// [service agent](https://docs.cloud.google.com/iam/docs/service-agents)
  /// access to the bucket, regardless of the IP filter configuration.
  ///
  /// If the value is true, other Google Cloud services can use service agents
  /// to access the bucket without IP-based validation.
  final bool? allowAllServiceAgentAccess;

  /// Whether to allow VPC networks that are defined in `vpcNetworkSources` to
  /// originate from a different organization.
  ///
  /// If set to `true`, the request allows cross-organizational VPC networks.
  /// If set to `false`, the request restricts the VPC networks to the same
  /// organization as the bucket. If not specified, the default value is
  /// `false`.
  final bool? allowCrossOrgVpcs;

  /// The state of the IP filter configuration.
  ///
  /// Valid values are `Enabled` and `Disabled`. When set to `Enabled`, IP
  /// filtering rules are applied to a bucket and all incoming requests to the
  /// bucket are evaluated against these rules. When set to `Disabled`, IP
  /// filtering rules are not applied to a bucket.
  final String? mode;

  /// The public network IP address ranges that can access the bucket and its
  /// data.
  final BucketPublicNetworkSource? publicNetworkSource;

  /// The list of [VPC networks](https://docs.cloud.google.com/vpc/docs/vpc)
  /// that can access the bucket.
  final List<BucketPublicNetworkSource>? vpcNetworkSources;

  BucketIpFilter({
    this.allowAllServiceAgentAccess,
    this.allowCrossOrgVpcs,
    this.mode,
    this.publicNetworkSource,
    this.vpcNetworkSources,
  });

  @override
  String toString() =>
      'BucketIpFilter(allowAllServiceAgentAccess: $allowAllServiceAgentAccess, '
      'allowCrossOrgVpcs: $allowCrossOrgVpcs, mode: $mode, '
      'publicNetworkSource: $publicNetworkSource, '
      'vpcNetworkSources: $vpcNetworkSources)';

  BucketIpFilter copyWith({
    bool? allowAllServiceAgentAccess,
    bool? allowCrossOrgVpcs,
    String? mode,
    BucketPublicNetworkSource? publicNetworkSource,
    List<BucketPublicNetworkSource>? vpcNetworkSources,
  }) => BucketIpFilter(
    allowAllServiceAgentAccess:
        allowAllServiceAgentAccess ?? this.allowAllServiceAgentAccess,
    allowCrossOrgVpcs: allowCrossOrgVpcs ?? this.allowCrossOrgVpcs,
    mode: mode ?? this.mode,
    publicNetworkSource: publicNetworkSource ?? this.publicNetworkSource,
    vpcNetworkSources: vpcNetworkSources ?? this.vpcNetworkSources,
  );

  BucketIpFilter copyWithout({
    bool allowAllServiceAgentAccess = false,
    bool allowCrossOrgVpcs = false,
    bool mode = false,
    bool publicNetworkSource = false,
    bool vpcNetworkSources = false,
  }) => BucketIpFilter(
    allowAllServiceAgentAccess: allowAllServiceAgentAccess
        ? null
        : this.allowAllServiceAgentAccess,
    allowCrossOrgVpcs: allowCrossOrgVpcs ? null : this.allowCrossOrgVpcs,
    mode: mode ? null : this.mode,
    publicNetworkSource: publicNetworkSource ? null : this.publicNetworkSource,
    vpcNetworkSources: vpcNetworkSources ? null : this.vpcNetworkSources,
  );
}

/// The public network IP address ranges that can access the bucket and its
/// data.
final class BucketPublicNetworkSource {
  /// The list of public IPv4 and IPv6 CIDR ranges that can access the bucket
  /// and its data.
  ///
  /// In the CIDR IP address block, the specified IP address must be properly
  /// truncated, meaning all the host bits must be zero or else the input is
  /// considered malformed. For example, `192.0.2.0/24` is accepted but
  /// `192.0.2.1/24` is not. Similarly, for IPv6, `2001:db8::/32` is accepted
  /// whereas `2001:db8::1/32` is not.
  final List<String>? allowedIpCidrRanges;

  BucketPublicNetworkSource({this.allowedIpCidrRanges});

  @override
  String toString() =>
      'BucketPublicNetworkSource(allowedIpCidrRanges: $allowedIpCidrRanges)';

  BucketPublicNetworkSource copyWith({List<String>? allowedIpCidrRanges}) =>
      BucketPublicNetworkSource(
        allowedIpCidrRanges: allowedIpCidrRanges ?? this.allowedIpCidrRanges,
      );

  BucketPublicNetworkSource copyWithout({bool allowedIpCidrRanges = false}) =>
      BucketPublicNetworkSource(
        allowedIpCidrRanges: allowedIpCidrRanges
            ? null
            : this.allowedIpCidrRanges,
      );
}

/// The bucket's
/// [lifecycle](https://docs.cloud.google.com/storage/docs/lifecycle)
/// configuration.
final class Lifecycle {
  /// The lifecycle rules to follow.
  final List<LifecycleRule>? rule;

  Lifecycle({this.rule});

  @override
  String toString() => 'Lifecycle(rule: $rule)';

  Lifecycle copyWith({List<LifecycleRule>? rule}) =>
      Lifecycle(rule: rule ?? this.rule);

  Lifecycle copyWithout({bool rule = false}) =>
      Lifecycle(rule: rule ? null : this.rule);
}

/// A lifecycle management rule, which is made of an action to take and the
/// conditions under which the action is taken.
final class LifecycleRule {
  /// The action to take.
  final LifecycleRuleAction? action;

  /// The conditions under which the action will be taken.
  final LifecycleRuleCondition? condition;

  LifecycleRule({this.action, this.condition});

  @override
  String toString() => 'LifecycleRule(action: $action, condition: $condition)';

  LifecycleRule copyWith({
    LifecycleRuleAction? action,
    LifecycleRuleCondition? condition,
  }) => LifecycleRule(
    action: action ?? this.action,
    condition: condition ?? this.condition,
  );

  LifecycleRule copyWithout({bool action = false, bool condition = false}) =>
      LifecycleRule(
        action: action ? null : this.action,
        condition: condition ? null : this.condition,
      );
}

/// The action to take for a lifecycle rule.
final class LifecycleRuleAction {
  /// The new storage class when action.type is `"SetStorageClass"`.
  ///
  /// See
  /// [lifecycle actions](https://docs.cloud.google.com/storage/docs/lifecycle#actions)
  /// for a table of supported storage class transitions.
  final String? storageClass;

  /// The type of the action.
  ///
  /// See
  /// [lifecycle actions](https://docs.cloud.google.com/storage/docs/lifecycle#actions)
  /// for a table of supported actions.
  final String? type;

  LifecycleRuleAction({this.storageClass, this.type});

  @override
  String toString() =>
      'LifecycleRuleAction(storageClass: $storageClass, type: $type)';

  LifecycleRuleAction copyWith({String? storageClass, String? type}) =>
      LifecycleRuleAction(
        storageClass: storageClass ?? this.storageClass,
        type: type ?? this.type,
      );

  LifecycleRuleAction copyWithout({
    bool storageClass = false,
    bool type = false,
  }) => LifecycleRuleAction(
    storageClass: storageClass ? null : this.storageClass,
    type: type ? null : this.type,
  );
}

/// The condition(s) under which a lifecycle rule action will be taken.
final class LifecycleRuleCondition {
  /// The age of an object in days.
  final int? age;

  /// A date in [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339) format
  /// with only the date part (for instance, "2013-01-15").
  ///
  /// This condition is satisfied when an object is created before midnight of
  /// the specified date in UTC.
  final String? createdBefore;

  /// A date in [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339)
  /// format with only the date part (for instance, "2013-01-15").
  ///
  /// This condition is satisfied when the `customTime` on an object is before
  /// this date in UTC.
  final String? customTimeBefore;

  /// Days since the date set in the `customTime` metadata for the object.
  ///
  /// This condition is satisfied when the current date and time is at least
  /// the specified number of days after the `customTime`.
  final int? daysSinceCustomTime;

  /// Number of days elapsed since the noncurrent timestamp of an object.
  ///
  /// This condition is relevant only for versioned objects. This condition is
  /// satisfied when an object has been noncurrent for more than the specified
  /// number of days.
  final int? daysSinceNoncurrentTime;

  /// Whether the condition matches live objects (`true`) or non-live objects
  /// (`false`).
  ///
  /// This condition is relevant only for versioned objects.
  final bool? isLive;

  /// List of object name prefixes.
  ///
  /// This condition is satisfied when the beginning of an object's name is an
  /// exact case-sensitive match with the prefix. The prefix must meet
  /// [object naming requirements](https://cloud.google.com/storage/docs/naming#objectnaming).
  final List<String>? matchesPrefix;

  /// Objects having any of the storage classes specified by this condition will
  /// be matched.
  ///
  /// Values include `"STANDARD"`, `"NEARLINE"`, `"COLDLINE"`, `"ARCHIVE"`,
  /// `"MULTI_REGIONAL"`, `"REGIONAL"`, `"DURABLE_REDUCED_AVAILABILITY"`.
  final List<String>? matchesStorageClass;

  /// List of object name suffixes.
  ///
  /// This condition is satisfied when the end of an object's name is an exact
  /// case-sensitive match with the suffix. The suffix must meet
  /// [object naming requirements](https://cloud.google.com/storage/docs/naming#objectnaming).
  final List<String>? matchesSuffix;

  /// A date in [RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339)
  /// format with only the date part (for instance, "2013-01-15").
  ///
  /// This condition is satisfied for objects that became noncurrent on a date
  /// prior to the one specified in this condition.
  final String? noncurrentTimeBefore;

  /// If the value is N, this condition is satisfied when there are at least N
  /// versions (including the live version) newer than this version of the
  /// object.
  ///
  /// Relevant only for versioned objects.
  final int? numNewerVersions;

  LifecycleRuleCondition({
    this.age,
    this.createdBefore,
    this.customTimeBefore,
    this.daysSinceCustomTime,
    this.daysSinceNoncurrentTime,
    this.isLive,
    this.matchesPrefix,
    this.matchesStorageClass,
    this.matchesSuffix,
    this.noncurrentTimeBefore,
    this.numNewerVersions,
  });

  @override
  String toString() =>
      'LifecycleRuleCondition(age: $age, createdBefore: $createdBefore, '
      'customTimeBefore: $customTimeBefore, '
      'daysSinceCustomTime: $daysSinceCustomTime, '
      'daysSinceNoncurrentTime: $daysSinceNoncurrentTime, '
      'isLive: $isLive, matchesPrefix: $matchesPrefix, '
      'matchesStorageClass: $matchesStorageClass, '
      'matchesSuffix: $matchesSuffix, '
      'noncurrentTimeBefore: $noncurrentTimeBefore, '
      'numNewerVersions: $numNewerVersions)';

  LifecycleRuleCondition copyWith({
    int? age,
    String? createdBefore,
    String? customTimeBefore,
    int? daysSinceCustomTime,
    int? daysSinceNoncurrentTime,
    bool? isLive,
    List<String>? matchesPrefix,
    List<String>? matchesStorageClass,
    List<String>? matchesSuffix,
    String? noncurrentTimeBefore,
    int? numNewerVersions,
  }) => LifecycleRuleCondition(
    age: age ?? this.age,
    createdBefore: createdBefore ?? this.createdBefore,
    customTimeBefore: customTimeBefore ?? this.customTimeBefore,
    daysSinceCustomTime: daysSinceCustomTime ?? this.daysSinceCustomTime,
    daysSinceNoncurrentTime:
        daysSinceNoncurrentTime ?? this.daysSinceNoncurrentTime,
    isLive: isLive ?? this.isLive,
    matchesPrefix: matchesPrefix ?? this.matchesPrefix,
    matchesStorageClass: matchesStorageClass ?? this.matchesStorageClass,
    matchesSuffix: matchesSuffix ?? this.matchesSuffix,
    noncurrentTimeBefore: noncurrentTimeBefore ?? this.noncurrentTimeBefore,
    numNewerVersions: numNewerVersions ?? this.numNewerVersions,
  );

  LifecycleRuleCondition copyWithout({
    bool age = false,
    bool createdBefore = false,
    bool customTimeBefore = false,
    bool daysSinceCustomTime = false,
    bool daysSinceNoncurrentTime = false,
    bool isLive = false,
    bool matchesPrefix = false,
    bool matchesStorageClass = false,
    bool matchesSuffix = false,
    bool noncurrentTimeBefore = false,
    bool numNewerVersions = false,
  }) => LifecycleRuleCondition(
    age: age ? null : this.age,
    createdBefore: createdBefore ? null : this.createdBefore,
    customTimeBefore: customTimeBefore ? null : this.customTimeBefore,
    daysSinceCustomTime: daysSinceCustomTime ? null : this.daysSinceCustomTime,
    daysSinceNoncurrentTime: daysSinceNoncurrentTime
        ? null
        : this.daysSinceNoncurrentTime,
    isLive: isLive ? null : this.isLive,
    matchesPrefix: matchesPrefix ? null : this.matchesPrefix,
    matchesStorageClass: matchesStorageClass ? null : this.matchesStorageClass,
    matchesSuffix: matchesSuffix ? null : this.matchesSuffix,
    noncurrentTimeBefore: noncurrentTimeBefore
        ? null
        : this.noncurrentTimeBefore,
    numNewerVersions: numNewerVersions ? null : this.numNewerVersions,
  );
}

/// The bucket's logging configuration.
///
/// Defines the destination bucket and optional name prefix for the current
/// bucket's
/// [usage logs and storage logs](https://docs.cloud.google.com/storage/docs/access-logs).
final class BucketLoggingConfiguration {
  /// The destination bucket where the current bucket's logs should be placed.
  final String? logBucket;

  /// A prefix for log object names.
  ///
  /// The default prefix is the bucket name.
  final String? logObjectPrefix;

  BucketLoggingConfiguration({this.logBucket, this.logObjectPrefix});

  @override
  String toString() =>
      'Logging(logBucket: $logBucket, logObjectPrefix: $logObjectPrefix)';

  BucketLoggingConfiguration copyWith({
    String? logBucket,
    String? logObjectPrefix,
  }) => BucketLoggingConfiguration(
    logBucket: logBucket ?? this.logBucket,
    logObjectPrefix: logObjectPrefix ?? this.logObjectPrefix,
  );

  BucketLoggingConfiguration copyWithout({
    bool logBucket = false,
    bool logObjectPrefix = false,
  }) => BucketLoggingConfiguration(
    logBucket: logBucket ? null : this.logBucket,
    logObjectPrefix: logObjectPrefix ? null : this.logObjectPrefix,
  );
}

/// The owner of the bucket.
///
/// This is always the project team's owner group.
final class BucketOwner {
  /// The entity, in the form `"project-owner-<projectId>"`.
  final String? entity;

  /// The ID for the entity.
  final String? entityId;

  BucketOwner({this.entity, this.entityId});

  @override
  String toString() => 'BucketOwner(entity: $entity, entityId: $entityId)';

  /// Creates a new [BucketOwner] with the given non-`null` fields replaced.
  BucketOwner copyWith({String? entity, String? entityId}) => BucketOwner(
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
  );

  /// Creates a new [BucketOwner] with the given fields set to `null`.
  BucketOwner copyWithout({bool entity = false, bool entityId = false}) =>
      BucketOwner(
        entity: entity ? null : this.entity,
        entityId: entityId ? null : this.entityId,
      );
}

/// The bucket's [retention policy](https://docs.cloud.google.com/storage/docs/bucket-lock#retention-policy).
///
/// Defines the minimum age an object in the bucket must reach before it can be
/// deleted or replaced.
final class BucketRetentionPolicy {
  /// The time from which the retention policy was effective.
  final Timestamp? effectiveTime;

  /// Whether or not the retention policy is locked.
  ///
  /// If `true`, the retention policy cannot be removed and the retention period
  /// cannot be reduced.
  final bool? isLocked;

  /// The period of time, in seconds, that objects in the bucket must be
  /// retained and cannot be deleted, replaced, or made noncurrent.
  ///
  /// The value must be greater than 0 seconds and less than 3,155,760,000
  /// seconds (100 years).
  final int? retentionPeriod;

  BucketRetentionPolicy({
    this.effectiveTime,
    this.isLocked,
    this.retentionPeriod,
  });

  @override
  String toString() =>
      'RetentionPolicy(effectiveTime: $effectiveTime, isLocked: $isLocked, '
      'retentionPeriod: $retentionPeriod)';

  BucketRetentionPolicy copyWith({
    Timestamp? effectiveTime,
    bool? isLocked,
    int? retentionPeriod,
  }) => BucketRetentionPolicy(
    effectiveTime: effectiveTime ?? this.effectiveTime,
    isLocked: isLocked ?? this.isLocked,
    retentionPeriod: retentionPeriod ?? this.retentionPeriod,
  );

  BucketRetentionPolicy copyWithout({
    bool effectiveTime = false,
    bool isLocked = false,
    bool retentionPeriod = false,
  }) => BucketRetentionPolicy(
    effectiveTime: effectiveTime ? null : this.effectiveTime,
    isLocked: isLocked ? null : this.isLocked,
    retentionPeriod: retentionPeriod ? null : this.retentionPeriod,
  );
}

/// The bucket's
/// [soft delete policy](https://docs.cloud.google.com/storage/docs/soft-delete).
///
/// Defines the period of time during which objects in the bucket are retained
/// in a soft-deleted state after being deleted. Objects in a soft-deleted state
/// cannot be permanently deleted, and are restorable until their
/// [ObjectMetadata.hardDeleteTime].
final class BucketSoftDeletePolicy {
  /// The time from which the soft delete policy was effective.
  ///
  /// [effectiveTime] is updated whenever [retentionDurationSeconds] is
  /// increased.
  final Timestamp? effectiveTime;

  /// The period of time during which a soft-deleted object is retained and
  /// cannot be permanently deleted, in seconds.
  ///
  /// The value must be greater than or equal to `604800` (7 days) and less than
  /// `7776000` (90 days). The value can also be set to `0`, which disables the
  /// soft delete policy.
  final int? retentionDurationSeconds;

  BucketSoftDeletePolicy({this.effectiveTime, this.retentionDurationSeconds});

  @override
  String toString() =>
      'BucketSoftDeletePolicy(effectiveTime: $effectiveTime, '
      'retentionDurationSeconds: $retentionDurationSeconds)';

  BucketSoftDeletePolicy copyWith({
    Timestamp? effectiveTime,
    int? retentionDurationSeconds,
  }) => BucketSoftDeletePolicy(
    effectiveTime: effectiveTime ?? this.effectiveTime,
    retentionDurationSeconds:
        retentionDurationSeconds ?? this.retentionDurationSeconds,
  );

  BucketSoftDeletePolicy copyWithout({
    bool effectiveTime = false,
    bool retentionDurationSeconds = false,
  }) => BucketSoftDeletePolicy(
    effectiveTime: effectiveTime ? null : this.effectiveTime,
    retentionDurationSeconds: retentionDurationSeconds
        ? null
        : this.retentionDurationSeconds,
  );
}

/// The bucket's versioning configuration.
///
/// For more information, see
/// [Object Versioning](https://docs.cloud.google.com/storage/docs/object-versioning).
final class BucketVersioning {
  /// Whether versioning is enabled for this bucket.
  final bool? enabled;

  BucketVersioning({this.enabled});

  @override
  String toString() => 'BucketVersioning(enabled: $enabled)';

  BucketVersioning copyWith({bool? enabled}) =>
      BucketVersioning(enabled: enabled ?? this.enabled);

  BucketVersioning copyWithout({bool enabled = false}) =>
      BucketVersioning(enabled: enabled ? null : this.enabled);
}

/// The bucket's website configuration, controlling how the service behaves when
/// accessing bucket contents as a web site.
///
/// For more information, see
/// [Static Website Examples](https://docs.cloud.google.com/storage/docs/static-website).
final class BucketWebsiteConfiguration {
  /// If the requested object path is missing, the service will ensure the path
  /// has a trailing '/', appends this suffix, and attempts to retrieve the
  /// resulting object.
  ///
  /// This allows the creation of `index.html` objects to represent directory
  /// pages.
  final String? mainPageSuffix;

  /// If the requested object path is missing, and any [mainPageSuffix] object
  /// is missing, if applicable, the service returns the named object from this
  /// bucket as the content for a
  /// [`404 Not Found`](https://datatracker.ietf.org/doc/html/rfc7231#section-6.5.4)
  /// result.
  final String? notFoundPage;

  BucketWebsiteConfiguration({this.mainPageSuffix, this.notFoundPage});

  @override
  String toString() =>
      'BucketWebsiteConfiguration(mainPageSuffix: $mainPageSuffix, '
      'notFoundPage: $notFoundPage)';

  BucketWebsiteConfiguration copyWith({
    String? mainPageSuffix,
    String? notFoundPage,
  }) => BucketWebsiteConfiguration(
    mainPageSuffix: mainPageSuffix ?? this.mainPageSuffix,
    notFoundPage: notFoundPage ?? this.notFoundPage,
  );

  BucketWebsiteConfiguration copyWithout({
    bool mainPageSuffix = false,
    bool notFoundPage = false,
  }) => BucketWebsiteConfiguration(
    mainPageSuffix: mainPageSuffix ? null : this.mainPageSuffix,
    notFoundPage: notFoundPage ? null : this.notFoundPage,
  );
}

/// Information about a [Cloud Storage bucket].
///
/// For detailed information on the meaning of each field, see
/// [Bucket resource](https://docs.cloud.google.com/storage/docs/json_api/v1/buckets#resource).
///
/// [Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
final class BucketMetadata {
  /// Access controls on the bucket.
  final List<BucketAccessControl>? acl;

  /// The bucket's Autoclass configuration.
  final BucketAutoclass? autoclass;

  /// The bucket's billing configuration.
  final BucketBilling? billing;

  /// The bucket's
  /// [Cross-Origin Resource Sharing (CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
  /// configuration.
  final List<BucketCorsConfiguration>? cors;

  /// The bucket's custom placement configuration.
  ///
  /// This is only relevant for
  /// [Configurable dual regions](https://docs.cloud.google.com/storage/docs/locations#location-dr).
  final BucketCustomPlacementConfig? customPlacementConfig;

  /// Whether or not to automatically apply an
  /// [`eventBasedHold`](https://docs.cloud.google.com/storage/docs/object-holds#hold-types)
  /// to new objects added to the bucket.
  final bool? defaultEventBasedHold;

  /// Default access controls to apply to new objects when no ACL is provided.
  final List<ObjectAccessControl>? defaultObjectAcl;

  /// Encryption configuration for a bucket.
  final BucketEncryption? encryption;

  /// [HTTP 1.1 Entity tag](https://tools.ietf.org/html/rfc7232#section-2.3)
  /// for the bucket.
  final String? etag;

  /// The bucket's hierarchical namespace configuration.
  final BucketHierarchicalNamespace? hierarchicalNamespace;

  /// The bucket's IAM configuration.
  final BucketIamConfiguration? iamConfiguration;

  /// The ID of the bucket.
  final String? id;

  /// The bucket's
  /// [IP filter](https://docs.cloud.google.com/storage/docs/ip-filtering-overview)
  /// configuration.
  final BucketIpFilter? ipFilter;

  /// The version of the bucket.
  final int? generation;

  /// The time when a soft-deleted bucket is permanently deleted and can no
  /// longer be restored.
  ///
  /// This time is always equal to or later than the latest `hardDeleteTime` of
  /// any soft-deleted object within the bucket.
  final Timestamp? hardDeleteTime;

  /// The kind of item this is. For buckets, this is always `storage#bucket`.
  final String? kind;

  /// User-provided labels, in key/value pairs.
  final Map<String, String>? labels;

  /// The bucket's
  /// [lifecycle](https://docs.cloud.google.com/storage/docs/lifecycle)
  /// configuration.
  final Lifecycle? lifecycle;

  /// The location of the bucket.
  ///
  /// Object data for objects in the bucket resides in physical storage within
  /// this location. Defaults to `"US"`.
  ///
  /// See [Cloud Storage bucket locations](https://docs.cloud.google.com/storage/docs/locations) for the authoritative list.
  final String? location;

  /// The type of location that the bucket resides in.
  ///
  /// Possible values include `"region"`, `"dual-region"`, and `"multi-region"`.
  final String? locationType;

  /// The bucket's logging configuration.
  final BucketLoggingConfiguration? logging;

  /// The metadata generation of this bucket.
  final int? metageneration;

  /// The name of the bucket.
  final String? name;

  /// The bucket's
  /// [object retention configuration](https://docs.cloud.google.com/storage/docs/object-lock).
  final BucketObjectRetention? objectRetention;

  /// The owner of the bucket.
  ///
  /// This will always be the project team's owner group.
  final BucketOwner? owner;

  /// The project number of the project the bucket belongs to.
  final String? projectNumber;

  /// The bucket's retention policy.
  final BucketRetentionPolicy? retentionPolicy;

  /// The recovery point objective for cross-region replication of the bucket.
  ///
  /// Applicable only for dual- and multi-region buckets. `"DEFAULT"` uses
  /// default replication. `"ASYNC_TURBO"` enables turbo replication,
  /// which is valid for dual-region buckets only.
  ///
  /// If rpo is not specified when the bucket is created, it defaults to
  /// `"DEFAULT"`.
  ///
  /// For more information, see
  /// [redundancy across regions](https://docs.cloud.google.com/storage/docs/availability-durability#cross-region-redundancy).
  final String? rpo;

  /// The bucket's
  /// [soft delete policy](https://docs.cloud.google.com/storage/docs/soft-delete).
  final BucketSoftDeletePolicy? softDeletePolicy;

  /// The time at which the bucket became
  /// [soft-deleted](https://docs.cloud.google.com/storage/docs/soft-delete).
  final Timestamp? softDeleteTime;

  /// The bucket's default storage class, used whenever no
  /// [ObjectMetadata.storageClass] is specified for a newly-created object.
  ///
  /// If `storageClass` is not specified when the bucket is created, it defaults
  /// to `"STANDARD"`. For available storage classes, see
  /// [Storage classes](https://docs.cloud.google.com/storage/docs/storage-classes).
  final String? storageClass;

  /// The URI of this bucket.
  final Uri? selfLink;

  /// The creation time of the bucket.
  final Timestamp? timeCreated;

  /// The time at which the bucket's metadata or IAM policy was last updated
  final Timestamp? updated;

  /// The bucket's versioning configuration, controlling how the service
  /// behaves when accessing bucket contents as a web site.
  final BucketVersioning? versioning;

  /// The bucket's website configuration.
  final BucketWebsiteConfiguration? website;

  BucketMetadata({
    this.acl,
    this.autoclass,
    this.billing,
    this.cors,
    this.customPlacementConfig,
    this.defaultEventBasedHold,
    this.defaultObjectAcl,
    this.encryption,
    this.etag,
    this.generation,
    this.hardDeleteTime,
    this.hierarchicalNamespace,
    this.iamConfiguration,
    this.id,
    this.ipFilter,
    this.kind,
    this.labels,
    this.lifecycle,
    this.location,
    this.locationType,
    this.logging,
    this.metageneration,
    this.name,
    this.objectRetention,
    this.owner,
    this.projectNumber,
    this.retentionPolicy,
    this.rpo,
    this.softDeletePolicy,
    this.softDeleteTime,
    this.storageClass,
    this.selfLink,
    this.timeCreated,
    this.updated,
    this.versioning,
    this.website,
  });

  @override
  String toString() =>
      'BucketMetadata(acl: $acl, autoclass: $autoclass, billing: $billing, '
      'cors: $cors, customPlacementConfig: $customPlacementConfig, '
      'defaultEventBasedHold: $defaultEventBasedHold, '
      'defaultObjectAcl: $defaultObjectAcl, encryption: $encryption, '
      'etag: $etag, generation: $generation, '
      'hardDeleteTime: $hardDeleteTime, '
      'hierarchicalNamespace: $hierarchicalNamespace, '
      'iamConfiguration: $iamConfiguration, id: $id, ipFilter: $ipFilter, '
      'kind: $kind, labels: $labels, lifecycle: $lifecycle, '
      'location: $location, locationType: $locationType, logging: $logging, '
      'metageneration: $metageneration, name: $name, '
      'objectRetention: $objectRetention, owner: $owner, '
      'projectNumber: $projectNumber, retentionPolicy: $retentionPolicy, '
      'rpo: $rpo, softDeletePolicy: $softDeletePolicy, '
      'softDeleteTime: $softDeleteTime, storageClass: $storageClass, '
      'selfLink: $selfLink, timeCreated: $timeCreated, updated: $updated, '
      'versioning: $versioning, website: $website)';

  /// Creates a new [BucketMetadata] with the given non-`null` fields replaced.
  BucketMetadata copyWith({
    List<BucketAccessControl>? acl,
    BucketAutoclass? autoclass,
    BucketBilling? billing,
    List<BucketCorsConfiguration>? cors,
    BucketCustomPlacementConfig? customPlacementConfig,
    bool? defaultEventBasedHold,
    List<ObjectAccessControl>? defaultObjectAcl,
    BucketEncryption? encryption,
    String? etag,
    int? generation,
    Timestamp? hardDeleteTime,
    BucketHierarchicalNamespace? hierarchicalNamespace,
    BucketIamConfiguration? iamConfiguration,
    String? id,
    BucketIpFilter? ipFilter,
    String? kind,
    Map<String, String>? labels,
    Lifecycle? lifecycle,
    String? location,
    String? locationType,
    BucketLoggingConfiguration? logging,
    int? metageneration,
    String? name,
    BucketObjectRetention? objectRetention,
    BucketOwner? owner,
    String? projectNumber,
    BucketRetentionPolicy? retentionPolicy,
    String? rpo,
    BucketSoftDeletePolicy? softDeletePolicy,
    Timestamp? softDeleteTime,
    String? storageClass,
    Uri? selfLink,
    Timestamp? timeCreated,
    Timestamp? updated,
    BucketVersioning? versioning,
    BucketWebsiteConfiguration? website,
  }) => BucketMetadata(
    acl: acl ?? this.acl,
    autoclass: autoclass ?? this.autoclass,
    billing: billing ?? this.billing,
    cors: cors ?? this.cors,
    customPlacementConfig: customPlacementConfig ?? this.customPlacementConfig,
    defaultEventBasedHold: defaultEventBasedHold ?? this.defaultEventBasedHold,
    defaultObjectAcl: defaultObjectAcl ?? this.defaultObjectAcl,
    encryption: encryption ?? this.encryption,
    etag: etag ?? this.etag,
    generation: generation ?? this.generation,
    hardDeleteTime: hardDeleteTime ?? this.hardDeleteTime,
    hierarchicalNamespace: hierarchicalNamespace ?? this.hierarchicalNamespace,
    iamConfiguration: iamConfiguration ?? this.iamConfiguration,
    id: id ?? this.id,
    ipFilter: ipFilter ?? this.ipFilter,
    kind: kind ?? this.kind,
    labels: labels ?? this.labels,
    lifecycle: lifecycle ?? this.lifecycle,
    location: location ?? this.location,
    locationType: locationType ?? this.locationType,
    logging: logging ?? this.logging,
    metageneration: metageneration ?? this.metageneration,
    name: name ?? this.name,
    objectRetention: objectRetention ?? this.objectRetention,
    owner: owner ?? this.owner,
    projectNumber: projectNumber ?? this.projectNumber,
    retentionPolicy: retentionPolicy ?? this.retentionPolicy,
    rpo: rpo ?? this.rpo,
    softDeletePolicy: softDeletePolicy ?? this.softDeletePolicy,
    softDeleteTime: softDeleteTime ?? this.softDeleteTime,
    storageClass: storageClass ?? this.storageClass,
    selfLink: selfLink ?? this.selfLink,
    timeCreated: timeCreated ?? this.timeCreated,
    updated: updated ?? this.updated,
    versioning: versioning ?? this.versioning,
    website: website ?? this.website,
  );

  /// Creates a new [BucketMetadata] with the given fields set to `null`.
  BucketMetadata copyWithout({
    bool acl = false,
    bool autoclass = false,
    bool billing = false,
    bool cors = false,
    bool customPlacementConfig = false,
    bool defaultEventBasedHold = false,
    bool defaultObjectAcl = false,
    bool encryption = false,
    bool etag = false,
    bool generation = false,
    bool hardDeleteTime = false,
    bool hierarchicalNamespace = false,
    bool iamConfiguration = false,
    bool id = false,
    bool ipFilter = false,
    bool kind = false,
    bool labels = false,
    bool lifecycle = false,
    bool location = false,
    bool locationType = false,
    bool logging = false,
    bool metageneration = false,
    bool name = false,
    bool objectRetention = false,
    bool owner = false,
    bool projectNumber = false,
    bool retentionPolicy = false,
    bool rpo = false,
    bool softDeletePolicy = false,
    bool softDeleteTime = false,
    bool storageClass = false,
    bool selfLink = false,
    bool timeCreated = false,
    bool updated = false,
    bool versioning = false,
    bool website = false,
  }) => BucketMetadata(
    acl: acl ? null : this.acl,
    autoclass: autoclass ? null : this.autoclass,
    billing: billing ? null : this.billing,
    cors: cors ? null : this.cors,
    customPlacementConfig: customPlacementConfig
        ? null
        : this.customPlacementConfig,
    defaultEventBasedHold: defaultEventBasedHold
        ? null
        : this.defaultEventBasedHold,
    defaultObjectAcl: defaultObjectAcl ? null : this.defaultObjectAcl,
    encryption: encryption ? null : this.encryption,
    etag: etag ? null : this.etag,
    generation: generation ? null : this.generation,
    hardDeleteTime: hardDeleteTime ? null : this.hardDeleteTime,
    hierarchicalNamespace: hierarchicalNamespace
        ? null
        : this.hierarchicalNamespace,
    iamConfiguration: iamConfiguration ? null : this.iamConfiguration,
    id: id ? null : this.id,
    ipFilter: ipFilter ? null : this.ipFilter,
    kind: kind ? null : this.kind,
    labels: labels ? null : this.labels,
    lifecycle: lifecycle ? null : this.lifecycle,
    location: location ? null : this.location,
    locationType: locationType ? null : this.locationType,
    logging: logging ? null : this.logging,
    metageneration: metageneration ? null : this.metageneration,
    name: name ? null : this.name,
    objectRetention: objectRetention ? null : this.objectRetention,
    owner: owner ? null : this.owner,
    projectNumber: projectNumber ? null : this.projectNumber,
    retentionPolicy: retentionPolicy ? null : this.retentionPolicy,
    rpo: rpo ? null : this.rpo,
    softDeletePolicy: softDeletePolicy ? null : this.softDeletePolicy,
    softDeleteTime: softDeleteTime ? null : this.softDeleteTime,
    storageClass: storageClass ? null : this.storageClass,
    selfLink: selfLink ? null : this.selfLink,
    timeCreated: timeCreated ? null : this.timeCreated,
    updated: updated ? null : this.updated,
    versioning: versioning ? null : this.versioning,
    website: website ? null : this.website,
  );
}
