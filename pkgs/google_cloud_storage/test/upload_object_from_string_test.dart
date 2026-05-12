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
import 'package:test/test.dart';

import 'test_utils.dart';

void uploadObjectFromStringTest(
  Storage Function() createStorage,
  Future<String> Function(
    Storage storage,
    String name, {
    BucketMetadata? metadata,
    bool enableObjectRetention,
  })
  createBucketWithTearDown, [
  bool isStorageEmulator = false,
]) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('metadata is not set', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_str_no_meta',
    );

    final metadata = await storage.uploadObjectFromString(
      bucketName,
      'my-object',
      'Hello, World!',
      ifGenerationMatch: BigInt.zero,
    );

    expect(metadata.contentType, 'text/plain');

    final downloaded = await storage.downloadObject(bucketName, 'my-object');
    expect(utf8.decode(downloaded), 'Hello, World!');
  });

  test('metadata is set without contentType', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_str_cust_meta',
    );

    final metadata = await storage.uploadObjectFromString(
      bucketName,
      'my-object',
      'Hello, World!',
      metadata: ObjectMetadata(metadata: {'customMetadata': 'value'}),
      ifGenerationMatch: BigInt.zero,
    );

    expect(metadata.contentType, 'text/plain');
    expect(metadata.metadata?['customMetadata'], 'value');

    final downloaded = await storage.downloadObject(bucketName, 'my-object');
    expect(utf8.decode(downloaded), 'Hello, World!');
  });

  test('metadata is set with contentType', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_str_cust_cnt_typ',
    );

    final metadata = await storage.uploadObjectFromString(
      bucketName,
      'my-object',
      'Hello, World!',
      metadata: ObjectMetadata(contentType: 'text/html'),
      ifGenerationMatch: BigInt.zero,
    );

    expect(metadata.contentType, 'text/html');

    final downloaded = await storage.downloadObject(bucketName, 'my-object');
    expect(utf8.decode(downloaded), 'Hello, World!');
  });
}

void main() {
  group('upload object from string', () {
    group('google-cloud', tags: ['google-cloud'], () {
      uploadObjectFromStringTest(Storage.new, createBucketWithTearDown);
    });

    group('firebase-emulator', tags: ['firebase-emulator'], () {
      uploadObjectFromStringTest(
        createEmulatorClient,
        fakeCreateBucketWithTearDown,
        true,
      );
    });

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;
      late RetryTestHttpClient client;

      setUp(() {
        client = RetryTestHttpClient(http.Client());
        storage = Storage(
          projectId: 'test-project',
          apiEndpoint: 'localhost:9000',
          useAuthWithCustomEndpoint: false,
          client: client,
        );
      });

      tearDown(() => storage.close());

      uploadObjectFromStringTest(() => storage, createBucketWithTearDown);
    });
  });
}
