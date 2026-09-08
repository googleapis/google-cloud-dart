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
import 'dart:io';
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
  late KeyPair<RsassaPkcs1V15PrivateKey, RsassaPkcs1V15PublicKey> testKeyPair;
  late String privateKeyPem;

  group(
    'ServiceAccountCredentials',
    () {
      setUpAll(() async {
        testKeyPair = await RsassaPkcs1V15PrivateKey.generateKey(
          2048,
          BigInt.from(65537),
          Hash.sha256,
        );
        final pkcs8Bytes = await testKeyPair.privateKey.exportPkcs8Key();
        privateKeyPem = _pkcs8ToPem(pkcs8Bytes);
      });

      group('fromServiceAccountInfo', () {
        test('all keys set', () async {
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

          expect(creds.clientId, equals('client-123'));
          expect(creds.privateKeyId, equals('key-id-123'));
          expect(creds.projectId, equals('test-project'));
          expect(creds.quotaProjectId, equals('quota-project'));
          expect(
            creds.tokenUri,
            equals(Uri.https('oauth2.googleapis.com', '/custom_token')),
          );
          expect(creds.universeDomain, equals('custom.domain.com'));
        });

        test('minimal keys set', () async {
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
            equals(Uri.https('oauth2.googleapis.com', '/token')),
          );
          expect(creds.universeDomain, equals('googleapis.com'));
          expect(creds.clientId, isNull);
          expect(creds.privateKeyId, isNull);
          expect(creds.projectId, isNull);
          expect(creds.quotaProjectId, isNull);
        });

        test('interpolates custom universe_domain in '
            'default token_uri', () async {
          final info = {
            'type': 'service_account',
            'private_key': privateKeyPem,
            'client_email': 'test@test-project.iam.gserviceaccount.com',
            'universe_domain': 'custom.domain.com',
          };

          final creds = await ServiceAccountCredentials.fromServiceAccountInfo(
            info,
          );

          expect(
            creds.tokenUri,
            equals(Uri.https('oauth2.custom.domain.com', '/token')),
          );
          expect(creds.universeDomain, equals('custom.domain.com'));
        });

        test('throws on missing type', () async {
          final info = {
            'private_key': privateKeyPem,
            'client_email': 'test@test-project.iam.gserviceaccount.com',
          };

          expect(
            () => ServiceAccountCredentials.fromServiceAccountInfo(info),
            throwsFormatException,
          );
        });

        test('throws on invalid type', () async {
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

        test('throws on missing client_email', () async {
          final info = {
            'type': 'service_account',
            'private_key': privateKeyPem,
          };

          expect(
            () => ServiceAccountCredentials.fromServiceAccountInfo(info),
            throwsFormatException,
          );
        });

        test('throws on missing private_key', () async {
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

        test('throws on non-string client_id', () async {
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

        test(
          'fromServiceAccountInfo throws on non-string project_id',
          () async {
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
          },
        );

        test('throws on non-string quota_project_id', () async {
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
        });

        test('throws on non-string universe_domain', () async {
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
        });

        test('throws on non-string token_uri', () async {
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

        test('loads credentials from string', () async {
          final info = <String, Object?>{
            'type': 'service_account',
            'project_id': 'string-project',
            'private_key': privateKeyPem,
            'client_email': 'string@string-project.iam.gserviceaccount.com',
          };

          final creds =
              await ServiceAccountCredentials.fromServiceAccountString(
                jsonEncode(info),
              );

          expect(
            creds.clientEmail,
            equals('string@string-project.iam.gserviceaccount.com'),
          );
          expect(creds.projectId, equals('string-project'));
        });
      });

      group('fromServiceAccountFile', () {
        test('loads credentials from file', () async {
          final tempDir = await Directory.systemTemp.createTemp('sa_test_');
          final tempFile = File('${tempDir.path}/service_account.json');
          addTearDown(() async {
            await tempDir.delete(recursive: true);
          });

          // This string was taken from a real key dump.
          const jsonString = r'''
{
  "type": "service_account",
  "project_id": "test-project",
  "private_key_id": "b6405252fba05768ca6b5f57a80ee58aad2dd354",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDybXE/bJWPH1ct\nWWZw1SJaJYGv6KzS/Zunvr0Oepz4TCqW5CyboISm2yHBr6Qv8oPAYPaFg357HTD8\nooMvbeLSnBO1HyYCMdCiQvFAl2moWfJfE+KmujYYe91zOnl2eLTacGzChKqYh4nX\naZjycQ8YYEM/Tde1zwxEAXTOJ6PI2HfXtqIvXU4KUKN3AShOq/KdPG5Qs0sRY7fT\nievhW3/e+D6upLV//zgJjSP79qsRT8Xb7DRfVhB833p6hrV693Y/iwFlLo8uHa/L\n0khXdCPJVJrX9ch31IXkwIUygwUTs3t0b/yDHTTgPO3aoMjV2q3SRpzEjne0vp7X\nxUg2ZQjtAgMBAAECggEAERtA6QFQAmPrQmNzE5YukN7hqliITXEg2TLf41QqnGi/\nfptGPIsUoTOIS8MJmmqJ+nq9Gom/VI+oQ8Nx71hZL5Rc3aR/iZsbRj/kBzNH/N2v\n+R6NmUc9hvfClh1zsbTtyhYxzn4PDalOxDkK1ly8/HLae+6RwJ4GFwxlQiDQ8VyV\n25TKcxhfxEhnkd/JiB6d3M9Bj0jCqsM3nP8OpJjmQTFFG8et/zZeDHIAxFRaA438\nDKvS8ASO279YDG/G4M24ZRZjqOSYhKaT1ll5bjImYQqm58TrKsfyfUM1PiT3moJ2\nBnVjv3Mtoig2GPEe3Zk/n79t0b+i20lUOXT8PhzDcQKBgQD69dYOkMxlkKkOtrgc\nHvVZVJlyMSj4LqiUw2lwEzxVy1aQ2y78sIMPSkqcr7Yird6/IfL9Ukw0rU9yXoey\nVR5TyuTiTi7jk6aJp8qjfs9ipNBNy0hrIJov9UIYf9Z1wB9Ie8YBjN/2ckDecDQa\na0hZ6dUq7sJ0dJPsDRFVHG/BGQKBgQD3S71sS1iW8+3yya0jjWW5AfBTh7uYMRiB\nBS8zcc+fwuQ6w1W824hg8fbe9ylKllCi761Xf8RPGmwWoAh2AoZWMp6bWfeJp9tK\ng7m2hgSvQGpJNOBaLJ/DVnKT7UIYD3VHtQWkAR78iSx0xDrQpIY/XuCSIFaJ4kxT\nz3rPTrac9QKBgF7e5n/1Hz/Z8v779hezYF7Xy3ZOvUUtJk+um8JhkzJ/vwbdxSKD\ne9gg5pnbFwh/IDCzHc/D98kGJ3193OB+qwtULTicA7/GhnONed5axv1sfs6Z5ZOR\n7JfqqIToduNmsKzPFahqYBQjVwB//EJsghpzekFTpzEtDOp0ejPpnxmpAoGBAKzR\nIjwW338GUogzxiotOyQyJafKGCAAV1Z6sASsiWLlSKeEMFt9s23ESjiA0ztLlmh3\nRFT8dcyt81FQXvlRRF3inBKGqcVqJ4aITXUvbQCn7F7ic9KwkqlotUOJL4Iu80+8\nQofdPLFQj1++bje2chbBEAEuViufmKWNPg63vEgtAoGBAJMA1g6oL20nldq6Hwuj\ntprNKGz7fQ1yKhaM6WlUglwrbSPmtVdUFTeODstr1xTxtuahI4qI9aDXY0s9YmBm\nV/UfqBoY3zIblJnpqDU2LS0d3Aa4USXYd6yfnlYqwV6d3Yx+PoIuWFLTWRSoKaxN\nDRSZjlF1dDs1nFF17kV1B6Cf\n-----END PRIVATE KEY-----\n",
  "client_email": "testkey@test-project.iam.gserviceaccount.com",
  "client_id": "114569939335839849739",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/testkey%40test-project.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';
          await tempFile.writeAsString(jsonString);

          final creds = await ServiceAccountCredentials.fromServiceAccountFile(
            tempFile.path,
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
            equals(Uri.https('oauth2.googleapis.com', '/token')),
          );
          expect(creds.universeDomain, equals('googleapis.com'));
        });
      }, testOn: 'vm');

      group('fromPkcs8', () {
        test('creates valid credentials', () async {
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
          expect(
            creds.tokenUri,
            equals(Uri.https('oauth2.googleapis.com', '/token')),
          );
          expect(creds.universeDomain, equals('googleapis.com'));
        });

        test(
          'interpolates custom universeDomain in default tokenUri',
          () async {
            final creds = await ServiceAccountCredentials.fromPkcs8(
              clientEmail: 'pkcs8@project.iam.gserviceaccount.com',
              privateKeyPkcs8: privateKeyPem,
              universeDomain: 'custom.domain.com',
            );

            expect(
              creds.tokenUri,
              equals(Uri.https('oauth2.custom.domain.com', '/token')),
            );
            expect(creds.universeDomain, equals('custom.domain.com'));
          },
        );
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
    },
    skip: _canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );
}
