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

void main() async {
  late Storage storage;

  group('insert object acl', () {
    group('google-cloud', tags: ['google-cloud', 'no-ulba'], () {
      setUp(() {
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ins_obj_acl_ok',
          metadata: BucketMetadata(
            iamConfiguration: BucketIamConfiguration(
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: false,
              ),
            ),
          ),
        );

        await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'Hello World!',
          ifGenerationMatch: BigInt.zero,
        );

        final acl = await storage.insertObjectAcl(
          bucketName,
          'object.txt',
          'user-${cloud.googleTestUser}',
          'READER',
        );

        expect(acl.entity, 'user-${cloud.googleTestUser}');
        expect(acl.role, 'READER');

        final metadata = await storage.objectMetadata(
          bucketName,
          'object.txt',
          projection: 'full',
        );
        final testUserRoles = [
          for (var i in metadata.acl ?? <ObjectAccessControl>[])
            if (i.entity == 'user-${cloud.googleTestUser}') (i.entity, i.role),
        ];
        expect(testUserRoles, [('user-${cloud.googleTestUser}', 'READER')]);
      });

      test('reader then owner', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ins_obj_acl_ok',
          metadata: BucketMetadata(
            iamConfiguration: BucketIamConfiguration(
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: false,
              ),
            ),
          ),
        );

        await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'Hello World!',
          ifGenerationMatch: BigInt.zero,
        );

        await storage.insertObjectAcl(
          bucketName,
          'object.txt',
          'user-${cloud.googleTestUser}',
          'READER',
        );
        await storage.insertObjectAcl(
          bucketName,
          'object.txt',
          'user-${cloud.googleTestUser}',
          'OWNER',
        );

        final metadata = await storage.objectMetadata(
          bucketName,
          'object.txt',
          projection: 'full',
        );

        final testUserRoles = [
          for (var i in metadata.acl ?? <ObjectAccessControl>[])
            if (i.entity == 'user-${cloud.googleTestUser}') (i.entity, i.role),
        ];
        expect(testUserRoles, [('user-${cloud.googleTestUser}', 'OWNER')]);
      });

      test('owner then reader', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ins_obj_acl_ok',
          metadata: BucketMetadata(
            iamConfiguration: BucketIamConfiguration(
              uniformBucketLevelAccess: UniformBucketLevelAccess(
                enabled: false,
              ),
            ),
          ),
        );

        await storage.uploadObjectFromString(
          bucketName,
          'object.txt',
          'Hello World!',
          ifGenerationMatch: BigInt.zero,
        );

        await storage.insertObjectAcl(
          bucketName,
          'object.txt',
          'user-${cloud.googleTestUser}',
          'OWNER',
        );
        await storage.insertObjectAcl(
          bucketName,
          'object.txt',
          'user-${cloud.googleTestUser}',
          'READER',
        );

        final metadata = await storage.objectMetadata(
          bucketName,
          'object.txt',
          projection: 'full',
        );

        final testUserRoles = [
          for (var i in metadata.acl ?? <ObjectAccessControl>[])
            if (i.entity == 'user-${cloud.googleTestUser}') (i.entity, i.role),
        ];
        expect(testUserRoles, [('user-${cloud.googleTestUser}', 'READER')]);
      });

      test('not found', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ins_obj_acl_not_found',
        );

        final bucketMetadata = await storage.bucketMetadata(
          bucketName,
          projection: 'full',
        );
        final entity = bucketMetadata.acl!.first.entity!;

        expect(
          () => storage.insertObjectAcl(
            bucketName,
            'non-existent.txt',
            entity,
            'READER',
          ),
          throwsA(isA<NotFoundException>()),
        );
      });
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
        storage.insertObjectAcl('bucket', 'object', 'entity', 'role'),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });
  });
}
