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

// Just enough DER to pull the SubjectPublicKeyInfo out of an X.509
// certificate, so that it can be handed to
// `RsassaPkcs1V15PublicKey.importSpkiKey`.
//
// A full ASN.1 library is deliberately avoided: the only structure that needs
// to be understood is the fixed prefix of `TBSCertificate`, and every field
// before `subjectPublicKeyInfo` can be skipped without being decoded.
//
// See https://datatracker.ietf.org/doc/html/rfc5280#section-4.1:
//
//   Certificate ::= SEQUENCE {
//     tbsCertificate       TBSCertificate,
//     signatureAlgorithm   AlgorithmIdentifier,
//     signatureValue       BIT STRING }
//
//   TBSCertificate ::= SEQUENCE {
//     version         [0] EXPLICIT Version DEFAULT v1,
//     serialNumber        CertificateSerialNumber,
//     signature           AlgorithmIdentifier,
//     issuer              Name,
//     validity            Validity,
//     subject             Name,
//     subjectPublicKeyInfo SubjectPublicKeyInfo,
//     ... }

const _tagSequence = 0x30;

/// Reads the DER tag and length starting at [offset].
///
/// For example:
///
/// ```
///    30 82 03 01  <769 bytes of content>
///     │  │  └──┴── length (0x0301 = 769 bytes)
///     │  └──────── number of length bytes (0x82 means 2 bytes)
///     └─────────── tag (0x30 means SEQUENCE)
/// ```
///
/// See https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/
({int tag, int contentStart, int contentEnd}) _readTagLengthValue(
  Uint8List bytes,
  int offset,
  int limit,
) {
  if (offset >= limit) {
    throw const FormatException('Truncated DER: expected a tag.');
  }
  final tag = bytes[offset];
  var index = offset + 1;

  if (index >= limit) {
    throw const FormatException('Truncated DER: expected a length.');
  }
  var length = bytes[index];
  index++;

  if (length & 0x80 != 0) {
    final byteCount = length & 0x7f;
    if (byteCount == 0) {
      throw const FormatException(
        'Indefinite-length DER is not valid in a certificate.',
      );
    }
    if (byteCount > 4) {
      throw const FormatException('DER length exceeds the supported range.');
    }
    if (index + byteCount > limit) {
      throw const FormatException(
        'Truncated DER: incomplete long-form length.',
      );
    }
    length = 0;
    for (var i = 0; i < byteCount; i++) {
      length = (length << 8) | bytes[index];
      index++;
    }
  }

  final end = index + length;
  if (end > limit || end < index) {
    throw const FormatException(
      'Truncated DER: value extends past its parent.',
    );
  }
  return (tag: tag, contentStart: index, contentEnd: end);
}

/// Decodes a PEM-encoded X.509 certificate into DER bytes.
///
/// Throws a [FormatException] if [pem] is not valid PEM.
Uint8List parsePemCertificate(String pem) {
  final body = LineSplitter.split(pem)
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('-----'))
      .join();
  if (body.isEmpty) {
    throw const FormatException('The PEM certificate is empty.');
  }
  try {
    return Uint8List.fromList(base64.decode(body));
  } on FormatException catch (e) {
    throw FormatException(
      'The PEM certificate is not valid base64: ${e.message}',
    );
  }
}

/// Extracts the DER-encoded `SubjectPublicKeyInfo` from an X.509 certificate.
///
/// The returned bytes are a complete SPKI structure suitable for
/// `RsassaPkcs1V15PublicKey.importSpkiKey`.
///
/// Throws a [FormatException] if [certificateDer] is not a well-formed
/// certificate.
Uint8List extractSubjectPublicKeyInfo(Uint8List certificateDer) {
  final certificate = _readTagLengthValue(
    certificateDer,
    0,
    certificateDer.length,
  );
  if (certificate.tag != _tagSequence) {
    throw const FormatException('Expected an X.509 Certificate SEQUENCE.');
  }

  final tbs = _readTagLengthValue(
    certificateDer,
    certificate.contentStart,
    certificate.contentEnd,
  );
  if (tbs.tag != _tagSequence) {
    throw const FormatException('Expected a TBSCertificate SEQUENCE.');
  }

  var offset = tbs.contentStart;

  // `version` is [0] EXPLICIT and defaults to v1, so it may be absent.
  final first = _readTagLengthValue(certificateDer, offset, tbs.contentEnd);
  if (first.tag == 0xa0) {
    offset = first.contentEnd;
  }

  // Skip serialNumber, signature, issuer, validity and subject. The field
  // after them is subjectPublicKeyInfo.
  for (var i = 0; i < 5; i++) {
    offset = _readTagLengthValue(
      certificateDer,
      offset,
      tbs.contentEnd,
    ).contentEnd;
  }

  final spki = _readTagLengthValue(certificateDer, offset, tbs.contentEnd);
  if (spki.tag != _tagSequence) {
    throw const FormatException('Expected a SubjectPublicKeyInfo SEQUENCE.');
  }

  // Return the whole triple, not just the content: importSpkiKey expects a
  // complete DER structure.
  return Uint8List.sublistView(certificateDer, offset, spki.contentEnd);
}
