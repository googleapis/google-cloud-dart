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

import '../test_utils.dart';

void main() {
  group('parsePemCertificate', () {
    test('decodes armored base64', () {
      final der = Uint8List.fromList([1, 2, 3, 4]);
      final pem =
          '-----BEGIN CERTIFICATE-----\n'
          '${base64.encode(der)}\n'
          '-----END CERTIFICATE-----\n';

      expect(parsePemCertificate(pem), der);
    });

    test('tolerates surrounding whitespace and CRLF line endings', () {
      final der = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final pem =
          '  \r\n-----BEGIN CERTIFICATE-----\r\n'
          '${base64.encode(der.sublist(0, 3))}\r\n'
          '${base64.encode(der.sublist(3))}\r\n'
          '-----END CERTIFICATE-----  \r\n';

      expect(parsePemCertificate(pem), der);
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

    test('rejects missing or wrong encapsulation boundaries', () {
      expect(
        () => parsePemCertificate('AQIDBA=='),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parsePemCertificate(
          '-----BEGIN PUBLIC KEY-----\nAQIDBA==\n-----END PUBLIC KEY-----',
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => parsePemCertificate(
          '-----BEGIN CERTIFICATE-----\nAQIDBA==\n-----END CERTIFICATE-----\n'
          '-----BEGIN CERTIFICATE-----\nAQIDBA==\n-----END CERTIFICATE-----',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('extractSubjectPublicKeyInfo', () {
    test(
      'parses a real Google certificate',
      skip: canUseWebCrypto
          ? null
          : 'Requires Dart 3.13 or later for native assets',
      () async {
        final der = parsePemCertificate(testGoogleSecureTokenCertificatePem);

        final spki = extractSubjectPublicKeyInfo(der);

        // Proves the bytes really are an SPKI, not just a plausible slice.
        final imported = await RsassaPkcs1V15PublicKey.importSpkiKey(
          spki,
          Hash.sha256,
        );
        final jwk = await imported.exportJsonWebKey();
        expect(jwk['kty'], 'RSA');
      },
    );

    test('empty input', () {
      expect(
        () => extractSubjectPublicKeyInfo(Uint8List(0)),
        throwsA(isA<FormatException>()),
      );
    });

    test('a non-SEQUENCE outer tag', () {
      final notACertificate = Uint8List.fromList([0x02, 0x01, 0x00]);

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

    test('trailing bytes after outer SEQUENCE', () {
      final certificate = parsePemCertificate(
        testGoogleSecureTokenCertificatePem,
      );
      final withTrailing = Uint8List.fromList([...certificate, 0x00]);

      expect(
        () => extractSubjectPublicKeyInfo(withTrailing),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('trailing bytes'),
          ),
        ),
      );
    });

    test('a certificate truncated mid-structure', () {
      final certificate = parsePemCertificate(
        testGoogleSecureTokenCertificatePem,
      );
      final truncated = Uint8List.sublistView(
        certificate,
        0,
        certificate.length ~/ 2,
      );

      expect(
        () => extractSubjectPublicKeyInfo(truncated),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Truncated DER'),
          ),
        ),
      );
    });

    test('a TBSCertificate with too few fields', () {
      // Outer SEQUENCE containing a TBSCertificate SEQUENCE with only one
      // INTEGER field.
      final certificate = Uint8List.fromList([
        0x30,
        0x05,
        0x30,
        0x03,
        0x02,
        0x01,
        0x01,
      ]);

      expect(
        () => extractSubjectPublicKeyInfo(certificate),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Truncated DER'),
          ),
        ),
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

    test('non-minimal DER length encoding', () {
      // 0x81 0x02 encodes length 2 in long form (should be short form 0x02).
      expect(
        () => extractSubjectPublicKeyInfo(
          Uint8List.fromList([0x30, 0x81, 0x02, 0x30, 0x00]),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Non-minimal DER length'),
          ),
        ),
      );
      // 0x82 0x00 0x80 has a leading zero byte in the length.
      expect(
        () => extractSubjectPublicKeyInfo(
          Uint8List.fromList([0x30, 0x82, 0x00, 0x80, ...List.filled(128, 0)]),
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Non-minimal DER length'),
          ),
        ),
      );
    });

    test('high-tag-number form', () {
      expect(
        () =>
            extractSubjectPublicKeyInfo(Uint8List.fromList([0x1f, 0x20, 0x00])),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('High-tag-number'),
          ),
        ),
      );
    });
  });
}
