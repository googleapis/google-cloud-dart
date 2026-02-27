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

@Tags(['firebase-emulator'])
@TestOn('vm')
library;

import 'dart:convert';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';

void main() async {
  group('smoke tests', () {
    test('STORAGE_EMULATOR_HOST configuration', () async {
      final storage = Storage();
      addTearDown(storage.close);

      const bucketName = 'storage_emulator_host';

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

    test('explicit configuration', () async {
      final storage = Storage(
        projectId: 'test-project',
        apiEndpoint: '127.0.0.1:9199',
        useAuthWithCustomEndpoint: false,
      );
      addTearDown(storage.close);

      const bucketName = 'explicit_configuration';

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
