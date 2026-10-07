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

