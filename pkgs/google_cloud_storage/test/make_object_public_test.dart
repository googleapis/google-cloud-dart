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
import 'package:test/test.dart';

import 'test_utils.dart';

void makeObjectPublicTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('success', () async {
    final bucketName = await createBucketWithTearDown(storage, 'make_obj_pub');

    await storage.uploadObjectFromString(
      bucketName,
      'object.txt',
      'Hello World!',
    );

    await storage.makeObjectPublic(bucketName, 'object.txt');
    final md = await storage.objectMetadata(
      bucketName,
      'object.txt',
      projection: 'full',
    );
    expect(
      md.acl,
      contains(
        isA<ObjectAccessControl>().having((e) => (e.entity, e.role), '', (
          'allUsers',
          'READER',
        )),
      ),
    );
  });

  test('no object', () async {
    final bucketName = await createBucketWithTearDown(storage, 'make_obj_pub');

    await expectLater(
      () => storage.makeObjectPublic(bucketName, 'non-existent.txt'),
      throwsA(isA<NotFoundException>()),
    );
  });
}

void main() {
  group('make object public', () {
    group(
      'google-cloud',
      tags: ['google-cloud'],
      skip: 'public access not allowed in test project',
      () {
        makeObjectPublicTest(Storage.new);
      },
    );

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;

      setUp(() {
        storage = Storage(
          projectId: 'test-project',
          apiEndpoint: 'localhost:9000',
          useAuthWithCustomEndpoint: false,
          client: http.Client(),
        );
      });

      tearDown(() => storage.close());

      makeObjectPublicTest(() => storage);
    });
  });
}
