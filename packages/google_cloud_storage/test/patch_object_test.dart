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

import 'package:google_cloud_protobuf/protobuf.dart' hide Duration;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart';
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

  group('patch object', () {
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

    test('change acl', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_acl',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_acl',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..acl = [ObjectAccessControl(role: 'OWNER', entity: 'allUsers')];

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
        projection: 'full',
      );

      expect(actualMetadata.acl?.first.role, 'OWNER');
      expect(actualMetadata.metageneration, BigInt.from(2));
    }, skip: 'not supported by test project (UBLA)');

    test('remove acl', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_acl',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_acl',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..acl = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
        projection: 'full',
      );

      expect(actualMetadata.acl, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    }, skip: 'not supported by test project (UBLA)');

    test('change cache control', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_cache_control',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_cache_control',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..cacheControl = 'public, max-age=3600';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.cacheControl, 'public, max-age=3600');
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove cache control', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_cache_control',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_cache_control',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(cacheControl: 'no-cache'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..cacheControl = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.cacheControl, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change content disposition', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_content_disposition',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_content_disposition',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentDisposition = 'attachment; filename="filename.jpg"';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(
        actualMetadata.contentDisposition,
        'attachment; filename="filename.jpg"',
      );
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove content disposition', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_content_disposition',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_content_disposition',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(contentDisposition: 'attachment'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentDisposition = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentDisposition, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change content encoding', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_content_encoding',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_content_encoding',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentEncoding = 'gzip';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentEncoding, 'gzip');
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove content encoding', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_content_encoding',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_content_encoding',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(contentEncoding: 'gzip'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentEncoding = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentEncoding, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change content language', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_content_language',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_content_language',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentLanguage = 'en';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentLanguage, 'en');
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove content language', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_content_language',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_content_language',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(contentLanguage: 'en'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentLanguage = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentLanguage, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change content type', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_content_type',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_content_type',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentType, 'text/plain');
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove content type', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_content_type',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_content_type',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(contentType: 'text/html'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..contentType = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.contentType, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change custom time', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_custom_time',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_custom_time',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final customTime = Timestamp(seconds: 1234567890);
      final patchMetadata = ObjectMetadataPatchBuilder()
        ..customTime = customTime;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.customTime?.seconds, customTime.seconds);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change event based hold', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_event_based_hold',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_event_based_hold',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..eventBasedHold = true;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.eventBasedHold, isTrue);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove event based hold', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_event_based_hold',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_event_based_hold',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(eventBasedHold: true),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..eventBasedHold = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.eventBasedHold, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change metadata', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_metadata',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..metadata = {'key': 'value'};

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.metadata, {'key': 'value'});
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove metadata', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_remove_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_remove_metadata',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(metadata: {'key': 'value'}),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..metadata = null;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.metadata, isNull);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test(
      'change retention',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_object_change_retention',
        );
        addTearDown(testClient.endTest);
        final bucketName = await createBucketWithTearDown(
          storage,
          'patch_object_change_retention',
          enableObjectRetention: true,
        );

        await storage.insertObject(
          bucketName,
          'object.txt',
          utf8.encode('content'),
        );

        final retainUntilTime = DateTime.now()
            .add(const Duration(seconds: 1))
            .toUtc()
            .toTimestamp();
        final patchMetadata = ObjectMetadataPatchBuilder()
          ..retention = ObjectRetention(
            mode: 'Unlocked',
            retainUntilTime: retainUntilTime,
          );

        final actualMetadata = await storage.patchObject(
          bucketName,
          'object.txt',
          patchMetadata,
        );

        expect(actualMetadata.retention?.mode, 'Unlocked');
        expect(
          actualMetadata.retention?.retainUntilTime?.seconds,
          retainUntilTime.seconds,
        );
        expect(actualMetadata.metageneration, BigInt.from(2));

        // Wait for the retention period to expire so teardown can delete it.
        await Future<void>.delayed(const Duration(seconds: 1));
      },
      skip: TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'Cannot set relative timestamp when replaying'
          : false,
    );

    test(
      'remove retention',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_object_remove_retention',
        );
        addTearDown(testClient.endTest);
        final bucketName = await createBucketWithTearDown(
          storage,
          'patch_object_remove_retention',
          enableObjectRetention: true,
        );

        final retainUntilTime = DateTime.now()
            .add(const Duration(seconds: 1))
            .toUtc()
            .toTimestamp();

        await storage.insertObject(
          bucketName,
          'object.txt',
          utf8.encode('content'),
          metadata: ObjectMetadata(
            retention: ObjectRetention(
              mode: 'Unlocked',
              retainUntilTime: retainUntilTime,
            ),
          ),
        );

        final patchMetadata = ObjectMetadataPatchBuilder()..retention = null;
        // Wait for the retention period to expire.
        await Future<void>.delayed(const Duration(seconds: 1));
        final actualMetadata = await storage.patchObject(
          bucketName,
          'object.txt',
          patchMetadata,
        );

        expect(actualMetadata.retention, isNull);
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'Cannot set relative timestamp when replaying'
          : false,
    );

    test('change temporary hold', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_change_temporary_hold',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_change_temporary_hold',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()..temporaryHold = true;

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.temporaryHold, isTrue);
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('no change', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_no_change',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_no_change',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder();

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.metageneration, BigInt.two);
    });

    test('with generation', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_with_generation',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_with_generation',
        metadata: BucketMetadata(versioning: BucketVersioning(enabled: true)),
      );

      final obj1 = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('v1'),
      );
      final obj2 = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('v2'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..metadata = {'version': '1'};

      final patchedMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
        generation: obj1.generation,
      );

      expect(patchedMetadata.generation, obj1.generation);
      expect(patchedMetadata.metadata, {'version': '1'});

      final metadataV2 = await storage.objectMetadata(
        bucketName,
        'object.txt',
        generation: obj2.generation,
      );
      expect(metadataV2.metadata, isNull);
    });

    test('non existant', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_non_existant',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_non_existant',
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      expect(
        () =>
            storage.patchObject(bucketName, 'non-existent.txt', patchMetadata),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('with if metageneration match success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_with_if_metageneration_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_with_if_metageneration_match_success',
      );
      final obj = await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
        ifMetagenerationMatch: obj.metageneration,
      );

      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('with if metageneration match failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_object_with_if_metageneration_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName = await createBucketWithTearDown(
        storage,
        'patch_object_with_if_metageneration_match_failure',
      );
      await storage.insertObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      expect(
        () => storage.patchObject(
          bucketName,
          'object.txt',
          patchMetadata,
          ifMetagenerationMatch: BigInt.zero,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test(
      'with predefined acl',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_object_with_predefined_acl',
        );
        addTearDown(testClient.endTest);
        final bucketName = await createBucketWithTearDown(
          storage,
          'patch_object_with_predefined_acl',
        );
        await storage.insertObject(
          bucketName,
          'object.txt',
          utf8.encode('content'),
        );

        final actualMetadata = await storage.patchObject(
          bucketName,
          'object.txt',
          ObjectMetadataPatchBuilder(),
          predefinedAcl: 'projectPrivate',
          projection: 'full',
        );

        expect(actualMetadata.acl?.first.role, 'OWNER');
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'test project does not support uniform bucket level access',
    );

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"contentType": "text/plain"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      final actualMetadata = await storage.patchObject(
        'bucket',
        'object.txt',
        patchMetadata,
        ifMetagenerationMatch: BigInt.one,
      );
      expect(actualMetadata.contentType, 'text/plain');
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

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..contentType = 'text/plain';

      expect(
        () => storage.patchObject('bucket', 'object.txt', patchMetadata),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
