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

import 'package:collection/collection.dart';
import 'package:google_cloud_protobuf/protobuf.dart';

import 'object_access_controls.dart';

/// Metadata of customer-supplied encryption key, if the object is encrypted by
/// such a key.
final class CustomerEncryption {
  /// The encryption algorithm.
  final String? encryptionAlgorithm;

  /// SHA256 hash value of the encryption key.
  final String? keySha256;

  CustomerEncryption({this.encryptionAlgorithm, this.keySha256});

  @override
  String toString() =>
      'CustomerEncryption(encryptionAlgorithm: $encryptionAlgorithm, '
      'keySha256: $keySha256)';

  @override
  int get hashCode => [encryptionAlgorithm, keySha256.hashCode].hashCode;

  @override
  bool operator ==(Object other) =>
      other is CustomerEncryption &&
      other.encryptionAlgorithm == encryptionAlgorithm &&
      other.keySha256 == keySha256;

  /// Creates a new [CustomerEncryption] with the given non-`null` fields
  /// replaced.
  CustomerEncryption copyWith({
    String? encryptionAlgorithm,
    String? keySha256,
  }) => CustomerEncryption(
    encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
    keySha256: keySha256 ?? this.keySha256,
  );

  /// Creates a new [CustomerEncryption] with the given fields set to `null`.
  CustomerEncryption copyWithout({
    bool encryptionAlgorithm = false,
    bool keySha256 = false,
  }) => CustomerEncryption(
    encryptionAlgorithm: encryptionAlgorithm ? null : this.encryptionAlgorithm,
    keySha256: keySha256 ? null : this.keySha256,
  );
}

/// The owner of the object. This will always be the uploader of the object
final class Owner {
  /// The entity, in the form user-userId.
  final String? entity;

  /// The ID for the entity.
  final String? entityId;

  Owner({this.entity, this.entityId});

  @override
  String toString() => 'Owner(entity: $entity, entityId: $entityId)';

  @override
  int get hashCode => [entity, entityId.hashCode].hashCode;

  @override
  bool operator ==(Object other) =>
      other is Owner && other.entity == entity && other.entityId == entityId;

  /// Creates a new [Owner] with the given non-`null` fields replaced.
  Owner copyWith({String? entity, String? entityId}) =>
      Owner(entity: entity ?? this.entity, entityId: entityId ?? this.entityId);

  /// Creates a new [Owner] with the given fields set to `null`.
  Owner copyWithout({bool entity = false, bool entityId = false}) => Owner(
    entity: entity ? null : this.entity,
    entityId: entityId ? null : this.entityId,
  );
}

/// The object's [retention configuration](https://docs.cloud.google.com/storage/docs/object-lock).
///
/// This defines the earliest datetime that the object can be deleted or
/// replaced.
final class ObjectRetention {
  /// The mode of the retention configuration, which can be either `"Unlocked"`
  /// or `"Locked"`.
  ///
  /// If set to `"Locked"`, `mode` cannot be changed, the retention
  /// configuration cannot be removed, and [retainUntilTime] cannot
  /// be reduced.
  final String? mode;

  /// The earliest time that the object can be deleted or replaced.
  ///
  /// This value is independent of any retention policy that is set for the
  /// bucket that contains the object. The maximum value is 3,155,760,000
  /// seconds (100 years) from the current date and time.
  final Timestamp? retainUntilTime;

  ObjectRetention({this.mode, this.retainUntilTime});

  @override
  String toString() =>
      'ObjectRetention(mode: $mode, retainUntilTime: $retainUntilTime)';

  @override
  int get hashCode => [mode, retainUntilTime.hashCode].hashCode;

  @override
  bool operator ==(Object other) =>
      other is ObjectRetention &&
      other.mode == mode &&
      other.retainUntilTime == retainUntilTime;

  /// Creates a new [ObjectRetention] with the given non-`null` fields replaced.
  ObjectRetention copyWith({String? mode, Timestamp? retainUntilTime}) =>
      ObjectRetention(
        mode: mode ?? this.mode,
        retainUntilTime: retainUntilTime ?? this.retainUntilTime,
      );

  /// Creates a new [ObjectRetention] with the given fields set to `null`.
  ObjectRetention copyWithout({
    bool mode = false,
    bool retainUntilTime = false,
  }) => ObjectRetention(
    mode: mode ? null : this.mode,
    retainUntilTime: retainUntilTime ? null : this.retainUntilTime,
  );
}

/// Contexts attached to an object, in key-value pairs.
///
/// For more information about object contexts, see
/// [Object contexts overview](https://cloud.google.com/storage/docs/object-contexts).
class ObjectContexts {
  final Map<String, ObjectCustomContextPayload>? custom;

  ObjectContexts({this.custom});

  @override
  String toString() => 'ObjectContexts(custom: $custom)';

  @override
  int get hashCode => custom.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ObjectContexts &&
      const DeepCollectionEquality().equals(other.custom, custom);

  /// Creates a new [ObjectContexts] with the given non-`null` fields replaced.
  ObjectContexts copyWith({Map<String, ObjectCustomContextPayload>? custom}) =>
      ObjectContexts(custom: custom ?? this.custom);

  /// Creates a new [ObjectContexts] with the given fields set to `null`.
  ObjectContexts copyWithout({bool custom = false}) =>
      ObjectContexts(custom: custom ? null : this.custom);
}

/// The payload of a single user-defined object context.
class ObjectCustomContextPayload {
  /// The time at which the object context was created.
  final Timestamp? createTime;

  /// The time at which the object context was last updated.
  final Timestamp? updateTime;

  /// The value of the object context.
  final String? value;

  ObjectCustomContextPayload(this.createTime, this.updateTime, this.value);
}

// https://docs.cloud.google.com/storage/docs/json_api/v1/objects#resource
final class ObjectMetadata {
  final List<ObjectAccessControl>? acl;
  final String? bucket;
  final String? cacheControl;
  final int? componentCount;
  final String? contentDisposition;
  final String? contentEncoding;
  final String? contentLanguage;
  final String? contentType;

  /// Contexts attached to an object, in key-value pairs.
  ///
  /// For more information about object contexts, see
  /// [Object contexts overview](https://cloud.google.com/storage/docs/object-contexts).
  final ObjectContexts? contexts;

  final String? crc32c;
  final Timestamp? customTime;
  final CustomerEncryption? customerEncryption;
  final String? etag;
  final bool? eventBasedHold;
  final int? generation;
  final Timestamp? hardDeleteTime;
  final String? id;
  final String? kind;
  final String? kmsKeyName;
  final String? md5Hash;
  final Uri? mediaLink;
  final Map<String, String>? metadata;
  final int? metageneration;
  final String? name;
  final Owner? owner;
  final String? restoreToken;

  /// The object's [retention configuration](https://docs.cloud.google.com/storage/docs/object-lock).
  ///
  /// This defines the earliest datetime that the object can be deleted or
  /// replaced.
  final ObjectRetention? retention;
  final Timestamp? retentionExpirationTime;
  final Uri? selfLink;
  final int? size;
  final Timestamp? softDeleteTime;
  final String? storageClass;
  final bool? temporaryHold;
  final Timestamp? timeCreated;
  final Timestamp? timeDeleted;
  final Timestamp? timeStorageClassUpdated;
  final Timestamp? updated;

  ObjectMetadata({
    this.acl,
    this.bucket,
    this.cacheControl,
    this.componentCount,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    this.contexts,
    this.crc32c,
    this.customerEncryption,
    this.customTime,
    this.etag,
    this.eventBasedHold,
    this.generation,
    this.hardDeleteTime,
    this.id,
    this.kind,
    this.kmsKeyName,
    this.md5Hash,
    this.mediaLink,
    this.metadata,
    this.metageneration,
    this.name,
    this.owner,
    this.restoreToken,
    this.retention,
    this.retentionExpirationTime,
    this.selfLink,
    this.size,
    this.softDeleteTime,
    this.storageClass,
    this.temporaryHold,
    this.timeCreated,
    this.timeDeleted,
    this.timeStorageClassUpdated,
    this.updated,
  });

  @override
  String toString() =>
      'ObjectMetadata(acl: $acl, bucket: $bucket, cacheControl: $cacheControl, '
      'componentCount: $componentCount, '
      'contentDisposition: $contentDisposition, '
      'contentEncoding: $contentEncoding, contentLanguage: $contentLanguage, '
      'contentType: $contentType, contexts: $contexts, crc32c: $crc32c, '
      'customerEncryption: $customerEncryption, customTime: $customTime, '
      'etag: $etag, eventBasedHold: $eventBasedHold, generation: $generation, '
      'hardDeleteTime: $hardDeleteTime, id: $id, kind: $kind, '
      'kmsKeyName: $kmsKeyName, md5Hash: $md5Hash, mediaLink: $mediaLink, '
      'metadata: $metadata, metageneration: $metageneration, name: $name, '
      'owner: $owner, restoreToken: $restoreToken, retention: $retention, '
      'retentionExpirationTime: $retentionExpirationTime, selfLink: $selfLink, '
      'size: $size, softDeleteTime: $softDeleteTime, '
      'storageClass: $storageClass, temporaryHold: $temporaryHold, '
      'timeCreated: $timeCreated, timeDeleted: $timeDeleted, '
      'timeStorageClassUpdated: $timeStorageClassUpdated, updated: $updated)';

  @override
  int get hashCode => [
    acl,
    bucket,
    cacheControl,
    componentCount,
    contentDisposition,
    contentEncoding,
    contentLanguage,
    contentType,
    contexts,
    crc32c,
    customerEncryption,
    customTime,
    etag,
    eventBasedHold,
    generation,
    hardDeleteTime,
    id,
    kind,
    kmsKeyName,
    md5Hash,
    mediaLink,
    metadata,
    metageneration,
    name,
    owner,
    restoreToken,
    retention,
    retentionExpirationTime,
    selfLink,
    size,
    softDeleteTime,
    storageClass,
    temporaryHold,
    timeCreated,
    timeDeleted,
    timeStorageClassUpdated,
    updated,
  ].hashCode;

  @override
  bool operator ==(Object other) =>
      other is ObjectMetadata &&
      const DeepCollectionEquality().equals(other.acl, acl) &&
      other.bucket == bucket &&
      other.cacheControl == cacheControl &&
      other.componentCount == componentCount &&
      other.contentDisposition == contentDisposition &&
      other.contentEncoding == contentEncoding &&
      other.contentLanguage == contentLanguage &&
      other.contentType == contentType &&
      other.contexts == contexts &&
      other.crc32c == crc32c &&
      other.customerEncryption == customerEncryption &&
      other.customTime == customTime &&
      other.etag == etag &&
      other.eventBasedHold == eventBasedHold &&
      other.generation == generation &&
      other.hardDeleteTime == hardDeleteTime &&
      other.id == id &&
      other.kind == kind &&
      other.kmsKeyName == kmsKeyName &&
      other.md5Hash == md5Hash &&
      other.mediaLink == mediaLink &&
      const DeepCollectionEquality().equals(other.metadata, metadata) &&
      other.metageneration == metageneration &&
      other.name == name &&
      other.owner == owner &&
      other.restoreToken == restoreToken &&
      other.retention == retention &&
      other.retentionExpirationTime == retentionExpirationTime &&
      other.selfLink == selfLink &&
      other.size == size &&
      other.softDeleteTime == softDeleteTime &&
      other.storageClass == storageClass &&
      other.temporaryHold == temporaryHold &&
      other.timeCreated == timeCreated &&
      other.timeDeleted == timeDeleted &&
      other.timeStorageClassUpdated == timeStorageClassUpdated &&
      other.updated == updated;

  /// Creates a new [ObjectMetadata] with the given non-`null` fields replaced.
  /// Creates a new [ObjectMetadata] with the given non-`null` fields replaced.
  ObjectMetadata copyWith({
    List<ObjectAccessControl>? acl,
    String? bucket,
    String? cacheControl,
    int? componentCount,
    String? contentDisposition,
    String? contentEncoding,
    String? contentLanguage,
    String? contentType,
    ObjectContexts? contexts,
    String? crc32c,
    CustomerEncryption? customerEncryption,
    Timestamp? customTime,
    String? etag,
    bool? eventBasedHold,
    int? generation,
    Timestamp? hardDeleteTime,
    String? id,
    String? kind,
    String? kmsKeyName,
    String? md5Hash,
    Uri? mediaLink,
    Map<String, String>? metadata,
    int? metageneration,
    String? name,
    Owner? owner,
    String? restoreToken,
    ObjectRetention? retention,
    Timestamp? retentionExpirationTime,
    Uri? selfLink,
    int? size,
    Timestamp? softDeleteTime,
    String? storageClass,
    bool? temporaryHold,
    Timestamp? timeCreated,
    Timestamp? timeDeleted,
    Timestamp? timeStorageClassUpdated,
    Timestamp? updated,
  }) => ObjectMetadata(
    acl: acl ?? this.acl,
    bucket: bucket ?? this.bucket,
    cacheControl: cacheControl ?? this.cacheControl,
    componentCount: componentCount ?? this.componentCount,
    contentDisposition: contentDisposition ?? this.contentDisposition,
    contentEncoding: contentEncoding ?? this.contentEncoding,
    contentLanguage: contentLanguage ?? this.contentLanguage,
    contentType: contentType ?? this.contentType,
    contexts: contexts ?? this.contexts,
    crc32c: crc32c ?? this.crc32c,
    customerEncryption: customerEncryption ?? this.customerEncryption,
    customTime: customTime ?? this.customTime,
    etag: etag ?? this.etag,
    eventBasedHold: eventBasedHold ?? this.eventBasedHold,
    generation: generation ?? this.generation,
    hardDeleteTime: hardDeleteTime ?? this.hardDeleteTime,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    kmsKeyName: kmsKeyName ?? this.kmsKeyName,
    md5Hash: md5Hash ?? this.md5Hash,
    mediaLink: mediaLink ?? this.mediaLink,
    metadata: metadata ?? this.metadata,
    metageneration: metageneration ?? this.metageneration,
    name: name ?? this.name,
    owner: owner ?? this.owner,
    restoreToken: restoreToken ?? this.restoreToken,
    retention: retention ?? this.retention,
    retentionExpirationTime:
        retentionExpirationTime ?? this.retentionExpirationTime,
    selfLink: selfLink ?? this.selfLink,
    size: size ?? this.size,
    softDeleteTime: softDeleteTime ?? this.softDeleteTime,
    storageClass: storageClass ?? this.storageClass,
    temporaryHold: temporaryHold ?? this.temporaryHold,
    timeCreated: timeCreated ?? this.timeCreated,
    timeDeleted: timeDeleted ?? this.timeDeleted,
    timeStorageClassUpdated:
        timeStorageClassUpdated ?? this.timeStorageClassUpdated,
    updated: updated ?? this.updated,
  );

  /// Creates a new [ObjectMetadata] with the given fields set to `null`.
  ObjectMetadata copyWithout({
    bool acl = false,
    bool bucket = false,
    bool cacheControl = false,
    bool componentCount = false,
    bool contentDisposition = false,
    bool contentEncoding = false,
    bool contentLanguage = false,
    bool contentType = false,
    bool contexts = false,
    bool crc32c = false,
    bool customerEncryption = false,
    bool customTime = false,
    bool etag = false,
    bool eventBasedHold = false,
    bool generation = false,
    bool hardDeleteTime = false,
    bool id = false,
    bool kind = false,
    bool kmsKeyName = false,
    bool md5Hash = false,
    bool mediaLink = false,
    bool metadata = false,
    bool metageneration = false,
    bool name = false,
    bool owner = false,
    bool restoreToken = false,
    bool retention = false,
    bool retentionExpirationTime = false,
    bool selfLink = false,
    bool size = false,
    bool softDeleteTime = false,
    bool storageClass = false,
    bool temporaryHold = false,
    bool timeCreated = false,
    bool timeDeleted = false,
    bool timeStorageClassUpdated = false,
    bool updated = false,
  }) => ObjectMetadata(
    acl: acl ? null : this.acl,
    bucket: bucket ? null : this.bucket,
    cacheControl: cacheControl ? null : this.cacheControl,
    componentCount: componentCount ? null : this.componentCount,
    contentDisposition: contentDisposition ? null : this.contentDisposition,
    contentEncoding: contentEncoding ? null : this.contentEncoding,
    contentLanguage: contentLanguage ? null : this.contentLanguage,
    contentType: contentType ? null : this.contentType,
    contexts: contexts ? null : this.contexts,
    crc32c: crc32c ? null : this.crc32c,
    customerEncryption: customerEncryption ? null : this.customerEncryption,
    customTime: customTime ? null : this.customTime,
    etag: etag ? null : this.etag,
    eventBasedHold: eventBasedHold ? null : this.eventBasedHold,
    generation: generation ? null : this.generation,
    hardDeleteTime: hardDeleteTime ? null : this.hardDeleteTime,
    id: id ? null : this.id,
    kind: kind ? null : this.kind,
    kmsKeyName: kmsKeyName ? null : this.kmsKeyName,
    md5Hash: md5Hash ? null : this.md5Hash,
    mediaLink: mediaLink ? null : this.mediaLink,
    metadata: metadata ? null : this.metadata,
    metageneration: metageneration ? null : this.metageneration,
    name: name ? null : this.name,
    owner: owner ? null : this.owner,
    restoreToken: restoreToken ? null : this.restoreToken,
    retention: retention ? null : this.retention,
    retentionExpirationTime: retentionExpirationTime
        ? null
        : this.retentionExpirationTime,
    selfLink: selfLink ? null : this.selfLink,
    size: size ? null : this.size,
    softDeleteTime: softDeleteTime ? null : this.softDeleteTime,
    storageClass: storageClass ? null : this.storageClass,
    temporaryHold: temporaryHold ? null : this.temporaryHold,
    timeCreated: timeCreated ? null : this.timeCreated,
    timeDeleted: timeDeleted ? null : this.timeDeleted,
    timeStorageClassUpdated: timeStorageClassUpdated
        ? null
        : this.timeStorageClassUpdated,
    updated: updated ? null : this.updated,
  );
}
