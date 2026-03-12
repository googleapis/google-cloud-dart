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
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('storage constructors', () {
    group('with credentials', tags: ['integration'], () {
      test('no constuctor arguments', () async {
        storage = Storage();
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'stg_no_args');
      });

      test('constructor with client', () async {
        Future<auth.AutoRefreshingAuthClient> authClient() async =>
            await auth.clientViaApplicationDefaultCredentials(
              scopes: [
                'https://www.googleapis.com/auth/cloud-platform',
                'https://www.googleapis.com/auth/devstorage.read_write',
              ],
            );
        final client = await authClient();

        storage = Storage(client: client);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'stg_w_cl');
      });

      test('constructor with future client', () async {
        Future<auth.AutoRefreshingAuthClient> authClient() async =>
            await auth.clientViaApplicationDefaultCredentials(
              scopes: [
                'https://www.googleapis.com/auth/cloud-platform',
                'https://www.googleapis.com/auth/devstorage.read_write',
              ],
            );
        final client = authClient();

        storage = Storage(client: client);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'stg_w_fut_cl');
      });

      test('constructor with project id', () async {
        storage = Storage(projectId: projectId);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'stg_w_proj_id');
      });

      test('constructor with client and project id', () async {
        Future<auth.AutoRefreshingAuthClient> authClient() async =>
            await auth.clientViaApplicationDefaultCredentials(
              scopes: [
                'https://www.googleapis.com/auth/cloud-platform',
                'https://www.googleapis.com/auth/devstorage.read_write',
              ],
            );
        final client = await authClient();

        storage = Storage(client: client, projectId: projectId);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'stg_w_cl_and_proj_id');
      });
    }, testOn: 'vm');

    test('noProject', () async {
      storage = Storage(client: http.Client(), projectId: Storage.noProject);
      addTearDown(storage.close);

      expect(
        await storage.downloadObject(
          // This is a public dataset.
          'apache-beam-samples',
          'shakespeare/kinglear.txt',
        ),
        hasLength(greaterThan(100)),
      );
    });

    test('noProject throws StateError on createBucket', () async {
      storage = Storage(client: http.Client(), projectId: Storage.noProject);
      addTearDown(storage.close);

      expect(
        () => storage.createBucket(BucketMetadata(name: 'dummy-bucket')),
        throwsStateError,
      );
    });

    test('noProject throws StateError on listBuckets', () async {
      storage = Storage(client: http.Client(), projectId: Storage.noProject);
      addTearDown(storage.close);

      await expectLater(
        storage.listBuckets(),
        emitsInOrder([emitsError(isA<StateError>()), emitsDone]),
      );
    });
  });
}
