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
import 'package:google_cloud_storage/src/file_upload.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

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

  group('object metadata', () {
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

    test('simple', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'object_metadata_simple',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'object_metadata_simple'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: 0,
      );

      final metadata = await storage.objectMetadata(bucketName, 'object.txt');
      expect(metadata.name, 'object.txt');
      expect(metadata.bucket, bucketName);
      expect(metadata.size, 7);
    });

    test('with generation', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'object_metadata_with_generation',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'object_metadata_with_generation'
          : uniqueBucketName();

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          versioning: BucketVersioning(enabled: true),
        ),
      );

      final obj1 = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('Hello'),
        ifGenerationMatch: 0,
      );
      final obj2 = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('Hello World!'),
      );

      // Verify we have two versions
      expect(obj1.generation, isNot(obj2.generation));

      final metadataV1 = await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj1.generation,
      );
      expect(metadataV1.generation, obj1.generation);
      expect(metadataV1.size, 5);

      final metadataV2 = await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj2.generation,
      );
      expect(metadataV2.generation, obj2.generation);
      expect(metadataV2.size, 12);
    });

    test('with if metageneration match success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'object_metadata_with_if_metageneration_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'object_metadata_with_if_metageneration_match_success'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));
      final obj = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: 0,
      );

      final metadata = await storage.objectMetadata(
        bucketName,
        'object.txt',
        ifGenerationMatch: obj.generation,
      );
      expect(metadata.generation, obj.generation);
    });

    test('with if metageneration match failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'object_metadata_with_if_metageneration_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'object_metadata_with_if_metageneration_match_failure'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));
      final obj = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: 0,
      );

      expect(
        () => storage.objectMetadata(
          bucketName,
          'object.txt',
          ifGenerationMatch: obj.generation! + 1,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test('non-existant object', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'object_metadata_non_existant',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'object_metadata_non_existant'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      expect(
        () => storage.objectMetadata(bucketName, 'non-existent.txt'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('retry on transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"name": "object.txt", "bucket": "bucket"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final metadata = await storage.objectMetadata('bucket', 'object.txt');
      expect(metadata.name, 'object.txt');
    });
  });
}
