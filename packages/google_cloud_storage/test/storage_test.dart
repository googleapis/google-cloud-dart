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

@TestOn('vm')
library;

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;
  late TestHttpClient testClient;

  group('storage constructors', () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/devstorage.read_write',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
    });

    test('no constuctor arguments', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'storage_no_arguments',
      );
      addTearDown(testClient.endTest);

      storage = Storage();
      addTearDown(storage.close);

      // There is no easy way to verify that the project ID was used, other than
      // to create a bucket and assume that it is associated with the correct
      // project.
      await createBucketWithTearDown(storage, 'storage_no_arguments');
      },
      skip: TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? '"gcloud auth login" is required for tests using application '
                'default credentials'
          : false,
    );

    test('constructor with client', () async {
      await testClient.startTest('google_cloud_storage', 'storage_with_client');
      addTearDown(testClient.endTest);

      storage = Storage(client: testClient);
      addTearDown(storage.close);

      // There is no easy way to verify that the project ID was used, other than
      // to create a bucket and assume that it is associated with the correct
      // project.
      await createBucketWithTearDown(storage, 'storage_with_client');
    });

    test('constructor with project id', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'storage_with_project_id',
      );
      addTearDown(testClient.endTest);

      storage = Storage(projectId: projectId);
      addTearDown(storage.close);

      // There is no easy way to verify that the project ID was used, other than
      // to create a bucket and assume that it is associated with the correct
      // project.
      await createBucketWithTearDown(storage, 'storage_with_project_id');
      },
      skip: TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? '"gcloud auth login" is required for tests using application '
                'default credentials'
          : false,
    );

    test('constructor with client and project id', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'storage_with_client_and_project_id',
      );
      addTearDown(testClient.endTest);

      storage = Storage(client: testClient, projectId: projectId);
      addTearDown(storage.close);

      // There is no easy way to verify that the project ID was used, other than
      // to create a bucket and assume that it is associated with the correct
      // project.
      await createBucketWithTearDown(
        storage,
        'storage_with_client_and_project_id',
      );
    });
  });
}
