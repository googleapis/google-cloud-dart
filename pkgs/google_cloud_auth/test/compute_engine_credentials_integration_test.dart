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

@Tags(['google-cloud'])
library;

import 'dart:convert';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:test/test.dart';

void main() {
  group('ComputeEngineCredentials', testOn: 'vm', () {
    test('signs message using ComputeEngineCredentials', () async {
      final creds = await ComputeEngineCredentials.create();
      expect(creds.clientEmail, contains('@'));

      final message = utf8.encode('Hello from ComputeEngineCredentials test!');
      final signature = await creds.sign(message);

      expect(signature, isNotEmpty);
      expect(signature.length, greaterThan(64));
    });
  });
}
