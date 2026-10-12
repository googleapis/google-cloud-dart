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
/// - https://github.com/googleapis/google-api-java-client/blob/main/google-api-client/src/main/java/com/google/api/client/googleapis/auth/oauth2/GoogleIdTokenVerifier.java
/// - https://github.com/googleapis/google-auth-library-python/blob/main/google/oauth2/id_token.py
library;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../jwks/jwks_cache.dart';
import 'jws_parser.dart';
import 'token_verification_exception.dart';

/// The only signature algorithm this package accepts.
///
/// Deliberately not derived from the token's own `alg` header; see
/// [RFC 8725 §3.1](https://datatracker.ietf.org/doc/html/rfc8725#section-3.1).
const _requiredAlgorithm = 'RS256';

String? _optionalString(Map<String, Object?> json, String name) {
  final value = json[name];
  return value is String ? value : null;
}

/// Reads a JWT `NumericDate` claim, returning `null` if it is absent,
/// malformed or outside the range of [DateTime].
///
/// See [RFC 7519 §2](https://datatracker.ietf.org/doc/html/rfc7519#section-2).
DateTime? _timestamp(Map<String, Object?> payload, String name) {
  final value = payload[name];
  if (value is! num) return null;
  // A `NumericDate` has no maximum value defined in RFC 7519, but [DateTime]
  // does. `toInt` throws for the infinities that `jsonDecode` produces for
  // numbers too large for a double, and the constructor throws for values
  // outside the range of [DateTime]. The multiplication is done with doubles
  // because integers silently wrap around on native platforms, which could
  // turn an out-of-range value into an in-range one.
  try {
    return DateTime.fromMillisecondsSinceEpoch(
      (value.toDouble() * 1000).toInt(),
      isUtc: true,
    );
  } catch (_) {
    return null;
  }
}

/// Normalizes an `aud` claim, which may be a string or a list of strings.
///
/// See [RFC 7519 §4.1.3](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.3).
List<String> _audienceList(Object? audience) => switch (audience) {
  final String value => [value],
  final List<Object?> values => values.whereType<String>().toList(),
  _ => const [],
};

/// Whether the `aud` claim [audience] names at least one audience, and only
/// audiences in [allowed].
///
/// A token that is also intended for an audience outside [allowed] must be
/// rejected, even if it names an allowed audience too. See
/// [OpenID Connect Core 1.0 §3.1.3.7](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation).
bool _hasOnlyAllowedAudiences(Object? audience, Set<String> allowed) =>
    switch (audience) {
      final String value => allowed.contains(value),
      final List<Object?> values =>
        values.isNotEmpty && values.every(allowed.contains),
      _ => false,
    };

/// Validated claims extracted from a verified JWT ID token.
final class IdTokenClaims {
  /// The `sub` (subject) claim, or `null` if absent.
  ///
  /// See [RFC 7519 §4.1.2](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.2).
  final String? subject;

  /// The `iss` (issuer) claim, or `null` if absent.
  ///
  /// Guaranteed non-null when the verifier was configured with
  /// [TokenVerifier.expectedIssuers].
  ///
  /// See [RFC 7519 §4.1.1](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.1).
  final String? issuer;

  /// The `aud` (audience) claim, normalized to a list.
  ///
  /// Empty if the token carries no audience.
  ///
  /// See [RFC 7519 §4.1.3](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.3).
  final List<String> audience;

  /// The `exp` (expiration time) claim.
  ///
  /// See [RFC 7519 §4.1.4](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.4).
  final DateTime expiry;

  /// The `iat` (issued at) claim, or `null` if absent.
  ///
  /// See [RFC 7519 §4.1.6](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.6).
  final DateTime? issuedAt;

  /// The complete token payload.
  ///
  /// The payload as a whole is covered by the verified signature. The name
  /// refers to the individual claims within it that this class did not
  /// itself validate, such as application-specific custom claims.
  final Map<String, Object?> allClaims;

  IdTokenClaims._({
    required this.subject,
    required this.issuer,
    required this.audience,
    required this.expiry,
    required this.issuedAt,
    required this.allClaims,
  });

  /// The `email` claim, or `null` if absent.
  ///
  /// This is not a stable or unique identifier for the user: an issuer may
  /// reuse an address for a different user, and a user's address may change.
  /// Identify users by [issuer] and [subject] together instead; see
  /// [OpenID Connect Core 1.0 §5.7](https://openid.net/specs/openid-connect-core-1_0.html#ClaimStability).
  ///
  /// See [OpenID Connect Core 1.0 §5.1](https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims).
  String? get email => _optionalString(allClaims, 'email');

  /// Whether the `email_verified` claim is set.
  ///
  /// See [OpenID Connect Core 1.0 §5.1](https://openid.net/specs/openid-connect-core-1_0.html#StandardClaims).
  bool get isEmailVerified {
    final value = allClaims['email_verified'];
    return value == true || value == 'true';
  }
}

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
/// final verifier = TokenVerifier(
///   jwksUri: Uri.https('www.googleapis.com', '/oauth2/v3/certs'),
///   // Google ID tokens use either form of the issuer.
///   expectedIssuers: {'https://accounts.google.com', 'accounts.google.com'},
///   allowedAudiences: {'https://my-service.example.com'},
/// );
/// final claims = await verifier.verify(inboundToken);
/// ```
final class TokenVerifier {
  /// The default tolerance applied to `exp` and `iat` comparisons.
  ///
  /// [RFC 7519 §4.1.4](https://datatracker.ietf.org/doc/html/rfc7519#section-4.1.4)
  /// says:
  /// > Implementers MAY provide for some small leeway, usually no more than
  /// > a few minutes, to account for clock skew.
  static const defaultClockSkewTolerance = Duration(minutes: 5);

  /// Accepted `iss` values, or `null` to skip the issuer check.
  final Set<String>? expectedIssuers;

  /// Accepted `aud` values, or `null` to skip the audience check.
  ///
  /// A token is accepted only if its `aud` claim names at least one audience
  /// and *every* audience it names is in this set.
  final Set<String>? allowedAudiences;

  /// How far the local clock may disagree with the token's timestamps.
  final Duration clockSkewTolerance;

  final JwksCache _jwksCache;
  final DateTime Function() _clock;

  /// Creates a verifier for tokens signed by the keys published at [jwksUri].
  ///
  /// [jwksUri] may serve a JWKS document or a legacy map from key ID to PEM
  /// certificate.
  ///
  /// If [expectedIssuers] is set, tokens whose `iss` claim is missing or not
  /// in the set are rejected. If it is `null`, the issuer is not checked.
  /// Google ID tokens may have either `https://accounts.google.com` or
  /// `accounts.google.com` as their issuer, so include both.
  ///
  /// If [allowedAudiences] is set, a token is accepted only if its `aud` claim
  /// names at least one audience and every audience it names is in the set,
  /// so a token that is also intended for another, untrusted service is
  /// rejected. Leaving it `null` disables the audience check, which removes an
  /// important defense against a token minted for a different service being
  /// replayed against this one. Set it unless the audience is genuinely
  /// checked elsewhere.
  ///
  /// [clockSkewTolerance] is how far the local clock may disagree with the
  /// token's timestamps: a token is accepted until [clockSkewTolerance] after
  /// its `exp`, and rejected if its `iat` is more than [clockSkewTolerance] in
  /// the future. Defaults to [defaultClockSkewTolerance].
  ///
  /// If provided, [clientFactory] is called each time the keys are fetched,
  /// and the [http.Client] it returns is closed afterwards, so it must return
  /// a new client on every call.
  TokenVerifier({
    required Uri jwksUri,
    Set<String>? expectedIssuers,
    Set<String>? allowedAudiences,
    this.clockSkewTolerance = defaultClockSkewTolerance,
    FutureOr<http.Client> Function()? clientFactory,
    @visibleForTesting DateTime Function()? clock,
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

  /// Verifies that [rawToken] is a valid JSON Web Signature (JWS).
  ///
  /// Validatew the JWS according to:
  /// 1. [RFC 7519 §7.2](https://datatracker.ietf.org/doc/html/rfc7519#section-7.2)
  /// 2. [RFC 7515 §5.2](https://datatracker.ietf.org/doc/html/rfc7515#section-5.2)
  /// 3. [OpenID Connect Core 1.0 §3.1.3.7](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation)
  ///
  /// Throws [TokenVerificationException] if any check fails, or if the public
  /// keys cannot be fetched.
  Future<IdTokenClaims> verify(String rawToken) async {
    final JwsParts parts;
    try {
      parts = JwsParts.parse(rawToken);
    } on FormatException catch (e, stackTrace) {
      throw TokenVerificationException(
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
        'The token algorithm must be "$_requiredAlgorithm", '
        'but was "${parts.algorithm}".',
      );
    }

    // A token is invalid if its "crit" header parameter lists an extension
    // that the recipient doesn't support (RFC 7515 §4.1.11), and none are
    // supported.
    if (parts.header.containsKey('crit')) {
      throw TokenVerificationException(
        'The token has a "crit" (critical) header parameter, but no critical '
        'extensions are supported.',
      );
    }

    final keyId = parts.keyId;
    if (keyId == null) {
      throw TokenVerificationException(
        'The token has no "kid" (key ID) header parameter.',
      );
    }

    final key = await _jwksCache.lookupKey(keyId);
    if (key == null) {
      throw TokenVerificationException(
        'The token "kid" ("$keyId") does not match any key published by '
        '$jwksUri. The signing keys may have rotated.',
      );
    }

    if (!await key.verifyBytes(parts.signature, parts.signedContent)) {
      throw TokenVerificationException('The token signature is invalid.');
    }

    return _verifyClaims(parts.payload);
  }

  IdTokenClaims _verifyClaims(Map<String, Object?> payload) {
    final issuer = _optionalString(payload, 'iss');
    final expectedIssuers = this.expectedIssuers;
    if (expectedIssuers != null &&
        (issuer == null || !expectedIssuers.contains(issuer))) {
      throw TokenVerificationException(
        'The token "iss" (issuer) claim is "$issuer", but one of '
        '${expectedIssuers.join(', ')} was expected.',
      );
    }

    final audience = _audienceList(payload['aud']);
    final allowedAudiences = this.allowedAudiences;
    if (allowedAudiences != null &&
        !_hasOnlyAllowedAudiences(payload['aud'], allowedAudiences)) {
      throw TokenVerificationException(
        'The token "aud" (audience) claim is ${payload['aud']}, but it must be '
        'one or more of ${allowedAudiences.join(', ')}.',
      );
    }

    // A token with no expiry would be valid forever, so treat it as invalid
    // rather than as unbounded.
    final expiry = _timestamp(payload, 'exp');
    if (expiry == null) {
      throw TokenVerificationException(
        'The token has no "exp" (expiration time) claim.',
      );
    }

    // Apply the tolerance to `now` rather than to the token's timestamps,
    // which may be at the limits of what [DateTime] can represent.
    final now = _clock();
    if (!now.subtract(clockSkewTolerance).isBefore(expiry)) {
      throw TokenVerificationException('The token expired at $expiry.');
    }

    final issuedAt = _timestamp(payload, 'iat');
    if (issuedAt != null && now.add(clockSkewTolerance).isBefore(issuedAt)) {
      throw TokenVerificationException(
        'The token was issued at $issuedAt, which is in the future.',
      );
    }

    return IdTokenClaims._(
      subject: _optionalString(payload, 'sub'),
      issuer: issuer,
      audience: List.unmodifiable(audience),
      expiry: expiry,
      issuedAt: issuedAt,
      allClaims: Map.unmodifiable(payload),
    );
  }

  /// Discards the cached public keys and fetches a new set.
  Future<void> refreshKeys() => _jwksCache.refresh();
}
