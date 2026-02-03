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
import 'package:google_cloud_rpc/service_client.dart';
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'bucket_metadata_json.dart';

class _JsonEncodableWrapper implements JsonEncodable {
  final Object json;

  _JsonEncodableWrapper(this.json);

  @override
  Object? toJson() => json;
}

/// API for storing and retrieving potentially large, immutable data objects.
///
/// See [Google Cloud Storage](https://cloud.google.com/storage).
final class Storage {
  final ServiceClient _client;
  final String projectId;

  Storage({required http.Client client, required this.projectId})
    : _client = ServiceClient(client: client);

  /// Create a new Google Cloud Storage bucket.
  ///
  /// This operation is always idempotent. Throws [ConflictException] if the
  /// bucket already exists.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/insert).
  Future<BucketMetadata> createBucket(
    BucketMetadata metadata, {
    RetryRunner retry = defaultRetry,
  }) async => await retry.run(() async {
    final url = Uri.https('storage.googleapis.com', '/storage/v1/b');
    final queryParams = {'project': projectId};

    final j = await _client.post(
      url.replace(queryParameters: queryParams),
      body: _JsonEncodableWrapper(bucketMetadataToJson(metadata)),
    );
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: true);

  /// Update a Google Cloud Storage bucket.
  ///
  /// If set, `ifMetagenerationMatch` makes updating the bucket metadata
  /// conditional on whether the bucket's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// bucket, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
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
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/patch).
  ///
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<BucketMetadata> patchBucket(
    String bucketName,
    BucketMetadata metadata, {
    int? ifMetagenerationMatch,
    // TODO(https://github.com/googleapis/google-cloud-dart/issues/115):
    // support ifMetagenerationNotMatch.
    //
    // If `ifMetagenerationNotMatch` is set, the server will respond with a 304
    // status code and an empty body. This will cause `buckets.patch` to throw
    // `TypeError` during JSON deserialization.
    String? predefinedAcl,
    String? predefinedDefaultObjectAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) async => await retry.run(() async {
    final url = Uri(
      scheme: 'https',
      host: 'storage.googleapis.com',
      pathSegments: ['storage', 'v1', 'b', bucketName],
    );
    final queryParams = {
      'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
      'project': projectId,
      'predefinedAcl': ?predefinedAcl,
      'predefinedDefaultObjectAcl': ?predefinedDefaultObjectAcl,
      'projection': ?projection,
      'userProject': ?userProject,
    };
    final j = await _client.patch(
      url.replace(queryParameters: queryParams),
      body: _JsonEncodableWrapper(bucketMetadataToJson(metadata)),
    );
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: ifMetagenerationMatch != null);

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
