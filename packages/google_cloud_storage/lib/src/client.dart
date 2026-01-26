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

import 'package:googleapis/storage/v1.dart' as storage;

import '../google_cloud_storage.dart';
import 'googleapis_converters.dart';

/// API for storing and retrieving potentially large, immutable data objects.
///
/// See [Google Cloud Storage](https://cloud.google.com/storage).
final class Storage {
  final storage.StorageApi _api;

  Storage(this._api);

  Future<BucketMetadata> bucketMetadata(
    String bucket, {
    BucketMetadata? metadata,
  }) async {
    if (metadata != null) {
      return fromBucket(await _api.buckets.patch(toBucket(metadata), bucket));
    }
    return fromBucket(await _api.buckets.get(bucket));
  }

  /// Information about a [Google Cloud Storage object].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  Future<ObjectMetadata> objectMetadata(String bucket, String object) async =>
      throw UnimplementedError('objectMetadata');
}
