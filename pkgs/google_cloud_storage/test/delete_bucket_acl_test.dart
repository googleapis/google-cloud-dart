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

void deleteBucketAclTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('success', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'del_bkt_acl_ok',
      metadata: BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: false),
        ),
      ),
    );

    // The `iam.allowedPolicyMemberDomains` constraint on the test project does
    // not allow `cloud.googleTestUser` to be an owner, so we use project
    // viewers instead.
    final initialMetadata = await storage.bucketMetadata(bucketName);
    final entity = 'project-viewers-${initialMetadata.projectNumber}';
    await storage.insertBucketAcl(bucketName, entity, 'READER');

    await storage.deleteBucketAcl(bucketName, entity);

    final metadata = await storage.bucketMetadata(
      bucketName,
      projection: 'full',
    );

    final testUserRoles = [
      for (var i in metadata.acl ?? <BucketAccessControl>[])
        if (i.entity == entity) (i.entity, i.role),
    ];
    expect(testUserRoles, isEmpty);
  });

  test('no bucket', () async {
    expect(
      () => storage.deleteBucketAcl('del_bkt_acl_no_bucket', 'allUsers'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('no acl', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'del_bkt_acl_no_acl',
      metadata: BucketMetadata(
        iamConfiguration: BucketIamConfiguration(
          uniformBucketLevelAccess: UniformBucketLevelAccess(enabled: false),
        ),
      ),
    );

    const entity = 'user-${cloud.googleTestUser}';
    expect(
      () => storage.deleteBucketAcl(bucketName, entity),
      throwsA(isA<NotFoundException>()),
    );
  });
}

void main() async {
  group('delete bucket acl', () {
    group('google-cloud', tags: ['google-cloud', 'no-ulba'], () {
      deleteBucketAclTest(Storage.new);
    });

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;

      setUp(() {
        (_, storage) = createStorageTestbenchClient();
      });

      tearDown(() => storage.close());

      deleteBucketAclTest(() => storage);
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
        storage.deleteBucketAcl('bucket', 'entity'),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });
  });
}
