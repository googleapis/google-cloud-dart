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
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:google_cloud_auth/src/application_default_credentials.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart';

String _pkcs8ToPem(Uint8List pkcs8Bytes) {
  final b64 = base64.encode(pkcs8Bytes);
  final lines = <String>['-----BEGIN PRIVATE KEY-----'];
  for (var i = 0; i < b64.length; i += 64) {
    lines.add(b64.substring(i, min(i + 64, b64.length)));
  }
  lines.add('-----END PRIVATE KEY-----');
  return lines.join('\n');
}

final _canUseWebCrypto = () {
  if (!const bool.fromEnvironment('dart.library.io')) return true;
  final versionStr = Platform.version.split(' ').first;
  final parts = versionStr.split('.').map(int.tryParse).toList();
  if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
    if (parts[0]! > 3) return true;
    if (parts[0]! == 3 && parts[1]! >= 13) return true;
  }
  return false;
}();

void main() {
  late String privateKeyPem;
  late Directory tempDir;

  setUpAll(() async {
    if (!_canUseWebCrypto) return;
    final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
      2048,
      BigInt.from(65537),
      Hash.sha256,
    );
    final pkcs8Bytes = await keyPair.privateKey.exportPkcs8Key();
    privateKeyPem = _pkcs8ToPem(pkcs8Bytes);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('adc_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('applicationDefaultCredentials', () {
    test(
      'loads ServiceAccountCredentials from GOOGLE_APPLICATION_CREDENTIALS',
      () async {
        final saFile = File('${tempDir.path}/service_account.json');
        await saFile.writeAsString(
          jsonEncode({
            'type': 'service_account',
            'project_id': 'env-project',
            'private_key': privateKeyPem,
            'client_email': 'env-sa@project.iam.gserviceaccount.com',
          }),
        );

        final signer = await internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'GOOGLE_APPLICATION_CREDENTIALS') return saFile.path;
            return null;
          },
        );

        expect(signer, isA<ServiceAccountCredentials>());
        expect(signer.clientEmail, 'env-sa@project.iam.gserviceaccount.com');

        final signature = await signer.sign(utf8.encode('test'));
        expect(signature, isNotEmpty);
      },
      skip: _canUseWebCrypto ? null : 'Requires Dart 3.13 or later',
    );

    test('throws CredentialException when GOOGLE_APPLICATION_CREDENTIALS file '
        'does not exist', () async {
      expect(
        () => internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
              return '${tempDir.path}/non_existent.json';
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

    test('throws CredentialException when GOOGLE_APPLICATION_CREDENTIALS is '
        'not valid JSON', () async {
      final invalidFile = File('${tempDir.path}/invalid.json');
      await invalidFile.writeAsString('not a json file');

      expect(
        () => internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
              return invalidFile.path;
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

    test('throws CredentialException when GOOGLE_APPLICATION_CREDENTIALS is '
        'not a service account', () async {
      final userFile = File('${tempDir.path}/user_creds.json');
      await userFile.writeAsString(
        jsonEncode({
          'type': 'authorized_user',
          'client_id': 'client-id',
          'client_secret': 'client-secret',
          'refresh_token': 'token',
        }),
      );

      expect(
        () => internalDefaultCredentials(
          getEnvironmentVariable: (String name) {
            if (name == 'GOOGLE_APPLICATION_CREDENTIALS') {
              return userFile.path;
            }
            return null;
          },
        ),
        throwsA(
          isA<CredentialException>().having(
            (e) => e.message,
            'message',
            contains("has type 'authorized_user'"),
          ),
        ),
      );
    });

    test('loads ServiceAccountCredentials from well-known file', () async {
      final wellKnownFile = File('${tempDir.path}/gcloud_adc.json');
      await wellKnownFile.writeAsString(
        jsonEncode({
          'type': 'service_account',
          'project_id': 'wk-project',
          'private_key': privateKeyPem,
          'client_email': 'wk-sa@project.iam.gserviceaccount.com',
        }),
      );

      final signer = await internalDefaultCredentials(
        getEnvironmentVariable: (String name) => null,
        wellKnownFilePath: wellKnownFile.path,
      );

      expect(signer, isA<ServiceAccountCredentials>());
      expect(signer.clientEmail, 'wk-sa@project.iam.gserviceaccount.com');
    }, skip: _canUseWebCrypto ? null : 'Requires Dart 3.13 or later');

    test(
      'throws CredentialException when well-known file is not valid JSON',
      () async {
        final invalidFile = File('${tempDir.path}/invalid_adc.json');
        await invalidFile.writeAsString('not a json file');

        expect(
          () => internalDefaultCredentials(
            getEnvironmentVariable: (String name) => null,
            wellKnownFilePath: invalidFile.path,
          ),
          throwsA(
            isA<CredentialException>().having(
              (e) => e.message,
              'message',
              contains('not a valid JSON file'),
            ),
          ),
        );
      },
    );

    test('throws CredentialException when well-known file is not a service '
        'account', () async {
      final userFile = File('${tempDir.path}/user_adc.json');
      await userFile.writeAsString(
        jsonEncode({
          'type': 'authorized_user',
          'client_id': 'client-id',
          'client_secret': 'client-secret',
          'refresh_token': 'token',
        }),
      );

      expect(
        () => internalDefaultCredentials(
          getEnvironmentVariable: (String name) => null,
          wellKnownFilePath: userFile.path,
        ),
        throwsA(
          isA<CredentialException>().having(
            (e) => e.message,
            'message',
            contains("has type 'authorized_user'"),
          ),
        ),
      );
    });

    test('falls back to ComputeEngineCredentials when metadata server is '
        'available', () async {
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

      final signer = await internalDefaultCredentials(
        client: mockClient,
        getEnvironmentVariable: (String name) => null,
        wellKnownFilePath: '${tempDir.path}/non_existent.json',
      );

      expect(signer, isA<ComputeEngineCredentials>());
      expect(signer.clientEmail, 'gce-sa@project.iam.gserviceaccount.com');
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

    test(
      'defaultCredentials delegates to internalDefaultCredentials',
      () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        expect(
          () => defaultCredentials(client: mockClient),
          throwsA(isA<CredentialException>()),
        );
      },
    );

    test(
      'signs message using defaultCredentials',
      tags: ['google-cloud'],
      () async {
        final signer = await defaultCredentials();
        expect(signer.clientEmail, contains('@'));

        final message = utf8.encode('Hello from defaultCredentials!');
        final signature = await signer.sign(message);

        expect(signature, isNotEmpty);
        expect(signature.length, greaterThan(64));
      },
    );
  });
}
