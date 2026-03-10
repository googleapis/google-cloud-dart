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

  group('upload object from string', () {
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

    test('metadata is not set', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'upload_object_from_string_no_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'upload_object_from_string_no_metadata',
      );

      final metadata = await storage.uploadObjectFromString(
        bucketName,
        'my-object',
        'Hello, World!',
        ifGenerationMatch: BigInt.zero,
      );

      expect(metadata.contentType, 'text/plain');

      final downloaded = await storage.downloadObject(bucketName, 'my-object');
      expect(utf8.decode(downloaded), 'Hello, World!');
    });

    test('metadata is set without contentType', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'upload_object_from_string_custom_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'upload_object_from_string_custom_metadata',
      );

      final metadata = await storage.uploadObjectFromString(
        bucketName,
        'my-object',
        'Hello, World!',
        metadata: ObjectMetadata(metadata: {'customMetadata': 'value'}),
        ifGenerationMatch: BigInt.zero,
      );

      expect(metadata.contentType, 'text/plain');
      expect(metadata.metadata?['customMetadata'], 'value');

      final downloaded = await storage.downloadObject(bucketName, 'my-object');
      expect(utf8.decode(downloaded), 'Hello, World!');
    });

    test('metadata is set with contentType', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'upload_object_from_string_custom_content_type',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'upload_object_from_string_custom_content_type',
      );

      final metadata = await storage.uploadObjectFromString(
        bucketName,
        'my-object',
        'Hello, World!',
        metadata: ObjectMetadata(contentType: 'text/html'),
        ifGenerationMatch: BigInt.zero,
      );

      expect(metadata.contentType, 'text/html');

      final downloaded = await storage.downloadObject(bucketName, 'my-object');
      expect(utf8.decode(downloaded), 'Hello, World!');
    });
  });
}
