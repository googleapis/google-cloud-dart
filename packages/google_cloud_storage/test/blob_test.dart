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
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;
  late TestHttpClient testClient;

  group('blob', () {
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

    test('delete', () async {
      await testClient.startTest('google_cloud_storage', 'blob_delete');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(storage, 'blob_delete');
      await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).blob('object1');
      await blob.delete();

      await expectLater(blob.metadata, throwsA(isA<NotFoundException>()));
    });

    test('download', () async {
      await testClient.startTest('google_cloud_storage', 'blob_download');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'blob_download',
      );
      await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).blob('object1');
      final bytes = await blob.download();
      expect(bytes, utf8.encode('Hello World!'));
    });
    test('metadata', () async {
      await testClient.startTest('google_cloud_storage', 'blob_metadata');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'blob_metadata',
      );
      await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).blob('object1');
      final metadata = await blob.metadata();
      expect(metadata.name, 'object1');
    });

    test('patch', () async {
      await testClient.startTest('google_cloud_storage', 'blob_patch');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(storage, 'blob_patch');
      await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
      );

      final blob = storage.bucket(bucketName).blob('object1');
      final metadata = await blob.patch(
        ObjectMetadataPatchBuilder()..contentType = 'text/plain',
      );
      expect(metadata.contentType, 'text/plain');
    });

    test('upload', () async {
      await testClient.startTest('google_cloud_storage', 'blob_upload');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(storage, 'blob_upload');

      final blob = storage.bucket(bucketName).blob('object1');
      final metadata = await blob.upload(
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );
      expect(metadata.name, 'object1');
      expect(metadata.contentType, 'application/octet-stream');
    });
  });
}
