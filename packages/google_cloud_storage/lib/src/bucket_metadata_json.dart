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

import 'bucket_metadata.dart';
import 'common_json.dart';
import 'object_metadata.dart';

BucketAutoclass? bucketAutoclassFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketAutoclass(
    enabled: json['enabled'] as bool?,
    terminalStorageClass: json['terminalStorageClass'] as String?,
    terminalStorageClassUpdateTime: timestampFromJson(
      json['terminalStorageClassUpdateTime'],
    ),
    toggleTime: timestampFromJson(json['toggleTime']),
  );
}

Map<String, Object?>? bucketAutoclassToJson(BucketAutoclass? instance) {
  if (instance == null) return null;
  return {
    'enabled': ?instance.enabled,
    'terminalStorageClass': ?instance.terminalStorageClass,
    'terminalStorageClassUpdateTime': ?timestampToJson(
      instance.terminalStorageClassUpdateTime,
    ),
    'toggleTime': ?timestampToJson(instance.toggleTime),
  };
}

BucketBilling? bucketBillingFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketBilling(requesterPays: json['requesterPays'] as bool?);
}

Map<String, Object?>? bucketBillingToJson(BucketBilling? instance) {
  if (instance == null) return null;
  return {'requesterPays': ?instance.requesterPays};
}

BucketAccessControl? bucketAccessControlFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketAccessControl(
    bucket: json['bucket'] as String?,
    domain: json['domain'] as String?,
    email: json['email'] as String?,
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
    etag: json['etag'] as String?,
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    projectTeam: projectTeamFromJson(
      json['projectTeam'] as Map<String, Object?>?,
    ),
    role: json['role'] as String?,
    selfLink: json['selfLink'] == null
        ? null
        : Uri.parse(json['selfLink'] as String),
  );
}

Map<String, Object?>? bucketAccessControlToJson(BucketAccessControl? instance) {
  if (instance == null) return null;
  return {
    'bucket': ?instance.bucket,
    'domain': ?instance.domain,
    'email': ?instance.email,
    'entity': ?instance.entity,
    'entityId': ?instance.entityId,
    'etag': ?instance.etag,
    'id': ?instance.id,
    'kind': ?instance.kind,
    'projectTeam': ?projectTeamToJson(instance.projectTeam),
    'role': ?instance.role,
    'selfLink': ?instance.selfLink?.toString(),
  };
}

BucketEncryption? bucketEncryptionFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketEncryption(
    defaultKmsKeyName: json['defaultKmsKeyName'] as String?,
  );
}

Map<String, Object?>? bucketEncryptionToJson(BucketEncryption? instance) {
  if (instance == null) return null;
  return {'defaultKmsKeyName': ?instance.defaultKmsKeyName};
}

BucketObjectRetention? bucketObjectRetentionFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketObjectRetention(mode: json['mode'] as String?);
}

Map<String, Object?>? bucketObjectRetentionToJson(
  BucketObjectRetention? instance,
) {
  if (instance == null) return null;
  return {'mode': ?instance.mode};
}

BucketCorsConfiguration? bucketCorsConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketCorsConfiguration(
    maxAgeSeconds: json['maxAgeSeconds'] as int?,
    method: (json['method'] as List<Object?>?)?.cast<String>(),
    origin: (json['origin'] as List<Object?>?)?.cast<String>(),
    responseHeader: (json['responseHeader'] as List<Object?>?)?.cast<String>(),
  );
}

Map<String, Object?>? bucketCorsConfigurationToJson(
  BucketCorsConfiguration? instance,
) {
  if (instance == null) return null;
  return {
    'maxAgeSeconds': ?instance.maxAgeSeconds,
    'method': ?instance.method,
    'origin': ?instance.origin,
    'responseHeader': ?instance.responseHeader,
  };
}

BucketCustomPlacementConfig? bucketCustomPlacementConfigFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketCustomPlacementConfig(
    dataLocations: (json['dataLocations'] as List<Object?>?)?.cast<String>(),
  );
}

Map<String, Object?>? bucketCustomPlacementConfigToJson(
  BucketCustomPlacementConfig? instance,
) {
  if (instance == null) return null;
  return {'dataLocations': ?instance.dataLocations};
}

BucketHierarchicalNamespace? bucketHierarchicalNamespaceFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketHierarchicalNamespace(enabled: json['enabled'] as bool?);
}

Map<String, Object?>? bucketHierarchicalNamespaceToJson(
  BucketHierarchicalNamespace? instance,
) {
  if (instance == null) return null;
  return {'enabled': ?instance.enabled};
}

BucketIamConfiguration? bucketIamConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketIamConfiguration(
    publicAccessPrevention: json['publicAccessPrevention'] as String?,
    uniformBucketLevelAccess: uniformBucketLevelAccessFromJson(
      json['uniformBucketLevelAccess'] as Map<String, Object?>?,
    ),
  );
}

Map<String, Object?>? bucketIamConfigurationToJson(
  BucketIamConfiguration? instance,
) {
  if (instance == null) return null;
  return {
    'publicAccessPrevention': ?instance.publicAccessPrevention,
    'uniformBucketLevelAccess': ?uniformBucketLevelAccessToJson(
      instance.uniformBucketLevelAccess,
    ),
  };
}

UniformBucketLevelAccess? uniformBucketLevelAccessFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return UniformBucketLevelAccess(
    enabled: json['enabled'] as bool?,
    lockedTime: timestampFromJson(json['lockedTime']),
  );
}

Map<String, Object?>? uniformBucketLevelAccessToJson(
  UniformBucketLevelAccess? instance,
) {
  if (instance == null) return null;
  return {
    'enabled': ?instance.enabled,
    'lockedTime': ?timestampToJson(instance.lockedTime),
  };
}

BucketIpFilter? bucketIpFilterFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketIpFilter(
    allowAllServiceAgentAccess: json['allowAllServiceAgentAccess'] as bool?,
    allowCrossOrgVpcs: json['allowCrossOrgVpcs'] as bool?,
    mode: json['mode'] as String?,
    publicNetworkSource: bucketPublicNetworkSourceFromJson(
      json['publicNetworkSource'] as Map<String, Object?>?,
    ),
    vpcNetworkSources: (json['vpcNetworkSources'] as List<Object?>?)
        ?.map(
          (e) => bucketPublicNetworkSourceFromJson(e as Map<String, Object?>?)!,
        )
        .toList(),
  );
}

Map<String, Object?>? bucketIpFilterToJson(BucketIpFilter? instance) {
  if (instance == null) return null;
  return {
    'allowAllServiceAgentAccess': ?instance.allowAllServiceAgentAccess,
    'allowCrossOrgVpcs': ?instance.allowCrossOrgVpcs,
    'mode': ?instance.mode,
    'publicNetworkSource': ?bucketPublicNetworkSourceToJson(
      instance.publicNetworkSource,
    ),
    'vpcNetworkSources': ?instance.vpcNetworkSources
        ?.map(bucketPublicNetworkSourceToJson)
        .toList(),
  };
}

BucketPublicNetworkSource? bucketPublicNetworkSourceFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketPublicNetworkSource(
    allowedIpCidrRanges: (json['allowedIpCidrRanges'] as List<Object?>?)
        ?.cast<String>(),
  );
}

Map<String, Object?>? bucketPublicNetworkSourceToJson(
  BucketPublicNetworkSource? instance,
) {
  if (instance == null) return null;
  return {'allowedIpCidrRanges': ?instance.allowedIpCidrRanges};
}

Lifecycle? lifecycleFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return Lifecycle(
    rule: (json['rule'] as List<Object?>?)
        ?.map((e) => lifecycleRuleFromJson(e as Map<String, Object?>?)!)
        .toList(),
  );
}

Map<String, Object?>? lifecycleToJson(Lifecycle? instance) {
  if (instance == null) return null;
  return {'rule': ?instance.rule?.map(lifecycleRuleToJson).toList()};
}

LifecycleRule? lifecycleRuleFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return LifecycleRule(
    action: lifecycleRuleActionFromJson(
      json['action'] as Map<String, Object?>?,
    ),
    condition: lifecycleRuleConditionFromJson(
      json['condition'] as Map<String, Object?>?,
    ),
  );
}

Map<String, Object?>? lifecycleRuleToJson(LifecycleRule? instance) {
  if (instance == null) return null;
  return {
    'action': ?lifecycleRuleActionToJson(instance.action),
    'condition': ?lifecycleRuleConditionToJson(instance.condition),
  };
}

LifecycleRuleAction? lifecycleRuleActionFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return LifecycleRuleAction(
    storageClass: json['storageClass'] as String?,
    type: json['type'] as String?,
  );
}

Map<String, Object?>? lifecycleRuleActionToJson(LifecycleRuleAction? instance) {
  if (instance == null) return null;
  return {'storageClass': ?instance.storageClass, 'type': ?instance.type};
}

LifecycleRuleCondition? lifecycleRuleConditionFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return LifecycleRuleCondition(
    age: json['age'] as int?,
    createdBefore: dateFromJson(json['createdBefore']),
    customTimeBefore: dateFromJson(json['customTimeBefore']),
    daysSinceCustomTime: json['daysSinceCustomTime'] as int?,
    daysSinceNoncurrentTime: json['daysSinceNoncurrentTime'] as int?,
    isLive: json['isLive'] as bool?,
    matchesPrefix: (json['matchesPrefix'] as List<Object?>?)?.cast<String>(),
    matchesStorageClass: (json['matchesStorageClass'] as List<Object?>?)
        ?.cast<String>(),
    matchesSuffix: (json['matchesSuffix'] as List<Object?>?)?.cast<String>(),
    noncurrentTimeBefore: dateFromJson(json['noncurrentTimeBefore']),
    numNewerVersions: json['numNewerVersions'] as int?,
  );
}

Map<String, Object?>? lifecycleRuleConditionToJson(
  LifecycleRuleCondition? instance,
) {
  if (instance == null) return null;
  return {
    'age': ?instance.age,
    'createdBefore': ?dateToJson(instance.createdBefore),
    'customTimeBefore': ?dateToJson(instance.customTimeBefore),
    'daysSinceCustomTime': ?instance.daysSinceCustomTime,
    'daysSinceNoncurrentTime': ?instance.daysSinceNoncurrentTime,
    'isLive': ?instance.isLive,
    'matchesPrefix': ?instance.matchesPrefix,
    'matchesStorageClass': ?instance.matchesStorageClass,
    'matchesSuffix': ?instance.matchesSuffix,
    'noncurrentTimeBefore': ?dateToJson(instance.noncurrentTimeBefore),
    'numNewerVersions': ?instance.numNewerVersions,
  };
}

BucketLoggingConfiguration? bucketLoggingConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketLoggingConfiguration(
    logBucket: json['logBucket'] as String?,
    logObjectPrefix: json['logObjectPrefix'] as String?,
  );
}

Map<String, Object?>? bucketLoggingConfigurationToJson(
  BucketLoggingConfiguration? instance,
) {
  if (instance == null) return null;
  return {
    'logBucket': ?instance.logBucket,
    'logObjectPrefix': ?instance.logObjectPrefix,
  };
}

BucketOwner? bucketOwnerFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketOwner(
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
  );
}

Map<String, Object?>? bucketOwnerToJson(BucketOwner? instance) {
  if (instance == null) return null;
  return {'entity': ?instance.entity, 'entityId': ?instance.entityId};
}

BucketRetentionPolicy? bucketRetentionPolicyFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketRetentionPolicy(
    effectiveTime: timestampFromJson(json['effectiveTime']),
    isLocked: json['isLocked'] as bool?,
    retentionPeriod: int64FromJson(json['retentionPeriod']),
  );
}

Map<String, Object?>? bucketRetentionPolicyToJson(
  BucketRetentionPolicy? instance,
) {
  if (instance == null) return null;
  return {
    'effectiveTime': ?timestampToJson(instance.effectiveTime),
    'isLocked': ?instance.isLocked,
    'retentionPeriod': ?int64ToJson(instance.retentionPeriod),
  };
}

BucketSoftDeletePolicy? bucketSoftDeletePolicyFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketSoftDeletePolicy(
    effectiveTime: timestampFromJson(json['effectiveTime']),
    retentionDurationSeconds: int64FromJson(json['retentionDurationSeconds']),
  );
}

Map<String, Object?>? bucketSoftDeletePolicyToJson(
  BucketSoftDeletePolicy? instance,
) {
  if (instance == null) return null;
  return {
    'effectiveTime': ?timestampToJson(instance.effectiveTime),
    'retentionDurationSeconds': ?int64ToJson(instance.retentionDurationSeconds),
  };
}

BucketVersioning? bucketVersioningFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return BucketVersioning(enabled: json['enabled'] as bool?);
}

Map<String, Object?>? bucketVersioningToJson(BucketVersioning? instance) {
  if (instance == null) return null;
  return {'enabled': ?instance.enabled};
}

BucketWebsiteConfiguration? bucketWebsiteConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return BucketWebsiteConfiguration(
    mainPageSuffix: json['mainPageSuffix'] as String?,
    notFoundPage: json['notFoundPage'] as String?,
  );
}

Map<String, Object?>? bucketWebsiteConfigurationToJson(
  BucketWebsiteConfiguration? instance,
) {
  if (instance == null) return null;
  return {
    'mainPageSuffix': ?instance.mainPageSuffix,
    'notFoundPage': ?instance.notFoundPage,
  };
}

BucketMetadata bucketMetadataFromJson(
  Map<String, Object?> json,
) => BucketMetadata(
  acl: (json['acl'] as List<Object?>?)
      ?.map((e) => bucketAccessControlFromJson(e as Map<String, Object?>?)!)
      .toList(),
  autoclass: bucketAutoclassFromJson(
    json['autoclass'] as Map<String, Object?>?,
  ),
  billing: bucketBillingFromJson(json['billing'] as Map<String, Object?>?),
  cors: (json['cors'] as List<Object?>?)
      ?.map((e) => bucketCorsConfigurationFromJson(e as Map<String, Object?>?)!)
      .toList(),
  customPlacementConfig: bucketCustomPlacementConfigFromJson(
    json['customPlacementConfig'] as Map<String, Object?>?,
  ),
  defaultEventBasedHold: json['defaultEventBasedHold'] as bool?,
  defaultObjectAcl: (json['defaultObjectAcl'] as List<Object?>?)
      ?.map((e) => _objectAccessControlFromJson(e as Map<String, Object?>?)!)
      .toList(),
  encryption: bucketEncryptionFromJson(
    json['encryption'] as Map<String, Object?>?,
  ),
  etag: json['etag'] as String?,
  generation: int64FromJson(json['generation']),
  hardDeleteTime: timestampFromJson(json['hardDeleteTime']),
  hierarchicalNamespace: bucketHierarchicalNamespaceFromJson(
    json['hierarchicalNamespace'] as Map<String, Object?>?,
  ),
  iamConfiguration: bucketIamConfigurationFromJson(
    json['iamConfiguration'] as Map<String, Object?>?,
  ),
  id: json['id'] as String?,
  ipFilter: bucketIpFilterFromJson(json['ipFilter'] as Map<String, Object?>?),
  kind: json['kind'] as String?,
  labels: (json['labels'] as Map<String, Object?>?)?.cast<String, String>(),
  lifecycle: lifecycleFromJson(json['lifecycle'] as Map<String, Object?>?),
  location: json['location'] as String?,
  locationType: json['locationType'] as String?,
  logging: bucketLoggingConfigurationFromJson(
    json['logging'] as Map<String, Object?>?,
  ),
  metageneration: int64FromJson(json['metageneration']),
  name: json['name'] as String?,
  objectRetention: bucketObjectRetentionFromJson(
    json['objectRetention'] as Map<String, Object?>?,
  ),
  owner: bucketOwnerFromJson(json['owner'] as Map<String, Object?>?),
  projectNumber: json['projectNumber'] as String?,
  retentionPolicy: bucketRetentionPolicyFromJson(
    json['retentionPolicy'] as Map<String, Object?>?,
  ),
  rpo: json['rpo'] as String?,
  selfLink: json['selfLink'] == null
      ? null
      : Uri.parse(json['selfLink'] as String),
  softDeletePolicy: bucketSoftDeletePolicyFromJson(
    json['softDeletePolicy'] as Map<String, Object?>?,
  ),
  softDeleteTime: timestampFromJson(json['softDeleteTime']),
  storageClass: json['storageClass'] as String?,
  timeCreated: timestampFromJson(json['timeCreated']),
  updated: timestampFromJson(json['updated']),
  versioning: bucketVersioningFromJson(
    json['versioning'] as Map<String, Object?>?,
  ),
  website: bucketWebsiteConfigurationFromJson(
    json['website'] as Map<String, Object?>?,
  ),
);

Map<String, Object?> bucketMetadataToJson(BucketMetadata instance) => {
  'acl': ?instance.acl?.map(bucketAccessControlToJson).toList(),
  'autoclass': ?bucketAutoclassToJson(instance.autoclass),
  'billing': ?bucketBillingToJson(instance.billing),
  'cors': ?instance.cors?.map(bucketCorsConfigurationToJson).toList(),
  'customPlacementConfig': ?bucketCustomPlacementConfigToJson(
    instance.customPlacementConfig,
  ),
  'defaultEventBasedHold': ?instance.defaultEventBasedHold,
  'defaultObjectAcl': ?instance.defaultObjectAcl
      ?.map(_objectAccessControlToJson)
      .toList(),
  'encryption': ?bucketEncryptionToJson(instance.encryption),
  'etag': ?instance.etag,
  'generation': ?int64ToJson(instance.generation),
  'hardDeleteTime': ?timestampToJson(instance.hardDeleteTime),
  'hierarchicalNamespace': ?bucketHierarchicalNamespaceToJson(
    instance.hierarchicalNamespace,
  ),
  'iamConfiguration': ?bucketIamConfigurationToJson(instance.iamConfiguration),
  'id': ?instance.id,
  'ipFilter': ?bucketIpFilterToJson(instance.ipFilter),
  'kind': ?instance.kind,
  'labels': ?instance.labels,
  'lifecycle': ?lifecycleToJson(instance.lifecycle),
  'location': ?instance.location,
  'locationType': ?instance.locationType,
  'logging': ?bucketLoggingConfigurationToJson(instance.logging),
  'metageneration': ?int64ToJson(instance.metageneration),
  'name': ?instance.name,
  'objectRetention': ?bucketObjectRetentionToJson(instance.objectRetention),
  'owner': ?bucketOwnerToJson(instance.owner),
  'projectNumber': ?instance.projectNumber,
  'retentionPolicy': ?bucketRetentionPolicyToJson(instance.retentionPolicy),
  'rpo': ?instance.rpo,
  'selfLink': ?instance.selfLink?.toString(),
  'softDeletePolicy': ?bucketSoftDeletePolicyToJson(instance.softDeletePolicy),
  'softDeleteTime': ?timestampToJson(instance.softDeleteTime),
  'storageClass': ?instance.storageClass,
  'timeCreated': ?timestampToJson(instance.timeCreated),
  'updated': ?timestampToJson(instance.updated),
  'versioning': ?bucketVersioningToJson(instance.versioning),
  'website': ?bucketWebsiteConfigurationToJson(instance.website),
};

// Private helpers

ObjectAccessControl? _objectAccessControlFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return ObjectAccessControl(
    bucket: json['bucket'] as String?,
    domain: json['domain'] as String?,
    email: json['email'] as String?,
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
    etag: json['etag'] as String?,
    generation:
        json['generation']
            as String?, // ObjectAccessControl.generation is String?
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    object: json['object'] as String?,
    projectTeam: projectTeamFromJson(
      json['projectTeam'] as Map<String, Object?>?,
    ),
    role: json['role'] as String?,
    selfLink: json['selfLink'] == null
        ? null
        : Uri.parse(json['selfLink'] as String),
  );
}

Map<String, Object?>? _objectAccessControlToJson(
  ObjectAccessControl? instance,
) {
  if (instance == null) return null;
  return {
    'bucket': ?instance.bucket,
    'domain': ?instance.domain,
    'email': ?instance.email,
    'entity': ?instance.entity,
    'entityId': ?instance.entityId,
    'etag': ?instance.etag,
    'generation': ?instance.generation,
    'id': ?instance.id,
    'kind': ?instance.kind,
    'object': ?instance.object,
    'projectTeam': ?projectTeamToJson(instance.projectTeam),
    'role': ?instance.role,
    'selfLink': ?instance.selfLink?.toString(),
  };
}
