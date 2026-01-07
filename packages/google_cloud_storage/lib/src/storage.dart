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

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'bucket.dart' as bucket;
import 'retry.dart';

final class StorageService {
  static const _host = 'storage.googleapis.com';

  final http.Client client;

  StorageService(this.client);

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

  Future<Bucket> createBucket({
    required String bucketName,
    String? project,
    Retry retry = defaultRetry,
  }) async {
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

  void close() {
    client.close();
  }
}
