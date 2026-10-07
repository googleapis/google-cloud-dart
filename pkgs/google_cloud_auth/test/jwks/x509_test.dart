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
import 'dart:typed_data';

import 'package:google_cloud_auth/src/jwks/x509.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart';

import '../src/test_support.dart';
import '../test_utils.dart';

void main() {
  group('parsePemCertificate', () {
    test('decodes armored base64', () {
      final der = Uint8List.fromList([1, 2, 3, 4]);

      expect(parsePemCertificate(pemCertificate(der)), der);
    });

    test('tolerates surrounding whitespace and CRLF line endings', () {
      final der = Uint8List.fromList(List.generate(100, (i) => i));
      final pem = pemCertificate(der).replaceAll('\n', '\r\n');

      expect(parsePemCertificate('  \n$pem  \n'), der);
    });

    test('rejects empty PEM', () {
      expect(
        () => parsePemCertificate(
          '-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-base64 content', () {
      expect(
        () => parsePemCertificate(
          '-----BEGIN CERTIFICATE-----\n!!!!\n-----END CERTIFICATE-----',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group(
    'extractSubjectPublicKeyInfo',
    () {
      late RsassaPkcs1V15PrivateKey privateKey;
      late Uint8List spki;

      setUpAll(() async {
        if (!canUseWebCrypto) return;
        final pair = await RsassaPkcs1V15PrivateKey.generateKey(
          2048,
          BigInt.from(65537),
          Hash.sha256,
        );
        privateKey = pair.privateKey;
        spki = await pair.publicKey.exportSpkiKey();
      });

      test('round-trips a generated key through a certificate', () async {
        final certificate = synthesizeCertificate(spki);

        final extracted = extractSubjectPublicKeyInfo(certificate);

        expect(extracted, spki);
      });

      test('extracted SPKI imports and verifies a real signature', () async {
        final certificate = synthesizeCertificate(spki);
        final extracted = extractSubjectPublicKeyInfo(certificate);

        final imported = await RsassaPkcs1V15PublicKey.importSpkiKey(
          extracted,
          Hash.sha256,
        );

        final message = ascii.encode('payload to sign');
        final signature = await privateKey.signBytes(message);
        expect(await imported.verifyBytes(signature, message), isTrue);
      });

      test('handles a certificate with no explicit version field', () async {
        // `version` is [0] EXPLICIT and defaults to v1, so it may be absent.
        final certificate = synthesizeCertificate(spki, includeVersion: false);

        expect(extractSubjectPublicKeyInfo(certificate), spki);
      });

      test('parses a real Google certificate', () async {
        final der = parsePemCertificate(testGoogleSecureTokenCertificatePem);

        final spki = extractSubjectPublicKeyInfo(der);

        // Proves the bytes really are an SPKI, not just a plausible slice.
        final imported = await RsassaPkcs1V15PublicKey.importSpkiKey(
          spki,
          Hash.sha256,
        );
        final jwk = await imported.exportJsonWebKey();
        expect(jwk['kty'], 'RSA');
      });

      group('rejects', () {
        test('empty input', () {
          expect(
            () => extractSubjectPublicKeyInfo(Uint8List(0)),
            throwsA(isA<FormatException>()),
          );
        });

        test('a non-SEQUENCE outer tag', () {
          final notACertificate = derEncode(0x02, const [1, 2, 3]);

          expect(
            () => extractSubjectPublicKeyInfo(notACertificate),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains('Certificate SEQUENCE'),
              ),
            ),
          );
        });

        test('a certificate truncated mid-structure', () {
          final certificate = synthesizeCertificate(spki);
          final truncated = Uint8List.sublistView(
            certificate,
            0,
            certificate.length ~/ 2,
          );

          expect(
            () => extractSubjectPublicKeyInfo(truncated),
            throwsA(isA<FormatException>()),
          );
        });

        test('a TBSCertificate with too few fields', () {
          final tbs = derEncode(0x30, <int>[
            ...derEncode(0x02, const [0x01]),
            ...derEncode(0x30, const []),
          ]);
          final certificate = derEncode(0x30, tbs);

          expect(
            () => extractSubjectPublicKeyInfo(certificate),
            throwsA(isA<FormatException>()),
          );
        });

        test('indefinite-length encoding', () {
          // 0x80 as a length byte signals indefinite length, which is BER but
          // not DER and must not be accepted.
          final certificate = Uint8List.fromList([0x30, 0x80, 0x30, 0x00]);

          expect(
            () => extractSubjectPublicKeyInfo(certificate),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains('Indefinite-length'),
              ),
            ),
          );
        });
      });
    },
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );
}
