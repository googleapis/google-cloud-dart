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

import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_protobuf/protobuf.dart' hide Duration;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;
  late http.Client client;

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

      client = await authClient();
      storage = Storage(client: client, projectId: projectId);
    });

    tearDown(() => storage.close());

    test('change acl', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_acl',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_acl',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cch_ctrl',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cch_ctrl',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cnt_disp',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_cnt_disp',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cnt_enc',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_cnt_enc',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cnt_lang',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_cnt_lang',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cnt_typ',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_cnt_typ',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_cust_tm',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_evt_bsd_hld',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_evt_bsd_hld',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_meta',
      );
      await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('content'),
        metadata: ObjectMetadata(
          metadata: {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'},
        ),
      );

      final patchMetadata = ObjectMetadataPatchBuilder()
        ..metadata = {'key1': 'newvalue1', 'key2': null};

      final actualMetadata = await storage.patchObject(
        bucketName,
        'object.txt',
        patchMetadata,
      );

      expect(actualMetadata.metadata, {'key1': 'newvalue1', 'key3': 'value3'});
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove metadata', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_meta',
      );
      await storage.uploadObject(
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
        final bucketName = await createBucketWithTearDown(
          storage,
          'pch_obj_chg_ret',
          enableObjectRetention: true,
        );

        await storage.uploadObject(
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
      skip: Platform.environment['GOOGLE_CLOUD_PROJECT'] == null
          ? 'Cannot set relative timestamp when replaying'
          : false,
    );

    test('remove retention', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_remove_ret',
        enableObjectRetention: true,
      );

      final retainUntilTime = DateTime.now()
          .add(const Duration(seconds: 1))
          .toUtc()
          .toTimestamp();

      await storage.uploadObject(
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
    });

    test('change temporary hold', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_chg_tmp_hld',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_no_chg',
      );
      await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_w_gen',
        metadata: BucketMetadata(versioning: BucketVersioning(enabled: true)),
      );

      final obj1 = await storage.uploadObject(
        bucketName,
        'object.txt',
        utf8.encode('v1'),
      );
      final obj2 = await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_non_existant',
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_w_if_mgen_match_ok',
      );
      final obj = await storage.uploadObject(
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
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_w_if_mgen_match_fail',
      );
      await storage.uploadObject(
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

    test('with if generation match success', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_w_if_gen_match_ok',
      );
      final obj = await storage.uploadObject(
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
        ifGenerationMatch: obj.generation,
      );

      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('with if generation match failure', () async {
      final bucketName = await createBucketWithTearDown(
        storage,
        'pch_obj_w_if_gen_match_fail',
      );
      final obj = await storage.uploadObject(
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
          ifGenerationMatch: obj.generation! + BigInt.one,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });

    test(
      'with predefined acl',
      () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'pch_obj_w_predefined_acl',
        );
        await storage.uploadObject(
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
