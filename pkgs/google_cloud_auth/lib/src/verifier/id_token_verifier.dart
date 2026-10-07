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

import 'dart:async';

import 'package:http/http.dart' as http;

import '../jwks/jwks_cache.dart';
import '../jwt/jws_parser.dart';
import 'token_verification_exception.dart';

/// The only signature algorithm this package accepts.
///
/// Deliberately not derived from the token's own `alg` header; see
/// [RFC 8725 §3.1](https://datatracker.ietf.org/doc/html/rfc8725#section-3.1).
const _requiredAlgorithm = 'RS256';

String? _optionalString(Map<String, dynamic> json, String name) {
  final value = json[name];
  return value is String ? value : null;
}

/// Reads a JWT `NumericDate` claim, returning `null` if absent or malformed.
DateTime? _timestamp(Map<String, dynamic> payload, String name) {
  final value = payload[name];
  if (value is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000, isUtc: true);
}

/// Normalizes an `aud` claim, which may be a string or a list of strings.
List<String> _audienceList(Object? audience) => switch (audience) {
  final String value => [value],
  final List<dynamic> values => values.whereType<String>().toList(),
  _ => const [],
};

// Design based on:
// - https://github.com/googleapis/google-api-java-client/blob/main/google-api-client/src/main/java/com/google/api/client/googleapis/auth/oauth2/GoogleIdTokenVerifier.java
// - https://github.com/googleapis/google-auth-library-python/blob/main/google/oauth2/id_token.py

/// Generic OpenID Connect and JWKS ID token verifier.
///
/// Verifies the RS256 signature of an inbound token against the public keys
/// published at a JWKS endpoint, then checks the standard claims. Keys are
/// cached in memory and refreshed according to the endpoint's HTTP caching
/// headers, so steady-state verification performs no network I/O.
///
/// Example:
///
/// ```dart
/// final verifier = IdTokenVerifier(
///   jwksUri: Uri.https('token.actions.githubusercontent.com', '/.well-known/jwks'),
///   expectedIssuers: {'https://token.actions.githubusercontent.com'},
///   allowedAudiences: {'https://pub.dev'},
/// );
/// final claims = await verifier.verify(inboundToken);
/// ```
final class IdTokenVerifier {
  /// The default tolerance applied to `exp` and `iat` comparisons.
  static const defaultClockSkewTolerance = Duration(minutes: 5);

  /// Accepted `iss` values, or `null` to skip the issuer check.
  final Set<String>? expectedIssuers;

  /// Accepted `aud` values, or `null` to skip the audience check.
  ///
  /// A token is accepted when *any* of its audiences is in this set.
  final Set<String>? allowedAudiences;

  /// How far the local clock may disagree with the token's timestamps.
  final Duration clockSkewTolerance;

  final JwksCache _jwksCache;
  final DateTime Function() _clock;

  /// Creates a verifier for tokens signed by the keys published at [jwksUri].
  ///
  /// Leaving [allowedAudiences] unset disables the audience check, which
  /// removes an important defense against a token minted for a different
  /// service being replayed against this one. Set it unless the audience is
  /// genuinely checked elsewhere.
  IdTokenVerifier({
    required Uri jwksUri,
    Set<String>? expectedIssuers,
    Set<String>? allowedAudiences,
    this.clockSkewTolerance = defaultClockSkewTolerance,
    FutureOr<http.Client> Function()? clientFactory,
    DateTime Function()? clock,
  }) : expectedIssuers = expectedIssuers == null
           ? null
           : Set.unmodifiable(expectedIssuers),
       allowedAudiences = allowedAudiences == null
           ? null
           : Set.unmodifiable(allowedAudiences),
       _clock = clock ?? DateTime.now,
       _jwksCache = JwksCache(
         uri: jwksUri,
         clientFactory: clientFactory,
         clock: clock,
       );

  /// The endpoint public keys are fetched from.
  Uri get jwksUri => _jwksCache.uri;

  /// Verifies [rawToken] and returns its validated claims.
  ///
  /// Checks, in order: that the token is a well-formed JWS, that its
  /// algorithm is RS256, that its signature matches the public key named by
  /// its `kid`, and then [expectedIssuers], [allowedAudiences], `exp` and
  /// `iat`.
  ///
  /// Throws [TokenVerificationException] if any check fails, or if the public
  /// keys cannot be fetched.
  Future<IdTokenClaims> verify(String rawToken) async {
    final JwsParts parts;
    try {
      parts = JwsParts.parseUnverified(rawToken);
    } on FormatException catch (e, stackTrace) {
      throw TokenVerificationException(
        TokenVerificationFailure.malformed,
        'The token is not a well-formed JWS: ${e.message}',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }

    // Pin the algorithm instead of dispatching on the token's own header,
    // which is what makes algorithm-confusion attacks possible. This also
    // rejects unsecured (`"alg": "none"`) tokens.
    if (parts.algorithm != _requiredAlgorithm) {
      throw TokenVerificationException(
        TokenVerificationFailure.unsupportedAlgorithm,
        'The token algorithm must be "$_requiredAlgorithm", '
        'but was "${parts.algorithm}".',
      );
    }

    final keyId = parts.keyId;
    if (keyId == null) {
      throw TokenVerificationException(
        TokenVerificationFailure.missingKeyId,
        'The token has no "kid" (key ID) header parameter.',
      );
    }

    final key = await _jwksCache.lookupKey(keyId);
    if (key == null) {
      throw TokenVerificationException(
        TokenVerificationFailure.unknownKeyId,
        'The token "kid" ("$keyId") does not match any key published by '
        '$jwksUri. The signing keys may have rotated.',
      );
    }

    if (!await key.verifyBytes(parts.signature, parts.signedContent)) {
      throw TokenVerificationException(
        TokenVerificationFailure.invalidSignature,
        'The token signature is invalid.',
      );
    }

    return _verifyClaims(parts.payload);
  }

  IdTokenClaims _verifyClaims(Map<String, dynamic> payload) {
    final issuer = _optionalString(payload, 'iss');
    final expectedIssuers = this.expectedIssuers;
    if (expectedIssuers != null &&
        (issuer == null || !expectedIssuers.contains(issuer))) {
      throw TokenVerificationException(
        TokenVerificationFailure.invalidIssuer,
        'The token "iss" (issuer) claim is "$issuer", but one of '
        '${expectedIssuers.join(', ')} was expected.',
      );
    }

    final audience = _audienceList(payload['aud']);
    final allowedAudiences = this.allowedAudiences;
    if (allowedAudiences != null && !audience.any(allowedAudiences.contains)) {
      throw TokenVerificationException(
        TokenVerificationFailure.invalidAudience,
        'The token "aud" (audience) claim is ${audience.join(', ')}, but one '
        'of ${allowedAudiences.join(', ')} was expected.',
      );
    }

    // A token with no expiry would be valid forever, so treat it as invalid
    // rather than as unbounded.
    final expiry = _timestamp(payload, 'exp');
    if (expiry == null) {
      throw TokenVerificationException(
        TokenVerificationFailure.missingExpiration,
        'The token has no "exp" (expiration time) claim.',
      );
    }

    final now = _clock();
    if (!now.isBefore(expiry.add(clockSkewTolerance))) {
      throw TokenVerificationException(
        TokenVerificationFailure.expired,
        'The token expired at $expiry.',
      );
    }

    final issuedAt = _timestamp(payload, 'iat');
    if (issuedAt != null &&
        now.isBefore(issuedAt.subtract(clockSkewTolerance))) {
      throw TokenVerificationException(
        TokenVerificationFailure.issuedInFuture,
        'The token was issued at $issuedAt, which is in the future.',
      );
    }

    return IdTokenClaims._(
      subject: _optionalString(payload, 'sub'),
      issuer: issuer,
      audience: List.unmodifiable(audience),
      expiry: expiry,
      issuedAt: issuedAt,
      unverifiedPayload: Map.unmodifiable(payload),
    );
  }

  /// Discards the cached public keys and fetches a new set.
  Future<void> refreshKeys() => _jwksCache.refresh();
}

/// Validated claims extracted from a verified JWT ID token.
final class IdTokenClaims {
  /// The `sub` (subject) claim, or `null` if absent.
  ///
  /// Present on essentially all ID tokens, but not required: neither the Java
  /// nor the Python reference verifier enforces it, and some Google tokens
  /// legitimately omit it.
  final String? subject;

  /// The `iss` (issuer) claim, or `null` if absent.
  ///
  /// Guaranteed non-null when the verifier was configured with
  /// [IdTokenVerifier.expectedIssuers].
  final String? issuer;

  /// The `aud` (audience) claim, normalized to a list.
  ///
  /// Empty if the token carries no audience.
  final List<String> audience;

  /// The `exp` (expiration time) claim. Always present.
  final DateTime expiry;

  /// The `iat` (issued at) claim, or `null` if absent.
  final DateTime? issuedAt;

  /// The complete token payload.
  ///
  /// The payload as a whole is covered by the verified signature. The name
  /// refers to the individual claims within it that this class did not
  /// itself validate, such as application-specific custom claims.
  final Map<String, dynamic> unverifiedPayload;

  IdTokenClaims._({
    required this.subject,
    required this.issuer,
    required this.audience,
    required this.expiry,
    required this.issuedAt,
    required this.unverifiedPayload,
  });

  /// The `email` claim, or `null` if absent.
  String? get email => _optionalString(unverifiedPayload, 'email');

  /// Whether the `email_verified` claim is set.
  ///
  /// Accepts both the boolean `true` and the string `"true"`, matching the
  /// coercion the Java reference implementation performs.
  bool get isEmailVerified {
    final value = unverifiedPayload['email_verified'];
    return value == true || value == 'true';
  }
}
