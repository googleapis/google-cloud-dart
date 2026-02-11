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
import 'package:google_cloud_storage/src/bucket_metadata.dart';
import 'package:google_cloud_storage/src/bucket_metadata_json.dart';
import 'package:google_cloud_storage/src/object_metadata.dart';
import 'package:google_cloud_storage/src/project_team.dart';
import 'package:test/test.dart';

void main() {
  group('bucketMetadataToJson', () {
    group('acl', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            acl: [
              BucketAccessControl(
                bucket: 'bucket',
                domain: 'domain',
                email: 'email',
                entity: 'entity',
                entityId: 'entityId',
                etag: 'etag',
                id: 'id',
                kind: 'kind',
                projectTeam: ProjectTeam(
                  projectNumber: 'projectNumber',
                  team: 'team',
                ),
                role: 'role',
                selfLink: Uri.parse('http://example.com/selfLink'),
              ),
            ],
          ),
        );
        expect(json['acl'], [
          {
            'bucket': 'bucket',
            'domain': 'domain',
            'email': 'email',
            'entity': 'entity',
            'entityId': 'entityId',
            'etag': 'etag',
            'id': 'id',
            'kind': 'kind',
            'projectTeam': {'projectNumber': 'projectNumber', 'team': 'team'},
            'role': 'role',
            'selfLink': 'http://example.com/selfLink',
          },
        ]);
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'acl': [
            {
              'bucket': 'bucket',
              'domain': 'domain',
              'email': 'email',
              'entity': 'entity',
              'entityId': 'entityId',
              'etag': 'etag',
              'id': 'id',
              'kind': 'kind',
              'projectTeam': {'projectNumber': 'projectNumber', 'team': 'team'},
              'role': 'role',
              'selfLink': 'http://example.com/selfLink',
            },
          ],
        });
        final acl = metadata.acl!.first;
        expect(acl.bucket, 'bucket');
        expect(acl.domain, 'domain');
        expect(acl.email, 'email');
        expect(acl.entity, 'entity');
        expect(acl.entityId, 'entityId');
        expect(acl.etag, 'etag');
        expect(acl.id, 'id');
        expect(acl.kind, 'kind');
        expect(acl.projectTeam?.projectNumber, 'projectNumber');
        expect(acl.projectTeam?.team, 'team');
        expect(acl.role, 'role');
        expect(acl.selfLink, Uri.parse('http://example.com/selfLink'));
      });
    });

    group('autoclass', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            autoclass: BucketAutoclass(
              enabled: true,
              terminalStorageClass: 'NEARLINE',
              terminalStorageClassUpdateTime: Timestamp(
                seconds: 1000,
                nanos: 0,
              ),
              toggleTime: Timestamp(seconds: 2000, nanos: 0),
            ),
          ),
        );
        expect(json['autoclass'], {
          'enabled': true,
          'terminalStorageClass': 'NEARLINE',
          'terminalStorageClassUpdateTime': '1970-01-01T00:16:40Z',
          'toggleTime': '1970-01-01T00:33:20Z',
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'autoclass': {
            'enabled': true,
            'terminalStorageClass': 'NEARLINE',
            'terminalStorageClassUpdateTime': '1970-01-01T00:16:40Z',
            'toggleTime': '1970-01-01T00:33:20Z',
          },
        });
        expect(metadata.autoclass?.enabled, true);
        expect(metadata.autoclass?.terminalStorageClass, 'NEARLINE');
        expect(
          metadata.autoclass?.terminalStorageClassUpdateTime?.seconds,
          1000,
        );
        expect(metadata.autoclass?.toggleTime?.seconds, 2000);
      });
    });

    group('billing', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(billing: BucketBilling(requesterPays: true)),
        );
        expect(json['billing'], {'requesterPays': true});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'billing': {'requesterPays': true},
        });
        expect(metadata.billing?.requesterPays, true);
      });
    });

    group('cors', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            cors: [
              BucketCorsConfiguration(
                maxAgeSeconds: 3600,
                method: ['GET'],
                origin: ['*'],
                responseHeader: ['Content-Type'],
              ),
            ],
          ),
        );
        expect(json['cors'], [
          {
            'maxAgeSeconds': 3600,
            'method': ['GET'],
            'origin': ['*'],
            'responseHeader': ['Content-Type'],
          },
        ]);
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'cors': [
            {
              'maxAgeSeconds': 3600,
              'method': ['GET'],
              'origin': ['*'],
              'responseHeader': ['Content-Type'],
            },
          ],
        });
        final cors = metadata.cors!.first;
        expect(cors.maxAgeSeconds, 3600);
        expect(cors.method, ['GET']);
        expect(cors.origin, ['*']);
        expect(cors.responseHeader, ['Content-Type']);
      });
    });

    group('customPlacementConfig', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            customPlacementConfig: BucketCustomPlacementConfig(
              dataLocations: ['US-EAST1'],
            ),
          ),
        );
        expect(json['customPlacementConfig'], {
          'dataLocations': ['US-EAST1'],
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'customPlacementConfig': {
            'dataLocations': ['US-EAST1'],
          },
        });
        expect(metadata.customPlacementConfig?.dataLocations, ['US-EAST1']);
      });
    });

    group('defaultEventBasedHold', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(defaultEventBasedHold: true),
        );
        expect(json['defaultEventBasedHold'], true);
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'defaultEventBasedHold': true,
        });
        expect(metadata.defaultEventBasedHold, true);
      });
    });

    group('defaultObjectAcl', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            defaultObjectAcl: [
              ObjectAccessControl(entity: 'user-1', role: 'READER'),
            ],
          ),
        );
        expect(json['defaultObjectAcl'], [
          {'entity': 'user-1', 'role': 'READER'},
        ]);
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'defaultObjectAcl': [
            {'entity': 'user-1', 'role': 'READER'},
          ],
        });
        expect(metadata.defaultObjectAcl?.first.entity, 'user-1');
        expect(metadata.defaultObjectAcl?.first.role, 'READER');
      });
    });

    group('encryption', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            encryption: BucketEncryption(defaultKmsKeyName: 'key1'),
          ),
        );
        expect(json['encryption'], {'defaultKmsKeyName': 'key1'});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'encryption': {'defaultKmsKeyName': 'key1'},
        });
        expect(metadata.encryption?.defaultKmsKeyName, 'key1');
      });
    });

    group('etag', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(etag: 'etag'));
        expect(json['etag'], 'etag');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'etag': 'etag'});
        expect(metadata.etag, 'etag');
      });
    });

    group('generation', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(generation: 123));
        expect(json['generation'], '123');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'generation': '123'});
        expect(metadata.generation, 123);
      });
    });

    group('hardDeleteTime', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(hardDeleteTime: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['hardDeleteTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'hardDeleteTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.hardDeleteTime?.seconds, 1000);
      });
    });

    group('hierarchicalNamespace', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            hierarchicalNamespace: BucketHierarchicalNamespace(enabled: true),
          ),
        );
        expect(json['hierarchicalNamespace'], {'enabled': true});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'hierarchicalNamespace': {'enabled': true},
        });
        expect(metadata.hierarchicalNamespace?.enabled, true);
      });
    });

    group('iamConfiguration', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            iamConfiguration: BucketIamConfiguration(
              publicAccessPrevention: 'enforced',
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: true,
                lockedTime: Timestamp(seconds: 1000, nanos: 0),
              ),
            ),
          ),
        );
        expect(json['iamConfiguration'], {
          'publicAccessPrevention': 'enforced',
          'uniformBucketLevelAccess': {
            'enabled': true,
            'lockedTime': '1970-01-01T00:16:40Z',
          },
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'iamConfiguration': {
            'publicAccessPrevention': 'enforced',
            'uniformBucketLevelAccess': {
              'enabled': true,
              'lockedTime': '1970-01-01T00:16:40Z',
            },
          },
        });
        expect(metadata.iamConfiguration?.publicAccessPrevention, 'enforced');
        expect(
          metadata.iamConfiguration?.uniformBucketLevelAccess?.enabled,
          true,
        );
        expect(
          metadata
              .iamConfiguration
              ?.uniformBucketLevelAccess
              ?.lockedTime
              ?.seconds,
          1000,
        );
      });
    });

    group('id', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(id: 'id'));
        expect(json['id'], 'id');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'id': 'id'});
        expect(metadata.id, 'id');
      });
    });

    group('ipFilter', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            ipFilter: BucketIpFilter(
              allowAllServiceAgentAccess: true,
              allowCrossOrgVpcs: false,
              mode: 'Enabled',
              publicNetworkSource: BucketPublicNetworkSource(
                allowedIpCidrRanges: ['10.0.0.0/24'],
              ),
              vpcNetworkSources: [
                BucketPublicNetworkSource(
                  allowedIpCidrRanges: ['192.168.0.0/24'],
                ),
              ],
            ),
          ),
        );
        expect(json['ipFilter'], {
          'allowAllServiceAgentAccess': true,
          'allowCrossOrgVpcs': false,
          'mode': 'Enabled',
          'publicNetworkSource': {
            'allowedIpCidrRanges': ['10.0.0.0/24'],
          },
          'vpcNetworkSources': [
            {
              'allowedIpCidrRanges': ['192.168.0.0/24'],
            },
          ],
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'ipFilter': {
            'allowAllServiceAgentAccess': true,
            'allowCrossOrgVpcs': false,
            'mode': 'Enabled',
            'publicNetworkSource': {
              'allowedIpCidrRanges': ['10.0.0.0/24'],
            },
            'vpcNetworkSources': [
              {
                'allowedIpCidrRanges': ['192.168.0.0/24'],
              },
            ],
          },
        });
        expect(metadata.ipFilter?.allowAllServiceAgentAccess, true);
        expect(metadata.ipFilter?.allowCrossOrgVpcs, false);
        expect(metadata.ipFilter?.mode, 'Enabled');
        expect(metadata.ipFilter?.publicNetworkSource?.allowedIpCidrRanges, [
          '10.0.0.0/24',
        ]);
        expect(
          metadata.ipFilter?.vpcNetworkSources?.first.allowedIpCidrRanges,
          ['192.168.0.0/24'],
        );
      });
    });

    group('kind', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(kind: 'kind'));
        expect(json['kind'], 'kind');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'kind': 'kind'});
        expect(metadata.kind, 'kind');
      });
    });

    group('labels', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(labels: {'key': 'value'}),
        );
        expect(json['labels'], {'key': 'value'});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'labels': {'key': 'value'},
        });
        expect(metadata.labels, {'key': 'value'});
      });
    });

    group('lifecycle', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            lifecycle: Lifecycle(
              rule: [
                LifecycleRule(
                  action: LifecycleRuleAction(
                    storageClass: 'NEARLINE',
                    type: 'SetStorageClass',
                  ),
                  condition: LifecycleRuleCondition(
                    age: 30,
                    createdBefore: DateTime.utc(2026, 2, 3),
                    customTimeBefore: DateTime.utc(2026, 2, 3),
                    daysSinceCustomTime: 10,
                    daysSinceNoncurrentTime: 20,
                    isLive: true,
                    matchesPrefix: ['prefix'],
                    matchesStorageClass: ['STANDARD'],
                    matchesSuffix: ['suffix'],
                    noncurrentTimeBefore: DateTime.utc(2026, 2, 3),
                    numNewerVersions: 3,
                  ),
                ),
              ],
            ),
          ),
        );
        expect(json['lifecycle'], {
          'rule': [
            {
              'action': {'storageClass': 'NEARLINE', 'type': 'SetStorageClass'},
              'condition': {
                'age': 30,
                'createdBefore': '2026-02-03',
                'customTimeBefore': '2026-02-03',
                'daysSinceCustomTime': 10,
                'daysSinceNoncurrentTime': 20,
                'isLive': true,
                'matchesPrefix': ['prefix'],
                'matchesStorageClass': ['STANDARD'],
                'matchesSuffix': ['suffix'],
                'noncurrentTimeBefore': '2026-02-03',
                'numNewerVersions': 3,
              },
            },
          ],
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'lifecycle': {
            'rule': [
              {
                'action': {
                  'storageClass': 'NEARLINE',
                  'type': 'SetStorageClass',
                },
                'condition': {
                  'age': 30,
                  'createdBefore': '2026-02-03',
                  'customTimeBefore': '2026-02-03',
                  'daysSinceCustomTime': 10,
                  'daysSinceNoncurrentTime': 20,
                  'isLive': true,
                  'matchesPrefix': ['prefix'],
                  'matchesStorageClass': ['STANDARD'],
                  'matchesSuffix': ['suffix'],
                  'noncurrentTimeBefore': '2026-02-03',
                  'numNewerVersions': 3,
                },
              },
            ],
          },
        });
        final rule = metadata.lifecycle!.rule!.first;
        expect(rule.action?.storageClass, 'NEARLINE');
        expect(rule.action?.type, 'SetStorageClass');
        expect(rule.condition?.age, 30);
        expect(rule.condition?.createdBefore, DateTime.parse('2026-02-03'));
        expect(rule.condition?.customTimeBefore, DateTime.parse('2026-02-03'));
        expect(rule.condition?.daysSinceCustomTime, 10);
        expect(rule.condition?.daysSinceNoncurrentTime, 20);
        expect(rule.condition?.isLive, true);
        expect(rule.condition?.matchesPrefix, ['prefix']);
        expect(rule.condition?.matchesStorageClass, ['STANDARD']);
        expect(rule.condition?.matchesSuffix, ['suffix']);
        expect(
          rule.condition?.noncurrentTimeBefore,
          DateTime.parse('2026-02-03'),
        );
        expect(rule.condition?.numNewerVersions, 3);
      });
    });

    group('location', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(location: 'US'));
        expect(json['location'], 'US');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'location': 'US'});
        expect(metadata.location, 'US');
      });
    });

    group('locationType', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(locationType: 'multi-region'),
        );
        expect(json['locationType'], 'multi-region');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'locationType': 'multi-region',
        });
        expect(metadata.locationType, 'multi-region');
      });
    });

    group('logging', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            logging: BucketLoggingConfiguration(
              logBucket: 'log-bucket',
              logObjectPrefix: 'log-prefix',
            ),
          ),
        );
        expect(json['logging'], {
          'logBucket': 'log-bucket',
          'logObjectPrefix': 'log-prefix',
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'logging': {
            'logBucket': 'log-bucket',
            'logObjectPrefix': 'log-prefix',
          },
        });
        expect(metadata.logging?.logBucket, 'log-bucket');
        expect(metadata.logging?.logObjectPrefix, 'log-prefix');
      });
    });

    group('metageneration', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(metageneration: 1));
        expect(json['metageneration'], '1');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'metageneration': '1'});
        expect(metadata.metageneration, 1);
      });
    });

    group('name', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(name: 'bucket'));
        expect(json['name'], 'bucket');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'name': 'bucket'});
        expect(metadata.name, 'bucket');
      });
    });

    group('objectRetention', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            objectRetention: BucketObjectRetention(mode: 'Enabled'),
          ),
        );
        expect(json['objectRetention'], {'mode': 'Enabled'});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'objectRetention': {'mode': 'Enabled'},
        });
        expect(metadata.objectRetention?.mode, 'Enabled');
      });
    });

    group('owner', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            owner: BucketOwner(entity: 'user-1', entityId: 'id-1'),
          ),
        );
        expect(json['owner'], {'entity': 'user-1', 'entityId': 'id-1'});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'owner': {'entity': 'user-1', 'entityId': 'id-1'},
        });
        expect(metadata.owner?.entity, 'user-1');
        expect(metadata.owner?.entityId, 'id-1');
      });
    });

    group('projectNumber', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(projectNumber: '123456'),
        );
        expect(json['projectNumber'], '123456');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'projectNumber': '123456'});
        expect(metadata.projectNumber, '123456');
      });
    });

    group('retentionPolicy', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            retentionPolicy: BucketRetentionPolicy(
              effectiveTime: Timestamp(seconds: 1000, nanos: 0),
              isLocked: true,
              retentionPeriod: 100,
            ),
          ),
        );
        expect(json['retentionPolicy'], {
          'effectiveTime': '1970-01-01T00:16:40Z',
          'isLocked': true,
          'retentionPeriod': '100',
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'retentionPolicy': {
            'effectiveTime': '1970-01-01T00:16:40Z',
            'isLocked': true,
            'retentionPeriod': '100',
          },
        });
        expect(metadata.retentionPolicy?.effectiveTime?.seconds, 1000);
        expect(metadata.retentionPolicy?.isLocked, true);
        expect(metadata.retentionPolicy?.retentionPeriod, 100);
      });
    });

    group('rpo', () {
      test('to json', () {
        final json = bucketMetadataToJson(BucketMetadata(rpo: 'DEFAULT'));
        expect(json['rpo'], 'DEFAULT');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'rpo': 'DEFAULT'});
        expect(metadata.rpo, 'DEFAULT');
      });
    });

    group('selfLink', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(selfLink: Uri.parse('http://example.com')),
        );
        expect(json['selfLink'], 'http://example.com');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'selfLink': 'http://example.com',
        });
        expect(metadata.selfLink, Uri.parse('http://example.com'));
      });
    });

    group('softDeletePolicy', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            softDeletePolicy: BucketSoftDeletePolicy(
              effectiveTime: Timestamp(seconds: 1000, nanos: 0),
              retentionDurationSeconds: 100,
            ),
          ),
        );
        expect(json['softDeletePolicy'], {
          'effectiveTime': '1970-01-01T00:16:40Z',
          'retentionDurationSeconds': '100',
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'softDeletePolicy': {
            'effectiveTime': '1970-01-01T00:16:40Z',
            'retentionDurationSeconds': '100',
          },
        });
        expect(metadata.softDeletePolicy?.effectiveTime?.seconds, 1000);
        expect(metadata.softDeletePolicy?.retentionDurationSeconds, 100);
      });
    });

    group('softDeleteTime', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(softDeleteTime: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['softDeleteTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'softDeleteTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.softDeleteTime?.seconds, 1000);
      });
    });

    group('storageClass', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(storageClass: 'STANDARD'),
        );
        expect(json['storageClass'], 'STANDARD');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({'storageClass': 'STANDARD'});
        expect(metadata.storageClass, 'STANDARD');
      });
    });

    group('timeCreated', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(timeCreated: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['timeCreated'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'timeCreated': '1970-01-01T00:16:40Z',
        });
        expect(metadata.timeCreated?.seconds, 1000);
      });
    });

    group('updated', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(updated: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['updated'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'updated': '1970-01-01T00:16:40Z',
        });
        expect(metadata.updated?.seconds, 1000);
      });
    });

    group('versioning', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(versioning: BucketVersioning(enabled: true)),
        );
        expect(json['versioning'], {'enabled': true});
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'versioning': {'enabled': true},
        });
        expect(metadata.versioning?.enabled, true);
      });
    });

    group('website', () {
      test('to json', () {
        final json = bucketMetadataToJson(
          BucketMetadata(
            website: BucketWebsiteConfiguration(
              mainPageSuffix: 'index.html',
              notFoundPage: '404.html',
            ),
          ),
        );
        expect(json['website'], {
          'mainPageSuffix': 'index.html',
          'notFoundPage': '404.html',
        });
      });
      test('from json', () {
        final metadata = bucketMetadataFromJson({
          'website': {
            'mainPageSuffix': 'index.html',
            'notFoundPage': '404.html',
          },
        });
        expect(metadata.website?.mainPageSuffix, 'index.html');
        expect(metadata.website?.notFoundPage, '404.html');
      });
    });
  });
}
