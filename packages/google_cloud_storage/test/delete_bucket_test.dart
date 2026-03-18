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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

  group('delete bucket', () {
    setUp(() {
      storage = Storage();
    });

    tearDown(() => storage.close());

    test('success', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(storage, 'del_bkt_ok');

      await storage.createBucket(BucketMetadata(name: bucketName));

      await storage.deleteBucket(bucketName);

      // Verify bucket is deleted.
      expect(
        () => storage.patchBucket(bucketName, BucketMetadataPatchBuilder()),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('delete non-existent bucket', tags: ['google-cloud'], () async {
      final bucketName = bucketNameWithTearDown(
        storage,
        'del_bkt_non_existent',
      );
      expect(
        () => storage.deleteBucket(bucketName),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'delete bucket with ifMetagenerationMatch success',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'del_bkt_w_if_mgen_match_ok',
        );

        final metadata = await storage.createBucket(
          BucketMetadata(name: bucketName),
        );

        await storage.deleteBucket(
          bucketName,
          ifMetagenerationMatch: metadata.metageneration,
        );

        // Verify bucket is deleted.
        expect(
          () => storage.patchBucket(bucketName, BucketMetadataPatchBuilder()),
          throwsA(isA<NotFoundException>()),
        );
      },
    );

    test(
      'delete bucket with ifMetagenerationMatch failure',
      tags: ['google-cloud'],
      () async {
        final bucketName = bucketNameWithTearDown(
          storage,
          'del_bkt_w_if_mgen_match_fail',
        );

        await storage.createBucket(BucketMetadata(name: bucketName));

        expect(
          () => storage.deleteBucket(
            bucketName,
            ifMetagenerationMatch: BigInt.zero,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );

        // Clean up.
        await storage.deleteBucket(bucketName);
      },
    );

    test('idempotent transport failure', () async {
      var count = 0;
      final mockClient = MockClient((request) async {
        count++;
        if (count == 1) {
          throw http.ClientException('Some transport failure');
        } else if (count == 2) {
          return http.Response('', 204);
        } else {
          throw StateError('Unexpected call count: $count');
        }
      });

      final storage = Storage(client: mockClient, projectId: projectId);

      await storage.deleteBucket('bucket', ifMetagenerationMatch: BigInt.one);
      expect(count, 2);
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

      final storage = Storage(client: mockClient, projectId: projectId);

      await expectLater(
        () => storage.deleteBucket('bucket'),
        throwsA(isA<http.ClientException>()),
      );
      expect(count, 1);
    });
  });
}
