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

import 'package:meta/meta.dart';

const _tagInteger = 0x02;
const _tagSequence = 0x30;
const _tagVersion = 0xa0;

const _pemHeader = '-----BEGIN CERTIFICATE-----';
const _pemFooter = '-----END CERTIFICATE-----';

/// Reads the DER tag and length.
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
  if ((tag & 0x1f) == 0x1f) {
    throw const FormatException(
      'High-tag-number form is not supported in DER certificates.',
    );
  }
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
      // No value that we need to parse will be >4GiB.
      throw const FormatException('DER length exceeds the supported range.');
    }
    if (index + byteCount > limit) {
      throw const FormatException(
        'Truncated DER: incomplete long-form length.',
      );
    }
    if (bytes[index] == 0) {
      throw const FormatException('Non-minimal DER length: leading zero byte.');
    }
    length = 0;
    for (var i = 0; i < byteCount; i++) {
      length = (length * 256) + bytes[index];
      index++;
    }
    if (length < 0x80) {
      throw const FormatException(
        'Non-minimal DER length: value fits in short form.',
      );
    }
  }

  final end = index + length;
  if (end > limit) {
    throw const FormatException(
      'Truncated DER: value extends past its parent.',
    );
  }
  return (tag: tag, contentStart: index, contentEnd: end);
}

/// Decodes a PEM-encoded X.509 certificate into DER bytes.
///
/// Throws a [FormatException] if [pem] is not valid PEM.
@internal
Uint8List parsePemCertificate(String pem) {
  final lines = LineSplitter.split(
    pem,
  ).map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
  if (lines.length < 2 ||
      lines.first != _pemHeader ||
      lines.last != _pemFooter) {
    throw const FormatException(
      'The PEM certificate must start with $_pemHeader and end with '
      '$_pemFooter.',
    );
  }
  final bodyLines = lines.sublist(1, lines.length - 1);
  if (bodyLines.isEmpty) {
    throw const FormatException('The PEM certificate is empty.');
  }
  if (bodyLines.any((line) => line.startsWith('-----'))) {
    throw const FormatException(
      'The PEM certificate contains unexpected encapsulation boundaries.',
    );
  }
  try {
    return Uint8List.fromList(base64.decode(bodyLines.join()));
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
/// See [RFC 5280 § 4.1](https://datatracker.ietf.org/doc/html/rfc5280#section-4.1):
///
///   Certificate ::= SEQUENCE {
///     tbsCertificate       TBSCertificate,
///     signatureAlgorithm   AlgorithmIdentifier,
///     signatureValue       BIT STRING }
///
///   TBSCertificate ::= SEQUENCE {
///     version         [0] EXPLICIT Version DEFAULT v1,
///     serialNumber        CertificateSerialNumber,
///     signature           AlgorithmIdentifier,
///     issuer              Name,
///     validity            Validity,
///     subject             Name,
///     subjectPublicKeyInfo SubjectPublicKeyInfo,
///     ... }
///
/// Throws a [FormatException] if [certificateDer] is not a well-formed
/// certificate.
@internal
Uint8List extractSubjectPublicKeyInfo(Uint8List certificateDer) {
  final certificate = _readTagLengthValue(
    certificateDer,
    0,
    certificateDer.length,
  );
  if (certificate.tag != _tagSequence) {
    throw const FormatException('Expected an X.509 Certificate SEQUENCE.');
  }
  if (certificate.contentEnd != certificateDer.length) {
    throw const FormatException(
      'Unexpected trailing bytes after X.509 Certificate SEQUENCE.',
    );
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
  if (first.tag == _tagVersion) {
    offset = first.contentEnd;
  }

  const expectedTags = [
    _tagInteger, // serialNumber
    _tagSequence, // signature
    _tagSequence, // issuer
    _tagSequence, // validity
    _tagSequence, // subject
  ];
  for (final expectedTag in expectedTags) {
    final field = _readTagLengthValue(certificateDer, offset, tbs.contentEnd);
    if (field.tag != expectedTag) {
      throw const FormatException('Unexpected field in TBSCertificate.');
    }
    offset = field.contentEnd;
  }

  final spki = _readTagLengthValue(certificateDer, offset, tbs.contentEnd);
  if (spki.tag != _tagSequence) {
    throw const FormatException('Expected a SubjectPublicKeyInfo SEQUENCE.');
  }

  // Return the whole triple, not just the content: importSpkiKey expects a
  // complete DER structure.
  return Uint8List.sublistView(certificateDer, offset, spki.contentEnd);
}
