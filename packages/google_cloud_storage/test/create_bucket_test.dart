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

import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
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

  group('create bucket', () {
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

    test('create_bucket_with_metadata_name_only', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'create_bucket_with_metadata_name_only',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'create_bucket_with_metadata_name_only'
          : uniqueBucketName();

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
      expect(actualMetadata.generation, greaterThan(0));
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
      expect(actualMetadata.metageneration, 1);
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
      if (TestHttpClient.isReplaying) {
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

    test('create_bucket_with_metadata_lifecycle', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'create_bucket_with_metadata_lifecycle',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'create_bucket_with_metadata_lifecycle'
          : uniqueBucketName();

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

    test('create_bucket_with_metadata_duplicate', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'create_bucket_with_metadata_duplicate',
      );
      addTearDown(testClient.endTest);
      final bucketName =
          TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? 'create_bucket_with_metadata_duplicate'
          : uniqueBucketName();

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
