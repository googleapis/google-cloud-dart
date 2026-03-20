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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/file_upload.dart'
    show fixedBoundaryString;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

class ProxyHttpClient extends http.BaseClient {
  final http.Client _client;
  String c1 = '1';

  ProxyHttpClient(this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest originalRequest) {
    originalRequest.headers['x-retry-test-id'] = c1;
    return _client.send(originalRequest);
  }

  @override
  void close() => _client.close();
}

void main() async {
  late Storage storage;
  late ProxyHttpClient client;

  group('download object', () {
    group('storage-testbench', tags: ['storage-testbench'], () {
      setUp(() async {
        client = ProxyHttpClient(http.Client());
        storage = Storage(
          projectId: 'test-project',
          apiEndpoint: 'localhost:9000',
          useAuthWithCustomEndpoint: false,
          client: client,
        );
      });

      test('empty object', () async {
        final c2 = http.Client();
        final r = await c2.post(
          Uri.parse('http://localhost:9000/retry_test'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'instructions': {
              'storage.objects.get': ['return-503'],
            },
            'transport': 'HTTP',
          }),
        );
        print(r.body);

        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_empty',
        );

        await storage.uploadObject(
          bucketName,
          'object1',
          [],
          ifGenerationMatch: BigInt.zero,
        );

        client.c1 = r.body;
        final data = await storage.downloadObject(bucketName, 'object1');

        expect(data, isEmpty);
      });

      tearDown(() => storage.close());
    });

    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() async {
        fixedBoundaryString = 'boundary';
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('empty object', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_empty',
        );

        await storage.uploadObject(
          bucketName,
          'object1',
          [],
          ifGenerationMatch: BigInt.zero,
        );

        final data = await storage.downloadObject(bucketName, 'object1');

        expect(data, isEmpty);
      });
      for (var i = 1; i <= 16_777_216; i *= 4) {
        test('object of size $i bytes', () async {
          final bucketName = await createBucketWithTearDown(
            storage,
            'dl_obj_sz_$i',
          );

          final uploadedData = Uint8List(i);
          for (var j = 0; j < i; j++) {
            uploadedData[j] = j % 256;
          }
          await storage.uploadObject(
            bucketName,
            'object1',
            uploadedData,
            ifGenerationMatch: BigInt.zero,
          );
          final downloadedData = await storage.downloadObject(
            bucketName,
            'object1',
          );

          expect(downloadedData, uploadedData);
        });
      }

      test('gzipped', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_gzipped',
        );

        await storage.uploadObject(
          bucketName,
          'object1',
          gzip.encode(utf8.encode('Hello World!')),
          metadata: ObjectMetadata(
            contentType: 'text/plain',
            contentEncoding: 'gzip',
          ),
          ifGenerationMatch: BigInt.zero,
        );

        final data = await storage.downloadObject(bucketName, 'object1');

        expect(data, utf8.encode('Hello World!'));
      });

      test('with generation', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_gen',
          metadata: BucketMetadata(versioning: BucketVersioning(enabled: true)),
        );

        final metadataV1 = await storage.uploadObject(bucketName, 'object1', [
          1,
        ], ifGenerationMatch: BigInt.zero);
        addTearDown(
          () => storage.deleteObject(
            bucketName,
            'object1',
            generation: metadataV1.generation,
          ),
        );

        final metadataV2 = await storage.uploadObject(bucketName, 'object1', [
          2,
        ], ifGenerationMatch: metadataV1.generation);
        addTearDown(
          () => storage.deleteObject(
            bucketName,
            'object1',
            generation: metadataV2.generation,
          ),
        );

        final v1Data = await storage.downloadObject(
          bucketName,
          'object1',
          generation: metadataV1.generation,
        );
        expect(v1Data, [1]);

        final v2Data = await storage.downloadObject(
          bucketName,
          'object1',
          generation: metadataV2.generation,
        );
        expect(v2Data, [2]);
      });

      test('with ifGenerationMatch success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_if_gen_match_ok',
        );

        final metadata = await storage.uploadObject(bucketName, 'object1', [
          1,
        ], ifGenerationMatch: BigInt.zero);

        // Success case
        await storage.downloadObject(
          bucketName,
          'object1',
          ifGenerationMatch: metadata.generation,
        );
      });

      test('with ifGenerationMatch failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_if_gen_match_fail',
        );

        final metadata = await storage.uploadObject(bucketName, 'object1', [
          1,
        ], ifGenerationMatch: BigInt.zero);

        // Failure case
        await expectLater(
          () => storage.downloadObject(
            bucketName,
            'object1',
            ifGenerationMatch: metadata.generation! + BigInt.one,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });

      test('with ifMetagenerationMatch success', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_if_mgen_match_ok',
        );

        final metadata = await storage.uploadObject(bucketName, 'object1', [
          1,
        ], ifGenerationMatch: BigInt.zero);

        await storage.downloadObject(
          bucketName,
          'object1',
          ifMetagenerationMatch: metadata.metageneration,
        );
      });

      test('with ifMetagenerationMatch failure', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'dl_obj_if_mgen_match_fail',
        );

        final metadata = await storage.uploadObject(bucketName, 'object1', [
          1,
        ], ifGenerationMatch: BigInt.zero);

        // Failure case
        await expectLater(
          () => storage.downloadObject(
            bucketName,
            'object1',
            ifMetagenerationMatch: metadata.metageneration! + BigInt.one,
          ),
          throwsA(isA<PreconditionFailedException>()),
        );
      });
    });
  });

  test('hash failure', () async {
    var count = 0;
    final mockClient = MockClient((request) async {
      count++;
      final headers = {'content-type': 'text/plain; charset=UTF-8'};
      if (count == 1) {
        headers['x-goog-hash'] = 'crc32c=/BAD';
      } else if (count == 2) {
        headers['x-goog-hash'] = 'md5=/BAD';
      } else {
        headers['x-goog-hash'] = 'crc32c=/mzx3A==,md5=7Qdih1MuhjZehB6Sv8UNjA==';
      }
      return http.Response('Hello World!', 200, headers: headers);
    });

    final storage = Storage(client: mockClient, projectId: 'fake project');

    final actualData = await storage.downloadObject('bucket', 'object');
    expect(actualData, utf8.encode('Hello World!'));
  });
}
