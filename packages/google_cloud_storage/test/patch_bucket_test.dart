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

import 'dart:math';

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

const bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

String uniqueBucketName() {
  final random = Random();
  return [
    for (int i = 0; i < 32; i++)
      bucketChars[random.nextInt(bucketChars.length)],
  ].join();
}

void main() async {
  late Storage storage;
  late TestHttpClient testClient;

  group('patch bucket', () {
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

    test('patch_bucket_with_metadata', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_metadata'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      final patchMetadata = BucketMetadata(
        versioning: BucketVersioning(enabled: true),
      );

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.versioning?.enabled, isTrue);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('patch_bucket_with_metadata_empty_metadata', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_metadata_empty_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_metadata_empty_metadata'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      final patchMetadata = BucketMetadata();

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(
        actualMetadata.updated?.toDateTime(),
        actualMetadata.timeCreated?.toDateTime(),
      );
      expect(actualMetadata.metageneration, 1);
    });

    test('patch_bucket_with_metadata_same_metadata', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_metadata_same_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_metadata_same_metadata'
          : uniqueBucketName();

      final createMetadata = await storage.createBucket(
        BucketMetadata(name: bucketName),
      );

      final actualMetadata = await storage.patchBucket(
        bucketName,
        createMetadata,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('patch_bucket_non_existant', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_non_existant',
      );
      addTearDown(testClient.endTest);

      final patchMetadata = BucketMetadata(
        versioning: BucketVersioning(enabled: true),
      );

      expect(
        () => storage.patchBucket('non_existant_bucket', patchMetadata),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('patch_bucket_with_metadata_change_immutable_data', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_metadata_change_immutable_data',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_metadata_change_immutable_data'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      final patchMetadata = BucketMetadata(name: 'new_name');

      expect(
        () => storage.patchBucket(bucketName, patchMetadata),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('patch_bucket_with_if_metageneration_match_success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_if_metageneration_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_if_metageneration_match_success'
          : uniqueBucketName();

      final requestMetadata = BucketMetadata(name: bucketName);
      final createdMetadata = await storage.createBucket(requestMetadata);
      final metageneration = createdMetadata.metageneration;

      var patchMetadata = BucketMetadata(
        versioning: BucketVersioning(enabled: true),
      );
      final patchedMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
        ifMetagenerationMatch: metageneration,
      );
      expect(patchedMetadata.metageneration, 2);
    });

    test('patch_bucket_with_if_metageneration_match_failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_if_metageneration_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'patch_bucket_with_if_metageneration_match_failure'
          : uniqueBucketName();

      await storage.createBucket(BucketMetadata(name: bucketName));

      var patchMetadata = BucketMetadata(
        versioning: BucketVersioning(enabled: true),
      );
      expect(
        () => storage.patchBucket(
          bucketName,
          patchMetadata,
          ifMetagenerationMatch: 0,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test(
      'patch_bucket_with_predefined_acl',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_with_predefined_acl',
        );
        addTearDown(testClient.endTest);
        final bucketName =
            TestHttpClient.isRecording || TestHttpClient.isReplaying
            ? 'patch_bucket_with_metadata'
            : uniqueBucketName();

        await storage.createBucket(
          BucketMetadata(
            name: bucketName,
            iamConfiguration: BucketIamConfiguration(
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: false,
              ),
            ),
          ),
        );

        final actualMetadata = await storage.patchBucket(
          bucketName,
          BucketMetadata(),
          predefinedAcl: 'projectPrivate',
          projection: 'full',
        );

        expect(actualMetadata.acl?.first.role, 'OWNER');
        expect(
          actualMetadata.updated!.toDateTime().isAfter(
            actualMetadata.timeCreated!.toDateTime(),
          ),
          isTrue,
        );
        expect(actualMetadata.metageneration, 2);
      },
      skip: 'test project does not support uniform bucket level access',
    );

    test(
      'patch_bucket_with_predefined_default_object_acl',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_with_predefined_default_object_acl',
        );
        addTearDown(testClient.endTest);
        final bucketName =
            TestHttpClient.isRecording || TestHttpClient.isReplaying
            ? 'patch_bucket_with_metadata'
            : uniqueBucketName();

        await storage.createBucket(
          BucketMetadata(
            name: bucketName,
            iamConfiguration: BucketIamConfiguration(
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: false,
              ),
            ),
          ),
        );

        final actualMetadata = await storage.patchBucket(
          bucketName,
          BucketMetadata(),
          predefinedDefaultObjectAcl: 'projectPrivate',
          projection: 'full',
        );

        expect(actualMetadata.acl?.first.role, 'OWNER');
        expect(
          actualMetadata.updated!.toDateTime().isAfter(
            actualMetadata.timeCreated!.toDateTime(),
          ),
          isTrue,
        );
        expect(actualMetadata.metageneration, 2);
      },
      skip: 'test project does not support uniform bucket level access',
    );

    test('patch_bucket_idempotent_transport_failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"name": "new_name"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final requestMetadata = BucketMetadata(name: 'new_name');

      final actualMetadata = await storage.patchBucket(
        'bucket',
        requestMetadata,
        ifMetagenerationMatch: 1,
      );
      expect(actualMetadata.name, 'new_name');
    });

    test('patch_bucket_non_idempotent_transport_failure', () async {
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

      final requestMetadata = BucketMetadata(name: 'new_name');

      expect(
        () => storage.patchBucket('bucket', requestMetadata),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
