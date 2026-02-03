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

import 'dart:convert';

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'bucket_metadata_json.dart';

Future<T> _translateException<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on storage.DetailedApiRequestError catch (e) {
    final responseBody = jsonEncode(e.jsonResponse);
    final response = http.Response(
      responseBody,
      e.status!,
      headers: {'content-type': 'application/json'},
    );
    throw ServiceException.fromHttpResponse(response, responseBody);
  }
}

class Foo implements JsonEncodable {
  final Object json;

  Foo(this.json);

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

  Future<BucketMetadata> c(BucketMetadata metadata) async {
    final url = Uri.parse('https://storage.googleapis.com/storage/v1/b');
    final queryParams = {
      'project': [projectId],
    };

    final j = await _client.post(
      url.replace(queryParameters: queryParams),
      body: Foo(bucketMetadataToJson(metadata)),
    );
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }

  /// Create a new Google Cloud Storage bucket.
  ///
  /// This operation is always idempotent. Throws [ConflictException] if the
  /// bucket already exists.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/insert).
  Future<BucketMetadata> createBucket(
    BucketMetadata metadata, {
    RetryRunner retry = defaultRetry,
  }) async => await retry.run(() => c(metadata));

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
