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

import 'package:meta/meta.dart';

import '../google_cloud_storage.dart';
import 'blob.dart' show newBlob;

@internal
Bucket newBucket(Storage storage, String name) => Bucket._(storage, name);

/// A [Google Cloud Storage bucket].
///
/// [Bucket] instances are created with [Storage.bucket].
///
/// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
final class Bucket {
  final Storage storage;
  final String name;

  Bucket._(this.storage, this.name);

  /// A [Google Cloud Storage object][] with the given [name].
  ///
  /// [name] should be a valid [object name][].
  ///
  /// The object need not actually exist on Google Cloud Storage. This method
  /// does not perform any network operations.
  ///
  /// [object name]: https://docs.cloud.google.com/storage/docs/objects#naming
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  Blob blob(String name) => newBlob(storage, this.name, name);

  /// Create a new [Google Cloud Storage bucket][].
  ///
  /// If [metadata] is provided, it's [BucketMetadata.name] is ignored and
  /// [name] is used instead.
  ///
  /// This operation is always idempotent. Throws [ConflictException] if the
  /// bucket already exists.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/insert).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketMetadata> create({
    BucketMetadata? metadata,
    bool enableObjectRetention = false,
    RetryRunner retry = defaultRetry,
  }) => storage.createBucket(
    metadata?.copyWith(name: name) ?? BucketMetadata(name: name),
    enableObjectRetention: enableObjectRetention,
    retry: retry,
  );

  /// Deletes this already-empty [Google Cloud Storage bucket][].
  ///
  /// This operation is idempotent if `ifMetagenerationMatch` is set.
  ///
  /// Throws [NotFoundException] if the bucket does not exist. Throws
  /// [ConflictException] if the bucket is not empty.
  ///
  /// If set, `ifMetagenerationMatch` makes deleting the bucket conditional on
  /// whether the bucket's metageneration matches the provided value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/delete).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<void> delete({
    BigInt? ifMetagenerationMatch,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.deleteBucket(
    name,
    ifMetagenerationMatch: ifMetagenerationMatch,
    userProject: userProject,
    retry: retry,
  );

  /// Information about this [Google Cloud Storage bucket][].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the bucket does not exist.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the bucket metadata
  /// conditional on whether the bucket's metageneration matches the provided
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
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/get).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<BucketMetadata> metadata({
    BigInt? ifMetagenerationMatch,
    String? userProject,
    String? projection,
    RetryRunner retry = defaultRetry,
  }) => storage.bucketMetadata(
    name,
    ifMetagenerationMatch: ifMetagenerationMatch,
    userProject: userProject,
    projection: projection,
    retry: retry,
  );

  /// Update this [Google Cloud Storage bucket][].
  ///
  /// This operation is idempotent if [ifMetagenerationMatch] is set.
  ///
  /// If set, [ifMetagenerationMatch] makes updating the bucket metadata
  /// conditional on whether the bucket's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If set, [predefinedAcl] applies a predefined set of access controls to the
  /// bucket, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/patch).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<BucketMetadata> patch(
    BucketMetadataPatchBuilder metadata, {
    BigInt? ifMetagenerationMatch,
    String? predefinedAcl,
    String? predefinedDefaultObjectAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.patchBucket(
    name,
    metadata,
    ifMetagenerationMatch: ifMetagenerationMatch,
    predefinedAcl: predefinedAcl,
    predefinedDefaultObjectAcl: predefinedDefaultObjectAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );
}
