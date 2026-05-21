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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart' as cloud;

import 'test_utils.dart';

void patchObjectAclTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('success', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'patch_obj_acl_ok',
      metadata: BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: false),
        ),
      ),
    );

    await storage.uploadObjectFromString(
      bucketName,
      'object.txt',
      'Hello World!',
      ifGenerationMatch: BigInt.zero,
    );

    const entity = 'user-${cloud.googleTestUser}';
    await storage.insertObjectAcl(bucketName, 'object.txt', entity, 'READER');

    final acl = await storage.patchObjectAcl(
      bucketName,
      'object.txt',
      entity,
      'OWNER',
    );
    expect(acl.entity, entity);
    expect(acl.role, 'OWNER');

    final metadata = await storage.objectMetadata(
      bucketName,
      'object.txt',
      projection: 'full',
    );
    final testUserAcl = metadata.acl!.firstWhere((i) => i.entity == entity);
    expect(testUserAcl.role, 'OWNER');
  });

  test('no object', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'patch_obj_acl_no_object',
    );

    expect(
      () => storage.patchObjectAcl(
        bucketName,
        'non-existent.txt',
        'allUsers',
        'READER',
      ),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('success with generation', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'patch_obj_acl_gen_ok',
      metadata: BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: false),
        ),
      ),
    );

    final md = await storage.uploadObjectFromString(
      bucketName,
      'object.txt',
      'Hello World!',
      ifGenerationMatch: BigInt.zero,
    );

    const entity = 'user-${cloud.googleTestUser}';
    await storage.insertObjectAcl(bucketName, 'object.txt', entity, 'READER');

    final acl = await storage.patchObjectAcl(
      bucketName,
      'object.txt',
      entity,
      'OWNER',
      generation: md.generation,
    );
    expect(acl.entity, entity);
    expect(acl.role, 'OWNER');

    final metadata = await storage.objectMetadata(
      bucketName,
      'object.txt',
      projection: 'full',
    );
    final testUserAcl = metadata.acl!.firstWhere((i) => i.entity == entity);
    expect(testUserAcl.role, 'OWNER');
  });

  test('not found with wrong generation', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'patch_obj_acl_gen_not_found',
      metadata: BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: false),
        ),
      ),
    );

    await storage.uploadObjectFromString(
      bucketName,
      'object.txt',
      'Hello World!',
      ifGenerationMatch: BigInt.zero,
    );

    const entity = 'user-${cloud.googleTestUser}';
    await storage.insertObjectAcl(bucketName, 'object.txt', entity, 'READER');

    expect(
      () => storage.patchObjectAcl(
        bucketName,
        'object.txt',
        entity,
        'OWNER',
        generation: BigInt.from(12345),
      ),
      throwsA(isA<NotFoundException>()),
    );
  });
}

void main() async {
  group('patch object acl', () {
    group('google-cloud', tags: ['google-cloud', 'no-ulba'], () {
      patchObjectAclTest(Storage.new);
    });

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;

      setUp(() {
        (_, storage) = createStorageTestbenchClient();
      });

      tearDown(() => storage.close());

      patchObjectAclTest(() => storage);
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

      final storage = Storage(client: mockClient, projectId: 'fake project');

      await expectLater(
        storage.patchObjectAcl('bucket', 'object', 'entity', 'role'),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"kind": "storage#objectAccessControl", '
            '"entity": "user-test", "role": "OWNER"}',
            200,
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final acl = await storage.patchObjectAcl(
        'bucket',
        'object',
        'user-test',
        'OWNER',
        generation: BigInt.from(1),
      );
      expect(acl.entity, 'user-test');
      expect(acl.role, 'OWNER');
      expect(count, 2);
    });
  });
}
