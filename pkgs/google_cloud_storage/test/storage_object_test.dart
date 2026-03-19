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
@Tags(['google-cloud'])
library;

import 'dart:convert';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('storage object', () {
    setUp(() {
      fixedBoundaryString = 'boundary';
      storage = Storage();
    });

    tearDown(() => storage.close());

    test('delete', () async {
      final bucketName = await createBucketWithTearDown(storage, 'stg_obj_del');
      await storage.uploadObject(
        bucketName,
        'blob1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).object('blob1');
      await blob.delete();

      await expectLater(blob.metadata, throwsA(isA<NotFoundException>()));
    });

    test('download', () async {
      final bucketName = await createBucketWithTearDown(storage, 'stg_obj_dl');
      await storage.uploadObject(
        bucketName,
        'blob1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).object('blob1');
      final bytes = await blob.download();
      expect(bytes, utf8.encode('Hello World!'));
    });

    test('metadata', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'stg_obj_meta',
      );
      await storage.uploadObject(
        bucketName,
        'blob1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );

      final blob = storage.bucket(bucketName).object('blob1');
      final metadata = await blob.metadata();
      expect(metadata.name, 'blob1');
    });

    test('patch', () async {
      final bucketName = await createBucketWithTearDown(storage, 'stg_obj_pch');
      await storage.uploadObject(
        bucketName,
        'blob1',
        utf8.encode('Hello World!'),
      );

      final blob = storage.bucket(bucketName).object('blob1');
      final metadata = await blob.patch(
        ObjectMetadataPatchBuilder()..contentType = 'text/plain',
      );
      expect(metadata.contentType, 'text/plain');
    });

    test('upload', () async {
      final bucketName = await createBucketWithTearDown(storage, 'stg_obj_ul');

      final blob = storage.bucket(bucketName).object('blob1');
      final metadata = await blob.upload(
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );
      expect(metadata.name, 'blob1');
      expect(metadata.contentType, 'application/octet-stream');
    });

    test('uploadAsString', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'stg_obj_ul_as_str',
      );

      final blob = storage.bucket(bucketName).object('blob1');
      final metadata = await blob.uploadAsString(
        'Hello World!',
        ifGenerationMatch: BigInt.zero,
      );
      expect(metadata.name, 'blob1');
      expect(metadata.contentType, 'text/plain');
    });
  });
}
