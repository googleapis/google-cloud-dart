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

import 'test_utils.dart';

void listBucketAclTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('success', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'list_bkt_acl_ok',
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

    final aclList = await storage.listBucketAcl(bucketName);
    expect(aclList, isNotEmpty);

    final testUserAcl = aclList.firstWhere((i) => i.entity == entity);
    expect(testUserAcl.role, 'READER');
  });

  test('no bucket', () async {
    expect(
      () => storage.listBucketAcl(
        'list_bkt_acl_no_bucket_${DateTime.now().millisecondsSinceEpoch}',
      ),
      throwsA(isA<NotFoundException>()),
    );
  });
}

void main() async {
  group('list bucket acl', () {
    group('google-cloud', tags: ['google-cloud', 'no-ulba'], () {
      listBucketAclTest(Storage.new);
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

      listBucketAclTest(() => storage);
    });

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response(
            '{"kind": "storage#bucketAccessControls", "items": '
            '[{"kind": "storage#bucketAccessControl", "entity": '
            '"user-test", "role": "READER"}]}',
            200,
          );
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final aclList = await storage.listBucketAcl('bucket');
      expect(aclList, hasLength(1));
      expect(aclList.first.entity, 'user-test');
      expect(aclList.first.role, 'READER');
      expect(count, 2);
    });
  });
}
