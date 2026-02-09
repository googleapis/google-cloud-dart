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

import 'package:google_cloud_protobuf/protobuf.dart';
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

    test('change acl', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_acl',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_acl',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          acl: [BucketAccessControl(role: 'READER', entity: 'allUsers')],
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..acl = [BucketAccessControl(role: 'OWNER', entity: 'allUsers')];

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.acl?.first.role, 'OWNER');
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    }, skip: 'not supported by test project (UBLA)');

    test('remove acl', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_acl',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_acl',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          acl: [BucketAccessControl(role: 'READER', entity: 'allUsers')],
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..acl = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.acl, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    }, skip: 'not supported by test project (UBLA)');

    test('change autoclass', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_autoclass',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_autoclass',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          autoclass: BucketAutoclass(enabled: true),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..autoclass = BucketAutoclass(enabled: false);

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.autoclass?.enabled, isFalse);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove autoclass', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_autoclass',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_autoclass',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          autoclass: BucketAutoclass(enabled: false),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..autoclass = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.autoclass, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change cors', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_cors',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_cors',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          cors: [BucketCorsConfiguration(maxAgeSeconds: 3600)],
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..cors = [BucketCorsConfiguration(maxAgeSeconds: 7200)];

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.cors?.first.maxAgeSeconds, 7200);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove cors', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_cors',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_cors',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          cors: [BucketCorsConfiguration(maxAgeSeconds: 3600)],
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..cors = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.cors, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test(
      'change hierarchical namespace',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_change_hierarchical_namespace',
        );
        addTearDown(testClient.endTest);
        final bucketName = bucketNameWithTearDown(
          storage,
          'patch_bucket_change_hierarchical_namespace',
        );

        await storage.createBucket(
          BucketMetadata(
            name: bucketName,
            hierarchicalNamespace: BucketHierarchicalNamespace(enabled: true),
          ),
        );

        final patchMetadata = BucketMetadataPatchBuilder()
          ..hierarchicalNamespace = BucketHierarchicalNamespace(enabled: false);

        final actualMetadata = await storage.patchBucket(
          bucketName,
          patchMetadata,
        );

        expect(actualMetadata.hierarchicalNamespace?.enabled, isFalse);
        expect(
          actualMetadata.updated!.toDateTime().isAfter(
            actualMetadata.timeCreated!.toDateTime(),
          ),
          isTrue,
        );
        expect(actualMetadata.metageneration, 2);
      },
      skip: 'not supported by test project (UBLA)',
    );

    test(
      'remove hierarchical namespace',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_remove_hierarchical_namespace',
        );
        addTearDown(testClient.endTest);
        final bucketName = bucketNameWithTearDown(
          storage,
          'patch_bucket_remove_hierarchical_namespace',
        );

        await storage.createBucket(
          BucketMetadata(
            name: bucketName,
            hierarchicalNamespace: BucketHierarchicalNamespace(enabled: true),
          ),
        );

        final patchMetadata = BucketMetadataPatchBuilder()
          ..hierarchicalNamespace = null;

        final actualMetadata = await storage.patchBucket(
          bucketName,
          patchMetadata,
        );

        expect(actualMetadata.hierarchicalNamespace, isNull);
        expect(
          actualMetadata.updated!.toDateTime().isAfter(
            actualMetadata.timeCreated!.toDateTime(),
          ),
          isTrue,
        );
        expect(actualMetadata.metageneration, 2);
      },
      skip: 'not supported by test project (UBLA)',
    );

    test('change ip filter', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_ip_filter',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_ip_filter',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          ipFilter: BucketIpFilter(
            mode: 'Enabled',
            allowAllServiceAgentAccess: false,
            publicNetworkSource: BucketPublicNetworkSource(
              allowedIpCidrRanges: ['0.0.0.0/0'],
            ),
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..ipFilter = BucketIpFilter(mode: 'Disabled');

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.ipFilter?.mode, 'Disabled');
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    }, skip: 'requires storage.buckets.setIpFilter permission');

    test('remove ip filter', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_ip_filter',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_ip_filter',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          ipFilter: BucketIpFilter(
            mode: 'Enabled',
            allowAllServiceAgentAccess: false,
            publicNetworkSource: BucketPublicNetworkSource(
              allowedIpCidrRanges: ['0.0.0.0/0'],
            ),
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..ipFilter = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.ipFilter, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    }, skip: 'requires storage.buckets.setIpFilter permission');

    test('change labels', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_labels',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_labels',
      );

      await storage.createBucket(
        BucketMetadata(name: bucketName, labels: {'key': 'value'}),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..labels = {'key': 'newvalue'};

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.labels, {'key': 'newvalue'});
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove labels', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_labels',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_labels',
      );

      await storage.createBucket(
        BucketMetadata(name: bucketName, labels: {'key': 'value'}),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..labels = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.labels, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change lifecycle', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_lifecycle',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_lifecycle',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          lifecycle: Lifecycle(
            rule: [
              LifecycleRule(
                action: LifecycleRuleAction(type: 'Delete'),
                condition: LifecycleRuleCondition(age: 1),
              ),
            ],
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..lifecycle = Lifecycle(
          rule: [
            LifecycleRule(
              action: LifecycleRuleAction(type: 'Delete'),
              condition: LifecycleRuleCondition(age: 2),
            ),
          ],
        );

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.lifecycle?.rule?.first.condition?.age, 2);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove lifecycle', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_lifecycle',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_lifecycle',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          lifecycle: Lifecycle(
            rule: [
              LifecycleRule(
                action: LifecycleRuleAction(type: 'Delete'),
                condition: LifecycleRuleCondition(age: 1),
              ),
            ],
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..lifecycle = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.lifecycle, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change logging', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_logging',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_logging',
      );

      // Need a bucket to log to.
      final logBucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_logging_logs',
      );

      await storage.createBucket(BucketMetadata(name: logBucketName));

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          logging: BucketLoggingConfiguration(
            logBucket: logBucketName,
            logObjectPrefix: 'prefix',
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..logging = BucketLoggingConfiguration(
          logBucket: logBucketName,
          logObjectPrefix: 'new-prefix',
        );

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.logging?.logObjectPrefix, 'new-prefix');
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove logging', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_logging',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_logging',
      );

      // Need a bucket to log to.
      final logBucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_logging_logs',
      );

      await storage.createBucket(BucketMetadata(name: logBucketName));

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          logging: BucketLoggingConfiguration(
            logBucket: logBucketName,
            logObjectPrefix: 'prefix',
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..logging = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.logging, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change retention policy', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_retention_policy',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_retention_policy',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          retentionPolicy: BucketRetentionPolicy(retentionPeriod: 10),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..retentionPolicy = BucketRetentionPolicy(retentionPeriod: 20);

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.retentionPolicy?.retentionPeriod, 20);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove retention policy', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_retention_policy',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_retention_policy',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          retentionPolicy: BucketRetentionPolicy(retentionPeriod: 10),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..retentionPolicy = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.retentionPolicy, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change soft delete policy', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_soft_delete_policy',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_soft_delete_policy',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          softDeletePolicy: BucketSoftDeletePolicy(
            retentionDurationSeconds: 604800,
          ),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..softDeletePolicy = BucketSoftDeletePolicy(
          retentionDurationSeconds: 604800 * 2,
        );

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(
        actualMetadata.softDeletePolicy?.retentionDurationSeconds,
        604800 * 2,
      );
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change versioning', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_versioning',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_versioning',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          versioning: BucketVersioning(enabled: true),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: false);

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.versioning?.enabled, isFalse);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('same versioning', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_same_versioning',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_same_versioning',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          versioning: BucketVersioning(enabled: true),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

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

    test('remove versioning', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_versioning',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_versioning',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          versioning: BucketVersioning(enabled: true),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..versioning = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.versioning, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('change website', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_change_website',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_change_website',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          website: BucketWebsiteConfiguration(mainPageSuffix: 'index.html'),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..website = BucketWebsiteConfiguration(mainPageSuffix: 'home.html');

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.website?.mainPageSuffix, 'home.html');
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('remove website', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_remove_website',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_remove_website',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          website: BucketWebsiteConfiguration(mainPageSuffix: 'index.html'),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()..website = null;

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.website, isNull);
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, 2);
    });

    test('no change', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_metadata_empty_metadata',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_with_metadata_empty_metadata',
      );

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          versioning: BucketVersioning(enabled: true),
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder();

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.versioning?.enabled, isTrue);
      expect(
        actualMetadata.updated?.toDateTime(),
        actualMetadata.timeCreated?.toDateTime(),
      );
      expect(actualMetadata.metageneration, 1);
    });

    test('non existant', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_non_existant',
      );
      addTearDown(testClient.endTest);

      final patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

      expect(
        () => storage.patchBucket('non_existant_bucket', patchMetadata),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('with if metageneration match success', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_if_metageneration_match_success',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_with_if_metageneration_match_success',
      );

      final requestMetadata = BucketMetadata(name: bucketName);
      final createdMetadata = await storage.createBucket(requestMetadata);
      final metageneration = createdMetadata.metageneration;

      var patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);
      final patchedMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
        ifMetagenerationMatch: metageneration,
      );
      expect(patchedMetadata.metageneration, 2);
    });

    test('with if metageneration match failure', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'patch_bucket_with_if_metageneration_match_failure',
      );
      addTearDown(testClient.endTest);
      final bucketName = bucketNameWithTearDown(
        storage,
        'patch_bucket_with_if_metageneration_match_failure',
      );

      await storage.createBucket(BucketMetadata(name: bucketName));

      var patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);
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
      'with predefined acl',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_with_predefined_acl',
        );
        addTearDown(testClient.endTest);
        final bucketName = bucketNameWithTearDown(
          storage,
          'patch_bucket_with_predefined_acl',
        );

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
          BucketMetadataPatchBuilder(),
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
      'with predefined default object acl',
      () async {
        await testClient.startTest(
          'google_cloud_storage',
          'patch_bucket_with_predefined_default_object_acl',
        );
        addTearDown(testClient.endTest);
        final bucketName = bucketNameWithTearDown(
          storage,
          'patch_bucket_with_predefined_default_object_acl',
        );

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
          BucketMetadataPatchBuilder(),
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

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"versioning": {"enabled": true}}',
            200,
            headers: {'content-type': 'application/json; charset=UTF-8'},
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      final requestMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

      final actualMetadata = await storage.patchBucket(
        'bucket',
        requestMetadata,
        ifMetagenerationMatch: 1,
      );
      expect(actualMetadata.versioning?.enabled, isTrue);
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

      final requestMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

      expect(
        () => storage.patchBucket('bucket', requestMetadata),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
