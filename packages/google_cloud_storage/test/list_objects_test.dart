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

    test('list objects', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_success',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'list_objects_success',
      );

      await storage.createBucket(BucketMetadata(name: bucketName));
      await storage.insertObject(
        bucketName,
        'object1.txt',
        utf8.encode('content1'),
        ifGenerationMatch: BigInt.zero,
      );
      await storage.insertObject(
        bucketName,
        'object2.txt',
        utf8.encode('content2'),
        ifGenerationMatch: BigInt.zero,
      );

      final objects = await storage.listObjects(bucketName).toList();
      expect(objects, hasLength(2));
      expect(
        objects.map((o) => o.name),
        containsAll(['object1.txt', 'object2.txt']),
      );

      await storage.deleteObject(bucketName, 'object1.txt');
      await storage.deleteObject(bucketName, 'object2.txt');
    });

    test('list objects empty bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_empty_bucket',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'list_objects_empty_bucket',
      );

      await storage.createBucket(BucketMetadata(name: bucketName));

      final objects = await storage.listObjects(bucketName).toList();
      expect(objects, isEmpty);
    });

    test('list objects with projection full', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_with_projection_full',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'list_objects_with_projection_full',
      );

      await storage.createBucket(BucketMetadata(name: bucketName));
      await storage.insertObject(
        bucketName,
        'object1.txt',
        utf8.encode('content1'),
        ifGenerationMatch: BigInt.zero,
      );

      final objects = await storage
          .listObjects(bucketName, projection: 'full')
          .toList();
      expect(objects, hasLength(1));
      expect(objects.first.name, 'object1.txt');
      // expect(objects.first.acl, isNotNull); // acl is only returned with full projection

      await storage.deleteObject(bucketName, 'object1.txt');
    });

    test('list objects with maxResults', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects_with_max_results',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'list_objects_with_max_results',
      );

      await storage.createBucket(BucketMetadata(name: bucketName));
      await storage.insertObject(
        bucketName,
        'object1.txt',
        utf8.encode('content1'),
        ifGenerationMatch: BigInt.zero,
      );
      await storage.insertObject(
        bucketName,
        'object2.txt',
        utf8.encode('content2'),
        ifGenerationMatch: BigInt.zero,
      );

      final objects = await storage
          .listObjects(bucketName, maxResults: BigInt.one)
          .toList();
      // listObjects handles pagination internally, so we should still get all results
      // even with maxResults set to 1 per page.
      expect(objects, hasLength(2));
      expect(
        objects.map((o) => o.name),
        containsAll(['object1.txt', 'object2.txt']),
      );

      await storage.deleteObject(bucketName, 'object1.txt');
      await storage.deleteObject(bucketName, 'object2.txt');
    });
  });
}
