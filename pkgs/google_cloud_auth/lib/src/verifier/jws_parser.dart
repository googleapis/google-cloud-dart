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

/// Design based on:
/// - https://github.com/googleapis/google-api-java-client/blob/main/google-api-client/src/main/java/com/google/api/client/json/webtoken/JsonWebSignature.java
/// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/jwt.py
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

Uint8List _decodeBase64Url(String segment, String name) {
  try {
    return base64Url.decode(base64Url.normalize(segment));
  } on FormatException catch (e) {
    throw FormatException('The JWS $name is not valid base64url: ${e.message}');
  }
}

Map<String, Object?> _decodeJsonSegment(String segment, String name) {
  final bytes = _decodeBase64Url(segment, name);

  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException catch (e) {
    throw FormatException('The JWS $name is not valid JSON: ${e.message}');
  }

  if (decoded is! Map<String, Object?>) {
    throw FormatException('The JWS $name must be a JSON object.');
  }
  return decoded;
}

String? _optionalString(Map<String, Object?> json, String name) {
  final value = json[name];
  return value is String ? value : null;
}

/// The decoded parts of a JSON Web Signature (JWS) in compact serialization,
/// as defined by [RFC 7515](https://datatracker.ietf.org/doc/html/rfc7515).
///
/// Instances are produced by [JwsParts.parse], which performs **no**
/// cryptographic verification. Treat the contents as untrusted input unless
/// the token has separately been verified.
@internal
final class JwsParts {
  /// The decoded JOSE header.
  final Map<String, Object?> header;

  /// The decoded payload, also known as the claims set.
  final Map<String, Object?> payload;

  /// The raw signature bytes.
  ///
  /// Empty for unsecured JWTs (`"alg": "none"`), which some emulators produce.
  final Uint8List signature;

  /// The bytes over which [signature] is computed.
  ///
  /// This is the ASCII encoding of the header and payload segments joined by
  /// a `.`, exactly as they appeared in the original token. It must be taken
  /// from the original string rather than re-encoded, because JSON
  /// serialization is not canonical.
  final Uint8List signedContent;

  JwsParts._({
    required this.header,
    required this.payload,
    required this.signature,
    required this.signedContent,
  });

  /// The `alg` (algorithm) header parameter, or `null` if absent.
  ///
  /// Never trust this value when selecting a verification algorithm; doing so
  /// enables algorithm-confusion attacks. See
  /// [RFC 8725 §3.1](https://datatracker.ietf.org/doc/html/rfc8725#section-3.1).
  String? get algorithm => _optionalString(header, 'alg');

  /// The `kid` (key ID) header parameter, or `null` if absent.
  String? get keyId => _optionalString(header, 'kid');

  /// Parse a JWS in compact serialization.
  /// 
  /// Throws [FormatException] if the token is malformed.
  ///
  /// See [RFC 7515 § 3.3](https://datatracker.ietf.org/doc/html/rfc7515#section-3.3).
  static JwsParts parse(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException(
        'The JWS is malformed: expected 3 "." separated segments, '
        ' found ${parts.length}',
      );
    }

    return JwsParts._(
      header: _decodeJsonSegment(parts[0], 'header'),
      payload: _decodeJsonSegment(parts[1], 'payload'),
      signature: _decodeBase64Url(parts[2], 'signature'),
      signedContent: ascii.encode(token.substring(0, token.lastIndexOf('.'))),
    );
  }
}
