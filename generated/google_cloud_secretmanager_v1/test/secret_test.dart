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
library;

import 'dart:math';

import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;
import 'package:google_cloud_secretmanager_v1/secretmanager.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() async {
  late SecretManagerService secretManagerService;
  late http.Client client;

  group('secret', tags: ['integration'], () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/cloud-platform'],
          );

      client = await authClient();
      secretManagerService = SecretManagerService(client: client);
    });

    tearDown(() => secretManagerService.close());
    test('create_and_update', () async {
      final secretName =
          '${Random().nextInt(999999999)}${Random().nextInt(999999999)}';

      final createdSecret = await secretManagerService.createSecret(
        CreateSecretRequest(
          parent: 'projects/$projectId',
          secretId: secretName,
          secret: Secret(
            replication: Replication(automatic: Replication_Automatic()),
            ttl: protobuf.Duration(seconds: 120),
          ),
        ),
      );
      expect(createdSecret.name, endsWith(secretName));

      final updatedSecret = await secretManagerService.updateSecret(
        UpdateSecretRequest(
          secret: Secret(
            name: createdSecret.name,
            annotations: {'a': 'b'},
            labels: {'x': 'y'},
          ),
          updateMask: protobuf.FieldMask(paths: ['annotations']),
        ),
      );
      expect(updatedSecret.name, endsWith(secretName));
      expect(updatedSecret.annotations, {'a': 'b'});
      expect(updatedSecret.labels, isEmpty); // Not in `updateMask`.
    });
  });
}
