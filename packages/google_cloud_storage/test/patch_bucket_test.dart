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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('patch bucket', () {
    setUp(() {
      storage = Storage();
    });

    tearDown(() => storage.close());

    test(
      'change acl',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_acl');

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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'not supported by test project (UBLA)',
    );

    test(
      'remove acl',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_remove_acl',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'not supported by test project (UBLA)',
    );

    test('change autoclass', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_chg_autoclass',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove autoclass', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_autoclass',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change cors', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_cors');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove cors', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_remove_cors');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test(
      'change hierarchical namespace',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_chg_hierarchical_namespace',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'not supported by test project (UBLA)',
    );

    test(
      'remove hierarchical namespace',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_remove_hierarchical_namespace',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'not supported by test project (UBLA)',
    );

    test(
      'change ip filter',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_chg_ip_filter',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'requires storage.buckets.setIpFilter permission',
    );

    test(
      'remove ip filter',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_remove_ip_filter',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'requires storage.buckets.setIpFilter permission',
    );

    test('change labels', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_labels');

      await storage.createBucket(
        BucketMetadata(
          name: bucketName,
          labels: {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'},
        ),
      );

      final patchMetadata = BucketMetadataPatchBuilder()
        ..labels = {'key1': 'newvalue1', 'key2': null};

      final actualMetadata = await storage.patchBucket(
        bucketName,
        patchMetadata,
      );

      expect(actualMetadata.labels, {'key1': 'newvalue1', 'key3': 'value3'});
      expect(
        actualMetadata.updated!.toDateTime().isAfter(
          actualMetadata.timeCreated!.toDateTime(),
        ),
        isTrue,
      );
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove labels', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_labels',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change lifecycle', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_chg_lifecycle',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove lifecycle', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_lifecycle',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change logging', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_logging');

      // Need a bucket to log to.
      final logBucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_chg_logging_logs',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove logging', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_logging',
      );

      // Need a bucket to log to.
      final logBucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_logging_logs',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change retention policy', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_ret_pol');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove retention policy', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_remove_ret_pol',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change soft delete policy', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_chg_sft_del_pol',
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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change versioning', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_vers');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('same versioning', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_same_vers');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove versioning', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_remove_vers');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('change website', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_chg_web');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('remove website', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'pch_bkt_remove_web');

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
      expect(actualMetadata.metageneration, BigInt.from(2));
    });

    test('no change', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'pch_bkt_w_meta_empty_meta',
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
      expect(actualMetadata.metageneration, BigInt.one);
    });

    test('non existant', tags: ['google-cloud'], () async {
      final patchMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

      expect(
        () => storage.patchBucket('non_existant_bucket', patchMetadata),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'with if metageneration match success',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_w_if_mgen_match_ok',
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
        expect(patchedMetadata.metageneration, BigInt.from(2));
      },
    );

    test(
      'with if metageneration match failure',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_w_if_mgen_match_fail',
        );

        await storage.createBucket(BucketMetadata(name: bucketName));

        var patchMetadata = BucketMetadataPatchBuilder()
          ..versioning = BucketVersioning(enabled: true);
        expect(
          () => storage.patchBucket(
            bucketName,
            patchMetadata,
            ifMetagenerationMatch: BigInt.zero,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      },
    );

    test(
      'with predefined acl',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_w_predefined_acl',
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
        expect(actualMetadata.metageneration, BigInt.from(2));
      },
      skip: 'test project does not support uniform bucket level access',
    );

    test(
      'with predefined default object acl',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'pch_bkt_w_predefined_default_obj_acl',
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
        ifMetagenerationMatch: BigInt.one,
      );
      expect(actualMetadata.versioning?.enabled, isTrue);
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

      final requestMetadata = BucketMetadataPatchBuilder()
        ..versioning = BucketVersioning(enabled: true);

      expect(
        () => storage.patchBucket('bucket', requestMetadata),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
