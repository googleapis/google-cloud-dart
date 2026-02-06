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

import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

const bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

String uniqueBucketName() {
  final random = Random();
  return [
    for (int i = 0; i < 32; i++)
      bucketChars[random.nextInt(bucketChars.length)],
  ].join();
}

void main() async {
  late Storage storage;
  late TestHttpClient testClient;

  group('list buckets', () {
    setUp(() async {
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

    test('no buckets', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_no_buckets',
      );
      addTearDown(testClient.endTest);

      final prefix = TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'list_buckets_no_buckets'
          : uniqueBucketName();

      expect(storage.listBuckets(prefix: prefix), emitsDone);
    });

    test('single bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_single_bucket',
      );
      addTearDown(testClient.endTest);

      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'list_buckets_single_bucket'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      expect(
        storage.listBuckets(prefix: bucketName).map((b) => b.name),
        emitsInOrder([emits(bucketName), emitsDone]),
      );
    });

    test('soft deleted bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_soft_deleted_bucket',
      );
      addTearDown(testClient.endTest);

      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'list_buckets_soft_deleted_bucket'
          : uniqueBucketName();

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          softDeletePolicy: BucketSoftDeletePolicy(
            retentionDurationSeconds: 60,
          ),
        ),
      );
      await storage.deleteBucket(bucketName);

      expect(
        storage
            .listBuckets(prefix: bucketName, softDeleted: true)
            .map((b) => b.name),
        emitsInOrder([emits(bucketName), emitsDone]),
      );
    });

    test('pagination', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_pagination',
      );
      addTearDown(testClient.endTest);

      final prefix = TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'list_buckets_pagination'
          : uniqueBucketName();

      final bucket1 = '${prefix}_1';
      final bucket2 = '${prefix}_2';
      final bucket3 = '${prefix}_3';
      final bucket4 = '${prefix}_4';
      final bucket5 = '${prefix}_5';

      await storage.createBucket(BucketMetadata(name: bucket1));
      await storage.createBucket(BucketMetadata(name: bucket2));
      await storage.createBucket(BucketMetadata(name: bucket3));
      await storage.createBucket(BucketMetadata(name: bucket4));
      await storage.createBucket(BucketMetadata(name: bucket5));

      expect(
        storage.listBuckets(prefix: prefix).map((b) => b.name),
        emitsInOrder([
          emits(bucket1),
          emits(bucket2),
          emits(bucket3),
          emits(bucket4),
          emits(bucket5),
          emitsDone,
        ]),
      );
    });
  });
}
