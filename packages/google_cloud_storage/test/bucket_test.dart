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

import 'dart:io';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {

  late Storage storage;
  late http.Client client;

  group('bucket', () {
    setUp(() async {
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

    test('create', () async {
      final bucketName = bucketNameWithTearDown(storage, 'dart_bkt_crt');

      final bucket = storage.bucket(bucketName);
      final metadata = await bucket.create();
      expect(metadata.name, bucketName);
    });

    test('create with contradictory name metadata', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'dart_bkt_crt_contradictory_name_meta',
      );

      final bucket = storage.bucket(bucketName);
      final metadata = await bucket.create(
        metadata: BucketMetadata(name: 'other-name'),
      );
      expect(metadata.name, bucketName);
    });

    test('delete', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'dart_bkt_del',
      );

      final bucket = storage.bucket(bucketName);
      await bucket.delete();
      await expectLater(bucket.metadata, throwsA(isA<NotFoundException>()));
    });

    test('metadata', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'dart_bkt_meta',
      );

      final bucket = storage.bucket(bucketName);
      final metadata = await bucket.metadata();
      expect(metadata.name, bucketName);
    });

    test('patch', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'dart_bkt_pch',
      );

      final bucket = storage.bucket(bucketName);
      final metadata = await bucket.patch(
        BucketMetadataPatchBuilder()..labels = {'foo': 'bar'},
      );
      expect(metadata.labels, {'foo': 'bar'});
    });
  });
}
