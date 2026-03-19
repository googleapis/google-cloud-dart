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

import 'package:test/test.dart';

void main() {
  group('BucketAutoclass', () {
    test('copyWith', () {
      final original = BucketAutoclass(
        enabled: true,
        terminalStorageClass: 'NEARLINE',
        terminalStorageClassUpdateTime: Timestamp(seconds: 1000, nanos: 0),
        toggleTime: Timestamp(seconds: 2000, nanos: 0),
      );
      final copy = original.copyWith(
        enabled: false,
        terminalStorageClass: 'ARCHIVE',
      );

      expect(copy.enabled, isFalse);
      expect(copy.terminalStorageClass, 'ARCHIVE');
      expect(copy.terminalStorageClassUpdateTime!.seconds, 1000);
      expect(copy.toggleTime!.seconds, 2000);

      // Original should remain unchanged
      expect(original.enabled, isTrue);
      expect(original.terminalStorageClass, 'NEARLINE');
    });

    test('copyWithout', () {
      final original = BucketAutoclass(
        enabled: true,
        terminalStorageClass: 'NEARLINE',
      );
      final copy = original.copyWithout(enabled: true);

      expect(copy.enabled, isNull);
      expect(copy.terminalStorageClass, 'NEARLINE');

      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });
  });

  group('BucketBilling', () {
    test('copyWith', () {
      final original = BucketBilling(requesterPays: true);
      final copy = original.copyWith(requesterPays: false);

      expect(copy.requesterPays, isFalse);
      // Original should remain unchanged
      expect(original.requesterPays, isTrue);
    });

    test('copyWithout', () {
      final original = BucketBilling(requesterPays: true);
      final copy = original.copyWithout(requesterPays: true);

      expect(copy.requesterPays, isNull);
      // Original should remain unchanged
      expect(original.requesterPays, isTrue);
    });
  });

  group('BucketAccessControl', () {
    test('copyWith', () {
      final original = BucketAccessControl(
        bucket: 'b',
        entity: 'e',
        role: 'READER',
      );
      final copy = original.copyWith(role: 'WRITER');

      expect(copy.bucket, 'b');
      expect(copy.role, 'WRITER');
      // Original should remain unchanged
      expect(original.role, 'READER');
    });

    test('copyWithout', () {
      final original = BucketAccessControl(role: 'READER');
      final copy = original.copyWithout(role: true);

      expect(copy.role, isNull);
      // Original should remain unchanged
      expect(original.role, 'READER');
    });
  });

  group('BucketEncryption', () {
    test('copyWith', () {
      final original = BucketEncryption(defaultKmsKeyName: 'key1');
      final copy = original.copyWith(defaultKmsKeyName: 'key2');

      expect(copy.defaultKmsKeyName, 'key2');
      // Original should remain unchanged
      expect(original.defaultKmsKeyName, 'key1');
    });

    test('copyWithout', () {
      final original = BucketEncryption(defaultKmsKeyName: 'key1');
      final copy = original.copyWithout(defaultKmsKeyName: true);

      expect(copy.defaultKmsKeyName, isNull);
      // Original should remain unchanged
      expect(original.defaultKmsKeyName, 'key1');
    });
  });

  group('BucketObjectRetention', () {
    test('copyWith', () {
      final original = BucketObjectRetention(mode: 'Enabled');
      final copy = original.copyWith(mode: 'Disabled');

      expect(copy.mode, 'Disabled');
      // Original should remain unchanged
      expect(original.mode, 'Enabled');
    });

    test('copyWithout', () {
      final original = BucketObjectRetention(mode: 'Enabled');
      final copy = original.copyWithout(mode: true);

      expect(copy.mode, isNull);
      // Original should remain unchanged
      expect(original.mode, 'Enabled');
    });
  });

  group('BucketCorsConfiguration', () {
    test('copyWith', () {
      final original = BucketCorsConfiguration(
        maxAgeSeconds: 100,
        method: ['GET'],
        origin: ['*'],
        responseHeader: ['Content-Type'],
      );
      final copy = original.copyWith(maxAgeSeconds: 200);

      expect(copy.maxAgeSeconds, 200);
      expect(copy.method, ['GET']);
      // Original should remain unchanged
      expect(original.maxAgeSeconds, 100);
    });

    test('copyWithout', () {
      final original = BucketCorsConfiguration(maxAgeSeconds: 100);
      final copy = original.copyWithout(maxAgeSeconds: true);

      expect(copy.maxAgeSeconds, isNull);
      // Original should remain unchanged
      expect(original.maxAgeSeconds, 100);
    });
  });

  group('BucketCustomPlacementConfig', () {
    test('copyWith', () {
      final original = BucketCustomPlacementConfig(dataLocations: ['US-EAST1']);
      final copy = original.copyWith(dataLocations: ['US-WEST1']);

      expect(copy.dataLocations, ['US-WEST1']);
      // Original should remain unchanged
      expect(original.dataLocations, ['US-EAST1']);
    });

    test('copyWithout', () {
      final original = BucketCustomPlacementConfig(dataLocations: ['US-EAST1']);
      final copy = original.copyWithout(dataLocations: true);

      expect(copy.dataLocations, isNull);
      // Original should remain unchanged
      expect(original.dataLocations, ['US-EAST1']);
    });
  });

  group('BucketHierarchicalNamespace', () {
    test('copyWith', () {
      final original = BucketHierarchicalNamespace(enabled: true);
      final copy = original.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });

    test('copyWithout', () {
      final original = BucketHierarchicalNamespace(enabled: true);
      final copy = original.copyWithout(enabled: true);

      expect(copy.enabled, isNull);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });
  });

  group('BucketIamConfiguration', () {
    test('copyWith', () {
      final original = BucketIamConfiguration(
        publicAccessPrevention: 'inherited',
        uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: true),
      );
      final copy = original.copyWith(publicAccessPrevention: 'enforced');

      expect(copy.publicAccessPrevention, 'enforced');
      expect(copy.uniformBucketLevelAccess!.enabled, isTrue);
      // Original should remain unchanged
      expect(original.publicAccessPrevention, 'inherited');
    });

    test('copyWithout', () {
      final original = BucketIamConfiguration(
        publicAccessPrevention: 'inherited',
      );
      final copy = original.copyWithout(publicAccessPrevention: true);

      expect(copy.publicAccessPrevention, isNull);
      // Original should remain unchanged
      expect(original.publicAccessPrevention, 'inherited');
    });
  });

  group('UniformBucketLevelAccess', () {
    test('copyWith', () {
      final original = UniformBucketLevelAccess(enabled: true);
      final copy = original.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });

    test('copyWithout', () {
      final original = UniformBucketLevelAccess(enabled: true);
      final copy = original.copyWithout(enabled: true);

      expect(copy.enabled, isNull);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });
  });

  group('BucketIpFilter', () {
    test('copyWith', () {
      final original = BucketIpFilter(
        allowAllServiceAgentAccess: true,
        mode: 'Enabled',
      );
      final copy = original.copyWith(mode: 'Disabled');

      expect(copy.mode, 'Disabled');
      expect(copy.allowAllServiceAgentAccess, isTrue);
      // Original should remain unchanged
      expect(original.mode, 'Enabled');
    });

    test('copyWithout', () {
      final original = BucketIpFilter(mode: 'Enabled');
      final copy = original.copyWithout(mode: true);

      expect(copy.mode, isNull);
      // Original should remain unchanged
      expect(original.mode, 'Enabled');
    });
  });

  group('BucketPublicNetworkSource', () {
    test('copyWith', () {
      final original = BucketPublicNetworkSource(
        allowedIpCidrRanges: ['10.0.0.0/24'],
      );
      final copy = original.copyWith(allowedIpCidrRanges: ['192.168.0.0/24']);

      expect(copy.allowedIpCidrRanges, ['192.168.0.0/24']);
      // Original should remain unchanged
      expect(original.allowedIpCidrRanges, ['10.0.0.0/24']);
    });

    test('copyWithout', () {
      final original = BucketPublicNetworkSource(
        allowedIpCidrRanges: ['10.0.0.0/24'],
      );
      final copy = original.copyWithout(allowedIpCidrRanges: true);

      expect(copy.allowedIpCidrRanges, isNull);
      // Original should remain unchanged
      expect(original.allowedIpCidrRanges, ['10.0.0.0/24']);
    });
  });

  group('Lifecycle', () {
    test('copyWith', () {
      final original = Lifecycle(
        rule: [LifecycleRule(action: LifecycleRuleAction(type: 'Delete'))],
      );
      final copy = original.copyWith(rule: []);

      expect(copy.rule, isEmpty);
      // Original should remain unchanged
      expect(original.rule, isNotEmpty);
    });

    test('copyWithout', () {
      final original = Lifecycle(rule: []);
      final copy = original.copyWithout(rule: true);

      expect(copy.rule, isNull);
      // Original should remain unchanged
      expect(original.rule, isEmpty);
    });
  });

  group('LifecycleRule', () {
    test('copyWith', () {
      final original = LifecycleRule(
        action: LifecycleRuleAction(type: 'Delete'),
      );
      final copy = original.copyWith(
        action: LifecycleRuleAction(type: 'SetStorageClass'),
      );

      expect(copy.action!.type, 'SetStorageClass');
      // Original should remain unchanged
      expect(original.action!.type, 'Delete');
    });

    test('copyWithout', () {
      final original = LifecycleRule(
        action: LifecycleRuleAction(type: 'Delete'),
      );
      final copy = original.copyWithout(action: true);

      expect(copy.action, isNull);
      // Original should remain unchanged
      expect(original.action, isNotNull);
    });
  });

  group('LifecycleRuleAction', () {
    test('copyWith', () {
      final original = LifecycleRuleAction(type: 'Delete');
      final copy = original.copyWith(type: 'SetStorageClass');

      expect(copy.type, 'SetStorageClass');
      // Original should remain unchanged
      expect(original.type, 'Delete');
    });

    test('copyWithout', () {
      final original = LifecycleRuleAction(type: 'Delete');
      final copy = original.copyWithout(type: true);

      expect(copy.type, isNull);
      // Original should remain unchanged
      expect(original.type, 'Delete');
    });
  });

  group('LifecycleRuleCondition', () {
    test('copyWith', () {
      final original = LifecycleRuleCondition(age: 30, isLive: true);
      final copy = original.copyWith(age: 60);

      expect(copy.age, 60);
      expect(copy.isLive, isTrue);
      // Original should remain unchanged
      expect(original.age, 30);
    });

    test('copyWithout', () {
      final original = LifecycleRuleCondition(age: 30);
      final copy = original.copyWithout(age: true);

      expect(copy.age, isNull);
      // Original should remain unchanged
      expect(original.age, 30);
    });
  });

  group('BucketLoggingConfiguration', () {
    test('copyWith', () {
      final original = BucketLoggingConfiguration(logBucket: 'logs');
      final copy = original.copyWith(logBucket: 'new-logs');

      expect(copy.logBucket, 'new-logs');
      // Original should remain unchanged
      expect(original.logBucket, 'logs');
    });

    test('copyWithout', () {
      final original = BucketLoggingConfiguration(logBucket: 'logs');
      final copy = original.copyWithout(logBucket: true);

      expect(copy.logBucket, isNull);
      // Original should remain unchanged
      expect(original.logBucket, 'logs');
    });
  });

  group('BucketOwner', () {
    test('copyWith', () {
      final original = BucketOwner(entity: 'user-1');
      final copy = original.copyWith(entity: 'user-2');

      expect(copy.entity, 'user-2');
      // Original should remain unchanged
      expect(original.entity, 'user-1');
    });

    test('copyWithout', () {
      final original = BucketOwner(entity: 'user-1');
      final copy = original.copyWithout(entity: true);

      expect(copy.entity, isNull);
      // Original should remain unchanged
      expect(original.entity, 'user-1');
    });
  });

  group('BucketRetentionPolicy', () {
    test('copyWith', () {
      final original = BucketRetentionPolicy(
        isLocked: true,
        retentionPeriod: 100,
      );
      final copy = original.copyWith(isLocked: false);

      expect(copy.isLocked, isFalse);
      expect(copy.retentionPeriod, 100);
      // Original should remain unchanged
      expect(original.isLocked, isTrue);
    });

    test('copyWithout', () {
      final original = BucketRetentionPolicy(isLocked: true);
      final copy = original.copyWithout(isLocked: true);

      expect(copy.isLocked, isNull);
      // Original should remain unchanged
      expect(original.isLocked, isTrue);
    });
  });

  group('BucketSoftDeletePolicy', () {
    test('copyWith', () {
      final original = BucketSoftDeletePolicy(retentionDurationSeconds: 1000);
      final copy = original.copyWith(retentionDurationSeconds: 2000);

      expect(copy.retentionDurationSeconds, 2000);
      // Original should remain unchanged
      expect(original.retentionDurationSeconds, 1000);
    });

    test('copyWithout', () {
      final original = BucketSoftDeletePolicy(retentionDurationSeconds: 1000);
      final copy = original.copyWithout(retentionDurationSeconds: true);

      expect(copy.retentionDurationSeconds, isNull);
      // Original should remain unchanged
      expect(original.retentionDurationSeconds, 1000);
    });
  });

  group('BucketVersioning', () {
    test('copyWith', () {
      final original = BucketVersioning(enabled: true);
      final copy = original.copyWith(enabled: false);

      expect(copy.enabled, isFalse);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });

    test('copyWithout', () {
      final original = BucketVersioning(enabled: true);
      final copy = original.copyWithout(enabled: true);

      expect(copy.enabled, isNull);
      // Original should remain unchanged
      expect(original.enabled, isTrue);
    });
  });

  group('BucketWebsiteConfiguration', () {
    test('copyWith', () {
      final original = BucketWebsiteConfiguration(mainPageSuffix: 'index.html');
      final copy = original.copyWith(mainPageSuffix: 'home.html');

      expect(copy.mainPageSuffix, 'home.html');
      // Original should remain unchanged
      expect(original.mainPageSuffix, 'index.html');
    });

    test('copyWithout', () {
      final original = BucketWebsiteConfiguration(mainPageSuffix: 'index.html');
      final copy = original.copyWithout(mainPageSuffix: true);

      expect(copy.mainPageSuffix, isNull);
      // Original should remain unchanged
      expect(original.mainPageSuffix, 'index.html');
    });
  });

  group('BucketMetadata', () {
    test('copyWith', () {
      final original = BucketMetadata(
        name: 'bucket',
        location: 'US',
        storageClass: 'STANDARD',
      );
      final copy = original.copyWith(location: 'EU', storageClass: 'NEARLINE');

      expect(copy.name, 'bucket');
      expect(copy.location, 'EU');
      expect(copy.storageClass, 'NEARLINE');
      // Original should remain unchanged
      expect(original.location, 'US');
      expect(original.storageClass, 'STANDARD');
    });

    test('copyWithout', () {
      final original = BucketMetadata(name: 'bucket', location: 'US');
      final copy = original.copyWithout(location: true);

      expect(copy.name, 'bucket');
      expect(copy.location, isNull);
      // Original should remain unchanged
      expect(original.location, 'US');
    });
  });
}
