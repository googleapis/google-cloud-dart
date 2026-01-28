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
import 'package:google_cloud_storage/src/googleapis_converters.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:test/test.dart';

void main() {
  group('toGoogleApisBucket', () {
    test('acl', () {
      final metadata = BucketMetadata(
        acl: [
          BucketAccessControl(
            bucket: 'bucket-name',
            domain: 'domain',
            email: 'email',
            entity: 'user-test',
            id: 'id',
            kind: 'kind',
            projectTeam: ProjectTeam(
              projectNumber: 'projectNumber',
              team: 'team',
            ),
            role: 'READER',
            selfLink: Uri.https('www.googleapis.com', '/storage'),
          ),
        ],
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.acl, hasLength(1));
      final acl = bucket.acl![0];
      expect(acl.bucket, 'bucket-name');
      expect(acl.domain, 'domain');
      expect(acl.email, 'email');
      expect(acl.entity, 'user-test');
      expect(acl.id, 'id');
      expect(acl.kind, 'kind');
      expect(acl.projectTeam?.projectNumber, 'projectNumber');
      expect(acl.projectTeam?.team, 'team');
      expect(acl.role, 'READER');
      expect(acl.selfLink, 'https://www.googleapis.com/storage');
    });

    test('autoclass', () {
      final metadata = BucketMetadata(
        autoclass: BucketAutoclass(
          enabled: true,
          terminalStorageClass: 'ARCHIVE',
          terminalStorageClassUpdateTime: _timestampFromDateTime(
            DateTime.utc(2022, 1, 1),
          ),
          toggleTime: _timestampFromDateTime(DateTime.utc(2022, 2, 2)),
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.autoclass?.enabled, isTrue);
      expect(bucket.autoclass?.terminalStorageClass, 'ARCHIVE');
      expect(
        bucket.autoclass?.terminalStorageClassUpdateTime,
        DateTime.utc(2022, 1, 1),
      );
      expect(bucket.autoclass?.toggleTime, DateTime.utc(2022, 2, 2));
    });

    test('billing', () {
      final metadata = BucketMetadata(
        billing: BucketBilling(requesterPays: true),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.billing?.requesterPays, isTrue);
    });

    test('cors', () {
      final metadata = BucketMetadata(
        cors: [
          BucketCorsConfiguration(
            maxAgeSeconds: 3600,
            method: ['GET'],
            origin: ['*'],
            responseHeader: ['Content-Type'],
          ),
        ],
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.cors, hasLength(1));
      final cors = bucket.cors![0];
      expect(cors.maxAgeSeconds, 3600);
      expect(cors.method, ['GET']);
      expect(cors.origin, ['*']);
      expect(cors.responseHeader, ['Content-Type']);
    });

    test('customPlacementConfig', () {
      final metadata = BucketMetadata(
        customPlacementConfig: BucketCustomPlacementConfig(
          dataLocations: ['US-EAST1'],
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.customPlacementConfig?.dataLocations, ['US-EAST1']);
    });

    test('defaultEventBasedHold', () {
      final metadata = BucketMetadata(defaultEventBasedHold: true);
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.defaultEventBasedHold, isTrue);
    });

    test('defaultObjectAcl', () {
      final metadata = BucketMetadata(
        defaultObjectAcl: [
          ObjectAccessControl(
            bucket: 'bucket-name',
            domain: 'domain',
            email: 'email',
            entity: 'user-test',
            entityId: 'entityId',
            etag: 'etag',
            generation: '1',
            id: 'id',
            kind: 'kind',
            object: 'object',
            projectTeam: ProjectTeam(
              projectNumber: 'projectNumber',
              team: 'team',
            ),
            role: 'READER',
            selfLink: Uri.https('www.googleapis.com', '/storage'),
          ),
        ],
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.defaultObjectAcl, hasLength(1));
      final acl = bucket.defaultObjectAcl![0];
      expect(acl.bucket, 'bucket-name');
      expect(acl.domain, 'domain');
      expect(acl.email, 'email');
      expect(acl.entity, 'user-test');
      expect(acl.entityId, 'entityId');
      expect(acl.etag, 'etag');
      expect(acl.generation, '1');
      expect(acl.id, 'id');
      expect(acl.kind, 'kind');
      expect(acl.object, 'object');
      expect(acl.projectTeam?.projectNumber, 'projectNumber');
      expect(acl.projectTeam?.team, 'team');
      expect(acl.role, 'READER');
      expect(acl.selfLink, 'https://www.googleapis.com/storage');
    });

    test('encryption', () {
      final metadata = BucketMetadata(
        encryption: BucketEncryption(defaultKmsKeyName: 'key-name'),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.encryption?.defaultKmsKeyName, 'key-name');
    });

    test('etag', () {
      final metadata = BucketMetadata(etag: 'etag');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.etag, 'etag');
    });

    test('generation', () {
      final metadata = BucketMetadata(generation: 1);
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.generation, '1');
    });

    test('hardDeleteTime', () {
      final metadata = BucketMetadata(
        hardDeleteTime: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.hardDeleteTime, DateTime.utc(2022, 1, 1));
    });

    test('hierarchicalNamespace', () {
      final metadata = BucketMetadata(
        hierarchicalNamespace: BucketHierarchicalNamespace(enabled: true),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.hierarchicalNamespace?.enabled, isTrue);
    });

    test('iamConfiguration', () {
      final metadata = BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          publicAccessPrevention: 'enforced',
          uniformBucketLevelAccess: UniformBucketLevelAccess(
            enabled: true,
            lockedTime: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
          ),
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.iamConfiguration?.publicAccessPrevention, 'enforced');
      expect(
        bucket.iamConfiguration?.uniformBucketLevelAccess?.enabled,
        isTrue,
      );
      expect(
        bucket.iamConfiguration?.uniformBucketLevelAccess?.lockedTime,
        DateTime.utc(2022, 1, 1),
      );
    });

    test('id', () {
      final metadata = BucketMetadata(id: 'id');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.id, 'id');
    });

    test('ipFilter', () {
      final metadata = BucketMetadata(
        ipFilter: BucketIpFilter(
          allowAllServiceAgentAccess: true,
          allowCrossOrgVpcs: true,
          mode: 'Enabled',
          publicNetworkSource: BucketPublicNetworkSource(
            allowedIpCidrRanges: ['0.0.0.0/0'],
          ),
          vpcNetworkSources: [
            BucketPublicNetworkSource(allowedIpCidrRanges: ['10.0.0.0/8']),
          ],
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.ipFilter?.allowAllServiceAgentAccess, isTrue);
      expect(bucket.ipFilter?.allowCrossOrgVpcs, isTrue);
      expect(bucket.ipFilter?.mode, 'Enabled');
      expect(bucket.ipFilter?.publicNetworkSource?.allowedIpCidrRanges, [
        '0.0.0.0/0',
      ]);
      expect(bucket.ipFilter?.vpcNetworkSources, hasLength(1));
      expect(bucket.ipFilter?.vpcNetworkSources![0].allowedIpCidrRanges, [
        '10.0.0.0/8',
      ]);
    });

    test('kind', () {
      final metadata = BucketMetadata(kind: 'storage#bucket');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.kind, 'storage#bucket');
    });

    test('labels', () {
      final metadata = BucketMetadata(labels: {'key': 'value'});
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.labels, {'key': 'value'});
    });

    test('lifecycle', () {
      final metadata = BucketMetadata(
        lifecycle: Lifecycle(
          rule: [
            LifecycleRule(
              action: LifecycleRuleAction(
                storageClass: 'ARCHIVE',
                type: 'SetStorageClass',
              ),
              condition: LifecycleRuleCondition(
                age: 30,
                createdBefore: DateTime.utc(2022, 1, 1),
                customTimeBefore: DateTime.utc(2022, 2, 2),
                daysSinceCustomTime: 10,
                daysSinceNoncurrentTime: 20,
                isLive: true,
                matchesPrefix: ['prefix'],
                matchesStorageClass: ['STANDARD'],
                matchesSuffix: ['suffix'],
                noncurrentTimeBefore: DateTime.utc(2022, 3, 3),
                numNewerVersions: 3,
              ),
            ),
          ],
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.lifecycle?.rule, hasLength(1));
      final rule = bucket.lifecycle!.rule![0];
      expect(rule.action?.storageClass, 'ARCHIVE');
      expect(rule.action?.type, 'SetStorageClass');
      expect(rule.condition?.age, 30);
      expect(rule.condition?.createdBefore, DateTime.utc(2022, 1, 1));
      expect(rule.condition?.customTimeBefore, DateTime.utc(2022, 2, 2));
      expect(rule.condition?.daysSinceCustomTime, 10);
      expect(rule.condition?.daysSinceNoncurrentTime, 20);
      expect(rule.condition?.isLive, isTrue);
      expect(rule.condition?.matchesPrefix, ['prefix']);
      expect(rule.condition?.matchesStorageClass, ['STANDARD']);
      expect(rule.condition?.matchesSuffix, ['suffix']);
      expect(rule.condition?.noncurrentTimeBefore, DateTime.utc(2022, 3, 3));
      expect(rule.condition?.numNewerVersions, 3);
    });

    test('location', () {
      final metadata = BucketMetadata(location: 'US');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.location, 'US');
    });

    test('locationType', () {
      final metadata = BucketMetadata(locationType: 'multi-region');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.locationType, 'multi-region');
    });

    test('logging', () {
      final metadata = BucketMetadata(
        logging: BucketLoggingConfiguration(
          logBucket: 'log-bucket',
          logObjectPrefix: 'log-prefix',
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.logging?.logBucket, 'log-bucket');
      expect(bucket.logging?.logObjectPrefix, 'log-prefix');
    });

    test('metageneration', () {
      final metadata = BucketMetadata(metageneration: 1);
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.metageneration, '1');
    });

    test('name', () {
      final metadata = BucketMetadata(name: 'bucket-name');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.name, 'bucket-name');
    });

    test('objectRetention', () {
      final metadata = BucketMetadata(
        objectRetention: BucketObjectRetention(mode: 'Enabled'),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.objectRetention?.mode, 'Enabled');
    });

    test('owner', () {
      final metadata = BucketMetadata(
        owner: BucketOwner(entity: 'entity', entityId: 'entityId'),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.owner?.entity, 'entity');
      expect(bucket.owner?.entityId, 'entityId');
    });

    test('projectNumber', () {
      final metadata = BucketMetadata(projectNumber: '123456');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.projectNumber, '123456');
    });

    test('retentionPolicy', () {
      final metadata = BucketMetadata(
        retentionPolicy: BucketRetentionPolicy(
          effectiveTime: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
          isLocked: true,
          retentionPeriod: 3600,
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.retentionPolicy?.effectiveTime, DateTime.utc(2022, 1, 1));
      expect(bucket.retentionPolicy?.isLocked, isTrue);
      expect(bucket.retentionPolicy?.retentionPeriod, '3600');
    });

    test('rpo', () {
      final metadata = BucketMetadata(rpo: 'DEFAULT');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.rpo, 'DEFAULT');
    });

    test('selfLink', () {
      final metadata = BucketMetadata(
        selfLink: Uri.parse('https://www.googleapis.com/storage/v1/b/bucket'),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.selfLink, 'https://www.googleapis.com/storage/v1/b/bucket');
    });

    test('softDeletePolicy', () {
      final metadata = BucketMetadata(
        softDeletePolicy: BucketSoftDeletePolicy(
          effectiveTime: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
          retentionDurationSeconds: 604800,
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.softDeletePolicy?.effectiveTime, DateTime.utc(2022, 1, 1));
      expect(bucket.softDeletePolicy?.retentionDurationSeconds, '604800');
    });

    test('softDeleteTime', () {
      final metadata = BucketMetadata(
        softDeleteTime: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.softDeleteTime, DateTime.utc(2022, 1, 1));
    });

    test('storageClass', () {
      final metadata = BucketMetadata(storageClass: 'STANDARD');
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.storageClass, 'STANDARD');
    });

    test('timeCreated', () {
      final metadata = BucketMetadata(
        timeCreated: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.timeCreated, DateTime.utc(2022, 1, 1));
    });

    test('updated', () {
      final metadata = BucketMetadata(
        updated: _timestampFromDateTime(DateTime.utc(2022, 1, 1)),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.updated, DateTime.utc(2022, 1, 1));
    });

    test('versioning', () {
      final metadata = BucketMetadata(
        versioning: BucketVersioning(enabled: true),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.versioning?.enabled, isTrue);
    });

    test('website', () {
      final metadata = BucketMetadata(
        website: BucketWebsiteConfiguration(
          mainPageSuffix: 'index.html',
          notFoundPage: '404.html',
        ),
      );
      final bucket = toGoogleApisBucket(metadata);
      expect(bucket.website?.mainPageSuffix, 'index.html');
      expect(bucket.website?.notFoundPage, '404.html');
    });
  });
}

Timestamp _timestampFromDateTime(DateTime dateTime) => Timestamp(
  seconds: (dateTime.millisecondsSinceEpoch / 1000).floor(),
  nanos: (dateTime.microsecondsSinceEpoch % 1000000) * 1000,
);
