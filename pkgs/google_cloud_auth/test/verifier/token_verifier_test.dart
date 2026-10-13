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

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:webcrypto/webcrypto.dart';

import '../test_utils.dart';

final _jwksUri = Uri.https('example.com', '/certs');
const _issuer = 'https://issuer.example.com';
const _audience = 'my-service';
const _keyId = 'test-key-1';

final _now = DateTime.utc(2026, 6, 1, 12);

/// Where to request a GitHub Actions OIDC token, and the bearer token to use.
///
/// GitHub only sets these in jobs granted the `id-token: write` permission.
/// See https://docs.github.com/en/actions/reference/security/oidc.
final _githubTokenRequestUrl = readEnvironment('ACTIONS_ID_TOKEN_REQUEST_URL');
final _githubTokenRequestToken = readEnvironment(
  'ACTIONS_ID_TOKEN_REQUEST_TOKEN',
);

/// Converts [time] to a JWT `NumericDate`, in seconds since the epoch.
int _numericDate(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

Matcher _throwsVerification(Object messageMatcher) => throwsA(
  isA<TokenVerificationException>().having(
    (e) => e.message,
    'message',
    messageMatcher,
  ),
);

void main() {
  late RsassaPkcs1V15PrivateKey privateKey;
  late String jwksJson;

  setUpAll(() async {
    if (!canUseWebCrypto) return;
    privateKey = await testWebCryptoPrivateKey();
    jwksJson = jsonEncode({
      'keys': [
        {
          ...await (await getTestPublicKey()).exportJsonWebKey(),
          'kid': _keyId,
          'alg': 'RS256',
          'use': 'sig',
        },
      ],
    });
  });

  TokenVerifier buildVerifier({
    Set<String>? expectedIssuers = const {_issuer},
    Set<String>? allowedAudiences = const {_audience},
    Duration clockSkewTolerance = TokenVerifier.defaultClockSkewTolerance,
    DateTime? now,
    String? jwksBody,
  }) => TokenVerifier(
    jwksUri: _jwksUri,
    expectedIssuers: expectedIssuers,
    allowedAudiences: allowedAudiences,
    clockSkewTolerance: clockSkewTolerance,
    clock: () => now ?? _now,
    clientFactory: () =>
        MockClient((_) async => http.Response(jwksBody ?? jwksJson, 200)),
  );

  /// Signs a JWT with [testPrivateKey].
  ///
  /// [header] entries override the defaults, so a test can e.g. set a wrong
  /// `alg`, or drop the `kid` by setting it to `null`. [editPayloadJson] can
  /// rewrite the encoded payload, e.g. to include JSON that [jsonEncode]
  /// cannot produce.
  Future<String> mintToken({
    required Map<String, Object?> payload,
    Map<String, Object?> header = const {},
    bool corruptSignature = false,
    String Function(String json)? editPayloadJson,
  }) async {
    final fullHeader = <String, Object?>{
      'alg': 'RS256',
      'typ': 'JWT',
      'kid': _keyId,
      ...header,
    }..removeWhere((_, value) => value == null);

    var payloadJson = jsonEncode(payload);
    if (editPayloadJson != null) payloadJson = editPayloadJson(payloadJson);

    final signingInput =
        '${base64UrlUnpadded(utf8.encode(jsonEncode(fullHeader)))}'
        '.'
        '${base64UrlUnpadded(utf8.encode(payloadJson))}';

    final signature = await privateKey.signBytes(ascii.encode(signingInput));
    if (corruptSignature) signature[0] ^= 0xff;

    return '$signingInput.${base64UrlUnpadded(signature)}';
  }

  /// A payload that passes every check, with the given overrides applied.
  Map<String, Object?> validPayload([
    Map<String, Object?> overrides = const {},
  ]) => {
    'iss': _issuer,
    'aud': _audience,
    'sub': 'user-123',
    'iat': _numericDate(_now.subtract(const Duration(minutes: 1))),
    'exp': _numericDate(_now.add(const Duration(hours: 1))),
    ...overrides,
  }..removeWhere((_, value) => value == #absent);

  group(
    'TokenVerifier.verify',
    () {
      test('accepts a valid token and returns its claims', () async {
        final token = await mintToken(payload: validPayload());

        final claims = await buildVerifier().verify(token);

        expect(claims.subject, 'user-123');
        expect(claims.issuer, _issuer);
        expect(claims.audience, [_audience]);
        expect(claims.expiry, _now.add(const Duration(hours: 1)));
        expect(claims.issuedAt, _now.subtract(const Duration(minutes: 1)));
      });

      test('exposes custom claims through allClaims', () async {
        final token = await mintToken(
          payload: validPayload({
            'tenant': 'acme',
            'roles': ['admin'],
          }),
        );

        final claims = await buildVerifier().verify(token);

        expect(claims.allClaims['tenant'], 'acme');
        expect(claims.allClaims['roles'], ['admin']);
      });

      group('signature', () {
        test('rejects a corrupted signature', () async {
          final token = await mintToken(
            payload: validPayload(),
            corruptSignature: true,
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('signature is invalid')),
          );
        });

        test('rejects a token signed by a different key', () async {
          // The endpoint publishes some other key under the token's `kid`.
          final verifier = buildVerifier(
            jwksBody: jsonEncode({_keyId: testGoogleSecureTokenCertificatePem}),
          );
          final token = await mintToken(payload: validPayload());

          await expectLater(
            verifier.verify(token),
            _throwsVerification(contains('signature is invalid')),
          );
        });

        test('rejects an unknown key id', () async {
          final token = await mintToken(
            payload: validPayload(),
            header: {'kid': 'not-published'},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('does not match any key')),
          );
        });

        test('rejects a token with no key id', () async {
          final token = await mintToken(
            payload: validPayload(),
            header: {'kid': null},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('no "kid"')),
          );
        });
      });

      group('algorithm', () {
        // The signature is still a valid RS256 signature; only the declared
        // algorithm changes. A verifier that dispatched on the header would be
        // fooled, so each of these must be rejected before any key lookup.
        for (final algorithm in ['none', 'HS256', 'RS512', 'ES256']) {
          test('rejects "$algorithm"', () async {
            final token = await mintToken(
              payload: validPayload(),
              header: {'alg': algorithm},
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(contains('must be "RS256"')),
            );
          });
        }

        test('rejects a missing algorithm', () async {
          final token = await mintToken(
            payload: validPayload(),
            header: {'alg': null},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('must be "RS256"')),
          );
        });
      });

      group('critical header parameter', () {
        test('rejects an unsupported extension', () async {
          // The example from RFC 7515 §4.1.11.
          final token = await mintToken(
            payload: validPayload(),
            header: {
              'crit': ['exp'],
              'exp': 1363284000,
            },
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"crit"')),
          );
        });

        test('rejects an empty list', () async {
          // RFC 7515 forbids producers from sending this, so it isn't treated
          // as listing no extensions.
          final token = await mintToken(
            payload: validPayload(),
            header: {'crit': <String>[]},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"crit"')),
          );
        });
      });

      group('issuer', () {
        test('rejects a mismatch', () async {
          final token = await mintToken(
            payload: validPayload({'iss': 'https://evil.example.com'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"iss"')),
          );
        });

        test('rejects a missing issuer when issuers are configured', () async {
          final token = await mintToken(
            payload: validPayload({'iss': #absent}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"iss"')),
          );
        });

        test('accepts any of several configured issuers', () async {
          final token = await mintToken(payload: validPayload());

          final claims = await buildVerifier(
            expectedIssuers: {'https://other.example.com', _issuer},
          ).verify(token);

          expect(claims.issuer, _issuer);
        });

        test('skips the check when no issuers are configured', () async {
          final token = await mintToken(
            payload: validPayload({'iss': #absent}),
          );

          final claims = await buildVerifier(
            expectedIssuers: null,
          ).verify(token);

          expect(claims.issuer, isNull);
        });
      });

      group('audience', () {
        test('accepts a list of allowed audiences', () async {
          final token = await mintToken(
            payload: validPayload({
              'aud': ['other', _audience],
            }),
          );

          final claims = await buildVerifier(
            allowedAudiences: {'other', _audience},
          ).verify(token);

          expect(claims.audience, ['other', _audience]);
        });

        test('rejects a list containing a disallowed audience', () async {
          // OpenID Connect Core 1.0 §3.1.3.7: a token that is also intended
          // for an untrusted audience must be rejected, even though it names
          // this one too.
          final token = await mintToken(
            payload: validPayload({
              'aud': ['other', _audience],
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"aud"')),
          );
        });

        test('rejects an empty audience list', () async {
          final token = await mintToken(
            payload: validPayload({'aud': <String>[]}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"aud"')),
          );
        });

        test('rejects a list containing a non-string audience', () async {
          final token = await mintToken(
            payload: validPayload({
              'aud': [_audience, 123],
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"aud"')),
          );
        });

        test('rejects a mismatch', () async {
          final token = await mintToken(
            payload: validPayload({'aud': 'someone-else'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"aud"')),
          );
        });

        test('rejects a superstring rather than matching loosely', () async {
          // Guards against the substring matching the previous Firebase
          // functions implementation used.
          final token = await mintToken(
            payload: validPayload({'aud': 'not-$_audience-really'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('"aud"')),
          );
        });

        test(
          'rejects a missing audience when audiences are configured',
          () async {
            final token = await mintToken(
              payload: validPayload({'aud': #absent}),
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(contains('"aud"')),
            );
          },
        );

        test('skips the check when no audiences are configured', () async {
          final token = await mintToken(
            payload: validPayload({'aud': 'anything'}),
          );

          final claims = await buildVerifier(
            allowedAudiences: null,
          ).verify(token);

          expect(claims.audience, ['anything']);
        });

        test(
          'rejects a malformed audience when no audiences are configured',
          () async {
            for (final audience in [
              [_audience, 123],
              123,
              {'name': _audience},
            ]) {
              final token = await mintToken(
                payload: validPayload({'aud': audience}),
              );

              await expectLater(
                buildVerifier(allowedAudiences: null).verify(token),
                _throwsVerification(
                  contains('must be a string or a list of strings'),
                ),
                reason: '$audience',
              );
            }
          },
        );

        test('treats a null audience as absent', () async {
          final token = await mintToken(payload: validPayload({'aud': null}));

          final claims = await buildVerifier(
            allowedAudiences: null,
          ).verify(token);

          expect(claims.audience, isEmpty);
        });
      });

      group('expiration', () {
        test('rejects an expired token', () async {
          final token = await mintToken(
            payload: validPayload({
              'exp': _numericDate(_now.subtract(const Duration(hours: 1))),
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('expired')),
          );
        });

        test('accepts a token expired within the skew tolerance', () async {
          final token = await mintToken(
            payload: validPayload({
              'exp': _numericDate(_now.subtract(const Duration(minutes: 2))),
            }),
          );

          await expectLater(buildVerifier().verify(token), completes);
        });

        test('rejects a token expired beyond the skew tolerance', () async {
          final token = await mintToken(
            payload: validPayload({
              'exp': _numericDate(_now.subtract(const Duration(minutes: 6))),
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('expired')),
          );
        });

        test('honors a custom skew tolerance', () async {
          final token = await mintToken(
            payload: validPayload({
              'exp': _numericDate(_now.subtract(const Duration(minutes: 2))),
            }),
          );

          await expectLater(
            buildVerifier(clockSkewTolerance: Duration.zero).verify(token),
            _throwsVerification(contains('expired')),
          );
        });

        test('rejects a token with no exp claim', () async {
          // A token without an expiry would otherwise be valid forever.
          final token = await mintToken(
            payload: validPayload({'exp': #absent}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('no "exp"')),
          );
        });

        test('accepts the largest exp that DateTime can represent', () async {
          // Adding the skew tolerance to this would overflow `DateTime`.
          final token = await mintToken(
            payload: validPayload({'exp': 8640000000000}),
          );

          final claims = await buildVerifier().verify(token);

          expect(
            claims.expiry,
            DateTime.fromMillisecondsSinceEpoch(8640000000000000, isUtc: true),
          );
        });

        test('rejects an exp beyond the range of DateTime', () async {
          // On native platforms, converting this to milliseconds would
          // overflow and wrap around to 1969.
          final token = await mintToken(payload: validPayload({'exp': 1e19}));

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('no "exp"')),
          );
        });

        test(
          'rejects an exp whose milliseconds overflow a 64-bit int',
          () async {
            // This is 2^64 / 1000, rounded up, so on native platforms
            // multiplying it by 1000 as an integer would wrap around to 384, a
            // valid time in 1970.
            final token = await mintToken(
              payload: validPayload({'exp': 18446744073709552}),
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(contains('no "exp"')),
            );
          },
        );

        test('rejects an exp too large for a double', () async {
          // `1e400` is valid JSON, but `jsonDecode` turns it into infinity.
          final token = await mintToken(
            payload: validPayload({'exp': 0}),
            editPayloadJson: (json) =>
                json.replaceFirst('"exp":0', '"exp":1e400'),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(contains('no "exp"')),
          );
        });

        test('keeps the fractional part of an exp', () async {
          final token = await mintToken(
            payload: validPayload({
              'exp': _numericDate(_now.add(const Duration(hours: 1))) + 0.5,
            }),
          );

          final claims = await buildVerifier().verify(token);

          expect(
            claims.expiry,
            _now.add(const Duration(hours: 1, milliseconds: 500)),
          );
        });
      });

      group('issued at', () {
        test(
          'rejects a token issued beyond the skew tolerance ahead',
          () async {
            final token = await mintToken(
              payload: validPayload({
                'iat': _numericDate(_now.add(const Duration(minutes: 6))),
              }),
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(contains('in the future')),
            );
          },
        );

        test('accepts a token issued slightly ahead', () async {
          final token = await mintToken(
            payload: validPayload({
              'iat': _numericDate(_now.add(const Duration(minutes: 2))),
            }),
          );

          await expectLater(buildVerifier().verify(token), completes);
        });

        test('accepts a token with no iat claim', () async {
          final token = await mintToken(
            payload: validPayload({'iat': #absent}),
          );

          final claims = await buildVerifier().verify(token);

          expect(claims.issuedAt, isNull);
        });

        test('accepts the smallest iat that DateTime can represent', () async {
          // Subtracting the skew tolerance from this would overflow
          // `DateTime`.
          final token = await mintToken(
            payload: validPayload({'iat': -8640000000000}),
          );

          final claims = await buildVerifier().verify(token);

          expect(
            claims.issuedAt,
            DateTime.fromMillisecondsSinceEpoch(-8640000000000000, isUtc: true),
          );
        });
      });

      group('subject', () {
        test('is exposed when present', () async {
          final token = await mintToken(payload: validPayload());

          expect((await buildVerifier().verify(token)).subject, 'user-123');
        });

        test('is null rather than fatal when absent', () async {
          // Some Google tokens, such as Firebase beforeSendEmail events,
          // legitimately omit `sub`, and neither reference verifier requires
          // it.
          final token = await mintToken(
            payload: validPayload({'sub': #absent}),
          );

          expect((await buildVerifier().verify(token)).subject, isNull);
        });
      });

      group('email claims', () {
        test('exposes email', () async {
          final token = await mintToken(
            payload: validPayload({'email': 'user@example.com'}),
          );

          expect(
            (await buildVerifier().verify(token)).email,
            'user@example.com',
          );
        });

        test('isEmailVerified accepts the boolean true', () async {
          final token = await mintToken(
            payload: validPayload({'email_verified': true}),
          );

          expect((await buildVerifier().verify(token)).isEmailVerified, isTrue);
        });

        test('isEmailVerified accepts the string "true"', () async {
          // Google emits both forms; Java coerces them the same way.
          final token = await mintToken(
            payload: validPayload({'email_verified': 'true'}),
          );

          expect((await buildVerifier().verify(token)).isEmailVerified, isTrue);
        });

        test('isEmailVerified is false when absent or falsy', () async {
          for (final value in [false, 'false', 'yes', 0, #absent]) {
            final token = await mintToken(
              payload: validPayload({'email_verified': value}),
            );

            expect(
              (await buildVerifier().verify(token)).isEmailVerified,
              isFalse,
              reason: 'for $value',
            );
          }
        });
      });

      group('malformed input', () {
        for (final token in ['', 'garbage', 'a.b', 'a.b.c.d', '!!!.x.y']) {
          test('rejects ${token.isEmpty ? '(empty)' : token}', () async {
            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(contains('well-formed JWS')),
            );
          });
        }
      });

      test('surfaces a key fetch failure as a verification failure', () async {
        final verifier = TokenVerifier(
          jwksUri: _jwksUri,
          clock: () => _now,
          clientFactory: () =>
              MockClient((_) async => http.Response('down', 503)),
        );
        final token = await mintToken(payload: validPayload());

        await expectLater(
          verifier.verify(token),
          _throwsVerification(contains('Failed to fetch public keys')),
        );
      });

      test('verifies against a legacy certificate map endpoint', () async {
        final verifier = TokenVerifier(
          jwksUri: _jwksUri,
          expectedIssuers: const {_issuer},
          allowedAudiences: const {_audience},
          clock: () => _now,
          clientFactory: () => MockClient(
            (_) async =>
                http.Response(jsonEncode({_keyId: testCertificatePem}), 200),
          ),
        );
        final token = await mintToken(payload: validPayload());

        expect((await verifier.verify(token)).subject, 'user-123');
      });

      test(
        'verifies a GitHub Actions OIDC token',
        () async {
          // Request a token the same way `core.getIDToken()` from
          // `@actions/core` does.
          const audience = 'google-cloud-dart-test';
          final requestUrl = Uri.parse(_githubTokenRequestUrl!);
          final response = await http.get(
            requestUrl.replace(
              queryParameters: {
                ...requestUrl.queryParameters,
                'audience': audience,
              },
            ),
            headers: {'Authorization': 'Bearer $_githubTokenRequestToken'},
          );
          expect(response.statusCode, 200, reason: response.body);
          final token =
              (jsonDecode(response.body) as Map<String, Object?>)['value']!
                  as String;

          final verifier = TokenVerifier(
            jwksUri: Uri.https(
              'token.actions.githubusercontent.com',
              '/.well-known/jwks',
            ),
            expectedIssuers: const {
              'https://token.actions.githubusercontent.com',
            },
            allowedAudiences: const {audience},
          );
          final claims = await verifier.verify(token);

          final repository = readEnvironment('GITHUB_REPOSITORY');
          expect(claims.subject, startsWith('repo:$repository:'));
          expect(claims.allClaims['repository'], repository);
        },
        skip: _githubTokenRequestUrl == null || _githubTokenRequestToken == null
            ? 'Requires a GitHub Actions job with "id-token: write" permission'
            : null,
      );
    },
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );
}
