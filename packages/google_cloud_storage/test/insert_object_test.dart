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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

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

    test('new, no metadata', () async {
      await testClient.startTest('google_cloud_storage', 'insert_object_new');
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new',
      );

      final beforeRequestTime = DateTime.now().toUtc();

      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );
      final afterRequestTime = DateTime.now().toUtc();
      expect(objectMetadata.acl, isNull);
      expect(objectMetadata.bucket, bucketName);
      expect(objectMetadata.cacheControl, isNull);
      expect(objectMetadata.componentCount, isNull);
      expect(objectMetadata.contentDisposition, isNull);
      expect(objectMetadata.contentEncoding, isNull);
      expect(objectMetadata.contentLanguage, isNull);
      expect(objectMetadata.contentType, 'application/octet-stream');
      expect(objectMetadata.contexts, isNull);
      expect(objectMetadata.crc32c, '/mzx3A==');
      expect(objectMetadata.customTime, isNull);
      expect(objectMetadata.customerEncryption, isNull);
      expect(objectMetadata.etag, isNotEmpty);
      expect(objectMetadata.eventBasedHold, isNull);
      expect(objectMetadata.generation, isNotNull);
      expect(objectMetadata.hardDeleteTime, isNull);
      expect(objectMetadata.id, isNotEmpty);
      expect(objectMetadata.kind, 'storage#object');
      expect(objectMetadata.kmsKeyName, isNull);
      expect(
        objectMetadata.mediaLink?.toString(),
        startsWith(
          'https://storage.googleapis.com/download/storage/v1/b/$bucketName/o/'
          'object1',
        ),
      );
      expect(objectMetadata.metadata, isNull);
      expect(objectMetadata.md5Hash, isNotEmpty);
      expect(objectMetadata.metageneration, BigInt.one);
      expect(objectMetadata.name, 'object1');
      expect(objectMetadata.owner, isNull);
      expect(objectMetadata.restoreToken, isNull);
      expect(objectMetadata.retentionExpirationTime, isNull);
      expect(
        objectMetadata.selfLink,
        Uri(
          scheme: 'https',
          host: 'www.googleapis.com',
          path: '/storage/v1/b/$bucketName/o/object1',
        ),
      );
      expect(objectMetadata.size, BigInt.from(12));
      expect(objectMetadata.softDeleteTime, isNull);
      expect(objectMetadata.storageClass, 'STANDARD');
      expect(objectMetadata.temporaryHold, isNull);
      if (TestHttpClient.isReplaying) {
        expect(
          objectMetadata.timeCreated?.toDateTime().microsecondsSinceEpoch,
          greaterThan(0),
        );
      } else {
        expect(
          objectMetadata.timeCreated?.toDateTime().microsecondsSinceEpoch,
          allOf(
            greaterThanOrEqualTo(beforeRequestTime.microsecondsSinceEpoch),
            lessThanOrEqualTo(afterRequestTime.microsecondsSinceEpoch),
          ),
        );
      }
      expect(objectMetadata.timeDeleted, isNull);
      expect(objectMetadata.timeStorageClassUpdated, isNotNull);
      expect(
        objectMetadata.updated?.toDateTime(),
        objectMetadata.timeCreated?.toDateTime(),
      );
    });

    test('new with content-type', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_content_type',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_content_type',
      );

      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        metadata: ObjectMetadata(contentType: 'text/plain'),
        ifGenerationMatch: BigInt.zero,
      );

      expect(objectMetadata.contentType, 'text/plain');
    });

    test('new with crc32c', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_crc32c',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_crc32c',
      );

      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        metadata: ObjectMetadata(crc32c: '/mzx3A=='),
        ifGenerationMatch: BigInt.zero,
      );
      expect(objectMetadata.crc32c, '/mzx3A==');
    });

    test('new with invalid crc32c', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_invalid_crc32c',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_invalid_crc32c',
      );

      expect(
        () => storage.insertObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(crc32c: 'invalid'),
          ifGenerationMatch: BigInt.zero,
        ),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('new with md5', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_md5',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_md5',
      );

      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        metadata: ObjectMetadata(md5Hash: '7Qdih1MuhjZehB6Sv8UNjA=='),
        ifGenerationMatch: BigInt.zero,
      );
      expect(objectMetadata.md5Hash, '7Qdih1MuhjZehB6Sv8UNjA==');
    });

    test('new with invalid md5', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_invalid_md5',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_invalid_md5',
      );

      expect(
        () => storage.insertObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(md5Hash: 'invalid'),
          ifGenerationMatch: BigInt.zero,
        ),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('parameter name and metadata name mismatch', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'insert_object_new_with_parameter_name_and_metadata_name_mismatch',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_new_with_name_mismatch',
      );

      expect(
        () => storage.insertObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(name: 'object2'),
          ifGenerationMatch: BigInt.zero,
        ),
        throwsA(isA<BadRequestException>()),
      );
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_overwrite',
      );

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
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_overwrite_if_generation_match_success',
      );

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
      final bucketName = await createBucketWithTearDown(
        storage,
        'insert_object_overwrite_if_generation_match_failure',
      );

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
          ifGenerationMatch: BigInt.from(1234),
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"name": "object"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final actualMetadata = await storage.insertObject('bucket', 'object', [
        1,
        2,
        3,
      ], ifGenerationMatch: BigInt.one);
      expect(actualMetadata.name, 'object');
    });

    test('non-idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      expect(
        () => storage.insertObject('bucket', 'object', [1, 2, 3]),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
