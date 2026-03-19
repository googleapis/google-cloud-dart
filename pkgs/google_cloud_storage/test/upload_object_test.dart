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

import 'dart:convert';

import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('upload object', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() {
        fixedBoundaryString = 'boundary';
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('new, no metadata', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new',
        );

        final beforeRequestTime = DateTime.now().toUtc().subtract(
          const Duration(seconds: 1), // Add some buffer for clock skew.
        );
        final objectMetadata = await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          ifGenerationMatch: BigInt.zero,
        );
        final afterRequestTime = DateTime.now().toUtc().add(
          const Duration(seconds: 1), // Add some buffer for clock skew.
        );
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
        expect(
          objectMetadata.timeCreated?.toDateTime().microsecondsSinceEpoch,
          allOf(
            greaterThanOrEqualTo(beforeRequestTime.microsecondsSinceEpoch),
            lessThanOrEqualTo(afterRequestTime.microsecondsSinceEpoch),
          ),
        );
        expect(objectMetadata.timeDeleted, isNull);
        expect(objectMetadata.timeStorageClassUpdated, isNotNull);
        expect(
          objectMetadata.updated?.toDateTime(),
          objectMetadata.timeCreated?.toDateTime(),
        );
      });

      test('new with content-type', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_cnt_typ',
        );

        final objectMetadata = await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(contentType: 'text/plain'),
          ifGenerationMatch: BigInt.zero,
        );

        expect(objectMetadata.contentType, 'text/plain');
      });

      test('new with crc32c', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_crc32c',
        );

        final objectMetadata = await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(crc32c: '/mzx3A=='),
          ifGenerationMatch: BigInt.zero,
        );
        expect(objectMetadata.crc32c, '/mzx3A==');
      });

      test('new with invalid crc32c', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_invalid_crc32c',
        );

        expect(
          () => storage.uploadObject(
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
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_md5',
        );

        final objectMetadata = await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
          metadata: ObjectMetadata(md5Hash: '7Qdih1MuhjZehB6Sv8UNjA=='),
          ifGenerationMatch: BigInt.zero,
        );
        expect(objectMetadata.md5Hash, '7Qdih1MuhjZehB6Sv8UNjA==');
      });

      test('new with invalid md5', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_invalid_md5',
        );

        expect(
          () => storage.uploadObject(
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
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_new_w_name_mismatch',
        );

        expect(
          () => storage.uploadObject(
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
        const bucketName = 'upload_object_no_such_bucket';

        expect(
          () => storage.uploadObject(
            bucketName,
            'object1',
            utf8.encode('Hello World!'),
          ),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('overwrite', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_overwrite',
        );

        final oldGeneration = (await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
        )).generation;
        final newGeneration = (await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Goodbye World!'),
        )).generation;
        expect(newGeneration, isNot(oldGeneration));
      });

      test('with if generation match success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_overwrite_if_gen_match_ok',
        );

        final oldGeneration = (await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
        )).generation;
        final newGeneration = (await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Goodbye World!'),
          ifGenerationMatch: oldGeneration,
        )).generation;
        expect(newGeneration, isNot(oldGeneration));
      });

      test('with if generation match failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_overwrite_if_gen_match_fail',
        );

        await storage.uploadObject(
          bucketName,
          'object1',
          utf8.encode('Hello World!'),
        );
        expect(
          () => storage.uploadObject(
            bucketName,
            'object1',
            utf8.encode('Goodbye World!'),
            ifGenerationMatch: BigInt.from(1234),
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });
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

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final actualMetadata = await storage.uploadObject('bucket', 'object', [
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

      final storage = Storage(client: mockClient, projectId: 'fake project');

      expect(
        () => storage.uploadObject('bucket', 'object', [1, 2, 3]),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
