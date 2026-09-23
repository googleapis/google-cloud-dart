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

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:google_cloud_auth/src/application_default_credentials.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('applicationDefaultCredentials', () {
    test('available on Google Compute Engine', () async {
      // TODO(https://github.com/dart-lang/test/issues/2576): Throw then this
      // is fixed.
      if (!await ComputeEngineCredentials.isOnComputeEngine()) {
        return;
      }
      // Credentials should always be available when running on GCE.
      final creds = await defaultCredentials();
      creds.close();
    });

    group('ServiceAccountCredentials', () {
      group('from GOOGLE_APPLICATION_CREDENTIALS', () {
        test('success', () async {
          final saFilePath = await writeTempFile(
            'service_account.json',
            jsonEncode({
              'type': 'service_account',
              'project_id': 'env-project',
              'private_key': testPrivateKey,
              'client_email': 'env-sa@project.iam.gserviceaccount.com',
            }),
          );

          final credentials = await internalDefaultCredentials(
            readEnvironment: (String name) {
              if (name == 'GOOGLE_APPLICATION_CREDENTIALS') return saFilePath;
              return null;
            },
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

        test('file does not exist', () async {
          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) {
                if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
                  return 'non_existent.json';
                }
                return null;
              },
            ),
            throwsA(
              isA<CredentialException>().having(
                (e) => e.message,
                'message',
                contains('does not exist'),
              ),
            ),
          );
        });

        test('not valid JSON', () async {
          final invalidFilePath = await writeTempFile(
            'invalid.json',
            'not a json file',
          );

          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) {
                if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
                  return invalidFilePath;
                }
                return null;
              },
            ),
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
          final userFilePath = await writeTempFile(
            'user_creds.json',
            jsonEncode({'type': 'unrecognized_type'}),
          );

          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) {
                if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
                  return userFilePath;
                }
                return null;
              },
            ),
            throwsA(
              isA<CredentialException>().having(
                (e) => e.message,
                'message',
                contains("has type 'unrecognized_type'"),
              ),
            ),
          );
        });

        test('malformed service account missing client_email', () async {
          final saFilePath = await writeTempFile(
            'incomplete_sa.json',
            jsonEncode({
              'type': 'service_account',
              'project_id': 'env-project',
              'private_key': testPrivateKey,
            }),
          );

          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) {
                if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
                  return saFilePath;
                }
                return null;
              },
            ),
            throwsA(
              isA<CredentialException>().having(
                (e) => e.message,
                'message',
                contains('Failed to parse service account credentials'),
              ),
            ),
          );
        });
      });

      test('from CLOUDSDK_CONFIG', () async {
        final saFilePath = await writeTempFile(
          'application_default_credentials.json',
          jsonEncode({
            'type': 'service_account',
            'project_id': 'env-project',
            'private_key': testPrivateKey,
            'client_email': 'env-sa@project.iam.gserviceaccount.com',
          }),
        );
        final configDir = saFilePath.substring(
          0,
          saFilePath.lastIndexOf(RegExp(r'[/\\]')),
        );

        final credentials = await internalDefaultCredentials(
          readEnvironment: (String name) {
            if (name == 'CLOUDSDK_CONFIG') return configDir;
            return null;
          },
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
        test('success', () async {
          final saFilePath = await writeTempFile(
            'service_account.json',
            jsonEncode({
              'type': 'service_account',
              'project_id': 'env-project',
              'private_key': testPrivateKey,
              'client_email': 'env-sa@project.iam.gserviceaccount.com',
            }),
          );

          final credentials = await internalDefaultCredentials(
            readEnvironment: (String name) => null,
            wellKnownFilePath: saFilePath,
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

        test('not valid JSON', () async {
          final invalidFilePath = await writeTempFile(
            'invalid.json',
            'not a json file',
          );

          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) => null,
              wellKnownFilePath: invalidFilePath,
            ),
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
          final userFilePath = await writeTempFile(
            'user_creds.json',
            jsonEncode({'type': 'unrecognized_type'}),
          );

          expect(
            () => internalDefaultCredentials(
              readEnvironment: (String name) => null,
              wellKnownFilePath: userFilePath,
            ),
            throwsA(
              isA<CredentialException>().having(
                (e) => e.message,
                'message',
                contains("has type 'unrecognized_type'"),
              ),
            ),
          );
        });
      });
    }, testOn: 'vm');
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
      readEnvironment: (String name) => null,
      wellKnownFilePath: 'non_existent.json',
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

  test('ComputeEngineCredentials forwards GCE_METADATA_HOST from '
      'readEnvironment', () async {
    final hostsContacted = <String>{};
    final mockClient = MockClient((request) async {
      hostsContacted.add(request.url.host);
      return switch (request.url.path) {
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
      };
    });

    final credentials = await internalDefaultCredentials(
      client: mockClient,
      readEnvironment: (String name) => switch (name) {
        'GCE_METADATA_HOST' => 'custom-metadata-host',
        _ => null,
      },
      wellKnownFilePath: 'non_existent.json',
    );

    expect(credentials, isA<ComputeEngineCredentials>());
    expect(
      (credentials as ComputeEngineCredentials).metadataHost,
      equals('custom-metadata-host'),
    );
    expect(hostsContacted, equals({'custom-metadata-host'}));
  });

  test('throws CredentialException when no credentials can be found', () async {
    final mockClient = MockClient((request) async {
      throw http.ClientException('Connection refused');
    });

    expect(
      () => internalDefaultCredentials(
        client: mockClient,
        readEnvironment: (String name) => null,
        wellKnownFilePath: 'non_existent.json',
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
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '/custom/config',
            _ => null,
          },
        );
        expect(
          path,
          equals('/custom/config/application_default_credentials.json'),
        );
      });

      test('prioritizes CLOUDSDK_CONFIG over HOME', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '/custom/config',
            'HOME' => '/home/user',
            _ => null,
          },
        );
        expect(
          path,
          equals('/custom/config/application_default_credentials.json'),
        );
      });

      test('returns HOME-based config path when CLOUDSDK_CONFIG not set', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'HOME' => '/home/user',
            _ => null,
          },
        );
        expect(
          path,
          equals(
            '/home/user/.config/gcloud/application_default_credentials.json',
          ),
        );
      });

      test('returns null when no environment variables set', () {
        final path = wellKnownCredentialsPath((name) => null);
        expect(path, isNull);
      });

      test('returns null when HOME is empty', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'HOME' => '',
            _ => null,
          },
        );
        expect(path, isNull);
      });

      test('falls back to HOME when CLOUDSDK_CONFIG is empty', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '',
            'HOME' => '/home/user',
            _ => null,
          },
        );
        expect(
          path,
          equals(
            '/home/user/.config/gcloud/application_default_credentials.json',
          ),
        );
      });
    }, testOn: '!windows');

    group('Windows', () {
      test('returns CLOUDSDK_CONFIG path when set', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => r'C:\custom\config',
            _ => null,
          },
        );
        expect(
          path,
          equals(r'C:\custom\config\application_default_credentials.json'),
        );
      });

      test('prioritizes CLOUDSDK_CONFIG over APPDATA', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => r'C:\custom\config',
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
        );
        expect(
          path,
          equals(r'C:\custom\config\application_default_credentials.json'),
        );
      });

      test('returns APPDATA config path when CLOUDSDK_CONFIG not set', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
        );
        expect(
          path,
          equals(
            r'C:\Users\user\AppData\Roaming\gcloud\application_default_credentials.json',
          ),
        );
      });

      test('returns null when neither CLOUDSDK_CONFIG nor APPDATA is set', () {
        final path = wellKnownCredentialsPath((name) => null);
        expect(path, isNull);
      });

      test('returns null when APPDATA is empty', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'APPDATA' => '',
            _ => null,
          },
        );
        expect(path, isNull);
      });

      test('falls back to APPDATA when CLOUDSDK_CONFIG is empty', () {
        final path = wellKnownCredentialsPath(
          (name) => switch (name) {
            'CLOUDSDK_CONFIG' => '',
            'APPDATA' => r'C:\Users\user\AppData\Roaming',
            _ => null,
          },
        );
        expect(
          path,
          equals(
            r'C:\Users\user\AppData\Roaming\gcloud\application_default_credentials.json',
          ),
        );
      });
    }, testOn: 'windows');
  });
}
