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

import '../google_cloud_storage.dart';
import 'common_json.dart';

Map<String, Object?> objectMetadataToJson(ObjectMetadata instance) => {
  'acl': ?instance.acl?.map(objectAccessControlToJson).toList(),
  'bucket': ?instance.bucket,
  'cacheControl': ?instance.cacheControl,
  'componentCount': ?instance.componentCount,
  'contentDisposition': ?instance.contentDisposition,
  'contentEncoding': ?instance.contentEncoding,
  'contentLanguage': ?instance.contentLanguage,
  'contentType': ?instance.contentType,
  'contexts': ?_objectContextsToJson(instance.contexts),
  'crc32c': ?instance.crc32c,
  'customerEncryption': ?_customerEncryptionToJson(instance.customerEncryption),
  'customTime': ?timestampToJson(instance.customTime),
  'etag': ?instance.etag,
  'eventBasedHold': ?instance.eventBasedHold,
  'generation': ?int64ToJson(instance.generation),
  'hardDeleteTime': ?timestampToJson(instance.hardDeleteTime),
  'id': ?instance.id,
  'kind': ?instance.kind,
  'kmsKeyName': ?instance.kmsKeyName,
  'md5Hash': ?instance.md5Hash,
  'mediaLink': ?instance.mediaLink?.toString(),
  'metadata': ?instance.metadata,
  'metageneration': ?int64ToJson(instance.metageneration),
  'name': ?instance.name,
  'owner': ?_ownerToJson(instance.owner),
  'restoreToken': ?instance.restoreToken,
  'retention': ?objectRetentionToJson(instance.retention),
  'retentionExpirationTime': ?timestampToJson(instance.retentionExpirationTime),
  'selfLink': ?instance.selfLink?.toString(),
  'size': ?int64ToJson(instance.size),
  'softDeleteTime': ?timestampToJson(instance.softDeleteTime),
  'storageClass': ?instance.storageClass,
  'temporaryHold': ?instance.temporaryHold,
  'timeCreated': ?timestampToJson(instance.timeCreated),
  'timeDeleted': ?timestampToJson(instance.timeDeleted),
  'timeStorageClassUpdated': ?timestampToJson(instance.timeStorageClassUpdated),
  'updated': ?timestampToJson(instance.updated),
};

ObjectMetadata objectMetadataFromJson(
  Map<String, Object?> json,
) => ObjectMetadata(
  acl: (json['acl'] as List?)
      ?.map((e) => objectAccessControlFromJson(e as Map<String, Object?>?))
      .nonNulls
      .toList(),
  bucket: json['bucket'] as String?,
  cacheControl: json['cacheControl'] as String?,
  componentCount: json['componentCount'] as int?,
  contentDisposition: json['contentDisposition'] as String?,
  contentEncoding: json['contentEncoding'] as String?,
  contentLanguage: json['contentLanguage'] as String?,
  contentType: json['contentType'] as String?,
  contexts: _objectContextsFromJson(json['contexts'] as Map<String, Object?>?),
  crc32c: json['crc32c'] as String?,
  customerEncryption: _customerEncryptionFromJson(
    json['customerEncryption'] as Map<String, Object?>?,
  ),
  customTime: timestampFromJson(json['customTime']),
  etag: json['etag'] as String?,
  eventBasedHold: json['eventBasedHold'] as bool?,
  generation: int64FromJson(json['generation']),
  hardDeleteTime: timestampFromJson(json['hardDeleteTime']),
  id: json['id'] as String?,
  kind: json['kind'] as String?,
  kmsKeyName: json['kmsKeyName'] as String?,
  md5Hash: json['md5Hash'] as String?,
  mediaLink: json['mediaLink'] == null
      ? null
      : Uri.parse(json['mediaLink'] as String),
  metadata: (json['metadata'] as Map?)?.cast<String, String>(),
  metageneration: int64FromJson(json['metageneration']),
  name: json['name'] as String?,
  owner: _ownerFromJson(json['owner'] as Map<String, Object?>?),
  restoreToken: json['restoreToken'] as String?,
  retention: _objectRetentionFromJson(
    json['retention'] as Map<String, Object?>?,
  ),
  retentionExpirationTime: timestampFromJson(json['retentionExpirationTime']),
  selfLink: json['selfLink'] == null
      ? null
      : Uri.parse(json['selfLink'] as String),
  size: int64FromJson(json['size']),
  softDeleteTime: timestampFromJson(json['softDeleteTime']),
  storageClass: json['storageClass'] as String?,
  temporaryHold: json['temporaryHold'] as bool?,
  timeCreated: timestampFromJson(json['timeCreated']),
  timeDeleted: timestampFromJson(json['timeDeleted']),
  timeStorageClassUpdated: timestampFromJson(json['timeStorageClassUpdated']),
  updated: timestampFromJson(json['updated']),
);

CustomerEncryption? _customerEncryptionFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return CustomerEncryption(
    encryptionAlgorithm: json['encryptionAlgorithm'] as String?,
    keySha256: json['keySha256'] as String?,
  );
}

Map<String, Object?>? _customerEncryptionToJson(CustomerEncryption? instance) {
  if (instance == null) return null;
  return {
    'encryptionAlgorithm': ?instance.encryptionAlgorithm,
    'keySha256': ?instance.keySha256,
  };
}

Owner? _ownerFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return Owner(
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
  );
}

Map<String, Object?>? _ownerToJson(Owner? instance) {
  if (instance == null) return null;
  return {'entity': ?instance.entity, 'entityId': ?instance.entityId};
}

ObjectRetention? _objectRetentionFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return ObjectRetention(
    mode: json['mode'] as String?,
    retainUntilTime: timestampFromJson(json['retainUntilTime']),
  );
}

Map<String, Object?>? objectRetentionToJson(ObjectRetention? instance) {
  if (instance == null) return null;
  return {
    'mode': ?instance.mode,
    'retainUntilTime': ?timestampToJson(instance.retainUntilTime),
  };
}

ObjectContexts? _objectContextsFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  final customJson = json['custom'] as Map<String, Object?>?;
  Map<String, ObjectCustomContextPayload>? custom;
  if (customJson != null) {
    custom = {};
    for (final entry in customJson.entries) {
      final value = _objectCustomContextPayloadFromJson(
        entry.value as Map<String, Object?>?,
      );
      if (value != null) {
        custom[entry.key] = value;
      }
    }
  }
  return ObjectContexts(custom: custom);
}

Map<String, Object?>? _objectContextsToJson(ObjectContexts? instance) {
  if (instance == null) return null;
  return {
    'custom': ?instance.custom?.map(
      (key, value) => MapEntry(key, _objectCustomContextPayloadToJson(value)),
    ),
  };
}

ObjectCustomContextPayload? _objectCustomContextPayloadFromJson(
  Map<String, Object?>? json,
) {
  if (json == null) return null;
  return ObjectCustomContextPayload(
    createTime: timestampFromJson(json['createTime']),
    updateTime: timestampFromJson(json['updateTime']),
    value: json['value'] as String?,
  );
}

Map<String, Object?>? _objectCustomContextPayloadToJson(
  ObjectCustomContextPayload? instance,
) {
  if (instance == null) return null;
  return {
    'createTime': ?timestampToJson(instance.createTime),
    'updateTime': ?timestampToJson(instance.updateTime),
    'value': ?instance.value,
  };
}
