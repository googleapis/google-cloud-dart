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

import 'package:google_cloud_storage/google_cloud_storage.dart';
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

  group('bucket metadata', () {
    setUp(() async {
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

    test('simple', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'bucket_metadata_simple',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'bucket_metadata_simple',
      );

      final metadata = await storage.bucketMetadata(bucketName);
      expect(metadata.name, bucketName);
      expect(metadata.metageneration, isNotNull);
    });

    test('with if metageneration match success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'bucket_metadata_with_if_metageneration_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'bucket_metadata_with_if_metageneration_match_success',
      );

      final metadata = await storage.bucketMetadata(bucketName);

      final metadataWithMatch = await storage.bucketMetadata(
        bucketName,
        ifMetagenerationMatch: metadata.metageneration,
      );
      expect(metadataWithMatch.metageneration, metadata.metageneration);
    });

    test('with if metageneration match failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'bucket_metadata_with_if_metageneration_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'bucket_metadata_with_if_metageneration_match_failure',
      );

      final metadata = await storage.bucketMetadata(bucketName);

      expect(
        () => storage.bucketMetadata(
          bucketName,
          ifMetagenerationMatch: metadata.metageneration! + BigInt.one,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test('non-existant bucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'bucket_metadata_non_existant',
      );
      addTearDown(testClient.endTest);

      expect(
        () => storage.bucketMetadata('non-existent-bucket-name'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('retry on transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"name": "bucket", "metageneration": "1"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final metadata = await storage.bucketMetadata('bucket');
      expect(metadata.name, 'bucket');
    });
  });
}
