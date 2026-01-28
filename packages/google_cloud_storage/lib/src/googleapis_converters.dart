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
import 'package:googleapis/storage/v1.dart' as storage;

import 'bucket_metadata.dart';
import 'object_metadata.dart';
import 'project_team.dart';

storage.Bucket toGoogleApisBucket(BucketMetadata metadata) => storage.Bucket(
  acl: metadata.acl?.map(_toBucketAccessControl).toList(),
  autoclass: metadata.autoclass == null
      ? null
      : _toAutoclass(metadata.autoclass!),
  billing: metadata.billing == null ? null : _toBilling(metadata.billing!),
  cors: metadata.cors?.map(_toCors).toList(),
  customPlacementConfig: metadata.customPlacementConfig == null
      ? null
      : _toCustomPlacementConfig(metadata.customPlacementConfig!),
  defaultEventBasedHold: metadata.defaultEventBasedHold,
  defaultObjectAcl: metadata.defaultObjectAcl
      ?.map(_toObjectAccessControl)
      .toList(),
  encryption: metadata.encryption == null
      ? null
      : _toEncryption(metadata.encryption!),
  etag: metadata.etag,
  generation: metadata.generation?.toString(),
  hardDeleteTime: metadata.hardDeleteTime?.toDateTime(),
  hierarchicalNamespace: metadata.hierarchicalNamespace == null
      ? null
      : _toHierarchicalNamespace(metadata.hierarchicalNamespace!),
  iamConfiguration: metadata.iamConfiguration == null
      ? null
      : _toIamConfiguration(metadata.iamConfiguration!),
  id: metadata.id,
  ipFilter: metadata.ipFilter == null ? null : _toIpFilter(metadata.ipFilter!),
  kind: metadata.kind,
  labels: metadata.labels,
  lifecycle: metadata.lifecycle == null
      ? null
      : _toLifecycle(metadata.lifecycle!),
  location: metadata.location,
  locationType: metadata.locationType,
  logging: metadata.logging == null ? null : _toLogging(metadata.logging!),
  metageneration: metadata.metageneration?.toString(),
  name: metadata.name,
  objectRetention: metadata.objectRetention == null
      ? null
      : _toObjectRetention(metadata.objectRetention!),
  owner: metadata.owner == null ? null : _toOwner(metadata.owner!),
  projectNumber: metadata.projectNumber,
  retentionPolicy: metadata.retentionPolicy == null
      ? null
      : _toRetentionPolicy(metadata.retentionPolicy!),
  rpo: metadata.rpo,
  selfLink: metadata.selfLink?.toString(),
  softDeletePolicy: metadata.softDeletePolicy == null
      ? null
      : _toSoftDeletePolicy(metadata.softDeletePolicy!),
  softDeleteTime: metadata.softDeleteTime?.toDateTime(),
  storageClass: metadata.storageClass,
  timeCreated: metadata.timeCreated?.toDateTime(),
  updated: metadata.updated?.toDateTime(),
  versioning: metadata.versioning == null
      ? null
      : _toVersioning(metadata.versioning!),
  website: metadata.website == null ? null : _toWebsite(metadata.website!),
);

BucketMetadata fromGoogleApisBucket(storage.Bucket bucket) => BucketMetadata(
  acl: bucket.acl?.map(_fromBucketAccessControl).toList(),
  autoclass: bucket.autoclass == null
      ? null
      : _fromAutoclass(bucket.autoclass!),
  billing: bucket.billing == null ? null : _fromBilling(bucket.billing!),
  cors: bucket.cors?.map(_fromCors).toList(),
  customPlacementConfig: bucket.customPlacementConfig == null
      ? null
      : _fromCustomPlacementConfig(bucket.customPlacementConfig!),
  defaultEventBasedHold: bucket.defaultEventBasedHold,
  defaultObjectAcl: bucket.defaultObjectAcl
      ?.map(_fromObjectAccessControl)
      .toList(),
  encryption: bucket.encryption == null
      ? null
      : _fromEncryption(bucket.encryption!),
  etag: bucket.etag,
  generation: bucket.generation == null ? null : int.parse(bucket.generation!),
  hardDeleteTime: bucket.hardDeleteTime == null
      ? null
      : _timestampFromDateTime(bucket.hardDeleteTime!),
  hierarchicalNamespace: bucket.hierarchicalNamespace == null
      ? null
      : _fromHierarchicalNamespace(bucket.hierarchicalNamespace!),
  iamConfiguration: bucket.iamConfiguration == null
      ? null
      : _fromIamConfiguration(bucket.iamConfiguration!),
  id: bucket.id,
  ipFilter: bucket.ipFilter == null ? null : _fromIpFilter(bucket.ipFilter!),
  kind: bucket.kind,
  labels: bucket.labels,
  lifecycle: bucket.lifecycle == null
      ? null
      : _fromLifecycle(bucket.lifecycle!),
  location: bucket.location,
  locationType: bucket.locationType,
  logging: bucket.logging == null ? null : _fromLogging(bucket.logging!),
  metageneration: bucket.metageneration == null
      ? null
      : int.parse(bucket.metageneration!),
  name: bucket.name,
  objectRetention: bucket.objectRetention == null
      ? null
      : _fromObjectRetention(bucket.objectRetention!),
  owner: bucket.owner == null ? null : _fromOwner(bucket.owner!),
  projectNumber: bucket.projectNumber?.toString(),
  retentionPolicy: bucket.retentionPolicy == null
      ? null
      : _fromRetentionPolicy(bucket.retentionPolicy!),
  rpo: bucket.rpo,
  selfLink: bucket.selfLink == null ? null : Uri.parse(bucket.selfLink!),
  softDeletePolicy: bucket.softDeletePolicy == null
      ? null
      : _fromSoftDeletePolicy(bucket.softDeletePolicy!),
  softDeleteTime: bucket.softDeleteTime == null
      ? null
      : _timestampFromDateTime(bucket.softDeleteTime!),
  storageClass: bucket.storageClass,
  timeCreated: bucket.timeCreated == null
      ? null
      : _timestampFromDateTime(bucket.timeCreated!),
  updated: bucket.updated == null
      ? null
      : _timestampFromDateTime(bucket.updated!),
  versioning: bucket.versioning == null
      ? null
      : _fromVersioning(bucket.versioning!),
  website: bucket.website == null ? null : _fromWebsite(bucket.website!),
);

storage.BucketAutoclass _toAutoclass(BucketAutoclass autoclass) =>
    storage.BucketAutoclass(
      enabled: autoclass.enabled,
      terminalStorageClass: autoclass.terminalStorageClass,
      terminalStorageClassUpdateTime: autoclass.terminalStorageClassUpdateTime
          ?.toDateTime(),
      toggleTime: autoclass.toggleTime?.toDateTime(),
    );

BucketAutoclass _fromAutoclass(storage.BucketAutoclass autoclass) =>
    BucketAutoclass(
      enabled: autoclass.enabled,
      terminalStorageClass: autoclass.terminalStorageClass,
      terminalStorageClassUpdateTime:
          autoclass.terminalStorageClassUpdateTime == null
          ? null
          : _timestampFromDateTime(autoclass.terminalStorageClassUpdateTime!),
      toggleTime: autoclass.toggleTime == null
          ? null
          : _timestampFromDateTime(autoclass.toggleTime!),
    );

storage.BucketBilling _toBilling(BucketBilling billing) =>
    storage.BucketBilling(requesterPays: billing.requesterPays);

BucketBilling _fromBilling(storage.BucketBilling billing) =>
    BucketBilling(requesterPays: billing.requesterPays);

storage.BucketAccessControl _toBucketAccessControl(BucketAccessControl acl) =>
    storage.BucketAccessControl(
      bucket: acl.bucket,
      domain: acl.domain,
      email: acl.email,
      entity: acl.entity,
      entityId: acl.entityId,
      etag: acl.etag,
      id: acl.id,
      kind: acl.kind,
      projectTeam: acl.projectTeam == null
          ? null
          : _toProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink?.toString(),
    );

BucketAccessControl _fromBucketAccessControl(storage.BucketAccessControl acl) =>
    BucketAccessControl(
      bucket: acl.bucket,
      domain: acl.domain,
      email: acl.email,
      entity: acl.entity,
      entityId: acl.entityId,
      etag: acl.etag,
      id: acl.id,
      kind: acl.kind,
      projectTeam: acl.projectTeam == null
          ? null
          : _fromProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink == null ? null : Uri.parse(acl.selfLink!),
    );

storage.BucketAccessControlProjectTeam _toProjectTeam(ProjectTeam team) =>
    storage.BucketAccessControlProjectTeam(
      projectNumber: team.projectNumber,
      team: team.team,
    );

ProjectTeam _fromProjectTeam(storage.BucketAccessControlProjectTeam team) =>
    ProjectTeam(projectNumber: team.projectNumber, team: team.team);

storage.ObjectAccessControl _toObjectAccessControl(ObjectAccessControl acl) =>
    storage.ObjectAccessControl(
      bucket: acl.bucket,
      domain: acl.domain,
      email: acl.email,
      entity: acl.entity,
      entityId: acl.entityId,
      etag: acl.etag,
      generation: acl.generation,
      id: acl.id,
      kind: acl.kind,
      object: acl.object,
      projectTeam: acl.projectTeam == null
          ? null
          : _toObjectProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink?.toString(),
    );

ObjectAccessControl _fromObjectAccessControl(storage.ObjectAccessControl acl) =>
    ObjectAccessControl(
      bucket: acl.bucket,
      domain: acl.domain,
      email: acl.email,
      entity: acl.entity,
      entityId: acl.entityId,
      etag: acl.etag,
      generation: acl.generation,
      id: acl.id,
      kind: acl.kind,
      object: acl.object,
      projectTeam: acl.projectTeam == null
          ? null
          : _fromObjectProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink == null ? null : Uri.parse(acl.selfLink!),
    );

storage.ObjectAccessControlProjectTeam _toObjectProjectTeam(ProjectTeam team) =>
    storage.ObjectAccessControlProjectTeam(
      projectNumber: team.projectNumber,
      team: team.team,
    );

ProjectTeam _fromObjectProjectTeam(
  storage.ObjectAccessControlProjectTeam team,
) => ProjectTeam(projectNumber: team.projectNumber, team: team.team);

storage.BucketEncryption _toEncryption(BucketEncryption encryption) =>
    storage.BucketEncryption(defaultKmsKeyName: encryption.defaultKmsKeyName);

BucketEncryption _fromEncryption(storage.BucketEncryption encryption) =>
    BucketEncryption(defaultKmsKeyName: encryption.defaultKmsKeyName);

storage.BucketCors _toCors(BucketCorsConfiguration cors) => storage.BucketCors(
  maxAgeSeconds: cors.maxAgeSeconds,
  method: cors.method,
  origin: cors.origin,
  responseHeader: cors.responseHeader,
);

BucketCorsConfiguration _fromCors(storage.BucketCors cors) =>
    BucketCorsConfiguration(
      maxAgeSeconds: cors.maxAgeSeconds,
      method: cors.method,
      origin: cors.origin,
      responseHeader: cors.responseHeader,
    );

storage.BucketCustomPlacementConfig _toCustomPlacementConfig(
  BucketCustomPlacementConfig config,
) => storage.BucketCustomPlacementConfig(dataLocations: config.dataLocations);

BucketCustomPlacementConfig _fromCustomPlacementConfig(
  storage.BucketCustomPlacementConfig config,
) => BucketCustomPlacementConfig(dataLocations: config.dataLocations);

storage.BucketHierarchicalNamespace _toHierarchicalNamespace(
  BucketHierarchicalNamespace config,
) => storage.BucketHierarchicalNamespace(enabled: config.enabled);

BucketHierarchicalNamespace _fromHierarchicalNamespace(
  storage.BucketHierarchicalNamespace config,
) => BucketHierarchicalNamespace(enabled: config.enabled);

storage.BucketIamConfiguration _toIamConfiguration(
  BucketIamConfiguration config,
) => storage.BucketIamConfiguration(
  publicAccessPrevention: config.publicAccessPrevention,
  uniformBucketLevelAccess: config.uniformBucketLevelAccess == null
      ? null
      : _toUniformBucketLevelAccess(config.uniformBucketLevelAccess!),
);

BucketIamConfiguration _fromIamConfiguration(
  storage.BucketIamConfiguration config,
) => BucketIamConfiguration(
  publicAccessPrevention: config.publicAccessPrevention,
  uniformBucketLevelAccess: config.uniformBucketLevelAccess == null
      ? null
      : _fromUniformBucketLevelAccess(config.uniformBucketLevelAccess!),
);

storage.BucketIamConfigurationUniformBucketLevelAccess
_toUniformBucketLevelAccess(UniformBucketLevelAccess config) =>
    storage.BucketIamConfigurationUniformBucketLevelAccess(
      enabled: config.enabled,
      lockedTime: config.lockedTime?.toDateTime(),
    );

UniformBucketLevelAccess _fromUniformBucketLevelAccess(
  storage.BucketIamConfigurationUniformBucketLevelAccess config,
) => UniformBucketLevelAccess(
  enabled: config.enabled,
  lockedTime: config.lockedTime == null
      ? null
      : _timestampFromDateTime(config.lockedTime!),
);

storage.BucketIpFilter _toIpFilter(BucketIpFilter config) =>
    storage.BucketIpFilter(
      allowAllServiceAgentAccess: config.allowAllServiceAgentAccess,
      allowCrossOrgVpcs: config.allowCrossOrgVpcs,
      mode: config.mode,
      publicNetworkSource: config.publicNetworkSource == null
          ? null
          : _toPublicNetworkSource(config.publicNetworkSource!),
      vpcNetworkSources: config.vpcNetworkSources
          ?.map(_toVpcNetworkSource)
          .toList(),
    );

BucketIpFilter _fromIpFilter(storage.BucketIpFilter config) => BucketIpFilter(
  allowAllServiceAgentAccess: config.allowAllServiceAgentAccess,
  allowCrossOrgVpcs: config.allowCrossOrgVpcs,
  mode: config.mode,
  publicNetworkSource: config.publicNetworkSource == null
      ? null
      : _fromPublicNetworkSource(config.publicNetworkSource!),
  vpcNetworkSources: config.vpcNetworkSources
      ?.map(_fromVpcNetworkSource)
      .toList(),
);

storage.BucketIpFilterPublicNetworkSource _toPublicNetworkSource(
  BucketPublicNetworkSource source,
) => storage.BucketIpFilterPublicNetworkSource(
  allowedIpCidrRanges: source.allowedIpCidrRanges,
);

BucketPublicNetworkSource _fromPublicNetworkSource(
  storage.BucketIpFilterPublicNetworkSource source,
) => BucketPublicNetworkSource(allowedIpCidrRanges: source.allowedIpCidrRanges);

storage.BucketIpFilterVpcNetworkSources _toVpcNetworkSource(
  BucketPublicNetworkSource source,
) => storage.BucketIpFilterVpcNetworkSources(
  allowedIpCidrRanges: source.allowedIpCidrRanges,
);

BucketPublicNetworkSource _fromVpcNetworkSource(
  storage.BucketIpFilterVpcNetworkSources source,
) => BucketPublicNetworkSource(allowedIpCidrRanges: source.allowedIpCidrRanges);

storage.BucketLifecycle _toLifecycle(Lifecycle lifecycle) =>
    storage.BucketLifecycle(
      rule: lifecycle.rule?.map(_toLifecycleRule).toList(),
    );

Lifecycle _fromLifecycle(storage.BucketLifecycle lifecycle) =>
    Lifecycle(rule: lifecycle.rule?.map(_fromLifecycleRule).toList());

storage.BucketLifecycleRule _toLifecycleRule(LifecycleRule rule) =>
    storage.BucketLifecycleRule(
      action: rule.action == null ? null : _toLifecycleRuleAction(rule.action!),
      condition: rule.condition == null
          ? null
          : _toLifecycleRuleCondition(rule.condition!),
    );

LifecycleRule _fromLifecycleRule(storage.BucketLifecycleRule rule) =>
    LifecycleRule(
      action: rule.action == null
          ? null
          : _fromLifecycleRuleAction(rule.action!),
      condition: rule.condition == null
          ? null
          : _fromLifecycleRuleCondition(rule.condition!),
    );

storage.BucketLifecycleRuleAction _toLifecycleRuleAction(
  LifecycleRuleAction action,
) => storage.BucketLifecycleRuleAction(
  storageClass: action.storageClass,
  type: action.type,
);

LifecycleRuleAction _fromLifecycleRuleAction(
  storage.BucketLifecycleRuleAction action,
) => LifecycleRuleAction(storageClass: action.storageClass, type: action.type);

storage.BucketLifecycleRuleCondition _toLifecycleRuleCondition(
  LifecycleRuleCondition condition,
) => storage.BucketLifecycleRuleCondition(
  age: condition.age,
  createdBefore: condition.createdBefore == null
      ? null
      : DateTime.parse(condition.createdBefore!),
  customTimeBefore: condition.customTimeBefore == null
      ? null
      : DateTime.parse(condition.customTimeBefore!),
  daysSinceCustomTime: condition.daysSinceCustomTime,
  daysSinceNoncurrentTime: condition.daysSinceNoncurrentTime,
  isLive: condition.isLive,
  matchesPrefix: condition.matchesPrefix,
  matchesStorageClass: condition.matchesStorageClass,
  matchesSuffix: condition.matchesSuffix,
  noncurrentTimeBefore: condition.noncurrentTimeBefore == null
      ? null
      : DateTime.parse(condition.noncurrentTimeBefore!),
  numNewerVersions: condition.numNewerVersions,
);

LifecycleRuleCondition _fromLifecycleRuleCondition(
  storage.BucketLifecycleRuleCondition condition,
) {
  print(condition.createdBefore);
  return LifecycleRuleCondition(
    age: condition.age,

    /// XXX which midnight????
    createdBefore: condition.createdBefore == null
        ? null
        : _toRfc3339Date(condition.createdBefore!),
    customTimeBefore: condition.customTimeBefore == null
        ? null
        : _toRfc3339Date(condition.customTimeBefore!),
    daysSinceCustomTime: condition.daysSinceCustomTime,
    daysSinceNoncurrentTime: condition.daysSinceNoncurrentTime,
    isLive: condition.isLive,
    matchesPrefix: condition.matchesPrefix,
    matchesStorageClass: condition.matchesStorageClass,
    matchesSuffix: condition.matchesSuffix,
    noncurrentTimeBefore: condition.noncurrentTimeBefore == null
        ? null
        : _toRfc3339Date(condition.noncurrentTimeBefore!),
    numNewerVersions: condition.numNewerVersions,
  );
}

String _toRfc3339Date(DateTime dateTime) =>
    dateTime.toIso8601String().substring(0, 10);

storage.BucketLogging _toLogging(BucketLoggingConfiguration logging) =>
    storage.BucketLogging(
      logBucket: logging.logBucket,
      logObjectPrefix: logging.logObjectPrefix,
    );

BucketLoggingConfiguration _fromLogging(storage.BucketLogging logging) =>
    BucketLoggingConfiguration(
      logBucket: logging.logBucket,
      logObjectPrefix: logging.logObjectPrefix,
    );

storage.BucketOwner _toOwner(BucketOwner owner) =>
    storage.BucketOwner(entity: owner.entity, entityId: owner.entityId);

BucketOwner _fromOwner(storage.BucketOwner owner) =>
    BucketOwner(entity: owner.entity, entityId: owner.entityId);

storage.BucketRetentionPolicy _toRetentionPolicy(
  BucketRetentionPolicy policy,
) => storage.BucketRetentionPolicy(
  effectiveTime: policy.effectiveTime?.toDateTime(),
  isLocked: policy.isLocked,
  retentionPeriod: policy.retentionPeriod?.toString(),
);

BucketRetentionPolicy _fromRetentionPolicy(
  storage.BucketRetentionPolicy policy,
) => BucketRetentionPolicy(
  effectiveTime: policy.effectiveTime == null
      ? null
      : _timestampFromDateTime(policy.effectiveTime!),
  isLocked: policy.isLocked,
  retentionPeriod: policy.retentionPeriod == null
      ? null
      : int.parse(policy.retentionPeriod!),
);

storage.BucketSoftDeletePolicy _toSoftDeletePolicy(
  BucketSoftDeletePolicy policy,
) => storage.BucketSoftDeletePolicy(
  effectiveTime: policy.effectiveTime?.toDateTime(),
  retentionDurationSeconds: policy.retentionDurationSeconds?.toString(),
);

BucketSoftDeletePolicy _fromSoftDeletePolicy(
  storage.BucketSoftDeletePolicy policy,
) => BucketSoftDeletePolicy(
  effectiveTime: policy.effectiveTime == null
      ? null
      : _timestampFromDateTime(policy.effectiveTime!),
  retentionDurationSeconds: policy.retentionDurationSeconds == null
      ? null
      : int.parse(policy.retentionDurationSeconds!),
);

storage.BucketVersioning _toVersioning(BucketVersioning versioning) =>
    storage.BucketVersioning(enabled: versioning.enabled);

BucketVersioning _fromVersioning(storage.BucketVersioning versioning) =>
    BucketVersioning(enabled: versioning.enabled);

storage.BucketWebsite _toWebsite(BucketWebsiteConfiguration website) =>
    storage.BucketWebsite(
      mainPageSuffix: website.mainPageSuffix,
      notFoundPage: website.notFoundPage,
    );

BucketWebsiteConfiguration _fromWebsite(storage.BucketWebsite website) =>
    BucketWebsiteConfiguration(
      mainPageSuffix: website.mainPageSuffix,
      notFoundPage: website.notFoundPage,
    );

storage.BucketObjectRetention _toObjectRetention(
  BucketObjectRetention objectRetention,
) => storage.BucketObjectRetention(mode: objectRetention.mode);

BucketObjectRetention _fromObjectRetention(
  storage.BucketObjectRetention objectRetention,
) => BucketObjectRetention(mode: objectRetention.mode);

Timestamp _timestampFromDateTime(DateTime dateTime) => Timestamp(
  seconds: (dateTime.millisecondsSinceEpoch / 1000).floor(),
  nanos: (dateTime.microsecondsSinceEpoch % 1000000) * 1000,
);
