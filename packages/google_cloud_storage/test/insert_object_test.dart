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
import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
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

  group('insert object', () {
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

    test('success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_success',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'insert_object_success'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));
      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        contentType: 'text/plain',
      );
      expect(objectMetadata.contentType, 'text/plain');
      expect(objectMetadata.kind, 'storage#object');
      expect(objectMetadata.generation, isNotNull);
      expect(objectMetadata.metageneration, 1);
      expect(objectMetadata.name, 'object1');
      expect(objectMetadata.size, 12);
    });

    test('no such bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_no_such_bucket',
      );
      addTearDown(testClient.endTest);
      const bucketName = 'insert_object_no_such_bucket';

      expect(
        () => storage.insertObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('overwrite', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_overwrite',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'insert_object_overwrite'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));
      final oldGeneration = (await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
      )).generation;
      final newGeneration = (await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Goodbye World!'),
      )).generation;
      expect(newGeneration, isNot(oldGeneration));
    });

    test('with if generation match success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_overwrite_if_generation_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'insert_object_overwrite_if_generation_match_success'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      final oldGeneration = (await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
      )).generation;
      final newGeneration = (await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Goodbye World!'),
        ifGenerationMatch: oldGeneration,
      )).generation;
      expect(newGeneration, isNot(oldGeneration));
    });

    test('with if generation match failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_overwrite_if_generation_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'insert_object_overwrite_if_generation_match_failure'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
      );
      expect(
        () => storage.insertObject(
          bucketName,
          'object1',
          utf8.encode('Goodbye World!'),
          ifGenerationMatch: 1234,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });
  });
}
