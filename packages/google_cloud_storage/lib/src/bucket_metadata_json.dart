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

import 'bucket_metadata.dart';
import 'object_metadata.dart';
import 'project_team.dart';

BucketAutoclass? bucketAutoclassFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketAutoclass(
    enabled: json['enabled'] as bool?,
    terminalStorageClass: json['terminalStorageClass'] as String?,
    terminalStorageClassUpdateTime: _timestampFromJson(
      json['terminalStorageClassUpdateTime'],
    ),
    toggleTime: _timestampFromJson(json['toggleTime']),
  );
}

Map<String, Object?>? bucketAutoclassToJson(BucketAutoclass? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.enabled != null) 'enabled': instance.enabled,
    if (instance.terminalStorageClass != null)
      'terminalStorageClass': instance.terminalStorageClass,
    if (instance.terminalStorageClassUpdateTime != null)
      'terminalStorageClassUpdateTime': _timestampToJson(
        instance.terminalStorageClassUpdateTime,
      ),
    if (instance.toggleTime != null)
      'toggleTime': _timestampToJson(instance.toggleTime),
  };
}

BucketBilling? bucketBillingFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketBilling(requesterPays: json['requesterPays'] as bool?);
}

Map<String, Object?>? bucketBillingToJson(BucketBilling? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.requesterPays != null) 'requesterPays': instance.requesterPays,
  };
}

BucketAccessControl? bucketAccessControlFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketAccessControl(
    bucket: json['bucket'] as String?,
    domain: json['domain'] as String?,
    email: json['email'] as String?,
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
    etag: json['etag'] as String?,
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    projectTeam: _projectTeamFromJson(
      json['projectTeam'] as Map<String, Object?>?,
    ),
    role: json['role'] as String?,
    selfLink: json['selfLink'] == null
        ? null
        : Uri.parse(json['selfLink'] as String),
  );
}

Map<String, Object?>? bucketAccessControlToJson(BucketAccessControl? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.bucket != null) 'bucket': instance.bucket,
    if (instance.domain != null) 'domain': instance.domain,
    if (instance.email != null) 'email': instance.email,
    if (instance.entity != null) 'entity': instance.entity,
    if (instance.entityId != null) 'entityId': instance.entityId,
    if (instance.etag != null) 'etag': instance.etag,
    if (instance.id != null) 'id': instance.id,
    if (instance.kind != null) 'kind': instance.kind,
    if (instance.projectTeam != null)
      'projectTeam': _projectTeamToJson(instance.projectTeam),
    if (instance.role != null) 'role': instance.role,
    if (instance.selfLink != null) 'selfLink': instance.selfLink.toString(),
  };
}

BucketEncryption? bucketEncryptionFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketEncryption(
    defaultKmsKeyName: json['defaultKmsKeyName'] as String?,
  );
}

Map<String, Object?>? bucketEncryptionToJson(BucketEncryption? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.defaultKmsKeyName != null)
      'defaultKmsKeyName': instance.defaultKmsKeyName,
  };
}

BucketObjectRetention? bucketObjectRetentionFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketObjectRetention(mode: json['mode'] as String?);
}

Map<String, Object?>? bucketObjectRetentionToJson(
  BucketObjectRetention? instance,
) {
  if (instance == null) {
    return null;
  }
  return {if (instance.mode != null) 'mode': instance.mode};
}

BucketCorsConfiguration? bucketCorsConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
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
  if (instance == null) {
    return null;
  }
  return {
    if (instance.maxAgeSeconds != null) 'maxAgeSeconds': instance.maxAgeSeconds,
    if (instance.method != null) 'method': instance.method,
    if (instance.origin != null) 'origin': instance.origin,
    if (instance.responseHeader != null)
      'responseHeader': instance.responseHeader,
  };
}

BucketCustomPlacementConfig? bucketCustomPlacementConfigFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketCustomPlacementConfig(
    dataLocations: (json['dataLocations'] as List<Object?>?)?.cast<String>(),
  );
}

Map<String, Object?>? bucketCustomPlacementConfigToJson(
  BucketCustomPlacementConfig? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.dataLocations != null) 'dataLocations': instance.dataLocations,
  };
}

BucketHierarchicalNamespace? bucketHierarchicalNamespaceFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketHierarchicalNamespace(enabled: json['enabled'] as bool?);
}

Map<String, Object?>? bucketHierarchicalNamespaceToJson(
  BucketHierarchicalNamespace? instance,
) {
  if (instance == null) {
    return null;
  }
  return {if (instance.enabled != null) 'enabled': instance.enabled};
}

BucketIamConfiguration? bucketIamConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
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
  if (instance == null) {
    return null;
  }
  return {
    if (instance.publicAccessPrevention != null)
      'publicAccessPrevention': instance.publicAccessPrevention,
    if (instance.uniformBucketLevelAccess != null)
      'uniformBucketLevelAccess': uniformBucketLevelAccessToJson(
        instance.uniformBucketLevelAccess,
      ),
  };
}

UniformBucketLevelAccess? uniformBucketLevelAccessFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return UniformBucketLevelAccess(
    enabled: json['enabled'] as bool?,
    lockedTime: _timestampFromJson(json['lockedTime']),
  );
}

Map<String, Object?>? uniformBucketLevelAccessToJson(
  UniformBucketLevelAccess? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.enabled != null) 'enabled': instance.enabled,
    if (instance.lockedTime != null)
      'lockedTime': _timestampToJson(instance.lockedTime),
  };
}

BucketIpFilter? bucketIpFilterFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
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
  if (instance == null) {
    return null;
  }
  return {
    if (instance.allowAllServiceAgentAccess != null)
      'allowAllServiceAgentAccess': instance.allowAllServiceAgentAccess,
    if (instance.allowCrossOrgVpcs != null)
      'allowCrossOrgVpcs': instance.allowCrossOrgVpcs,
    if (instance.mode != null) 'mode': instance.mode,
    if (instance.publicNetworkSource != null)
      'publicNetworkSource': bucketPublicNetworkSourceToJson(
        instance.publicNetworkSource,
      ),
    if (instance.vpcNetworkSources != null)
      'vpcNetworkSources': instance.vpcNetworkSources!
          .map(bucketPublicNetworkSourceToJson)
          .toList(),
  };
}

BucketPublicNetworkSource? bucketPublicNetworkSourceFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketPublicNetworkSource(
    allowedIpCidrRanges: (json['allowedIpCidrRanges'] as List<Object?>?)
        ?.cast<String>(),
  );
}

Map<String, Object?>? bucketPublicNetworkSourceToJson(
  BucketPublicNetworkSource? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.allowedIpCidrRanges != null)
      'allowedIpCidrRanges': instance.allowedIpCidrRanges,
  };
}

Lifecycle? lifecycleFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return Lifecycle(
    rule: (json['rule'] as List<Object?>?)
        ?.map((e) => lifecycleRuleFromJson(e as Map<String, Object?>?)!)
        .toList(),
  );
}

Map<String, Object?>? lifecycleToJson(Lifecycle? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.rule != null)
      'rule': instance.rule!.map(lifecycleRuleToJson).toList(),
  };
}

LifecycleRule? lifecycleRuleFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
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
  if (instance == null) {
    return null;
  }
  return {
    if (instance.action != null)
      'action': lifecycleRuleActionToJson(instance.action),
    if (instance.condition != null)
      'condition': lifecycleRuleConditionToJson(instance.condition),
  };
}

LifecycleRuleAction? lifecycleRuleActionFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return LifecycleRuleAction(
    storageClass: json['storageClass'] as String?,
    type: json['type'] as String?,
  );
}

Map<String, Object?>? lifecycleRuleActionToJson(LifecycleRuleAction? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.storageClass != null) 'storageClass': instance.storageClass,
    if (instance.type != null) 'type': instance.type,
  };
}

LifecycleRuleCondition? lifecycleRuleConditionFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return LifecycleRuleCondition(
    age: json['age'] as int?,
    createdBefore: _dateFromJson(json['createdBefore']),
    customTimeBefore: _dateFromJson(json['customTimeBefore']),
    daysSinceCustomTime: json['daysSinceCustomTime'] as int?,
    daysSinceNoncurrentTime: json['daysSinceNoncurrentTime'] as int?,
    isLive: json['isLive'] as bool?,
    matchesPrefix: (json['matchesPrefix'] as List<Object?>?)?.cast<String>(),
    matchesStorageClass: (json['matchesStorageClass'] as List<Object?>?)
        ?.cast<String>(),
    matchesSuffix: (json['matchesSuffix'] as List<Object?>?)?.cast<String>(),
    noncurrentTimeBefore: _dateFromJson(json['noncurrentTimeBefore']),
    numNewerVersions: json['numNewerVersions'] as int?,
  );
}

Map<String, Object?>? lifecycleRuleConditionToJson(
  LifecycleRuleCondition? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.age != null) 'age': instance.age,
    if (instance.createdBefore != null)
      'createdBefore': _dateToJson(instance.createdBefore),
    if (instance.customTimeBefore != null)
      'customTimeBefore': _dateToJson(instance.customTimeBefore),
    if (instance.daysSinceCustomTime != null)
      'daysSinceCustomTime': instance.daysSinceCustomTime,
    if (instance.daysSinceNoncurrentTime != null)
      'daysSinceNoncurrentTime': instance.daysSinceNoncurrentTime,
    if (instance.isLive != null) 'isLive': instance.isLive,
    if (instance.matchesPrefix != null) 'matchesPrefix': instance.matchesPrefix,
    if (instance.matchesStorageClass != null)
      'matchesStorageClass': instance.matchesStorageClass,
    if (instance.matchesSuffix != null) 'matchesSuffix': instance.matchesSuffix,
    if (instance.noncurrentTimeBefore != null)
      'noncurrentTimeBefore': _dateToJson(instance.noncurrentTimeBefore),
    if (instance.numNewerVersions != null)
      'numNewerVersions': instance.numNewerVersions,
  };
}

BucketLoggingConfiguration? bucketLoggingConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketLoggingConfiguration(
    logBucket: json['logBucket'] as String?,
    logObjectPrefix: json['logObjectPrefix'] as String?,
  );
}

Map<String, Object?>? bucketLoggingConfigurationToJson(
  BucketLoggingConfiguration? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.logBucket != null) 'logBucket': instance.logBucket,
    if (instance.logObjectPrefix != null)
      'logObjectPrefix': instance.logObjectPrefix,
  };
}

BucketOwner? bucketOwnerFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketOwner(
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
  );
}

Map<String, Object?>? bucketOwnerToJson(BucketOwner? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.entity != null) 'entity': instance.entity,
    if (instance.entityId != null) 'entityId': instance.entityId,
  };
}

BucketRetentionPolicy? bucketRetentionPolicyFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketRetentionPolicy(
    effectiveTime: _timestampFromJson(json['effectiveTime']),
    isLocked: json['isLocked'] as bool?,
    retentionPeriod: _int64FromJson(json['retentionPeriod']),
  );
}

Map<String, Object?>? bucketRetentionPolicyToJson(
  BucketRetentionPolicy? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.effectiveTime != null)
      'effectiveTime': _timestampToJson(instance.effectiveTime),
    if (instance.isLocked != null) 'isLocked': instance.isLocked,
    if (instance.retentionPeriod != null)
      'retentionPeriod': _int64ToJson(instance.retentionPeriod),
  };
}

BucketSoftDeletePolicy? bucketSoftDeletePolicyFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketSoftDeletePolicy(
    effectiveTime: _timestampFromJson(json['effectiveTime']),
    retentionDurationSeconds: _int64FromJson(json['retentionDurationSeconds']),
  );
}

Map<String, Object?>? bucketSoftDeletePolicyToJson(
  BucketSoftDeletePolicy? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.effectiveTime != null)
      'effectiveTime': _timestampToJson(instance.effectiveTime),
    if (instance.retentionDurationSeconds != null)
      'retentionDurationSeconds': _int64ToJson(
        instance.retentionDurationSeconds,
      ),
  };
}

BucketVersioning? bucketVersioningFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return BucketVersioning(enabled: json['enabled'] as bool?);
}

Map<String, Object?>? bucketVersioningToJson(BucketVersioning? instance) {
  if (instance == null) {
    return null;
  }
  return {if (instance.enabled != null) 'enabled': instance.enabled};
}

BucketWebsiteConfiguration? bucketWebsiteConfigurationFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) {
    return null;
  }
  return BucketWebsiteConfiguration(
    mainPageSuffix: json['mainPageSuffix'] as String?,
    notFoundPage: json['notFoundPage'] as String?,
  );
}

Map<String, Object?>? bucketWebsiteConfigurationToJson(
  BucketWebsiteConfiguration? instance,
) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.mainPageSuffix != null)
      'mainPageSuffix': instance.mainPageSuffix,
    if (instance.notFoundPage != null) 'notFoundPage': instance.notFoundPage,
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
  generation: _int64FromJson(json['generation']),
  hardDeleteTime: _timestampFromJson(json['hardDeleteTime']),
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
  metageneration: _int64FromJson(json['metageneration']),
  name: json['name'] as String?,
  objectRetention: bucketObjectRetentionFromJson(
    json['objectRetention'] as Map<String, Object?>?,
  ),
  owner: bucketOwnerFromJson(json['owner'] as Map<String, Object?>?),
  projectNumber: _int64ToString(
    json['projectNumber'],
  ), // Handle int/string ambiguity for projectNumber
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
  softDeleteTime: _timestampFromJson(json['softDeleteTime']),
  storageClass: json['storageClass'] as String?,
  timeCreated: _timestampFromJson(json['timeCreated']),
  updated: _timestampFromJson(json['updated']),
  versioning: bucketVersioningFromJson(
    json['versioning'] as Map<String, Object?>?,
  ),
  website: bucketWebsiteConfigurationFromJson(
    json['website'] as Map<String, Object?>?,
  ),
);

Map<String, Object?> bucketMetadataToJson(BucketMetadata instance) => {
  if (instance.acl != null)
    'acl': instance.acl!.map(bucketAccessControlToJson).toList(),
  if (instance.autoclass != null)
    'autoclass': bucketAutoclassToJson(instance.autoclass),
  if (instance.billing != null)
    'billing': bucketBillingToJson(instance.billing),
  if (instance.cors != null)
    'cors': instance.cors!.map(bucketCorsConfigurationToJson).toList(),
  if (instance.customPlacementConfig != null)
    'customPlacementConfig': bucketCustomPlacementConfigToJson(
      instance.customPlacementConfig,
    ),
  if (instance.defaultEventBasedHold != null)
    'defaultEventBasedHold': instance.defaultEventBasedHold,
  if (instance.defaultObjectAcl != null)
    'defaultObjectAcl': instance.defaultObjectAcl!
        .map(_objectAccessControlToJson)
        .toList(),
  if (instance.encryption != null)
    'encryption': bucketEncryptionToJson(instance.encryption),
  if (instance.etag != null) 'etag': instance.etag,
  if (instance.generation != null)
    'generation': _int64ToJson(instance.generation),
  if (instance.hardDeleteTime != null)
    'hardDeleteTime': _timestampToJson(instance.hardDeleteTime),
  if (instance.hierarchicalNamespace != null)
    'hierarchicalNamespace': bucketHierarchicalNamespaceToJson(
      instance.hierarchicalNamespace,
    ),
  if (instance.iamConfiguration != null)
    'iamConfiguration': bucketIamConfigurationToJson(instance.iamConfiguration),
  if (instance.id != null) 'id': instance.id,
  if (instance.ipFilter != null)
    'ipFilter': bucketIpFilterToJson(instance.ipFilter),
  if (instance.kind != null) 'kind': instance.kind,
  if (instance.labels != null) 'labels': instance.labels,
  if (instance.lifecycle != null)
    'lifecycle': lifecycleToJson(instance.lifecycle),
  if (instance.location != null) 'location': instance.location,
  if (instance.locationType != null) 'locationType': instance.locationType,
  if (instance.logging != null)
    'logging': bucketLoggingConfigurationToJson(instance.logging),
  if (instance.metageneration != null)
    'metageneration': _int64ToJson(instance.metageneration),
  if (instance.name != null) 'name': instance.name,
  if (instance.objectRetention != null)
    'objectRetention': bucketObjectRetentionToJson(instance.objectRetention),
  if (instance.owner != null) 'owner': bucketOwnerToJson(instance.owner),
  if (instance.projectNumber != null) 'projectNumber': instance.projectNumber,
  if (instance.retentionPolicy != null)
    'retentionPolicy': bucketRetentionPolicyToJson(instance.retentionPolicy),
  if (instance.rpo != null) 'rpo': instance.rpo,
  if (instance.selfLink != null) 'selfLink': instance.selfLink.toString(),
  if (instance.softDeletePolicy != null)
    'softDeletePolicy': bucketSoftDeletePolicyToJson(instance.softDeletePolicy),
  if (instance.softDeleteTime != null)
    'softDeleteTime': _timestampToJson(instance.softDeleteTime),
  if (instance.storageClass != null) 'storageClass': instance.storageClass,
  if (instance.timeCreated != null)
    'timeCreated': _timestampToJson(instance.timeCreated),
  if (instance.updated != null) 'updated': _timestampToJson(instance.updated),
  if (instance.versioning != null)
    'versioning': bucketVersioningToJson(instance.versioning),
  if (instance.website != null)
    'website': bucketWebsiteConfigurationToJson(instance.website),
};

// Private helpers

ProjectTeam? _projectTeamFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
  return ProjectTeam(
    projectNumber: json['projectNumber'] as String?,
    team: json['team'] as String?,
  );
}

Map<String, Object?>? _projectTeamToJson(ProjectTeam? instance) {
  if (instance == null) {
    return null;
  }
  return {
    if (instance.projectNumber != null) 'projectNumber': instance.projectNumber,
    if (instance.team != null) 'team': instance.team,
  };
}

ObjectAccessControl? _objectAccessControlFromJson(Map<String, Object?>? json) {
  if (json == null) {
    return null;
  }
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
    projectTeam: _projectTeamFromJson(
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
  if (instance == null) {
    return null;
  }
  return {
    if (instance.bucket != null) 'bucket': instance.bucket,
    if (instance.domain != null) 'domain': instance.domain,
    if (instance.email != null) 'email': instance.email,
    if (instance.entity != null) 'entity': instance.entity,
    if (instance.entityId != null) 'entityId': instance.entityId,
    if (instance.etag != null) 'etag': instance.etag,
    if (instance.generation != null) 'generation': instance.generation,
    if (instance.id != null) 'id': instance.id,
    if (instance.kind != null) 'kind': instance.kind,
    if (instance.object != null) 'object': instance.object,
    if (instance.projectTeam != null)
      'projectTeam': _projectTeamToJson(instance.projectTeam),
    if (instance.role != null) 'role': instance.role,
    if (instance.selfLink != null) 'selfLink': instance.selfLink.toString(),
  };
}

Timestamp? _timestampFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    final dateTime = DateTime.parse(json);
    return Timestamp(
      seconds: (dateTime.millisecondsSinceEpoch / 1000).floor(),
      nanos: (dateTime.microsecondsSinceEpoch % 1000000) * 1000,
    );
  }
  throw ArgumentError.value(json, 'json', 'Expected String for Timestamp');
}

Object? _timestampToJson(Timestamp? instance) {
  if (instance == null) {
    return null;
  }
  return instance.toDateTime().toUtc().toIso8601String();
}

int? _int64FromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    return int.parse(json);
  }
  if (json is int) {
    return json;
  }
  throw ArgumentError.value(json, 'json', 'Expected String or int for int64');
}

Object? _int64ToJson(int? instance) {
  if (instance == null) {
    return null;
  }
  return instance.toString();
}

String? _int64ToString(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    return json;
  }
  if (json is int) {
    return json.toString();
  }
  throw ArgumentError.value(json, 'json', 'Expected String or int for String');
}

DateTime? _dateFromJson(Object? json) {
  if (json == null) {
    return null;
  }
  if (json is String) {
    return DateTime.parse(json);
  }
  throw ArgumentError.value(json, 'json', 'Expected String for DateTime');
}

String? _dateToJson(DateTime? instance) {
  if (instance == null) {
    return null;
  }
  return '${instance.year.toString().padLeft(4, '0')}-'
      '${instance.month.toString().padLeft(2, '0')}-'
      '${instance.day.toString().padLeft(2, '0')}';
}
