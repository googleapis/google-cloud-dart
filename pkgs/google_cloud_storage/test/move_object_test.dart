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
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('move object', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() {
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'move_obj_ok',
        );
        await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final moved = await storage.moveObject(
          bucketName,
          'source.txt',
          'dest.txt',
        );

        expect(moved.name, 'dest.txt');
        expect(moved.bucket, bucketName);
        expect(moved.metageneration, BigInt.one);

        // Verify source is gone
        expect(
          () => storage.objectMetadata(bucketName, 'source.txt'),
          throwsA(isA<NotFoundException>()),
        );

        // Verify dest exists
        final metadata = await storage.objectMetadata(bucketName, 'dest.txt');
        expect(metadata.name, 'dest.txt');
      });

      test('move through StorageObject', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'move_obj_so',
        );
        final source = storage.bucket(bucketName).object('source.txt');
        await source.uploadAsString('content', ifGenerationMatch: BigInt.zero);

        await source.move('dest.txt');

        // Verify source is gone
        expect(source.metadata, throwsA(isA<NotFoundException>()));

        // Verify dest exists
        final dest = storage.bucket(bucketName).object('dest.txt');
        final metadata = await dest.metadata();
        expect(metadata.name, 'dest.txt');
      });

      test('ifGenerationMatch: 0 failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'move_obj_fail_exist',
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
          () => storage.moveObject(
            bucketName,
            'source.txt',
            'dest.txt',
            ifGenerationMatch: BigInt.zero,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });

      test('ifSourceGenerationMatch success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'move_obj_src_gen_ok',
        );
        final source = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        final moved = await storage.moveObject(
          bucketName,
          'source.txt',
          'dest.txt',
          ifSourceGenerationMatch: source.generation,
        );

        expect(moved.name, 'dest.txt');
        // Verify source is gone
        expect(
          () => storage.objectMetadata(bucketName, 'source.txt'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('ifSourceGenerationMatch failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'move_obj_src_gen_fail',
        );
        final source = await storage.uploadObject(
          bucketName,
          'source.txt',
          utf8.encode('content'),
          ifGenerationMatch: BigInt.zero,
        );

        expect(
          () => storage.moveObject(
            bucketName,
            'source.txt',
            'dest.txt',
            ifSourceGenerationMatch: source.generation! + BigInt.one,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });
    });
  });
}
