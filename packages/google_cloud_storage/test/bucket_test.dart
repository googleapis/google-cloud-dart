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

@TestOn('vm')
library;

import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

const bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

String uniqueBucketName() => List.generate(
  32,
  (index) => bucketChars[Random().nextInt(bucketChars.length)],
).join();

void main() async {
  late StorageService storageService;
  late TestHttpClient testClient;

  group('bucket', () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/devstorage.read_write',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      storageService = StorageService(client: testClient);
    });

    tearDown(() => storageService.close());
    test('create', () async {
      await testClient.startTest('google_cloud_storage', 'bucket_create');

      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'dart-cloud-storage-test-bucket1'
          : uniqueBucketName();

      final bucket = await storageService.createBucket(
        bucketName: bucketName,
        project: projectId,
      );
      expect(bucket.name, bucketName);
      await testClient.endTest();
    });
  });
}
