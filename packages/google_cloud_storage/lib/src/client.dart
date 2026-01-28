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
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'googleapis_converters.dart';

/// API for storing and retrieving potentially large, immutable data objects.
///
/// See [Google Cloud Storage](https://cloud.google.com/storage).
final class Storage {
  final storage.StorageApi _api;
  final String projectId;
  final http.Client _client;

  Storage({required http.Client client, required this.projectId})
    : _client = client,
      _api = storage.StorageApi(client);

  Future<BucketMetadata> createBucket(BucketMetadata metadata) async =>
      fromGoogleApisBucket(
        await _api.buckets.insert(toGoogleApisBucket(metadata), projectId),
      );

  /// Information about a [Google Cloud Storage object].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  Future<ObjectMetadata> objectMetadata(String bucket, String object) async =>
      throw UnimplementedError('objectMetadata');

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// Once [close] is called, no other methods should be called.
  void close() => _client.close();
}
