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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('object metadata', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() async {
        fixedBoundaryString = 'boundary';
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('simple', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'obj_meta_simple',
        );

        await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'content',
          ifGenerationMatch: BigInt.zero,
        );

        final metadata = await storage.objectMetadata(bucketName, 'object.txt');
        expect(metadata.name, 'object.txt');
        expect(metadata.bucket, bucketName);
        expect(metadata.size, BigInt.from(7));
      });

      test('with generation', () async {
        final bucketName = bucketNameWithTearDown(storage, 'obj_meta_w_gen');
        await storage.createBucket(
          BucketMetadata(
            name: bucketName,
            versioning: BucketVersioning(enabled: true),
          ),
        );

        final obj1 = await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'Hello',
          ifGenerationMatch: BigInt.zero,
        );
        final obj2 = await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'Hello World!',
        );

        // Verify we have two versions
        expect(obj1.generation, isNot(obj2.generation));

        final metadataV1 = await storage.objectMetadata(
          bucketName,
          'object.txt',
          generation: obj1.generation,
        );
        expect(metadataV1.generation, obj1.generation);
        expect(metadataV1.size, BigInt.from(5));

        final metadataV2 = await storage.objectMetadata(
          bucketName,
          'object.txt',
          generation: obj2.generation,
        );
        expect(metadataV2.generation, obj2.generation);
        expect(metadataV2.size, BigInt.from(12));
      });

      test('with if generation match success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'obj_meta_w_if_gen_match_ok',
        );
        final obj = await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'content',
          ifGenerationMatch: BigInt.zero,
        );

        final metadata = await storage.objectMetadata(
          bucketName,
          'object.txt',
          ifGenerationMatch: obj.generation,
        );
        expect(metadata.generation, obj.generation);
      });

      test('with if generation match failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'obj_meta_w_if_gen_match_fail',
        );
        final obj = await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'content',
          ifGenerationMatch: BigInt.zero,
        );

        expect(
          () => storage.objectMetadata(
            bucketName,
            'object.txt',
            ifGenerationMatch: obj.generation! + BigInt.one,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });

      test('non-existant object', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'obj_meta_non_existant',
        );

        expect(
          () => storage.objectMetadata(bucketName, 'non-existent.txt'),
          throwsA(isA<NotFoundException>()),
        );
      });
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

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final metadata = await storage.objectMetadata('bucket', 'object.txt');
      expect(metadata.name, 'object.txt');
    });
  });
}
