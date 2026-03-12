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
@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {

  late Storage storage;
  late http.Client client;

  group('delete object', () {
    setUp(() async {
      fixedBoundaryString = 'boundary';
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

    test('success', () async {
      final bucketName = await createBucketWithTearDown(storage, 'del_obj_ok');
      await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: BigInt.zero,
      );

      await storage.deleteObject(bucketName, 'object.txt');

      expect(
        () => storage.objectMetadata(bucketName, 'object.txt'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('not found', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'del_obj_not_found',
      );

      expect(
        () => storage.deleteObject(bucketName, 'non-existent.txt'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('with generation success', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'del_obj_w_gen',
        metadata: BucketMetadata(versioning: BucketVersioning(enabled: true)),
      );
      final obj1 = await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('Text'),
      );
      final obj2 = await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('More text'),
      );

      // Verify both exist
      await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj1.generation,
      );
      await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj2.generation,
      );

      // Delete v1
      await storage.deleteObject(
        bucketName,
        'object.txt',
        generation: obj1.generation,
      );

      // Verify v1 is gone
      expect(
        () => storage.objectMetadata(
          bucketName,
          'object.txt',
          generation: obj1.generation,
        ),
        throwsA(isA<NotFoundException>()),
      );

      // Verify v2 still exists
      await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj2.generation,
      );
    });

    test('with ifGenerationMatch success', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'del_obj_w_if_gen_match_ok',
      );
      final obj = await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: BigInt.zero,
      );

      await storage.deleteObject(
        bucketName,
        'object.txt',
        ifGenerationMatch: obj.generation,
      );

      expect(
        () => storage.objectMetadata(bucketName, 'object.txt'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('with ifGenerationMatch failure', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'del_obj_w_if_gen_match_fail',
      );
      final obj = await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        ifGenerationMatch: BigInt.zero,
      );
      addTearDown(() => storage.deleteObject(bucketName, 'object.txt'));

      expect(
        () => storage.deleteObject(
          bucketName,
          'object.txt',
          ifGenerationMatch: obj.generation! + BigInt.one,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );

      // Verify object still exists
      await storage.objectMetadata(bucketName, 'object.txt');
    });

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '',
            204, // No Content
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      // Should retry because generation is specified
      await storage.deleteObject(
        'bucket',
        'object',
        generation: BigInt.from(123),
      );
      expect(count, 2);
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

      // Should not retry because no generation/ifGenerationMatch specified
      await expectLater(
        storage.deleteObject('bucket', 'object'),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });
  });
}
