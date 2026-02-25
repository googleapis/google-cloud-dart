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

import 'dart:convert';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() async {
  late Storage storage;
  late http.Client client;

  group('smoke tests', () {
    setUp(() async {
      client = http.Client();
      storage = Storage(
        client: client,
        projectId: 'test-project',
        apiEndpoint: '127.0.0.1:9199',
        useAuthWithCustomEndpoint: false,
      );
    });

    tearDown(() => storage.close());

    test('upload and download object', () async {
      const bucketName = 'insert_object_new';

      final objectMetadata = await storage.insertObject(
        bucketName,
        'object1',
        utf8.encode('Hello World!'),
        ifGenerationMatch: BigInt.zero,
      );
      expect(objectMetadata.size, BigInt.from(12));

      expect(
        await storage.downloadObject(bucketName, 'object1'),
        utf8.encode('Hello World!'),
      );
    });
  });
}
