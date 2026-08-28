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
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_auth/google_cloud_auth.dart';
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

void main() {
  late KeyPair<RsassaPkcs1V15PrivateKey, RsassaPkcs1V15PublicKey> testKeyPair;
  late String privateKeyPem;

  setUpAll(() async {
    testKeyPair = await RsassaPkcs1V15PrivateKey.generateKey(
      2048,
      BigInt.from(65537),
      Hash.sha256,
    );
    final pkcs8Bytes = await testKeyPair.privateKey.exportPkcs8Key();
    privateKeyPem = _pkcs8ToPem(pkcs8Bytes);
  });

  group('ServiceAccountCredentials', () {
    test('fromServiceAccountInfo creates valid credentials', () async {
      final info = {
        'type': 'service_account',
        'project_id': 'test-project',
        'private_key_id': 'key-id-123',
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
        'client_id': 'client-123',
        'token_uri': 'https://oauth2.googleapis.com/custom_token',
        'universe_domain': 'custom.domain.com',
        'quota_project_id': 'quota-project',
      };

      final creds = await ServiceAccountCredentials.fromServiceAccountInfo(
        info,
      );

      expect(
        creds.clientEmail,
        equals('test@test-project.iam.gserviceaccount.com'),
      );
      expect(
        creds.signerEmail,
        equals('test@test-project.iam.gserviceaccount.com'),
      );
      expect(
        creds.serviceAccountEmail,
        equals('test@test-project.iam.gserviceaccount.com'),
      );
      expect(creds.clientId, equals('client-123'));
      expect(creds.privateKeyId, equals('key-id-123'));
      expect(creds.projectId, equals('test-project'));
      expect(creds.quotaProjectId, equals('quota-project'));
      expect(
        creds.tokenUri,
        equals(Uri.parse('https://oauth2.googleapis.com/custom_token')),
      );
      expect(creds.universeDomain, equals('custom.domain.com'));
    });

    test(
      'fromServiceAccountInfo uses default token_uri and universe_domain',
      () async {
        final info = {
          'type': 'service_account',
          'private_key': privateKeyPem,
          'client_email': 'test@test-project.iam.gserviceaccount.com',
        };

        final creds = await ServiceAccountCredentials.fromServiceAccountInfo(
          info,
        );

        expect(
          creds.tokenUri,
          equals(Uri.parse('https://oauth2.googleapis.com/token')),
        );
        expect(creds.universeDomain, equals('googleapis.com'));
        expect(creds.clientId, isNull);
        expect(creds.privateKeyId, isNull);
        expect(creds.projectId, isNull);
        expect(creds.quotaProjectId, isNull);
      },
    );

    test('fromServiceAccountInfo throws on missing type', () async {
      final info = {
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test('fromServiceAccountInfo throws on invalid type', () async {
      final info = {
        'type': 'authorized_user',
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test('fromServiceAccountInfo throws on missing client_email', () async {
      final info = {'type': 'service_account', 'private_key': privateKeyPem};

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test('fromServiceAccountInfo throws on missing private_key', () async {
      final info = {
        'type': 'service_account',
        'client_email': 'test@test-project.iam.gserviceaccount.com',
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test(
      'fromServiceAccountInfo throws on non-string private_key_id',
      () async {
        final info = <String, Object?>{
          'type': 'service_account',
          'private_key': privateKeyPem,
          'client_email': 'test@test-project.iam.gserviceaccount.com',
          'private_key_id': 12345,
        };

        expect(
          () => ServiceAccountCredentials.fromServiceAccountInfo(info),
          throwsFormatException,
        );
      },
    );

    test('fromServiceAccountInfo throws on non-string client_id', () async {
      final info = <String, Object?>{
        'type': 'service_account',
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
        'client_id': 12345,
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test('fromServiceAccountInfo throws on non-string project_id', () async {
      final info = <String, Object?>{
        'type': 'service_account',
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
        'project_id': 12345,
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test(
      'fromServiceAccountInfo throws on non-string quota_project_id',
      () async {
        final info = <String, Object?>{
          'type': 'service_account',
          'private_key': privateKeyPem,
          'client_email': 'test@test-project.iam.gserviceaccount.com',
          'quota_project_id': 12345,
        };

        expect(
          () => ServiceAccountCredentials.fromServiceAccountInfo(info),
          throwsFormatException,
        );
      },
    );

    test(
      'fromServiceAccountInfo throws on non-string universe_domain',
      () async {
        final info = <String, Object?>{
          'type': 'service_account',
          'private_key': privateKeyPem,
          'client_email': 'test@test-project.iam.gserviceaccount.com',
          'universe_domain': 12345,
        };

        expect(
          () => ServiceAccountCredentials.fromServiceAccountInfo(info),
          throwsFormatException,
        );
      },
    );

    test('fromServiceAccountInfo throws on non-string token_uri', () async {
      final info = <String, Object?>{
        'type': 'service_account',
        'private_key': privateKeyPem,
        'client_email': 'test@test-project.iam.gserviceaccount.com',
        'token_uri': 12345,
      };

      expect(
        () => ServiceAccountCredentials.fromServiceAccountInfo(info),
        throwsFormatException,
      );
    });

    test('fromServiceAccountFile loads credentials from file', () async {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:google_cloud_auth/'),
      );
      final testServiceAccountFilePath = packageUri!
          .resolve('../test/test-project-db470-b6405252fba0.json')
          .toFilePath();
      final creds = await ServiceAccountCredentials.fromServiceAccountFile(
        testServiceAccountFilePath,
      );

      expect(
        creds.clientEmail,
        equals('testkey@test-project.iam.gserviceaccount.com'),
      );
      expect(creds.projectId, equals('test-project'));
      expect(
        creds.privateKeyId,
        equals('b6405252fba05768ca6b5f57a80ee58aad2dd354'),
      );
      expect(creds.clientId, equals('114569939335839849739'));
      expect(
        creds.tokenUri,
        equals(Uri.parse('https://oauth2.googleapis.com/token')),
      );
      expect(creds.universeDomain, equals('googleapis.com'));
    }, testOn: 'vm');

    test('fromServiceAccountString loads credentials from string', () async {
      final info = <String, Object?>{
        'type': 'service_account',
        'project_id': 'string-project',
        'private_key': privateKeyPem,
        'client_email': 'string@string-project.iam.gserviceaccount.com',
      };

      final creds = await ServiceAccountCredentials.fromServiceAccountString(
        jsonEncode(info),
      );

      expect(
        creds.clientEmail,
        equals('string@string-project.iam.gserviceaccount.com'),
      );
      expect(creds.projectId, equals('string-project'));
    });

    test('fromPkcs8 creates valid credentials', () async {
      final creds = await ServiceAccountCredentials.fromPkcs8(
        clientEmail: 'pkcs8@project.iam.gserviceaccount.com',
        privateKeyPkcs8: privateKeyPem,
        privateKeyId: 'pkcs8-key',
        projectId: 'pkcs8-project',
      );

      expect(
        creds.clientEmail,
        equals('pkcs8@project.iam.gserviceaccount.com'),
      );
      expect(creds.projectId, equals('pkcs8-project'));
      expect(creds.privateKeyId, equals('pkcs8-key'));
    });

    group('sign', () {
      test('signs message and signature is valid with public key', () async {
        final creds = await ServiceAccountCredentials.fromPkcs8(
          clientEmail: 'test@example.com',
          privateKeyPkcs8: privateKeyPem,
        );

        final message = utf8.encode('Hello Google Cloud!');
        final signature = await creds.sign(message);

        expect(signature, isNotEmpty);

        final isValid = await testKeyPair.publicKey.verifyBytes(
          signature,
          message,
        );
        expect(isValid, isTrue);
      });

      test('signature fails for modified message', () async {
        final creds = await ServiceAccountCredentials.fromPkcs8(
          clientEmail: 'test@example.com',
          privateKeyPkcs8: privateKeyPem,
        );

        final message = utf8.encode('Hello Google Cloud!');
        final signature = await creds.sign(message);

        final tamperedMessage = utf8.encode('Hello Google Cloud?');
        final isValid = await testKeyPair.publicKey.verifyBytes(
          signature,
          tamperedMessage,
        );
        expect(isValid, isFalse);
      });

      test('signs Uint8List message directly', () async {
        final creds = await ServiceAccountCredentials.fromPkcs8(
          clientEmail: 'test@example.com',
          privateKeyPkcs8: privateKeyPem,
        );

        final message = Uint8List.fromList([1, 2, 3, 4, 5]);
        final signature = await creds.sign(message);

        final isValid = await testKeyPair.publicKey.verifyBytes(
          signature,
          message,
        );
        expect(isValid, isTrue);
      });
    });
  });
}
