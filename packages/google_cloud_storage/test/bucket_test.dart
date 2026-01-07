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

String uniqueBucketName() {
  final random = Random();
  return List.generate(
    32,
    (index) => bucketChars[random.nextInt(bucketChars.length)],
  ).join();
}

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
      storageService = StorageService(testClient);
    });

    tearDown(() => storageService.close());

    test('create', () async {
      await testClient.startTest('google_cloud_storage', 'bucket_create');
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'dart-cloud-storage-test-bucket-create'
          : uniqueBucketName();

      final bucket = await storageService.createBucket(
        bucketName: bucketName,
        project: projectId,
      );
      addTearDown(bucket.delete);
      expect(bucket.name, bucketName);
      expect(
        bucket.selfLink,
        Uri.https('www.googleapis.com', 'storage/v1/b/$bucketName'),
      );
      expect(bucket.metaGeneration, 1);
      expect(bucket.location, 'US');
      expect(bucket.locationType, 'multi-region');
      expect(bucket.timeCreated, isNotNull);
    });

    test('create duplicate', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'bucket_create_duplicate',
      );
      addTearDown(testClient.endTest);

      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'dart-cloud-storage-test-bucket-create-dup'
          : uniqueBucketName();

      final bucket = await storageService.createBucket(
        bucketName: bucketName,
        project: projectId,
      );
      addTearDown(bucket.delete);
      expect(bucket.name, bucketName);

      // Verify that creating the same bucket again fails.
      await expectLater(
        storageService.createBucket(bucketName: bucketName, project: projectId),
        throwsA(isA<ConflictException>()),
      );
    });

    test('bucket exists', () async {
      await testClient.startTest('google_cloud_storage', 'bucket_exists');
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'dart-cloud-storage-test-bucket-exists'
          : uniqueBucketName();

      // Check that the bucket does not exist.
      expect(await storageService.bucketExists(bucketName), isFalse);

      final bucket = await storageService.createBucket(
        bucketName: bucketName,
        project: projectId,
      );
      addTearDown(bucket.delete);

      // Check that the bucket exists.
      expect(await storageService.bucketExists(bucketName), isTrue);
    });
  });
}
