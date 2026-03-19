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
import 'package:google_cloud_rpc/exceptions.dart';

import 'project_team.dart';

/// An Access Control List (ACL) for objects within Cloud Storage.
///
/// ACLs let you specify who has access to your data and to what extent.
///
/// [!IMPORTANT]
/// The methods that modify ACLs for this object will fail with
/// [BadRequestException] for buckets with uniform bucket-level access enabled.
/// Use `storage.buckets.getIamPolicy` and `storage.buckets.setIamPolicy` to
/// control access instead.
///
/// There are two roles that can be assigned to an object:
/// 1. `READER` can get an object, though the `acl` property will not be
///    revealed.
/// 2. `OWNER` are `READER`s, and they can get the `acl` property, update the
///    object's metadata, and call all [ObjectAccessControl]-related methods on
///    the object. The owner of an object is always an `OWNER`.
///
/// For more information, see [Access Control][], with the caveat that this API
/// uses `READER` and `OWNER` instead of `READ` and `FULL_CONTROL`.
///
/// See [ObjectAccessControls][].
///
/// [Access Control]: https://docs.cloud.google.com/storage/docs/access-control
/// [ObjectAccessControls]: https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls
final class ObjectAccessControl {
  /// The name of the bucket that the access control applies to.
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
  /// - `user-<email address>`
  /// - `group-<group id>`
  /// - `group-<email address>`
  /// - `domain-<domain>`
  /// - `project-team-<project id>`
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

  /// [HTTP 1.1 Entity tag][] for the access-control entry.
  ///
  /// [HTTP 1.1 Entity tag]: https://tools.ietf.org/html/rfc7232#section-2.3
  final String? etag;

  /// The content generation of the object.
  ///
  /// Used for [object versioning][] and [soft delete][].
  ///
  /// [object versioning]: https://docs.cloud.google.com/storage/docs/object-versioning
  /// [soft delete]: https://cloud.google.com/storage/docs/soft-delete
  final String? generation;

  /// The ID of this access-control entry.
  final String? id;

  /// The kind of item this is. For object access control entries, this is
  /// always `"storage#objectAccessControl"`.
  final String? kind;

  /// The name of the object, if applied to an object.
  final String? object;

  /// The project team associated with the entity, if any.
  final ProjectTeam? projectTeam;

  /// The access permission for the entity.
  ///
  /// Acceptable values are `"OWNER"` and `"READER"`.
  final String? role;

  /// The link to this access-control resource.
  final Uri? selfLink;

  ObjectAccessControl({
    this.bucket,
    this.domain,
    this.email,
    this.entity,
    this.entityId,
    this.etag,
    this.generation,
    this.id,
    this.kind,
    this.object,
    this.projectTeam,
    this.role,
    this.selfLink,
  });

  @override
  String toString() =>
      'ObjectAccessControl(bucket: $bucket, domain: $domain, email: $email, '
      'entity: $entity, entityId: $entityId, etag: $etag, '
      'generation: $generation, id: $id, kind: $kind, object: $object, '
      'projectTeam: $projectTeam, role: $role, selfLink: $selfLink)';

  /// Creates a new [ObjectAccessControl] with the given non-`null` fields
  /// replaced.
  ObjectAccessControl copyWith({
    String? bucket,
    String? domain,
    String? email,
    String? entity,
    String? entityId,
    String? etag,
    String? generation,
    String? id,
    String? kind,
    String? object,
    ProjectTeam? projectTeam,
    String? role,
    Uri? selfLink,
  }) => ObjectAccessControl(
    bucket: bucket ?? this.bucket,
    domain: domain ?? this.domain,
    email: email ?? this.email,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    etag: etag ?? this.etag,
    generation: generation ?? this.generation,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    object: object ?? this.object,
    projectTeam: projectTeam ?? this.projectTeam,
    role: role ?? this.role,
    selfLink: selfLink ?? this.selfLink,
  );

  /// Creates a new [ObjectAccessControl] with the given fields set to `null`.
  ObjectAccessControl copyWithout({
    bool bucket = false,
    bool domain = false,
    bool email = false,
    bool entity = false,
    bool entityId = false,
    bool etag = false,
    bool generation = false,
    bool id = false,
    bool kind = false,
    bool object = false,
    bool projectTeam = false,
    bool role = false,
    bool selfLink = false,
  }) => ObjectAccessControl(
    bucket: bucket ? null : this.bucket,
    domain: domain ? null : this.domain,
    email: email ? null : this.email,
    entity: entity ? null : this.entity,
    entityId: entityId ? null : this.entityId,
    etag: etag ? null : this.etag,
    generation: generation ? null : this.generation,
    id: id ? null : this.id,
    kind: kind ? null : this.kind,
    object: object ? null : this.object,
    projectTeam: projectTeam ? null : this.projectTeam,
    role: role ? null : this.role,
    selfLink: selfLink ? null : this.selfLink,
  );
}

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

/// The owner of an object.
///
/// This will always be the uploader of the object.
final class Owner {
  /// The entity, in the form user-userId.
  final String? entity;

  /// The ID for the entity.
  final String? entityId;

  Owner({this.entity, this.entityId});

  @override
  String toString() => 'Owner(entity: $entity, entityId: $entityId)';

  /// Creates a new [Owner] with the given non-`null` fields replaced.
  Owner copyWith({String? entity, String? entityId}) =>
      Owner(entity: entity ?? this.entity, entityId: entityId ?? this.entityId);

  /// Creates a new [Owner] with the given fields set to `null`.
  Owner copyWithout({bool entity = false, bool entityId = false}) => Owner(
    entity: entity ? null : this.entity,
    entityId: entityId ? null : this.entityId,
  );
}

/// An object's [retention configuration][].
///
/// This defines the earliest datetime that the object can be deleted or
/// replaced.
///
/// [retention configuration]: https://docs.cloud.google.com/storage/docs/object-lock
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
/// [Object contexts overview][].
///
/// [Object contexts overview]: https://cloud.google.com/storage/docs/object-contexts
class ObjectContexts {
  final Map<String, ObjectCustomContextPayload>? custom;

  ObjectContexts({this.custom});

  @override
  String toString() => 'ObjectContexts(custom: $custom)';

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

  ObjectCustomContextPayload({this.createTime, this.updateTime, this.value});
}

/// Information about a [Cloud Storage object][].
///
/// For detailed information on the meaning of each field, see
/// [Object resource][].
///
/// [Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
/// [Object resource]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects#resource
final class ObjectMetadata {
  /// Access controls on the object.
  ///
  /// Only requests that use the `projection=full` query parameter return this
  /// field in the response.
  ///
  /// If `iamConfiguration.uniformBucketLevelAccess.enabled` is set to true,
  /// this field does not apply, and requests that specify it fail.
  final List<ObjectAccessControl>? acl;

  /// The name of the bucket containing this object.
  final String? bucket;

  /// Cache-Control directive for the object data.
  ///
  /// If omitted, and the object is accessible to all anonymous users, the
  /// default will be `"public, max-age=3600"`.
  final String? cacheControl;

  /// Number of underlying components that make up this object. Components are
  /// accumulated by compose operations.
  final int? componentCount;

  /// Content-Disposition of the object data.
  final String? contentDisposition;

  /// [Content-Encoding][] of the object data.
  ///
  /// [Content-Encoding]: https://docs.cloud.google.com/storage/docs/metadata#content-encoding
  final String? contentEncoding;

  /// Content-Language of the object data.
  final String? contentLanguage;

  /// Content-Type of the object data. If an object is stored without a
  /// Content-Type, it is served as `application/octet-stream`.
  final String? contentType;

  /// Contexts attached to an object, in key-value pairs.
  ///
  /// For more information about object contexts, see
  /// [Object contexts overview][].
  ///
  /// [Object contexts overview]: https://cloud.google.com/storage/docs/object-contexts
  final ObjectContexts? contexts;

  /// CRC32c checksum, as described in RFC 4960, Appendix B; encoded using
  /// base64 in big-endian byte order.
  ///
  /// For more information about using the CRC32c checksum, see
  /// [Data Validation and Change Detection][].
  ///
  /// [Data Validation and Change Detection]: https://cloud.google.com/storage/docs/data-validation
  final String? crc32c;

  /// A timestamp specified by the user for an object.
  final Timestamp? customTime;

  /// Metadata of customer-supplied encryption key, if the object is encrypted
  /// by such a key.
  final CustomerEncryption? customerEncryption;

  /// HTTP 1.1 Entity tag for the object.
  final String? etag;

  /// Whether an object is under event-based hold.
  ///
  /// Event-based hold is a way to retain objects until an event occurs, which
  /// is signified by the hold's release (i.e. this value is set to false).
  ///
  /// After being released (set to false), such objects will be subject to
  /// bucket-level retention (if any).
  ///
  /// One sample use case of this flag is for banks to hold loan documents for
  /// at least 3 years after loan is paid in full. Here, bucket-level retention
  /// is 3 years and the event is the loan being paid in full. In this example,
  /// these objects will be held intact for any number of years until the event
  /// has occurred (event-based hold on the object is released) and then 3 more
  /// years after that. That means retention duration of the objects begins from
  /// the moment event-based hold transitioned from true to false.
  final bool? eventBasedHold;

  /// The content generation of this object. Used for object versioning.
  final BigInt? generation;

  /// This is the time (in the future) when the soft-deleted object will no
  /// longer be restorable.
  ///
  /// It is equal to the soft delete time plus the current soft delete retention
  /// duration of the bucket.
  final Timestamp? hardDeleteTime;

  /// The ID of the object, including the bucket name, object name, and
  /// generation number.
  final String? id;

  /// The kind of item this is. For objects, this is always storage#object.
  final String? kind;

  /// Not currently supported. Specifying the parameter causes the request to
  /// fail with status code 400 - Bad Request.
  final String? kmsKeyName;

  /// MD5 hash of the data; encoded using base64.
  ///
  /// For more information about using the MD5 hash, see
  /// [Data Validation and Change Detection][].
  ///
  /// [Data Validation and Change Detection]: https://cloud.google.com/storage/docs/data-validation
  final String? md5Hash;

  /// Media download link.
  final Uri? mediaLink;

  /// User-provided metadata, in key/value pairs.
  final Map<String, String>? metadata;

  /// The version of the metadata for this object at this generation.
  ///
  /// Used for preconditions and for detecting changes in metadata. A
  /// metageneration number is only meaningful in the context of a particular
  /// generation of a particular object.
  final BigInt? metageneration;

  /// The name of the object. Required if not specified by URL parameter.
  final String? name;

  /// The owner of the object. This will always be the uploader of the object.
  final Owner? owner;

  /// Restore token used to differentiate deleted objects with the same name and
  /// generation.
  ///
  /// This field is only returned for deleted objects in hierarchical namespace
  /// buckets.
  final String? restoreToken;

  /// The object's [retention configuration][].
  ///
  /// This defines the earliest datetime that the object can be deleted or
  /// replaced.
  ///
  /// [retention configuration]: https://docs.cloud.google.com/storage/docs/object-lock
  final ObjectRetention? retention;

  /// A server-determined value that specifies the earliest time that the
  /// object's retention period expires.
  ///
  /// Note 1: This field is not provided for objects with an active event-based
  /// hold, since retention expiration is unknown until the hold is removed.
  ///
  /// Note 2: This value can be provided even when temporary hold is set (so
  /// that the user can reason about policy without having to first unset the
  /// temporary hold).
  final Timestamp? retentionExpirationTime;

  /// The link to this object.
  final Uri? selfLink;

  /// Content-Length of the data in bytes.
  final BigInt? size;

  /// The time at which the object became soft-deleted.
  final Timestamp? softDeleteTime;

  /// Storage class of the object.
  final String? storageClass;

  /// Whether an object is under temporary hold.
  ///
  /// While this flag is set to true, the object is protected against deletion
  /// and overwrites. A common use case of this flag is regulatory
  /// investigations where objects need to be retained while the investigation
  /// is ongoing.
  ///
  /// Note that unlike event-based hold, temporary hold does not impact
  /// retention expiration time of an object.
  final bool? temporaryHold;

  /// The creation time of the object.
  final Timestamp? timeCreated;

  /// The time at which the object became noncurrent.
  ///
  /// Will be returned if and only if this version of the object has been
  /// deleted.
  final Timestamp? timeDeleted;

  /// The time at which the object's storage class was last changed.
  ///
  /// When the object is initially created, it will be set to timeCreated.
  final Timestamp? timeStorageClassUpdated;

  /// The modification time of the object metadata.
  ///
  /// Set initially to object creation time and then updated whenever any
  /// metadata of the object changes. This includes changes made by a requester,
  /// such as modifying custom metadata, as well as changes made by Cloud
  /// Storage on behalf of a requester, such as changing the storage class based
  /// on an Object Lifecycle Configuration.
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
    BigInt? generation,
    Timestamp? hardDeleteTime,
    String? id,
    String? kind,
    String? kmsKeyName,
    String? md5Hash,
    Uri? mediaLink,
    Map<String, String>? metadata,
    BigInt? metageneration,
    String? name,
    Owner? owner,
    String? restoreToken,
    ObjectRetention? retention,
    Timestamp? retentionExpirationTime,
    Uri? selfLink,
    BigInt? size,
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
