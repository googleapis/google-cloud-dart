import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../google_cloud_storage.dart';

@internal
Blob newBlob(Storage storage, String bucketName, String name) =>
    Blob._(storage, bucketName, name);

/// A [Google Cloud Storage object][].
///
/// [Blob] instances are created with [Bucket.blob].
///
/// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
final class Blob {
  final Storage storage;
  final String bucketName;
  final String name;

  Blob._(this.storage, this.bucketName, this.name);

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
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
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

  /// Creates or updates the content of this [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// `metadata.name` does not match [name], a [BadRequestException] is thrown.
  ///
  /// If set, `ifGenerationMatch` makes updating the object content conditional
  /// on whether the objects's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of `0` indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
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
  }) => storage.insertObject(
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
