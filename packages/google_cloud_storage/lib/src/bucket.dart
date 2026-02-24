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

@internal
Bucket newBucket(Storage storage, String name) => Bucket._(storage, name);

/// A [Google Cloud Storage bucket].
///
/// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
final class Bucket {
  final Storage storage;
  final String name;

  Bucket._(this.storage, this.name);

  /// Create a new Google Cloud Storage bucket.
  ///
  /// This operation is always idempotent. Throws [ConflictException] if the
  /// bucket already exists.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/insert).
  Future<BucketMetadata> create({
    BucketMetadata? metadata,
    bool enableObjectRetention = false,
    RetryRunner retry = defaultRetry,
  }) => storage.createBucket(
    metadata ?? BucketMetadata(name: name),
    enableObjectRetention: enableObjectRetention,
    retry: retry,
  );
}
