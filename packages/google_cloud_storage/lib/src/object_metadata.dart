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

/// Metadata of customer-supplied encryption key, if the object is encrypted by
/// such a key.
final class CustomerEncryption {
  /// The encryption algorithm.
  final String encryptionAlgorithm;

  /// SHA256 hash value of the encryption key.
  final String keySha256;

  CustomerEncryption({
    required this.encryptionAlgorithm,
    required this.keySha256,
  });
}

/// The owner of the object. This will always be the uploader of the object
final class Owner {
  /// The entity, in the form user-userId.
  final String entity;

  /// The ID for the entity.
  final String? entityId;

  Owner({required this.entity, this.entityId});
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
}

/// Contexts attached to an object, in key-value pairs.
///
/// For more information about object contexts, see
/// [Object contexts overview](https://cloud.google.com/storage/docs/object-contexts).
class ObjectContexts {
  final Map<String, ObjectCustomContextPayload>? custom;

  ObjectContexts({this.custom});
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
}
