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
import 'dart:io';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:google_cloud_auth/src/application_default_credentials.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void testFileLoad(
  Directory Function() tempDir,
  Future<GoogleCredentials> Function(String filePath) loadCredentials, {
  bool testNonExistentFile = false,
}) {
  test('success', () async {
    final saFile = File('${tempDir().path}/service_account.json');
    await saFile.writeAsString(
      jsonEncode({
        'type': 'service_account',
        'project_id': 'env-project',
        'private_key': testPrivateKey,
        'client_email': 'env-sa@project.iam.gserviceaccount.com',
      }),
    );

    final credentials = await loadCredentials(saFile.path);

    expect(
      credentials,
      isA<ServiceAccountCredentials>().having(
        (e) => e.clientEmail,
        'clientEmail',
        'env-sa@project.iam.gserviceaccount.com',
      ),
    );
  }, skip: canUseWebCrypto ? null : 'Requires Dart 3.13 or later');

  if (testNonExistentFile) {
    test('file does not exist', () async {
      expect(
        () => loadCredentials('${tempDir().path}/non_existent.json'),
        throwsA(
          isA<CredentialException>().having(
            (e) => e.message,
            'message',
            contains('does not exist'),
          ),
        ),
      );
    });
  }

  test('not valid JSON', () async {
    final invalidFile = File('${tempDir().path}/invalid.json');
    await invalidFile.writeAsString('not a json file');

    expect(
      () => loadCredentials(invalidFile.path),
      throwsA(
        isA<CredentialException>().having(
          (e) => e.message,
          'message',
          contains('not a valid JSON file'),
        ),
      ),
    );
  });

  test('unrecognized type', () async {
    final userFile = File('${tempDir().path}/user_creds.json');
    await userFile.writeAsString(jsonEncode({'type': 'unrecognized_type'}));

    expect(
      () => loadCredentials(userFile.path),
      throwsA(
        isA<CredentialException>().having(
          (e) => e.message,
          'message',
          contains("has type 'unrecognized_type'"),
        ),
      ),
    );
  });
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('adc_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('applicationDefaultCredentials', () {
    group('ServiceAccountCredentials from GOOGLE_APPLICATION_CREDENTIALS', () {
      testFileLoad(
        () => tempDir,
        (filePath) => internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'GOOGLE_APPLICATION_CREDENTIALS') return filePath;
            return null;
          },
        ),
        testNonExistentFile: true,
      );
    });

    group('ServiceAccountCredentials from well-known file', () {
      testFileLoad(
        () => tempDir,
        (filePath) => internalDefaultCredentials(
          getEnvironmentVariable: (String name) => null,
          wellKnownFilePath: filePath,
        ),
      );
    });

    test('ComputeEngineCredentials from metadata server', () async {
      final mockClient = MockClient(
        (request) async => switch (request.url.path) {
          '/computeMetadata/v1/' => http.Response(
            'ok',
            200,
            headers: {'metadata-flavor': 'Google'},
          ),
          '/computeMetadata/v1/instance/service-accounts/default/email' =>
            http.Response(
              'gce-sa@project.iam.gserviceaccount.com',
              200,
              headers: {'metadata-flavor': 'Google'},
            ),
          '/computeMetadata/v1/universe/universe-domain' => http.Response(
            'googleapis.com',
            200,
            headers: {'metadata-flavor': 'Google'},
          ),
          _ => http.Response('Not found', 404),
        },
      );

      final credentials = await internalDefaultCredentials(
        client: mockClient,
        getEnvironmentVariable: (String name) => null,
        wellKnownFilePath: '${tempDir.path}/non_existent.json',
      );

      expect(
        credentials,
        isA<ComputeEngineCredentials>().having(
          (e) => e.clientEmail,
          'clientEmail',
          'gce-sa@project.iam.gserviceaccount.com',
        ),
      );
    });

    test(
      'throws CredentialException when no credentials can be found',
      () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        expect(
          () => internalDefaultCredentials(
            client: mockClient,
            getEnvironmentVariable: (String name) => null,
            wellKnownFilePath: '${tempDir.path}/non_existent.json',
          ),
          throwsA(
            isA<CredentialException>().having(
              (e) => e.message,
              'message',
              contains('Could not load Application Default Credentials'),
            ),
          ),
        );
      },
    );
  });
}
