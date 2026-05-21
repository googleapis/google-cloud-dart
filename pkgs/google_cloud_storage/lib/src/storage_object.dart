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

import 'dart:typed_data';

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:meta/meta.dart';

import 'bucket.dart';
import 'bucket_metadata.dart';
import 'client.dart';
import 'object_metadata.dart';
import 'object_metadata_patch_builder.dart';
import 'retry.dart';

@internal
StorageObject newObject(Storage storage, String bucketName, String name) =>
    StorageObject._(storage, bucketName, name);

/// A [Google Cloud Storage object][].
///
/// [StorageObject] instances are created with [Bucket.object].
///
/// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
final class StorageObject {
  final Storage storage;
  final String bucketName;
  final String name;

  StorageObject._(this.storage, this.bucketName, this.name);

  /// Deletes this [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `generation` or `ifGenerationMatch` is
  /// set.
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If set, `generation` selects a specific revision of this object (as
  /// opposed to the latest version) to delete.
  ///
  /// If set, `ifGenerationMatch` makes the operation conditional on whether the
  /// object's current generation matches the given value. If the generation
  /// does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, `ifMetagenerationMatch` makes the operation conditional on whether
  /// the object's current metageneration matches the given value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/delete).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  Future<void> delete({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    RetryRunner retry = defaultRetry,
  }) => storage.deleteObject(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    retry: retry,
  );

  /// Download the content of this [Google Cloud Storage object][] as bytes.
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// If non-null, [generation] downloads a specific version of the object
  /// instead of the latest version.
  ///
  /// If non-null, [ifGenerationMatch] makes retrieving the object's data
  /// conditional on whether the object's generation matches the provided
  /// value. If the generation does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the object's data
  /// conditional on whether the object's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/get).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<Uint8List> download({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.downloadObject(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    userProject: userProject,
    retry: retry,
  );

  /// Grant read access to this [Google Cloud Storage object] for anonymous
  /// users.
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  Future<void> makePublic({RetryRunner retry = defaultRetry}) =>
      storage.makeObjectPublic(bucketName, name, retry: retry);

  /// Updates the metadata associated with this [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if [ifMetagenerationMatch] is set.
  ///
  /// If set, [generation] selects a specific revision of this object (as
  /// opposed to the latest version) to patch.
  ///
  /// If set, [ifGenerationMatch] makes the operation conditional on whether the
  /// object's current generation matches the given value. If the generation
  /// does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, [ifMetagenerationMatch] makes the operation conditional on whether
  /// the object's current metageneration matches the given value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, [predefinedAcl] applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting [predefinedAcl] will result in a
  /// [BadRequestException].
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/patch).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> patch(
    ObjectMetadataPatchBuilder metadata, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.patchObject(
    bucketName,
    name,
    metadata,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    predefinedAcl: predefinedAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  /// Information about this [Google Cloud Storage object][].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If non-null, [generation] returns a specific version of the object
  /// instead of the latest version.
  ///
  /// If non-null, [ifGenerationMatch] makes retrieving the object metadata
  /// conditional on whether the object's generation matches the provided
  /// value. If the generation does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the object metadata
  /// conditional on whether the object's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/get).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> metadata({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.objectMetadata(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  /// Moves this [Google Cloud Storage object][] to a new [newName].
  ///
  /// This operation is atomic and idempotent if [ifSourceGenerationMatch] or
  /// [ifGenerationMatch] is set (using both is recommended for maximum safety).
  /// https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency-operations
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If set, [ifSourceGenerationMatch] makes the operation conditional on
  /// whether the source object's current generation matches the given value.
  ///
  /// If set, [ifGenerationMatch] makes the operation conditional on whether
  /// the destination object's current generation matches the given value.
  /// A value of `BigInt.zero` indicates that the destination object must not
  /// already exist.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/move).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> move(
    String newName, {
    BigInt? ifSourceGenerationMatch,
    BigInt? ifGenerationMatch,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.moveObject(
    bucketName,
    name,
    newName,
    ifSourceGenerationMatch: ifSourceGenerationMatch,
    ifGenerationMatch: ifGenerationMatch,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  /// Creates or updates the content of this [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// `metadata.name` does not match [name], a [BadRequestException] is thrown.
  ///
  /// If set, `ifGenerationMatch` makes updating the object content conditional
  /// on whether the object's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of `0` indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/insert).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> upload(
    List<int> content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.uploadObject(
    bucketName,
    name,
    content,
    metadata: metadata,
    ifGenerationMatch: ifGenerationMatch,
    predefinedAcl: predefinedAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  /// Creates or updates the content of a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// [metadata] is `null` or `metadata.contentType` is `null`, the content type
  /// will be `'text/plain'`. If `metadata.name` does not match [name], a
  /// [BadRequestException] is thrown.
  ///
  /// If set, `ifGenerationMatch` makes updating the object content conditional
  /// on whether the object's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of `0` indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/insert).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> uploadAsString(
    String content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.uploadObjectFromString(
    bucketName,
    name,
    content,
    metadata: metadata,
    ifGenerationMatch: ifGenerationMatch,
    predefinedAcl: predefinedAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );
}
