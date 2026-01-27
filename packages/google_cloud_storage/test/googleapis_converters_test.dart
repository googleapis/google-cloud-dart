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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis/storage/v1.dart' as storage;

import 'package:test/test.dart';

import '../lib/src/googleapis_converters.dart';

void main() {
  group('BucketMetadata Converters', () {
    test('toBucket', () {
      final metadata = BucketMetadata(
        id: 'bucket-id',
        name: 'bucket-name',
        location: 'US',
        storageClass: 'STANDARD',
        autoclass: BucketAutoclass(
          enabled: true,
          terminalStorageClass: 'ARCHIVE',
        ),
        billing: BucketBilling(requesterPays: true),
        cors: [
          BucketCorsConfiguration(
            maxAgeSeconds: 3600,
            method: ['GET'],
            origin: ['*'],
            responseHeader: ['Content-Type'],
          ),
        ],
        customPlacementConfig: BucketCustomPlacementConfig(
          dataLocations: ['US-EAST1', 'US-WEST1'],
        ),
        defaultEventBasedHold: true,
        defaultObjectAcl: [
          ObjectAccessControl(entity: 'user-test', role: 'READER'),
        ],
        encryption: BucketEncryption(defaultKmsKeyName: 'key-name'),
        iamConfiguration: BucketIamConfiguration(
          publicAccessPrevention: 'enforced',
          uniformBucketLevelAccess: UniformBucketLevelAccess(
            enabled: true,
            lockedTime: Timestamp(seconds: 1600000000, nanos: 0),
          ),
        ),
        ipFilter: BucketIpFilter(
          mode: 'Enabled',
          publicNetworkSource: BucketPublicNetworkSource(
            allowedIpCidrRanges: ['0.0.0.0/0'],
          ),
        ),
        labels: {'env': 'prod'},
        lifecycle: Lifecycle(
          rule: [
            LifecycleRule(
              action: LifecycleRuleAction(type: 'Delete'),
              condition: LifecycleRuleCondition(age: 365),
            ),
          ],
        ),
        logging: BucketLoggingConfiguration(
          logBucket: 'log-bucket',
          logObjectPrefix: 'logs/',
        ),
        objectRetention: BucketObjectRetention(mode: 'Enabled'),
        owner: BucketOwner(entity: 'project-owner', entityId: 'owner-id'),
        retentionPolicy: BucketRetentionPolicy(
          retentionPeriod: 100,
          isLocked: true,
        ),
        rpo: 'ASYNC_TURBO',
        softDeletePolicy: BucketSoftDeletePolicy(
          retentionDurationSeconds: 604800,
        ),
        versioning: BucketVersioning(enabled: true),
        website: BucketWebsiteConfiguration(
          mainPageSuffix: 'index.html',
          notFoundPage: '404.html',
        ),
      );

      final bucket = toGoogleApisBucket(metadata);

      expect(bucket.id, 'bucket-id');
      expect(bucket.name, 'bucket-name');
      expect(bucket.location, 'US');
      expect(bucket.storageClass, 'STANDARD');
      expect(bucket.autoclass?.enabled, isTrue);
      expect(bucket.autoclass?.terminalStorageClass, 'ARCHIVE');
      expect(bucket.billing?.requesterPays, isTrue);
      expect(bucket.cors, hasLength(1));
      expect(bucket.cors![0].maxAgeSeconds, 3600);
      expect(bucket.customPlacementConfig?.dataLocations, [
        'US-EAST1',
        'US-WEST1',
      ]);
      expect(bucket.defaultEventBasedHold, isTrue);
      expect(bucket.defaultObjectAcl, hasLength(1));
      expect(bucket.defaultObjectAcl![0].entity, 'user-test');
      expect(bucket.encryption?.defaultKmsKeyName, 'key-name');
      expect(bucket.iamConfiguration?.publicAccessPrevention, 'enforced');
      expect(
        bucket.iamConfiguration?.uniformBucketLevelAccess?.enabled,
        isTrue,
      );
      expect(
        bucket.iamConfiguration?.uniformBucketLevelAccess?.lockedTime,
        isNotNull,
      );
      expect(bucket.ipFilter?.mode, 'Enabled');
      expect(bucket.labels, {'env': 'prod'});
      expect(bucket.lifecycle?.rule, hasLength(1));
      expect(bucket.lifecycle?.rule![0].action?.type, 'Delete');
      expect(bucket.logging?.logBucket, 'log-bucket');
      expect(bucket.objectRetention?.mode, 'Enabled');
      expect(bucket.owner?.entity, 'project-owner');
      expect(bucket.retentionPolicy?.retentionPeriod, '100');
      expect(bucket.rpo, 'ASYNC_TURBO');
      expect(bucket.softDeletePolicy?.retentionDurationSeconds, '604800');
      expect(bucket.versioning?.enabled, isTrue);
      expect(bucket.website?.mainPageSuffix, 'index.html');
    });

    test('fromBucket', () {
      final bucket = storage.Bucket(
        id: 'bucket-id',
        name: 'bucket-name',
        location: 'US',
        storageClass: 'STANDARD',
        autoclass: storage.BucketAutoclass(
          enabled: true,
          terminalStorageClass: 'ARCHIVE',
        ),
        billing: storage.BucketBilling(requesterPays: true),
        cors: [
          storage.BucketCors(
            maxAgeSeconds: 3600,
            method: ['GET'],
            origin: ['*'],
            responseHeader: ['Content-Type'],
          ),
        ],
        customPlacementConfig: storage.BucketCustomPlacementConfig(
          dataLocations: ['US-EAST1', 'US-WEST1'],
        ),
        defaultEventBasedHold: true,
        defaultObjectAcl: [
          storage.ObjectAccessControl(entity: 'user-test', role: 'READER'),
        ],
        encryption: storage.BucketEncryption(defaultKmsKeyName: 'key-name'),
        iamConfiguration: storage.BucketIamConfiguration(
          publicAccessPrevention: 'enforced',
          uniformBucketLevelAccess:
              storage.BucketIamConfigurationUniformBucketLevelAccess(
                enabled: true,
                lockedTime: DateTime.fromMillisecondsSinceEpoch(
                  1600000000000,
                  isUtc: true,
                ),
              ),
        ),
        ipFilter: storage.BucketIpFilter(
          mode: 'Enabled',
          publicNetworkSource: storage.BucketIpFilterPublicNetworkSource(
            allowedIpCidrRanges: ['0.0.0.0/0'],
          ),
        ),
        labels: {'env': 'prod'},
        lifecycle: storage.BucketLifecycle(
          rule: [
            storage.BucketLifecycleRule(
              action: storage.BucketLifecycleRuleAction(type: 'Delete'),
              condition: storage.BucketLifecycleRuleCondition(age: 365),
            ),
          ],
        ),
        logging: storage.BucketLogging(
          logBucket: 'log-bucket',
          logObjectPrefix: 'logs/',
        ),
        objectRetention: storage.BucketObjectRetention(mode: 'Enabled'),
        owner: storage.BucketOwner(
          entity: 'project-owner',
          entityId: 'owner-id',
        ),
        retentionPolicy: storage.BucketRetentionPolicy(
          retentionPeriod: '100',
          isLocked: true,
        ),
        rpo: 'ASYNC_TURBO',
        softDeletePolicy: storage.BucketSoftDeletePolicy(
          retentionDurationSeconds: '604800',
        ),
        versioning: storage.BucketVersioning(enabled: true),
        website: storage.BucketWebsite(
          mainPageSuffix: 'index.html',
          notFoundPage: '404.html',
        ),
      );

      final metadata = fromGoogleApisBucket(bucket);

      expect(metadata.id, 'bucket-id');
      expect(metadata.name, 'bucket-name');
      expect(metadata.location, 'US');
      expect(metadata.storageClass, 'STANDARD');
      expect(metadata.autoclass?.enabled, isTrue);
      expect(metadata.autoclass?.terminalStorageClass, 'ARCHIVE');
      expect(metadata.billing?.requesterPays, isTrue);
      expect(metadata.cors, hasLength(1));
      expect(metadata.cors![0].maxAgeSeconds, 3600);
      expect(metadata.customPlacementConfig?.dataLocations, [
        'US-EAST1',
        'US-WEST1',
      ]);
      expect(metadata.defaultEventBasedHold, isTrue);
      expect(metadata.defaultObjectAcl, hasLength(1));
      expect(metadata.defaultObjectAcl![0].entity, 'user-test');
      expect(metadata.encryption?.defaultKmsKeyName, 'key-name');
      expect(metadata.iamConfiguration?.publicAccessPrevention, 'enforced');
      expect(
        metadata.iamConfiguration?.uniformBucketLevelAccess?.enabled,
        isTrue,
      );
      expect(
        metadata.iamConfiguration?.uniformBucketLevelAccess?.lockedTime,
        isNotNull,
      );
      expect(metadata.ipFilter?.mode, 'Enabled');
      expect(metadata.labels, {'env': 'prod'});
      expect(metadata.lifecycle?.rule, hasLength(1));
      expect(metadata.lifecycle?.rule![0].action?.type, 'Delete');
      expect(metadata.logging?.logBucket, 'log-bucket');
      expect(metadata.objectRetention?.mode, 'Enabled');
      expect(metadata.owner?.entity, 'project-owner');
      expect(metadata.retentionPolicy?.retentionPeriod, 100);
      expect(metadata.rpo, 'ASYNC_TURBO');
      expect(metadata.softDeletePolicy?.retentionDurationSeconds, 604800);
      expect(metadata.versioning?.enabled, isTrue);
      expect(metadata.website?.mainPageSuffix, 'index.html');
    });

    test('fromBucket with partial timestamps', () {
      final bucket = storage.Bucket(
        id: 'bucket-id',
        timeCreated: DateTime.fromMillisecondsSinceEpoch(
          1600000000000,
          isUtc: true,
        ),
        updated: DateTime.fromMillisecondsSinceEpoch(
          1600000000000,
          isUtc: true,
        ),
      );
      final metadata = fromGoogleApisBucket(bucket);
      expect(metadata.timeCreated?.seconds, 1600000000);
      expect(metadata.updated?.seconds, 1600000000);
    });

    test('toBucket with partial timestamps', () {
      final metadata = BucketMetadata(
        id: 'bucket-id',
        timeCreated: Timestamp(seconds: 1600000000, nanos: 0),
        updated: Timestamp(seconds: 1600000000, nanos: 0),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.timeCreated?.isUtc, isTrue);
      expect(bucket.timeCreated?.year, 2020);
      expect(bucket.updated?.isUtc, isTrue);
    });
  });
}
