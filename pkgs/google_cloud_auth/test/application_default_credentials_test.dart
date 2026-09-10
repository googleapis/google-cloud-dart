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
    test('available on Google Compute Engine', () async {
      // TODO(https://github.com/dart-lang/test/issues/2576): Throw then this
      // is fixed.
      if (!await ComputeEngineCredentials.isOnComputeEngine()) {
        return;
      }
      // Credentials should always be available when running on GCE.
      await defaultCredentials();
    });

    group('ServiceAccountCredentials', () {
      group('from GOOGLE_APPLICATION_CREDENTIALS', () {
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

      test('from CLOUDSDK_CONFIG', () async {
        final saFile = File(
          '${tempDir.path}/application_default_credentials.json',
        );
        await saFile.writeAsString(
          jsonEncode({
            'type': 'service_account',
            'project_id': 'env-project',
            'private_key': testPrivateKey,
            'client_email': 'env-sa@project.iam.gserviceaccount.com',
          }),
        );

        final credentials = await internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'CLOUDSDK_CONFIG') return tempDir.path;
            return null;
          },
          isWindows: false,
        );

        expect(
          credentials,
          isA<ServiceAccountCredentials>().having(
            (e) => e.clientEmail,
            'clientEmail',
            'env-sa@project.iam.gserviceaccount.com',
          ),
        );
      }, skip: canUseWebCrypto ? null : 'Requires Dart 3.13 or later');

      group('from well-known file', () {
        testFileLoad(
          () => tempDir,
          (filePath) => internalDefaultCredentials(
            getEnvironmentVariable: (String name) => null,
            wellKnownFilePath: filePath,
          ),
        );
      });
    });
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

  test('throws CredentialException when no credentials can be found', () async {
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
  });

  group('getWellKnownCredentialsPath', () {
    group('POSIX', () {
      test('returns CLOUDSDK_CONFIG path when set', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '/custom/config',
            _ => null,
          },
          false,
        );
        expect(
          path,
          equals('/custom/config/application_default_credentials.json'),
        );
      });

      test('prioritizes CLOUDSDK_CONFIG over HOME', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '/custom/config',
            'HOME' => '/home/user',
            _ => null,
          },
          false,
        );
        expect(
          path,
          equals('/custom/config/application_default_credentials.json'),
        );
      });

      test('returns HOME-based config path when CLOUDSDK_CONFIG not set', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'HOME' => '/home/user',
            _ => null,
          },
          false,
        );
        expect(
          path,
          equals(
            '/home/user/.config/gcloud/application_default_credentials.json',
          ),
        );
      });

      test('returns null when neither CLOUDSDK_CONFIG nor HOME is set', () {
        final path = getWellKnownCredentialsPath((name) => null, false);
        expect(path, isNull);
      });

      test('returns null when HOME is empty', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'HOME' => '',
            _ => null,
          },
          false,
        );
        expect(path, isNull);
      });

      test('falls back to HOME when CLOUDSDK_CONFIG is empty', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '',
            'HOME' => '/home/user',
            _ => null,
          },
          false,
        );
        expect(
          path,
          equals(
            '/home/user/.config/gcloud/application_default_credentials.json',
          ),
        );
      });
    });

    group('Windows', () {
      test('returns CLOUDSDK_CONFIG path when set', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => r'C:\custom\config',
            _ => null,
          },
          true,
        );
        expect(
          path,
          equals(r'C:\custom\config\application_default_credentials.json'),
        );
      });

      test('prioritizes CLOUDSDK_CONFIG over APPDATA', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => r'C:\custom\config',
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
          true,
        );
        expect(
          path,
          equals(r'C:\custom\config\application_default_credentials.json'),
        );
      });

      test('returns APPDATA config path when CLOUDSDK_CONFIG not set', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
          true,
        );
        expect(
          path,
          equals(
            r'C:\Users\user\AppData\Roaming\gcloud\application_default_credentials.json',
          ),
        );
      });

      test('returns null when neither CLOUDSDK_CONFIG nor APPDATA is set', () {
        final path = getWellKnownCredentialsPath((name) => null, true);
        expect(path, isNull);
      });

      test('returns null when APPDATA is empty', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'APPDATA' => '',
            _ => null,
          },
          true,
        );
        expect(path, isNull);
      });

      test('falls back to APPDATA when CLOUDSDK_CONFIG is empty', () {
        final path = getWellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '',
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
          true,
        );
        expect(
          path,
          equals(
            r'C:\Users\user\AppData\Roaming\gcloud\application_default_credentials.json',
          ),
        );
      });
    });
  });
}
