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

/// Shared helpers for the JWT verification tests.
///
/// Key material is generated at run time rather than checked in, so these
/// tests carry no embedded private keys.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:webcrypto/webcrypto.dart';

/// An RSA key pair plus the representations the verifier consumes.
final class TestKey {
  final String keyId;
  final RsassaPkcs1V15PrivateKey privateKey;
  final RsassaPkcs1V15PublicKey publicKey;

  /// The public key as a JWK, ready to embed in a JWKS document.
  final Map<String, dynamic> jwk;

  /// The public key as DER `SubjectPublicKeyInfo`.
  final Uint8List spki;

  TestKey._({
    required this.keyId,
    required this.privateKey,
    required this.publicKey,
    required this.jwk,
    required this.spki,
  });

  static Future<TestKey> generate({String keyId = 'test-key-1'}) async {
    final pair = await RsassaPkcs1V15PrivateKey.generateKey(
      2048,
      BigInt.from(65537),
      Hash.sha256,
    );
    final jwk = await pair.publicKey.exportJsonWebKey();
    return TestKey._(
      keyId: keyId,
      privateKey: pair.privateKey,
      publicKey: pair.publicKey,
      jwk: {...jwk, 'kid': keyId, 'alg': 'RS256', 'use': 'sig'},
      spki: await pair.publicKey.exportSpkiKey(),
    );
  }

  /// A JWKS document containing this key.
  String jwksJson({List<Map<String, dynamic>> alsoInclude = const []}) =>
      jsonEncode({
        'keys': [jwk, ...alsoInclude],
      });

  /// A `{kid: pem}` document containing this key, in the legacy format some
  /// Google endpoints still use.
  String certificateMapJson() =>
      jsonEncode({keyId: pemCertificate(synthesizeCertificate(spki))});
}

/// Encodes a DER tag-length-value triple.
Uint8List derEncode(int tag, List<int> content) {
  final out = BytesBuilder()..addByte(tag);
  final length = content.length;
  if (length < 0x80) {
    out.addByte(length);
  } else {
    final lengthBytes = <int>[];
    var remaining = length;
    while (remaining > 0) {
      lengthBytes.insert(0, remaining & 0xff);
      remaining >>= 8;
    }
    out
      ..addByte(0x80 | lengthBytes.length)
      ..add(lengthBytes);
  }
  out.add(content);
  return out.toBytes();
}

/// Builds a DER X.509 certificate carrying [spki] as its public key.
///
/// Only the structure matters here: nothing in this package validates a
/// certificate's signature, because the endpoints serving them are trusted
/// via TLS. The fields before the public key are therefore filled with
/// minimal placeholders.
///
/// When [includeVersion] is false the optional `[0] EXPLICIT version` field
/// is omitted, exercising the v1-default path.
Uint8List synthesizeCertificate(Uint8List spki, {bool includeVersion = true}) {
  final tbs = <int>[
    if (includeVersion) ...derEncode(0xa0, derEncode(0x02, [0x02])),
    ...derEncode(0x02, [0x01, 0x23, 0x45]), // serialNumber
    ...derEncode(0x30, const []), // signature
    ...derEncode(0x30, const []), // issuer
    ...derEncode(0x30, const []), // validity
    ...derEncode(0x30, const []), // subject
    ...spki,
  ];

  return derEncode(0x30, <int>[
    ...derEncode(0x30, tbs),
    ...derEncode(0x30, const []), // signatureAlgorithm
    ...derEncode(0x03, const [0x00, 0xde, 0xad]), // signatureValue
  ]);
}

/// Wraps DER [bytes] in PEM certificate armor.
String pemCertificate(Uint8List bytes) {
  final body = base64.encode(bytes);
  final lines = <String>[];
  for (var i = 0; i < body.length; i += 64) {
    lines.add(body.substring(i, i + 64 > body.length ? body.length : i + 64));
  }
  return '-----BEGIN CERTIFICATE-----\n'
      '${lines.join('\n')}\n'
      '-----END CERTIFICATE-----\n';
}

/// A real certificate served by Google's Firebase secure token endpoint.
///
/// Embedded verbatim as a regression fixture so that the DER walker is
/// exercised against a genuine Google certificate, not only against
/// [synthesizeCertificate] output. Certificates are public data.
const googleSecureTokenCertificatePem = '''
-----BEGIN CERTIFICATE-----
MIIDHDCCAgSgAwIBAgIIFFdImQ/V0kUwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE
Awwmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMjYw
NTA0MTc0NzI3WhcNMjcwNTA0MTc0NzI3WjAxMS8wLQYDVQQDDCZzZWN1cmV0b2tl
bi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAOKOpTkKGfjHH1ny5ZJXKag63eWg9RvVlfY3SgKULip4mwM1
HuCIY0aYoXEdKdVFgS/+mPOPDfSSjcYbl1/+QTZH0mBiqatIgQGegNf5naIkF9jd
SxazYShP8cgjOkRckaFdrMvEa/mNOO5wTk6AEMbUR+V1M8auOAiqeAGOvTTgbOJl
bRB9NufzI8WbysbEPRtgqDYY9WxXcrukkacecYsaLkj0qy14DTZXt08NB+ZlYnHQ
2+qoEo33lMMm67gpBTPe3mu4L9CrZ9qDxzH7WqMz+7zGeA9FqDwyMu9UONE+Ssbs
xYN6dtw12vC1S6ueAzdGgWCOTB8njBAvkrYJ0gMCAwEAAaM4MDYwDAYDVR0TAQH/
BAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ
KoZIhvcNAQEFBQADggEBALxRVxyzG7sUYwBdUGOQ8wWt7o/1tvgAVKa9VpgzzlHb
W4irMEOCetKswJFN4KieFqfUcwsKucRiDZRm9iIrPTyI3AhH9Yu7UY7lrqkYZ//b
v1Q+oj1YqYcwHcyhuykzQIf+eq1reBWhG0GaDfxTdIeQkcYBZ5nVNICBXU2QVJLE
qjM89ncbpinVTzI7kH1uZvqMDeL7/su6GSvoi4oXokOauGcaogwbbE+HK//QMOMK
XSu2FfrwU5Vua5Mx37jQTnM5ruVJQvnNYsd9QAMfhd7cUMMYuIAW1sQMSk5/F95Q
QCCW8kDKq9yAOrfHSS2zw5pqsIc/HC/bD3cW9J0CYK8=
-----END CERTIFICATE-----
''';
