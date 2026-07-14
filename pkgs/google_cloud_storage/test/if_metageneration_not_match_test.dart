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

/// Responds as Google Cloud Storage does when an `ifMetagenerationNotMatch`
/// precondition is not satisfied: a "304 Not Modified" with an empty body.
MockClient _notModifiedClient(void Function(http.Request) onRequest) =>
    MockClient((request) async {
      onRequest(request);
      return http.Response('', 304);
    });

void main() {
  group('ifMetagenerationNotMatch', () {
    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;

      setUp(() {
        (_, storage) = createStorageTestbenchClient();
      });

      tearDown(() => storage.close());

      test('patchBucket throws when the metageneration matches', () async {
        final bucketName = bucketNameWithTearDown(storage, 'imnm_pch_bkt');
        final created = await storage.createBucket(
          BucketMetadata(name: bucketName),
        );

        await expectLater(
          storage.patchBucket(
            bucketName,
            BucketMetadataPatchBuilder()..labels = {'color': 'red'},
            ifMetagenerationNotMatch: created.metageneration,
          ),
          throwsA(isA<NotModifiedException>()),
        );

        // The bucket must be left untouched.
        final actual = await storage.bucketMetadata(bucketName);
        expect(actual.labels, anyOf(isNull, isEmpty));
        expect(actual.metageneration, created.metageneration);
      });

      test('patchBucket succeeds when the metageneration differs', () async {
        final bucketName = bucketNameWithTearDown(storage, 'imnm_pch_bkt_ok');
        final created = await storage.createBucket(
          BucketMetadata(name: bucketName),
        );

        final actual = await storage.patchBucket(
          bucketName,
          BucketMetadataPatchBuilder()..labels = {'color': 'red'},
          ifMetagenerationNotMatch: created.metageneration! + BigInt.one,
        );

        expect(actual.labels, containsPair('color', 'red'));
      });

      test('uploadObject throws when the metageneration matches', () async {
        final bucketName = bucketNameWithTearDown(storage, 'imnm_upl_obj');
        await storage.createBucket(BucketMetadata(name: bucketName));

        final created = await storage.uploadObject(bucketName, 'file.txt', [
          1,
          2,
          3,
        ]);

        await expectLater(
          storage.uploadObject(bucketName, 'file.txt', [
            4,
            5,
            6,
          ], ifMetagenerationNotMatch: created.metageneration),
          throwsA(isA<NotModifiedException>()),
        );

        // The content must be left untouched.
        final content = await storage.downloadObject(bucketName, 'file.txt');
        expect(content, [1, 2, 3]);
      });
    });

    test('patchBucket sends the query parameter', () async {
      late Uri requestUrl;
      final storage = Storage(
        client: _notModifiedClient((request) => requestUrl = request.url),
        projectId: 'fake project',
      );

      await expectLater(
        storage.patchBucket(
          'bucket',
          BucketMetadataPatchBuilder()..labels = {'color': 'red'},
          ifMetagenerationNotMatch: BigInt.two,
        ),
        throwsA(isA<NotModifiedException>()),
      );

      expect(requestUrl.queryParameters['ifMetagenerationNotMatch'], '2');
    });

    test('uploadObject sends the query parameter', () async {
      late Uri requestUrl;
      final storage = Storage(
        client: _notModifiedClient((request) => requestUrl = request.url),
        projectId: 'fake project',
      );

      await expectLater(
        storage.uploadObject('bucket', 'file.txt', [
          1,
          2,
          3,
        ], ifMetagenerationNotMatch: BigInt.two),
        throwsA(isA<NotModifiedException>()),
      );

      expect(requestUrl.queryParameters['ifMetagenerationNotMatch'], '2');
    });

    test('uploadObjectFromString sends the query parameter', () async {
      late Uri requestUrl;
      final storage = Storage(
        client: _notModifiedClient((request) => requestUrl = request.url),
        projectId: 'fake project',
      );

      await expectLater(
        storage.uploadObjectFromString(
          'bucket',
          'file.txt',
          'hello',
          ifMetagenerationNotMatch: BigInt.two,
        ),
        throwsA(isA<NotModifiedException>()),
      );

      expect(requestUrl.queryParameters['ifMetagenerationNotMatch'], '2');
    });

    test('a 304 response is reported as a NotModifiedException', () async {
      final storage = Storage(
        client: _notModifiedClient((_) {}),
        projectId: 'fake project',
      );

      await expectLater(
        storage.patchBucket(
          'bucket',
          BucketMetadataPatchBuilder()..labels = {'color': 'red'},
          ifMetagenerationNotMatch: BigInt.one,
        ),
        throwsA(
          isA<NotModifiedException>().having(
            (e) => e.toString(),
            'toString()',
            contains('ifMetagenerationNotMatch'),
          ),
        ),
      );
    });

    test('other error responses are not translated', () async {
      final storage = Storage(
        client: MockClient((_) async => http.Response('{}', 412)),
        projectId: 'fake project',
      );

      await expectLater(
        storage.patchBucket(
          'bucket',
          BucketMetadataPatchBuilder()..labels = {'color': 'red'},
          ifMetagenerationNotMatch: BigInt.one,
        ),
        throwsA(isA<PreconditionFailedException>()),
      );
    });
  });
}
