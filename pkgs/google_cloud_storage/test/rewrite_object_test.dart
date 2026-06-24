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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('rewrite object', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() {
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('success same bucket', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_same',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.bucket, bucketName);
        expect(rewritten.metageneration, BigInt.one);

        // Verify source still exists
        final sourceMeta = await storage.objectMetadata(
          bucketName,
          'source.txt',
        );
        expect(sourceMeta.name, 'source.txt');

        // Verify dest exists and has correct content
        final destMeta = await storage.objectMetadata(bucketName, 'dest.txt');
        expect(destMeta.name, 'dest.txt');
        final bytes = await storage.downloadObject(bucketName, 'dest.txt');
        expect(utf8.decode(bytes), 'content');
      });

      test('success cross bucket', () async {
        final srcBucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_cross_src',
        );
        final destBucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_cross_dest',
        );

        await storage.uploadObject(
          srcBucketName,
          'source.txt',
          utf8.encode('cross-bucket-content'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          srcBucketName,
          'source.txt',
          destBucketName,
          'dest.txt',
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.bucket, destBucketName);

        // Verify dest exists and has correct content
        final bytes = await storage.downloadObject(destBucketName, 'dest.txt');
        expect(utf8.decode(bytes), 'cross-bucket-content');
      });

      test('rewrite through StorageObject.rewrite same bucket', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_so_same',
        );
        final source = storage.bucket(bucketName).object('source.txt');
        await source.uploadAsString(
          'so-content',
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await source.rewrite('dest.txt');
        expect(rewritten.name, 'dest.txt');
        expect(rewritten.bucket, bucketName);

        final dest = storage.bucket(bucketName).object('dest.txt');
        final bytes = await dest.download();
        expect(utf8.decode(bytes), 'so-content');
      });

      test('rewrite through StorageObject.rewrite cross bucket', () async {
        final srcBucketName = await createBucketWithTearDown(
          storage,
          'rew_so_cross_src',
        );
        final destBucketName = await createBucketWithTearDown(
          storage,
          'rew_so_cross_dest',
        );

        final source = storage.bucket(srcBucketName).object('source.txt');
        await source.uploadAsString(
          'cross-so-content',
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await source.rewrite(
          'dest.txt',
          destinationBucket: destBucketName,
        );
        expect(rewritten.name, 'dest.txt');
        expect(rewritten.bucket, destBucketName);

        final dest = storage.bucket(destBucketName).object('dest.txt');
        final bytes = await dest.download();
        expect(utf8.decode(bytes), 'cross-so-content');
      });

      test('metadata override', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_meta',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          metadata: ObjectMetadata(contentType: 'text/plain'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          metadata: ObjectMetadata(contentType: 'application/json'),
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.contentType, 'application/json');
      });

      test('sourceGeneration', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_src_gen',
          metadata: BucketMetadata(versioning: BucketVersioning(enabled: true)),
        );
        final obj1 = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('v1'),
          ifGenerationMatch: BigInt.zero,
        );
        final obj2 = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('v2'),
          ifGenerationMatch: obj1.generation,
        );

        // Verify that latest is indeed v2
        final latestMeta = await storage.objectMetadata(
          bucketName,
          'source.txt',
        );
        expect(latestMeta.generation, obj2.generation);

        // Rewrite obj1 (v1) to dest.txt
        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          sourceGeneration: obj1.generation,
        );

        expect(rewritten.name, 'dest.txt');

        // Verify dest.txt content is 'v1'
        final bytes = await storage.downloadObject(bucketName, 'dest.txt');
        expect(utf8.decode(bytes), 'v1');
      });

      test('ifSourceGenerationMatch success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_src_gen_ok',
        );
        final source = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          ifSourceGenerationMatch: source.generation,
        );

        expect(rewritten.name, 'dest.txt');
      });

      test('ifSourceGenerationMatch failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_src_gen_fail',
        );
        final source = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        expect(
          () => storage.rewriteObject(
            bucketName,
            'source.txt',
            bucketName,
            'dest.txt',
            ifSourceGenerationMatch: source.generation! + BigInt.one,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });

      test('ifGenerationMatch: 0 failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_fail_exist',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('source'),
          ifGenerationMatch: BigInt.zero,
        );
        await storage.uploadObject(
          bucketName,
          'dest.txt',
          utf8.encode('dest'),
          ifGenerationMatch: BigInt.zero,
        );

        expect(
          () => storage.rewriteObject(
            bucketName,
            'source.txt',
            bucketName,
            'dest.txt',
            ifGenerationMatch: BigInt.zero,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });

      test('destinationPredefinedAcl', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_predefined_acl',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          destinationPredefinedAcl: 'projectPrivate',
          projection: 'full',
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.acl?.first.role, 'OWNER');
      });

      test('projection', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_projection',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          projection: 'full',
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.acl, isNotNull);
        expect(rewritten.owner, isNotNull);
      });

      test('multi-step chunked rewrite', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'rew_obj_chunked',
        );
        // Create a 2 MiB object (GCS requires chunk sizes to be a multiple of
        // 1 MiB).
        final content = 'A' * (2 * 1024 * 1024);
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode(content),
          ifGenerationMatch: BigInt.zero,
        );

        // Force a 1 MiB chunk size to guarantee a 2-step rewrite
        final rewritten = await storage.rewriteObject(
          bucketName,
          'source.txt',
          bucketName,
          'dest.txt',
          maxBytesRewrittenPerCall: BigInt.from(1024 * 1024),
        );

        expect(rewritten.name, 'dest.txt');
        expect(rewritten.bucket, bucketName);

        final bytes = await storage.downloadObject(bucketName, 'dest.txt');
        expect(utf8.decode(bytes), content);
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
            jsonEncode({
              'kind': 'storage#rewriteResponse',
              'totalBytesRewritten': '12',
              'objectSize': '12',
              'done': true,
              'resource': {
                'kind': 'storage#object',
                'name': 'dest.txt',
                'bucket': 'dest-bucket',
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: 'fake-project');

      // Should retry because ifGenerationMatch is specified
      await storage.rewriteObject(
        'src-bucket',
        'source.txt',
        'dest-bucket',
        'dest.txt',
        ifGenerationMatch: BigInt.from(789),
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

      final storage = Storage(client: mockClient, projectId: 'fake-project');

      // Should not retry because no generation conditions are specified
      await expectLater(
        storage.rewriteObject(
          'src-bucket',
          'source.txt',
          'dest-bucket',
          'dest.txt',
        ),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });
  });
}
