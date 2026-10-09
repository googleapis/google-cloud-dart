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
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:webcrypto/webcrypto.dart';

import '../verifier/token_verification_exception.dart';
import 'x509.dart';

// Design based on:
// - https://github.com/googleapis/google-auth-library-java/blob/main/oauth2_http/java/com/google/auth/oauth2/TokenVerifier.java
//   (see `PublicKeyLoader`).

/// Used when the response carries no usable freshness information.
const _defaultCacheDuration = Duration(hours: 1);

/// Maximum delta-seconds value (2^31 - 1, ~68 years), per
/// [RFC 9111 §1.2.2](https://datatracker.ietf.org/doc/html/rfc9111#section-1.2.2).
const _maxDeltaSeconds = 0x7fffffff;

final _noCachePattern = RegExp(r'(?:^|[,\s])no-(?:store|cache)(?:$|[,\s=])');
final _maxAgePattern = RegExp(
  r'(?:^|[,\s])max-age\s*=\s*(?:"(\d+)"|(\d+))(?:$|[,\s])',
);

/// Computes how long a response may be treated as fresh.
///
/// Honors `Cache-Control: max-age`, reduced by the `Age` header, per
/// [RFC 9111 §4.2](https://datatracker.ietf.org/doc/html/rfc9111#section-4.2).
///
/// Returns `null` when the `cache-control` header is missing or invalid.
@internal
@visibleForTesting
Duration? freshnessLifetime(Map<String, String> headers) {
  final cacheControl = headers['cache-control']?.toLowerCase();
  if (cacheControl == null) return null;

  if (_noCachePattern.hasMatch(cacheControl)) return .zero;

  final match = _maxAgePattern.firstMatch(cacheControl);
  if (match == null) return null;

  final digits = match.group(1) ?? match.group(2)!;
  final maxAge =
      int.tryParse(digits)?.clamp(0, _maxDeltaSeconds) ?? _maxDeltaSeconds;

  final age =
      int.tryParse(headers['age'] ?? '')?.clamp(0, _maxDeltaSeconds) ?? 0;
  final seconds = maxAge - age;
  return seconds > 0 ? Duration(seconds: seconds) : Duration.zero;
}

/// An in-memory cache of RSA public keys used to verify
/// [JSON Web Signatures](https://datatracker.ietf.org/doc/html/rfc7515) (JWS).
///
/// Keys are fetched from [uri], which may serve either of the two formats
/// Google uses:
///
/// - A JSON Web Key Set (JWKS), `{"keys": [...]}`. Example:
///   https://www.googleapis.com/oauth2/v3/certs.
/// - A map of key ID to PEM-encoded X.509 certificate, `{"<kid>": "<pem>"}`.
///   Example: https://www.googleapis.com/oauth2/v1/certs.
///
/// Only RSA keys usable for RS256 are retained; anything else in the response
/// is ignored.
@internal
final class JwksCache {
  /// The endpoint public keys are fetched from.
  final Uri uri;

  final FutureOr<http.Client> Function() _clientFactory;
  final DateTime Function() _clock;

  @visibleForTesting
  Map<String, RsassaPkcs1V15PublicKey>? keys;
  DateTime? _expiry;

  /// The in-flight fetch, so that concurrent callers share one request.
  Future<Map<String, RsassaPkcs1V15PublicKey>>? _activeFetch;

  /// Creates a new [JwksCache] backed by the given [uri].
  ///
  /// If provided, [clientFactory] will be used to fetch the keys at [uri].
  /// [JwksCache] may call [clientFactory] many times and will `close` the
  /// returned [http.Client]s.
  JwksCache({
    required this.uri,
    FutureOr<http.Client> Function()? clientFactory,
    DateTime Function()? clock,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _clock = clock ?? DateTime.now;

  /// Returns the key identified by [keyId], or `null` if the endpoint does
  /// not publish it.
  ///
  /// Keys are fetched only when nothing is cached or the cached set has
  /// expired. An unknown [keyId] does not trigger a fetch: doing so would let
  /// anyone force an outbound request per inbound token just by sending an
  /// arbitrary `kid`.
  ///
  /// Throws [TokenVerificationException] if the keys cannot be fetched.
  FutureOr<RsassaPkcs1V15PublicKey?> lookupKey(String keyId) {
    if (_freshKeys() case final fresh?) return fresh[keyId];
    return _fetch().then((keys) => keys[keyId]);
  }

  /// Discards any cached keys and fetches a new set.
  ///
  /// Throws [TokenVerificationException] if the keys cannot be fetched.
  Future<void> refresh() async {
    keys = null;
    _expiry = null;
    await _fetch();
  }

  Map<String, RsassaPkcs1V15PublicKey>? _freshKeys() {
    final keys = this.keys;
    final expiry = _expiry;
    if (keys == null || expiry == null) return null;
    return _clock().isBefore(expiry) ? keys : null;
  }

  Future<Map<String, RsassaPkcs1V15PublicKey>> _fetch() =>
      _activeFetch ??= _fetchKeys().whenComplete(() {
        _activeFetch = null;
      });

  Future<Map<String, RsassaPkcs1V15PublicKey>> _fetchKeys() async {
    final http.Response response;
    try {
      final client = await _clientFactory();
      try {
        response = await client.get(uri);
      } finally {
        client.close();
      }
    } on Exception catch (e, stackTrace) {
      throw TokenVerificationException(
        'Failed to fetch public keys from $uri: $e',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }

    if (response.statusCode != 200) {
      throw TokenVerificationException(
        'Failed to fetch public keys from $uri: '
        'HTTP ${response.statusCode} ${response.body}',
      );
    }

    keys = await _parseKeys(response.body);

    _expiry = _clock().add(
      freshnessLifetime(response.headers) ?? _defaultCacheDuration,
    );
    return keys!;
  }

  Future<Map<String, RsassaPkcs1V15PublicKey>> _parseKeys(String body) async {
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException catch (e, stackTrace) {
      throw TokenVerificationException(
        'Public keys from $uri are not valid JSON: ${e.message}',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }

    if (json is! Map<String, dynamic>) {
      throw TokenVerificationException(
        'Public keys from $uri are not a JSON object.',
      );
    }

    final keys = switch (json['keys']) {
      final List<Object?> jwks => await _parseJwks(jwks),
      null when !json.containsKey('keys') => await _parseCertificateMap(json),
      _ => <String, RsassaPkcs1V15PublicKey>{},
    };

    if (keys.isEmpty) {
      throw TokenVerificationException(
        'Public keys from $uri contained no usable RSA keys.',
      );
    }
    return keys;
  }

  /// Parse a JSON Web Key (JWK) JSON Object.
  ///
  /// See [RFC 7517 § 4](https://datatracker.ietf.org/doc/html/rfc7517#section-4).
  Future<Map<String, RsassaPkcs1V15PublicKey>> _parseJwks(
    List<Object?> jwks,
  ) async {
    final keys = <String, RsassaPkcs1V15PublicKey>{};
    for (final entry in jwks) {
      if (entry is! Map<String, dynamic>) continue;

      final keyId = entry['kid'];
      if (keyId is! String) continue;

      // Ignore anything that is not an RS256 signing key. Google publishes
      // ES256 keys on some endpoints, and those are deliberately unsupported.
      if (entry['kty'] != 'RSA') continue;
      if (entry['alg'] case final alg? when alg != 'RS256') continue;
      if (entry['use'] case final use? when use != 'sig') continue;

      try {
        keys[keyId] = await RsassaPkcs1V15PublicKey.importJsonWebKey(
          entry,
          Hash.sha256,
        );
      } on Object {
        // Skip individual malformed keys rather than failing the whole set.
        // This is consistent with TokenVerifier.java.
        continue;
      }
    }
    return keys;
  }

  Future<Map<String, RsassaPkcs1V15PublicKey>> _parseCertificateMap(
    Map<String, dynamic> json,
  ) async {
    final keys = <String, RsassaPkcs1V15PublicKey>{};
    for (final MapEntry(key: keyId, :value) in json.entries) {
      if (value is! String) continue;
      try {
        keys[keyId] = await RsassaPkcs1V15PublicKey.importSpkiKey(
          extractSubjectPublicKeyInfo(parsePemCertificate(value)),
          Hash.sha256,
        );
      } on Object {
        // Skip individual malformed keys rather than failing the whole set.
        // This is consistent with TokenVerifier.java.
        continue;
      }
    }
    return keys;
  }
}
