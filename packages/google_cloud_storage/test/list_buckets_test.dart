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

import 'dart:io';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  if (Platform.environment['GOOGLE_CLOUD_PROJECT'] == null) {
    test('skip', () {}, skip: 'Requires GOOGLE_CLOUD_PROJECT');
    return;
  }

  late Storage storage;
  late http.Client client;

  group('list buckets', () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/devstorage.read_write',
            ],
          );

      client = await authClient();
      storage = Storage(client: client, projectId: projectId);
    });

    tearDown(() => storage.close());

    test('no buckets', () async {
      expect(storage.listBuckets(prefix: 'nobuckethasthisprefix'), emitsDone);
    });

    test('single bucket', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'list_buckets_single_bucket',
      );

      await expectLater(
        storage.listBuckets(prefix: bucketName).map((b) => b.name),
        emitsInOrder([emits(bucketName), emitsDone]),
      );
    });

    test('soft deleted bucket', () async {
      final prefix = testBucketName('list_soft_deleted_bucket');
      final softDeletedBucket = await storage.createBucket(
        BucketMetadata(
          name: '${prefix}_soft',
          softDeletePolicy: BucketSoftDeletePolicy(
            retentionDurationSeconds: const Duration(days: 7).inSeconds,
          ),
        ),
      );
      await storage.deleteBucket(softDeletedBucket.name!);

      final nonSoftDeletedBucket = await storage.createBucket(
        BucketMetadata(name: '${prefix}_no_soft'),
      );
      addTearDown(() => storage.deleteBucket(nonSoftDeletedBucket.name!));

      await expectLater(
        storage
            .listBuckets(prefix: prefix, softDeleted: true)
            .map((b) => b.name),
        emitsInOrder([emits(softDeletedBucket.name), emitsDone]),
      );
    });

    test('pagination', () async {
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
