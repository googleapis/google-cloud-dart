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

void getObjectAclTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('success', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'get_obj_acl_ok',
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

    final acl = await storage.getObjectAcl(bucketName, 'object.txt', entity);
    expect(acl.entity, entity);
    expect(acl.role, 'READER');
  });

  test('no object', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'get_obj_acl_no_object',
    );

    expect(
      () => storage.getObjectAcl(bucketName, 'non-existent.txt', 'allUsers'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('no acl', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'get_obj_acl_no_acl',
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
    expect(
      () => storage.getObjectAcl(bucketName, 'object.txt', entity),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('success with generation', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'get_obj_acl_gen_ok',
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

    final acl = await storage.getObjectAcl(
      bucketName,
      'object.txt',
      entity,
      generation: md.generation,
    );
    expect(acl.entity, entity);
    expect(acl.role, 'READER');
  });

  test('not found with wrong generation', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'get_obj_acl_gen_not_found',
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
      () => storage.getObjectAcl(
        bucketName,
        'object.txt',
        entity,
        generation: BigInt.from(12345),
      ),
      throwsA(isA<NotFoundException>()),
    );
  });
}

void main() async {
  group('get object acl', () {
    group('google-cloud', tags: ['google-cloud', 'no-ulba'], () {
      getObjectAclTest(Storage.new);
    });

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;
      late RetryTestHttpClient client;

      setUp(() {
        client = RetryTestHttpClient(http.Client());
        storage = Storage(
          projectId: 'test-project',
          apiEndpoint: 'localhost:9000',
          useAuthWithCustomEndpoint: false,
          client: client,
        );
      });

      tearDown(() => storage.close());

      getObjectAclTest(() => storage);
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
            '"entity": "user-test", "role": "READER"}',
            200,
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final acl = await storage.getObjectAcl('bucket', 'object', 'user-test');
      expect(acl.entity, 'user-test');
      expect(acl.role, 'READER');
      expect(count, 2);
    });
  });
}
