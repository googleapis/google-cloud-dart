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

import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart' show projectId;

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('create bucket', () {
    setUp(() {
      storage = Storage();
    });

    tearDown(() => storage.close());

    test('create_bucket_with_metadata_name_only', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_name_only',
      );

      final requestMetadata = BucketMetadata(name: bucketName);

      final beforeRequestTime = DateTime.now().toUtc();
      final actualMetadata = await storage.createBucket(requestMetadata);
      final afterRequestTime = DateTime.now().toUtc();

      expect(actualMetadata.acl, isNull);
      expect(actualMetadata.autoclass, isNull);
      expect(actualMetadata.billing, isNull);
      expect(actualMetadata.cors, isNull);
      expect(actualMetadata.customPlacementConfig, isNull);
      expect(actualMetadata.defaultEventBasedHold, isNull);
      expect(actualMetadata.defaultObjectAcl, isNull);
      expect(actualMetadata.encryption, isNull);
      expect(actualMetadata.etag, isNotEmpty);
      expect(actualMetadata.generation, greaterThan(BigInt.zero));
      expect(actualMetadata.hardDeleteTime, isNull);
      expect(actualMetadata.hierarchicalNamespace, isNull);
      expect(actualMetadata.iamConfiguration, isNotNull);
      expect(
        actualMetadata.iamConfiguration!.publicAccessPrevention,
        'inherited',
      );
      expect(
        actualMetadata.iamConfiguration!.uniformBucketLevelAccess!.enabled,
        true,
      );
      expect(
        actualMetadata.iamConfiguration!.uniformBucketLevelAccess!.lockedTime!
            .toDateTime(),
        // Uniform bucket-level access can only be disabled for 90 days
        // after bucket creation.
        actualMetadata.timeCreated?.toDateTime().add(const Duration(days: 90)),
      );
      expect(actualMetadata.id, isNotEmpty);
      expect(actualMetadata.ipFilter, isNull);
      expect(actualMetadata.kind, 'storage#bucket');
      expect(actualMetadata.labels, isNull);
      expect(actualMetadata.lifecycle, isNull);
      expect(actualMetadata.location, 'US');
      expect(actualMetadata.locationType, 'multi-region');
      expect(actualMetadata.logging, isNull);
      expect(actualMetadata.metageneration, BigInt.one);
      expect(actualMetadata.name, bucketName);
      expect(actualMetadata.objectRetention, isNull);
      expect(actualMetadata.owner, isNull);
      expect(actualMetadata.projectNumber, isNotEmpty);
      expect(actualMetadata.retentionPolicy, isNull);
      expect(actualMetadata.rpo, 'DEFAULT');
      expect(
        actualMetadata.selfLink,
        Uri.parse('https://www.googleapis.com/storage/v1/b/$bucketName'),
      );
      expect(actualMetadata.softDeletePolicy, isNotNull);
      expect(
        actualMetadata.softDeletePolicy!.effectiveTime?.toDateTime(),
        actualMetadata.timeCreated?.toDateTime(),
      );
      expect(
        actualMetadata.softDeletePolicy!.retentionDurationSeconds,
        // Default soft delete retention is 7 days.
        const Duration(days: 7).inSeconds,
      );
      expect(actualMetadata.softDeleteTime, isNull);
      expect(actualMetadata.storageClass, 'STANDARD');
      if (Platform.environment['GOOGLE_CLOUD_PROJECT'] == null) {
        expect(
          actualMetadata.timeCreated?.toDateTime().microsecondsSinceEpoch,
          greaterThan(0),
        );
      } else {
        expect(
          actualMetadata.timeCreated?.toDateTime().microsecondsSinceEpoch,
          allOf(
            greaterThanOrEqualTo(beforeRequestTime.microsecondsSinceEpoch),
            lessThanOrEqualTo(afterRequestTime.microsecondsSinceEpoch),
          ),
        );
      }
      expect(
        actualMetadata.updated?.toDateTime(),
        actualMetadata.timeCreated?.toDateTime(),
      );
      expect(actualMetadata.versioning, isNull);
      expect(actualMetadata.website, isNull);
    });

    test('create_bucket_with_metadata_autoclass', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_autoclass',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        autoclass: BucketAutoclass(
          enabled: true,
          terminalStorageClass: 'NEARLINE',
        ),
      );

      final beforeRequestTime = DateTime.now().toUtc();
      final actualMetadata = await storage.createBucket(requestMetadata);
      final afterRequestTime = DateTime.now().toUtc();

      expect(actualMetadata.autoclass!.enabled, true);
      expect(actualMetadata.autoclass!.terminalStorageClass, 'NEARLINE');
      if (Platform.environment['GOOGLE_CLOUD_PROJECT'] == null) {
        expect(
          actualMetadata.autoclass!.terminalStorageClassUpdateTime
              ?.toDateTime()
              .microsecondsSinceEpoch,
          greaterThan(0),
        );
      } else {
        expect(
          actualMetadata.autoclass!.terminalStorageClassUpdateTime
              ?.toDateTime()
              .microsecondsSinceEpoch,
          allOf(
            greaterThanOrEqualTo(beforeRequestTime.microsecondsSinceEpoch),
            lessThanOrEqualTo(afterRequestTime.microsecondsSinceEpoch),
          ),
        );
      }
    });

    test('create_bucket_with_metadata_lifecycle', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_lifecycle',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        lifecycle: Lifecycle(
          rule: [
            LifecycleRule(
              condition: LifecycleRuleCondition(
                createdBefore: DateTime(2025, 12, 11),
              ),
              action: LifecycleRuleAction(type: 'Delete'),
            ),
          ],
        ),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.lifecycle!.rule!.length, 1);
      expect(
        actualMetadata.lifecycle!.rule![0].condition!.createdBefore,
        DateTime(2025, 12, 11),
      );
      expect(actualMetadata.lifecycle!.rule![0].action!.type, 'Delete');
    });

    test('create_bucket_with_metadata_billing', () async {
      final bucketName = testBucketName('crt_bkt_w_meta_billing');

      final requestMetadata = BucketMetadata(
        name: bucketName,
        billing: BucketBilling(requesterPays: true),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      // Manually add teardown with userProject to delete a Requester Pays
      // bucket.
      addTearDown(
        () => storage.deleteBucket(bucketName, userProject: projectId),
      );

      expect(actualMetadata.billing?.requesterPays, isTrue);
    });

    test('create_bucket_with_metadata_cors', () async {
      final bucketName = bucketNameWithTearDown(storage, 'crt_bkt_w_meta_cors');

      final requestMetadata = BucketMetadata(
        name: bucketName,
        cors: [
          BucketCorsConfiguration(
            maxAgeSeconds: 3600,
            method: ['GET'],
            origin: ['*'],
            responseHeader: ['Content-Type'],
          ),
        ],
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.cors, hasLength(1));
      expect(actualMetadata.cors![0].maxAgeSeconds, 3600);
      expect(actualMetadata.cors![0].method, ['GET']);
      expect(actualMetadata.cors![0].origin, ['*']);
      expect(actualMetadata.cors![0].responseHeader, ['Content-Type']);
    });

    test('create_bucket_with_metadata_default_event_based_hold', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_default_evt_bsd_hld',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        defaultEventBasedHold: true,
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.defaultEventBasedHold, isTrue);
    });

    test('create_bucket_with_metadata_iam_configuration', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_iam_configuration',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        iamConfiguration: BucketIamConfiguration(
          publicAccessPrevention: 'enforced',
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: true),
        ),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(
        actualMetadata.iamConfiguration?.publicAccessPrevention,
        'enforced',
      );
      expect(
        actualMetadata.iamConfiguration?.uniformBucketLevelAccess?.enabled,
        isTrue,
      );
    });

    test('create_bucket_with_metadata_labels', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_labels',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        labels: {'key': 'value'},
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.labels, {'key': 'value'});
    });

    test('create_bucket_with_metadata_retention_policy', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_ret_pol',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        retentionPolicy: BucketRetentionPolicy(retentionPeriod: 100),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.retentionPolicy?.retentionPeriod, 100);
      expect(actualMetadata.retentionPolicy?.effectiveTime, isNotNull);
    });

    test('create_bucket_with_metadata_soft_delete_policy', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_sft_del_pol',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        softDeletePolicy: BucketSoftDeletePolicy(
          retentionDurationSeconds: 604800,
        ), // 7 days min
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.softDeletePolicy?.retentionDurationSeconds, 604800);
    });

    test('create_bucket_with_metadata_storage_class', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_stg_class',
      );

      final requestMetadata = BucketMetadata(
        name: bucketName,
        storageClass: 'NEARLINE',
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.storageClass, 'NEARLINE');
    });

    test('create_bucket_with_metadata_versioning', () async {
      final bucketName = bucketNameWithTearDown(storage, 'crt_bkt_w_meta_vers');

      final requestMetadata = BucketMetadata(
        name: bucketName,
        versioning: BucketVersioning(enabled: true),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.versioning?.enabled, isTrue);
    });

    test('create_bucket_with_metadata_website', () async {
      final bucketName = bucketNameWithTearDown(storage, 'crt_bkt_w_meta_web');

      final requestMetadata = BucketMetadata(
        name: bucketName,
        website: BucketWebsiteConfiguration(
          mainPageSuffix: 'index.html',
          notFoundPage: '404.html',
        ),
      );

      final actualMetadata = await storage.createBucket(requestMetadata);

      expect(actualMetadata.website?.mainPageSuffix, 'index.html');
      expect(actualMetadata.website?.notFoundPage, '404.html');
    });

    test(
      'create_bucket_with_metadata_default_retry_transport_failure',
      () async {
        var count = 0;
        final mockClient = MockClient((request) async {
          count++;
          if (count == 1) {
            throw http.ClientException('Some transport failure');
          } else if (count == 2) {
            return http.Response(
              '{"name": "create_bucket_with_metadata_retry"}',
              200,
              headers: {'content-type': 'application/json; charset=UTF-8'},
            );
          } else {
            throw StateError('Unexpected call count: $count');
          }
        });

        final storage = Storage(client: mockClient, projectId: projectId);

        final requestMetadata = BucketMetadata(
          name: 'create_bucket_with_metadata_retry',
        );

        final actualMetadata = await storage.createBucket(requestMetadata);
        expect(actualMetadata.name, 'create_bucket_with_metadata_retry');
      },
    );

    test('create_bucket_with_metadata_default_retry_429', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          return http.Response(
            '{"error":{"code":429,"message":"Too many requests.","errors":[]}}',
            429, // Too many requests
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else if (count == 2) {
          return http.Response(
            '{"name": "create_bucket_with_metadata_retry"}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final requestMetadata = BucketMetadata(
        name: 'create_bucket_with_metadata_retry',
      );

      final actualMetadata = await storage.createBucket(requestMetadata);
      expect(actualMetadata.name, 'create_bucket_with_metadata_retry');
    });

    test('create_bucket_with_metadata_duplicate', () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'crt_bkt_w_meta_duplicate',
      );

      final requestMetadata = BucketMetadata(name: bucketName);

      await storage.createBucket(requestMetadata);
      expect(
        () => storage.createBucket(requestMetadata),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.status?.code,
            'e.status?.code',
            409,
          ),
        ),
      );
    });
  });
}
