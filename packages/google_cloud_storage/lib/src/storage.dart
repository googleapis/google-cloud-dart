// Copyright 2025 Google LLC
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

part of '../google_cloud_storage.dart';

// https://github.com/googleapis/googleapis/blob/211d22fa6dfabfa52cbda04d1aee852a01301edf/google/storage/v2/storage.proto
// https://github.com/invertase/dart_firebase_admin/tree/googleapis-storage/packages/googleapis_storage

// Get project is not provided - Python does the same but not Java.

// Discovery service or proto?
// How to run retry conformance tests?

final class StorageService {
  static const _host = 'storage.googleapis.com';

  final storage_v1.StorageApi storageApi;

  StorageService(this.storageApi);

  Future<bool> bucketExists(
    String bucketName, {
    Retry retry = defaultRetry,
  }) async {
    final url = Uri.https(_host, 'storage/v1/b/$bucketName');
    try {
      await retry.run(() => client.head(url));
      return true;
    } on NotFoundException {
      return false;
    }
  }

  Future<Bucket> createBucket({required String bucketName}) async {
    final bucket = storageApi.buckets.insert(
      storage_v1.Bucket(name: bucketName),
      'projects/$projectId',
    );
    final query = {if (project != null) 'project': project};

    final url = Uri.https(_host, 'storage/v1/b', query);
    final response = await retry.run(
      () => client.post(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'name': bucketName}),
      ),
    );
    return bucket.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
      this,
    );
  }

  Future<void> deleteBucket({
    required String bucketName,
    String? project,
    Retry retry = defaultRetry,
  }) async {
    final url = Uri.https(_host, 'storage/v1/b/$bucketName');
    await retry.run(() => client.delete(url));
  }

  Future<List<Bucket>> getBuckets({
    String? project,
    Retry retry = defaultRetry,
  }) async {
    final query = {if (project != null) 'project': project};

    final url = Uri.https(_host, 'storage/v1/b', query);
    final response = await retry.run(() => client.get(url));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (json['items'] as List<dynamic>)
        .map((e) => bucket.fromJson(e as Map<String, dynamic>, this))
        .toList();
  }

  void close() {
    client.close();
  }
}
