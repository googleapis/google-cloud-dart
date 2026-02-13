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
import 'dart:typed_data';

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

  group('download object', () {
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

    test('empty object', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'download_object_empty',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'download_object_empty',
      );

      await storage.insertObject(
        bucketName,
        'object1',
        [],
        ifGenerationMatch: BigInt.zero,
      );

      final data = await storage.downloadObject(bucketName, 'object1');

      expect(data, isEmpty);
    });

    for (var i = 1; i <= 16_777_216; i *= 4) {
      test('object of size $i bytes', () async {
        await testClient.startTest(
          'google_cloud_storage',
          'download_object_size_$i',
        );
        addTearDown(testClient.endTest);
        final bucketName = await createBucketWithTearDown(
          storage,
          'download_object_size_$i',
        );

        final uploadedData = Uint8List(i);
        for (var j = 0; j < i; j++) {
          uploadedData[j] = j % 256;
        }
        await storage.insertObject(
          bucketName,
          'object1',
          uploadedData,
          ifGenerationMatch: BigInt.zero,
        );
        final downloadedData = await storage.downloadObject(
          bucketName,
          'object1',
        );

        expect(downloadedData, uploadedData);
      });
    }
  });
}
