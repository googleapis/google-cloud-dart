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

@TestOn('vm')
library;

import 'dart:convert';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;
  late TestHttpClient testClient;

  group('list objects', () {
    setUp(() async {
      fixedBoundaryString = 'boundary';
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/devstorage.read_write',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      storage = Storage(client: testClient, projectId: projectId);
    });

    tearDown(() => storage.close());

    test('no objects', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_no_objects',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'list_objects_no_objects',
      );
      expect(storage.listObjects(bucketName), emitsDone);
    });

    test('single object', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_single_object',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'list_objects_single_object',
      );

      await storage.insertObject(
        bucketName,
        'object1.txt',
        utf8.encode('content1'),
        ifGenerationMatch: BigInt.zero,
      );

      await expectLater(
        storage.listObjects(bucketName).map((o) => o.name),
        emitsInOrder([emits('object1.txt'), emitsDone]),
      );
    });

    test('soft deleted bucket, list soft deleted objects', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_soft_deleted_bucket_soft',
      );
      addTearDown(testClient.endTest);

      final softDeletedBucket = await createBucketWithTearDown(
        storage,
        'list_objects_soft_deleted_bucket_soft',
        metadata: BucketMetadata(
          softDeletePolicy: BucketSoftDeletePolicy(
            retentionDurationSeconds: const Duration(days: 7).inSeconds,
          ),
        ),
      );

      await storage.insertObject(softDeletedBucket, 'object1.txt', [0]);
      await storage.deleteObject(softDeletedBucket, 'object1.txt');
      await storage.insertObject(softDeletedBucket, 'object2.txt', [1]);

      await expectLater(
        storage
            .listObjects(softDeletedBucket, softDeleted: true)
            .map((b) => b.name),
        emitsInOrder([emits('object1.txt'), emitsDone]),
      );
    });

    test('soft deleted bucket, list non-soft deleted objects', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_soft_deleted_bucket_no_soft',
      );
      addTearDown(testClient.endTest);

      final softDeletedBucket = await createBucketWithTearDown(
        storage,
        'list_objects_soft_deleted_bucket_no_soft',
        metadata: BucketMetadata(
          softDeletePolicy: BucketSoftDeletePolicy(
            retentionDurationSeconds: const Duration(days: 7).inSeconds,
          ),
        ),
      );

      await storage.insertObject(softDeletedBucket, 'object1.txt', [0]);
      await storage.deleteObject(softDeletedBucket, 'object1.txt');
      await storage.insertObject(softDeletedBucket, 'object2.txt', [1]);

      await expectLater(
        storage
            .listObjects(softDeletedBucket, softDeleted: false)
            .map((b) => b.name),
        emitsInOrder([emits('object2.txt'), emitsDone]),
      );
    });

    test('pagination', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_pagination',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'list_objects_pagination',
      );

      await storage.insertObject(bucketName, 'object1.txt', [1]);
      await storage.insertObject(bucketName, 'object2.txt', [2]);
      await storage.insertObject(bucketName, 'object3.txt', [3]);
      await storage.insertObject(bucketName, 'object4.txt', [4]);
      await storage.insertObject(bucketName, 'object5.txt', [5]);

      await expectLater(
        storage.listObjects(bucketName, maxResults: 2).map((b) => b.name),
        emitsInOrder([
          emits('object1.txt'),
          emits('object2.txt'),
          emits('object3.txt'),
          emits('object4.txt'),
          emits('object5.txt'),
          emitsDone,
        ]),
      );
    });
  });
}
