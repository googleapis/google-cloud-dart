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

import 'dart:io';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  if (Platform.environment['GOOGLE_CLOUD_PROJECT'] == null) {
    test('skip', () {}, skip: 'Requires GOOGLE_CLOUD_PROJECT');
    return;
  }

  late Storage storage;
  late http.Client client;

  group('storage constructors', () {
    group('with credentials', () {
      setUp(() async {
        Future<auth.AutoRefreshingAuthClient> authClient() async =>
            await auth.clientViaApplicationDefaultCredentials(
              scopes: [
                'https://www.googleapis.com/auth/cloud-platform',
                'https://www.googleapis.com/auth/devstorage.read_write',
              ],
            );

        client = await authClient();
      });

      test(
        'no constuctor arguments',
        () async {
          storage = Storage();
          addTearDown(storage.close);

          // There is no easy way to verify that the project ID was used, other
          // than to create a bucket and assume that it is associated with the
          // correct project.
          await createBucketWithTearDown(storage, 'storage_no_arguments');
        },
        skip: Platform.environment['GOOGLE_CLOUD_PROJECT'] == null
            ? '"gcloud auth login" is required for tests using application '
                  'default credentials'
            : false,
      );

      test('constructor with client', () async {
        storage = Storage(client: client);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'storage_with_client');
      });

      test('constructor with future client', () async {
        storage = Storage(client: Future.value(client));
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(storage, 'storage_with_future_client');
      });

      test(
        'constructor with project id',
        () async {
          storage = Storage(projectId: projectId);
          addTearDown(storage.close);

          // There is no easy way to verify that the project ID was used, other
          // than to create a bucket and assume that it is associated with the
          // correct project.
          await createBucketWithTearDown(storage, 'storage_with_project_id');
        },
        skip: Platform.environment['GOOGLE_CLOUD_PROJECT'] == null
            ? '"gcloud auth login" is required for tests using application '
                  'default credentials'
            : false,
      );

      test('constructor with client and project id', () async {
        storage = Storage(client: client, projectId: projectId);
        addTearDown(storage.close);

        // There is no easy way to verify that the project ID was used, other
        // than to create a bucket and assume that it is associated with the
        // correct project.
        await createBucketWithTearDown(
          storage,
          'storage_with_client_and_project_id',
        );
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
