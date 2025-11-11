// Copyright 2025 Google LLC
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
library generative_test;

import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:test/test.dart';
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

void main() async {
  late SecretManagerService secretManangerService;
  late TestHttpClient testClient;

  group('secret', () {
    setUp(() async {
      final authClient = () async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/generative-language.retriever',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      secretManangerService = SecretManagerService(client: testClient);
    });

    tearDown(() => secretManangerService.close());
    test('create_and_update', () async {
      await testClient.startTest(
        'google_cloud_secretmanager_v1',
        'create_and_update',
      );

      final request = CreateSecretRequest(
        parent: 'projects/$projectId',
        secretId: "12345",
        secret: Secret(ttl: protobuf.Duration(seconds: 120)),
      );

      final secret = await secretManangerService.createSecret(request);

      expect(secret.name, "12345");
      await testClient.endTest();
    }, timeout: const Timeout(const Duration(seconds: 60)));
  });
}
