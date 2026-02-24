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
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('insert object', () {
    setUp(() async {
      storage = Storage(
        client: http.Client(),
        projectId: projectId,
        apiEndpoint: '127.0.0.1:9199',
        useAuthWithCustomEndpoint: false,
      );
    });

    tearDown(() => storage.close());

    test('new, no metadata', () async {
      final bucketName = testBucketName('insert_object_new');

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
          'http://127.0.0.1:9199/download/storage/v1/b/$bucketName/o/'
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
          scheme: 'http',
          host: '127.0.0.1',
          port: 9199,
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
  });
}
