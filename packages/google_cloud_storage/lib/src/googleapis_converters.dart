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
import 'object_access_controls.dart';

storage.Bucket toBucket(BucketMetadata metadata) => storage.Bucket(
  acl: metadata.acl?.map(toBucketAccessControl).toList(),
  autoclass: metadata.autoclass == null
      ? null
      : toAutoclass(metadata.autoclass!),
  billing: metadata.billing == null ? null : toBilling(metadata.billing!),
  cors: metadata.cors?.map(toCors).toList(),
  customPlacementConfig: metadata.customPlacementConfig == null
      ? null
      : toCustomPlacementConfig(metadata.customPlacementConfig!),
  defaultEventBasedHold: metadata.defaultEventBasedHold,
  defaultObjectAcl: metadata.defaultObjectAcl
      ?.map(toObjectAccessControl)
      .toList(),
  encryption: metadata.encryption == null
      ? null
      : toEncryption(metadata.encryption!),
  etag: metadata.etag,
  generation: metadata.generation?.toString(),
  hardDeleteTime: metadata.hardDeleteTime?.toDateTime(),
  hierarchicalNamespace: metadata.hierarchicalNamespace == null
      ? null
      : toHierarchicalNamespace(metadata.hierarchicalNamespace!),
  iamConfiguration: metadata.iamConfiguration == null
      ? null
      : toIamConfiguration(metadata.iamConfiguration!),
  id: metadata.id,
  ipFilter: metadata.ipFilter == null ? null : toIpFilter(metadata.ipFilter!),
  kind: metadata.kind,
  labels: metadata.labels,
  lifecycle: metadata.lifecycle == null
      ? null
      : toLifecycle(metadata.lifecycle!),
  location: metadata.location,
  locationType: metadata.locationType,
  logging: metadata.logging == null ? null : toLogging(metadata.logging!),
  metageneration: metadata.metageneration?.toString(),
  name: metadata.name,
  objectRetention: metadata.objectRetention == null
      ? null
      : toObjectRetention(metadata.objectRetention!),
  owner: metadata.owner == null ? null : toOwner(metadata.owner!),
  projectNumber: metadata.projectNumber,
  retentionPolicy: metadata.retentionPolicy == null
      ? null
      : toRetentionPolicy(metadata.retentionPolicy!),
  rpo: metadata.rpo,
  selfLink: metadata.selfLink?.toString(),
  softDeletePolicy: metadata.softDeletePolicy == null
      ? null
      : toSoftDeletePolicy(metadata.softDeletePolicy!),
  softDeleteTime: metadata.softDeleteTime?.toDateTime(),
  storageClass: metadata.storageClass,
  timeCreated: metadata.timeCreated?.toDateTime(),
  updated: metadata.updated?.toDateTime(),
  versioning: metadata.versioning == null
      ? null
      : toVersioning(metadata.versioning!),
  website: metadata.website == null ? null : toWebsite(metadata.website!),
);

BucketMetadata fromBucket(storage.Bucket bucket) => BucketMetadata(
  acl: bucket.acl?.map(fromBucketAccessControl).toList(),
  autoclass: bucket.autoclass == null ? null : fromAutoclass(bucket.autoclass!),
  billing: bucket.billing == null ? null : fromBilling(bucket.billing!),
  cors: bucket.cors?.map(fromCors).toList(),
  customPlacementConfig: bucket.customPlacementConfig == null
      ? null
      : fromCustomPlacementConfig(bucket.customPlacementConfig!),
  defaultEventBasedHold: bucket.defaultEventBasedHold,
  defaultObjectAcl: bucket.defaultObjectAcl
      ?.map(fromObjectAccessControl)
      .toList(),
  encryption: bucket.encryption == null
      ? null
      : fromEncryption(bucket.encryption!),
  etag: bucket.etag,
  generation: bucket.generation == null ? null : int.parse(bucket.generation!),
  hardDeleteTime: bucket.hardDeleteTime == null
      ? null
      : _timestampFromDateTime(bucket.hardDeleteTime!),
  hierarchicalNamespace: bucket.hierarchicalNamespace == null
      ? null
      : fromHierarchicalNamespace(bucket.hierarchicalNamespace!),
  iamConfiguration: bucket.iamConfiguration == null
      ? null
      : fromIamConfiguration(bucket.iamConfiguration!),
  id: bucket.id,
  ipFilter: bucket.ipFilter == null ? null : fromIpFilter(bucket.ipFilter!),
  kind: bucket.kind,
  labels: bucket.labels,
  lifecycle: bucket.lifecycle == null ? null : fromLifecycle(bucket.lifecycle!),
  location: bucket.location,
  locationType: bucket.locationType,
  logging: bucket.logging == null ? null : fromLogging(bucket.logging!),
  metageneration: bucket.metageneration == null
      ? null
      : int.parse(bucket.metageneration!),
  name: bucket.name,
  objectRetention: bucket.objectRetention == null
      ? null
      : fromObjectRetention(bucket.objectRetention!),
  owner: bucket.owner == null ? null : fromOwner(bucket.owner!),
  projectNumber: bucket.projectNumber?.toString(),
  retentionPolicy: bucket.retentionPolicy == null
      ? null
      : fromRetentionPolicy(bucket.retentionPolicy!),
  rpo: bucket.rpo,
  selfLink: bucket.selfLink == null ? null : Uri.parse(bucket.selfLink!),
  softDeletePolicy: bucket.softDeletePolicy == null
      ? null
      : fromSoftDeletePolicy(bucket.softDeletePolicy!),
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
      : fromVersioning(bucket.versioning!),
  website: bucket.website == null ? null : fromWebsite(bucket.website!),
);

storage.BucketAutoclass toAutoclass(BucketAutoclass autoclass) =>
    storage.BucketAutoclass(
      enabled: autoclass.enabled,
      terminalStorageClass: autoclass.terminalStorageClass,
      terminalStorageClassUpdateTime: autoclass.terminalStorageClassUpdateTime
          ?.toDateTime(),
      toggleTime: autoclass.toggleTime?.toDateTime(),
    );

BucketAutoclass fromAutoclass(storage.BucketAutoclass autoclass) =>
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

storage.BucketBilling toBilling(BucketBilling billing) =>
    storage.BucketBilling(requesterPays: billing.requesterPays);

BucketBilling fromBilling(storage.BucketBilling billing) =>
    BucketBilling(requesterPays: billing.requesterPays);

storage.BucketAccessControl toBucketAccessControl(BucketAccessControl acl) =>
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
          : toProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink?.toString(),
    );

BucketAccessControl fromBucketAccessControl(storage.BucketAccessControl acl) =>
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
          : fromProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink == null ? null : Uri.parse(acl.selfLink!),
    );

storage.BucketAccessControlProjectTeam toProjectTeam(ProjectTeam team) =>
    storage.BucketAccessControlProjectTeam(
      projectNumber: team.projectNumber,
      team: team.team,
    );

ProjectTeam fromProjectTeam(storage.BucketAccessControlProjectTeam team) =>
    ProjectTeam(projectNumber: team.projectNumber, team: team.team);

storage.ObjectAccessControl toObjectAccessControl(ObjectAccessControl acl) =>
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
          : toObjectProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink?.toString(),
    );

ObjectAccessControl fromObjectAccessControl(storage.ObjectAccessControl acl) =>
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
          : fromObjectProjectTeam(acl.projectTeam!),
      role: acl.role,
      selfLink: acl.selfLink == null ? null : Uri.parse(acl.selfLink!),
    );

storage.ObjectAccessControlProjectTeam toObjectProjectTeam(ProjectTeam team) =>
    storage.ObjectAccessControlProjectTeam(
      projectNumber: team.projectNumber,
      team: team.team,
    );

ProjectTeam fromObjectProjectTeam(
  storage.ObjectAccessControlProjectTeam team,
) => ProjectTeam(projectNumber: team.projectNumber, team: team.team);

storage.BucketEncryption toEncryption(BucketEncryption encryption) =>
    storage.BucketEncryption(defaultKmsKeyName: encryption.defaultKmsKeyName);

BucketEncryption fromEncryption(storage.BucketEncryption encryption) =>
    BucketEncryption(defaultKmsKeyName: encryption.defaultKmsKeyName);

storage.BucketCors toCors(BucketCorsConfiguration cors) => storage.BucketCors(
  maxAgeSeconds: cors.maxAgeSeconds,
  method: cors.method,
  origin: cors.origin,
  responseHeader: cors.responseHeader,
);

BucketCorsConfiguration fromCors(storage.BucketCors cors) =>
    BucketCorsConfiguration(
      maxAgeSeconds: cors.maxAgeSeconds,
      method: cors.method,
      origin: cors.origin,
      responseHeader: cors.responseHeader,
    );

storage.BucketCustomPlacementConfig toCustomPlacementConfig(
  BucketCustomPlacementConfig config,
) => storage.BucketCustomPlacementConfig(dataLocations: config.dataLocations);

BucketCustomPlacementConfig fromCustomPlacementConfig(
  storage.BucketCustomPlacementConfig config,
) => BucketCustomPlacementConfig(dataLocations: config.dataLocations);

storage.BucketHierarchicalNamespace toHierarchicalNamespace(
  BucketHierarchicalNamespace config,
) => storage.BucketHierarchicalNamespace(enabled: config.enabled);

BucketHierarchicalNamespace fromHierarchicalNamespace(
  storage.BucketHierarchicalNamespace config,
) => BucketHierarchicalNamespace(enabled: config.enabled);

storage.BucketIamConfiguration toIamConfiguration(
  BucketIamConfiguration config,
) => storage.BucketIamConfiguration(
  publicAccessPrevention: config.publicAccessPrevention,
  uniformBucketLevelAccess: config.uniformBucketLevelAccess == null
      ? null
      : toUniformBucketLevelAccess(config.uniformBucketLevelAccess!),
);

BucketIamConfiguration fromIamConfiguration(
  storage.BucketIamConfiguration config,
) => BucketIamConfiguration(
  publicAccessPrevention: config.publicAccessPrevention,
  uniformBucketLevelAccess: config.uniformBucketLevelAccess == null
      ? null
      : fromUniformBucketLevelAccess(config.uniformBucketLevelAccess!),
);

storage.BucketIamConfigurationUniformBucketLevelAccess
toUniformBucketLevelAccess(UniformBucketLevelAccess config) =>
    storage.BucketIamConfigurationUniformBucketLevelAccess(
      enabled: config.enabled,
      lockedTime: config.lockedTime?.toDateTime(),
    );

UniformBucketLevelAccess fromUniformBucketLevelAccess(
  storage.BucketIamConfigurationUniformBucketLevelAccess config,
) => UniformBucketLevelAccess(
  enabled: config.enabled,
  lockedTime: config.lockedTime == null
      ? null
      : _timestampFromDateTime(config.lockedTime!),
);

storage.BucketIpFilter toIpFilter(BucketIpFilter config) =>
    storage.BucketIpFilter(
      allowAllServiceAgentAccess: config.allowAllServiceAgentAccess,
      allowCrossOrgVpcs: config.allowCrossOrgVpcs,
      mode: config.mode,
      publicNetworkSource: config.publicNetworkSource == null
          ? null
          : toPublicNetworkSource(config.publicNetworkSource!),
      vpcNetworkSources: config.vpcNetworkSources
          ?.map(toVpcNetworkSource)
          .toList(),
    );

BucketIpFilter fromIpFilter(storage.BucketIpFilter config) => BucketIpFilter(
  allowAllServiceAgentAccess: config.allowAllServiceAgentAccess,
  allowCrossOrgVpcs: config.allowCrossOrgVpcs,
  mode: config.mode,
  publicNetworkSource: config.publicNetworkSource == null
      ? null
      : fromPublicNetworkSource(config.publicNetworkSource!),
  vpcNetworkSources: config.vpcNetworkSources
      ?.map(fromVpcNetworkSource)
      .toList(),
);

storage.BucketIpFilterPublicNetworkSource toPublicNetworkSource(
  BucketPublicNetworkSource source,
) => storage.BucketIpFilterPublicNetworkSource(
  allowedIpCidrRanges: source.allowedIpCidrRanges,
);

BucketPublicNetworkSource fromPublicNetworkSource(
  storage.BucketIpFilterPublicNetworkSource source,
) => BucketPublicNetworkSource(allowedIpCidrRanges: source.allowedIpCidrRanges);

storage.BucketIpFilterVpcNetworkSources toVpcNetworkSource(
  BucketPublicNetworkSource source,
) => storage.BucketIpFilterVpcNetworkSources(
  allowedIpCidrRanges: source.allowedIpCidrRanges,
);

BucketPublicNetworkSource fromVpcNetworkSource(
  storage.BucketIpFilterVpcNetworkSources source,
) => BucketPublicNetworkSource(allowedIpCidrRanges: source.allowedIpCidrRanges);

storage.BucketLifecycle toLifecycle(Lifecycle lifecycle) =>
    storage.BucketLifecycle(
      rule: lifecycle.rule?.map(toLifecycleRule).toList(),
    );

Lifecycle fromLifecycle(storage.BucketLifecycle lifecycle) =>
    Lifecycle(rule: lifecycle.rule?.map(fromLifecycleRule).toList());

storage.BucketLifecycleRule toLifecycleRule(LifecycleRule rule) =>
    storage.BucketLifecycleRule(
      action: rule.action == null ? null : toLifecycleRuleAction(rule.action!),
      condition: rule.condition == null
          ? null
          : toLifecycleRuleCondition(rule.condition!),
    );

LifecycleRule fromLifecycleRule(storage.BucketLifecycleRule rule) =>
    LifecycleRule(
      action: rule.action == null
          ? null
          : fromLifecycleRuleAction(rule.action!),
      condition: rule.condition == null
          ? null
          : fromLifecycleRuleCondition(rule.condition!),
    );

storage.BucketLifecycleRuleAction toLifecycleRuleAction(
  LifecycleRuleAction action,
) => storage.BucketLifecycleRuleAction(
  storageClass: action.storageClass,
  type: action.type,
);

LifecycleRuleAction fromLifecycleRuleAction(
  storage.BucketLifecycleRuleAction action,
) => LifecycleRuleAction(storageClass: action.storageClass, type: action.type);

storage.BucketLifecycleRuleCondition toLifecycleRuleCondition(
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

LifecycleRuleCondition fromLifecycleRuleCondition(
  storage.BucketLifecycleRuleCondition condition,
) => LifecycleRuleCondition(
  age: condition.age,
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

String _toRfc3339Date(DateTime dateTime) =>
    dateTime.toIso8601String().substring(0, 10);

storage.BucketLogging toLogging(BucketLoggingConfiguration logging) =>
    storage.BucketLogging(
      logBucket: logging.logBucket,
      logObjectPrefix: logging.logObjectPrefix,
    );

BucketLoggingConfiguration fromLogging(storage.BucketLogging logging) =>
    BucketLoggingConfiguration(
      logBucket: logging.logBucket,
      logObjectPrefix: logging.logObjectPrefix,
    );

storage.BucketOwner toOwner(BucketOwner owner) =>
    storage.BucketOwner(entity: owner.entity, entityId: owner.entityId);

BucketOwner fromOwner(storage.BucketOwner owner) =>
    BucketOwner(entity: owner.entity, entityId: owner.entityId);

storage.BucketRetentionPolicy toRetentionPolicy(BucketRetentionPolicy policy) =>
    storage.BucketRetentionPolicy(
      effectiveTime: policy.effectiveTime?.toDateTime(),
      isLocked: policy.isLocked,
      retentionPeriod: policy.retentionPeriod?.toString(),
    );

BucketRetentionPolicy fromRetentionPolicy(
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

storage.BucketSoftDeletePolicy toSoftDeletePolicy(
  BucketSoftDeletePolicy policy,
) => storage.BucketSoftDeletePolicy(
  effectiveTime: policy.effectiveTime?.toDateTime(),
  retentionDurationSeconds: policy.retentionDurationSeconds?.toString(),
);

BucketSoftDeletePolicy fromSoftDeletePolicy(
  storage.BucketSoftDeletePolicy policy,
) => BucketSoftDeletePolicy(
  effectiveTime: policy.effectiveTime == null
      ? null
      : _timestampFromDateTime(policy.effectiveTime!),
  retentionDurationSeconds: policy.retentionDurationSeconds == null
      ? null
      : int.parse(policy.retentionDurationSeconds!),
);

storage.BucketVersioning toVersioning(BucketVersioning versioning) =>
    storage.BucketVersioning(enabled: versioning.enabled);

BucketVersioning fromVersioning(storage.BucketVersioning versioning) =>
    BucketVersioning(enabled: versioning.enabled);

storage.BucketWebsite toWebsite(BucketWebsiteConfiguration website) =>
    storage.BucketWebsite(
      mainPageSuffix: website.mainPageSuffix,
      notFoundPage: website.notFoundPage,
    );

BucketWebsiteConfiguration fromWebsite(storage.BucketWebsite website) =>
    BucketWebsiteConfiguration(
      mainPageSuffix: website.mainPageSuffix,
      notFoundPage: website.notFoundPage,
    );

storage.BucketObjectRetention toObjectRetention(
  BucketObjectRetention objectRetention,
) => storage.BucketObjectRetention(mode: objectRetention.mode);

BucketObjectRetention fromObjectRetention(
  storage.BucketObjectRetention objectRetention,
) => BucketObjectRetention(mode: objectRetention.mode);

Timestamp _timestampFromDateTime(DateTime dateTime) => Timestamp(
  seconds: (dateTime.millisecondsSinceEpoch / 1000).floor(),
  nanos: (dateTime.microsecondsSinceEpoch % 1000000) * 1000,
);
