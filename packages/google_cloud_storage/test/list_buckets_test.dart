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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

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

      expect(storage.listBuckets(prefix: 'nobuckethasthisprefix'), emitsDone);
    });

    test('single bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_single_bucket',
      );
      addTearDown(testClient.endTest);

      final bucketName = await createBucketWithTearDown(
        storage,
        'list_buckets_single_bucket',
      );

      await expectLater(
        storage.listBuckets(prefix: bucketName).map((b) => b.name),
        emitsInOrder([emits(bucketName), emitsDone]),
      );
    });

    test(
      'soft deleted bucket',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'list_buckets_soft_deleted_bucket',
        );
        addTearDown(testClient.endTest);

        final prefix = testBucketName('list_buckets_soft_deleted_bucket');
        final softDeletedBucket = await createBucketWithTearDown(
          storage,
          '${prefix}_soft',
          metadata: BucketMetadata(
            softDeletePolicy: BucketSoftDeletePolicy(
              retentionDurationSeconds: const Duration(days: 7).inSeconds,
            ),
          ),
        );
        await storage.deleteBucket(softDeletedBucket);

        await createBucketWithTearDown(storage, '${prefix}_no_soft');

        await expectLater(
          storage
              .listBuckets(prefix: prefix, softDeleted: true)
              .map((b) => b.name),
          emitsInOrder([emits(softDeletedBucket), emitsDone]),
        );
      },
      skip: TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'soft deleted buckets cannot be deleted before their retention '
                'period has expired, which makes it impossible to use fixed '
                'bucket names'
          : false,
    );

    test('pagination', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets_pagination',
      );
      addTearDown(testClient.endTest);

      final prefix = testBucketName('list_buckets_pagination');

      final bucket1 = await createBucketWithTearDown(storage, '${prefix}_1');
      final bucket2 = await createBucketWithTearDown(storage, '${prefix}_2');
      final bucket3 = await createBucketWithTearDown(storage, '${prefix}_3');
      final bucket4 = await createBucketWithTearDown(storage, '${prefix}_4');
      final bucket5 = await createBucketWithTearDown(storage, '${prefix}_5');

      await expectLater(
        storage.listBuckets(prefix: prefix, maxResults: 2).map((b) => b.name),
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
