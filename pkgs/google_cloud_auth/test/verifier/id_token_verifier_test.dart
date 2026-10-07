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

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../src/test_support.dart';
import '../test_utils.dart';

final _jwksUri = Uri.https('example.com', '/certs');
const _issuer = 'https://issuer.example.com';
const _audience = 'my-service';

final _now = DateTime.utc(2026, 6, 1, 12);

Matcher _throwsVerification(
  TokenVerificationFailure reason,
  Object messageMatcher,
) => throwsA(
  isA<TokenVerificationException>()
      .having((e) => e.reason, 'reason', reason)
      .having((e) => e.message, 'message', messageMatcher),
);

void main() {
  late TestKey key;

  setUpAll(() async {
    if (!canUseWebCrypto) return;
    key = await TestKey.generate();
  });

  IdTokenVerifier buildVerifier({
    Set<String>? expectedIssuers = const {_issuer},
    Set<String>? allowedAudiences = const {_audience},
    Duration clockSkewTolerance = IdTokenVerifier.defaultClockSkewTolerance,
    DateTime? now,
    String? jwksBody,
  }) => IdTokenVerifier(
    jwksUri: _jwksUri,
    expectedIssuers: expectedIssuers,
    allowedAudiences: allowedAudiences,
    clockSkewTolerance: clockSkewTolerance,
    clock: () => now ?? _now,
    clientFactory: () =>
        MockClient((_) async => http.Response(jwksBody ?? key.jwksJson(), 200)),
  );

  /// A payload that passes every check, with the given overrides applied.
  Map<String, dynamic> validPayload([
    Map<String, dynamic> overrides = const {},
  ]) => {
    'iss': _issuer,
    'aud': _audience,
    'sub': 'user-123',
    'iat': numericDate(_now.subtract(const Duration(minutes: 1))),
    'exp': numericDate(_now.add(const Duration(hours: 1))),
    ...overrides,
  }..removeWhere((_, value) => value == #absent);

  group(
    'IdTokenVerifier.verify',
    () {
      test('accepts a valid token and returns its claims', () async {
        final token = await key.mintToken(payload: validPayload());

        final claims = await buildVerifier().verify(token);

        expect(claims.subject, 'user-123');
        expect(claims.issuer, _issuer);
        expect(claims.audience, [_audience]);
        expect(claims.expiry, _now.add(const Duration(hours: 1)));
        expect(claims.issuedAt, _now.subtract(const Duration(minutes: 1)));
      });

      test('exposes custom claims through unverifiedPayload', () async {
        final token = await key.mintToken(
          payload: validPayload({
            'tenant': 'acme',
            'roles': ['admin'],
          }),
        );

        final claims = await buildVerifier().verify(token);

        expect(claims.unverifiedPayload['tenant'], 'acme');
        expect(claims.unverifiedPayload['roles'], ['admin']);
      });

      group('signature', () {
        test('rejects a corrupted signature', () async {
          final token = await key.mintToken(
            payload: validPayload(),
            corruptSignature: true,
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidSignature,
              contains('signature is invalid'),
            ),
          );
        });

        test('rejects a token signed by a different key', () async {
          final attacker = await TestKey.generate(keyId: key.keyId);
          final token = await attacker.mintToken(payload: validPayload());

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidSignature,
              contains('signature is invalid'),
            ),
          );
        });

        test('rejects an unknown key id', () async {
          final token = await key.mintToken(
            payload: validPayload(),
            header: {'kid': 'not-published'},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.unknownKeyId,
              contains('does not match any key'),
            ),
          );
        });

        test('rejects a token with no key id', () async {
          final token = await key.mintToken(
            payload: validPayload(),
            header: {'kid': null},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.missingKeyId,
              contains('no "kid"'),
            ),
          );
        });
      });

      group('algorithm', () {
        // The signature is still a valid RS256 signature; only the declared
        // algorithm changes. A verifier that dispatched on the header would be
        // fooled, so each of these must be rejected before any key lookup.
        for (final algorithm in ['none', 'HS256', 'RS512', 'ES256']) {
          test('rejects "$algorithm"', () async {
            final token = await key.mintToken(
              payload: validPayload(),
              header: {'alg': algorithm},
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(
                TokenVerificationFailure.unsupportedAlgorithm,
                contains('must be "RS256"'),
              ),
            );
          });
        }

        test('rejects a missing algorithm', () async {
          final token = await key.mintToken(
            payload: validPayload(),
            header: {'alg': null},
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.unsupportedAlgorithm,
              contains('must be "RS256"'),
            ),
          );
        });
      });

      group('issuer', () {
        test('rejects a mismatch', () async {
          final token = await key.mintToken(
            payload: validPayload({'iss': 'https://evil.example.com'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidIssuer,
              contains('"iss"'),
            ),
          );
        });

        test('rejects a missing issuer when issuers are configured', () async {
          final token = await key.mintToken(
            payload: validPayload({'iss': #absent}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidIssuer,
              contains('"iss"'),
            ),
          );
        });

        test('accepts any of several configured issuers', () async {
          final token = await key.mintToken(payload: validPayload());

          final claims = await buildVerifier(
            expectedIssuers: {'https://other.example.com', _issuer},
          ).verify(token);

          expect(claims.issuer, _issuer);
        });

        test('skips the check when no issuers are configured', () async {
          final token = await key.mintToken(
            payload: validPayload({'iss': #absent}),
          );

          final claims = await buildVerifier(
            expectedIssuers: null,
          ).verify(token);

          expect(claims.issuer, isNull);
        });
      });

      group('audience', () {
        test('accepts a list containing an allowed audience', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'aud': ['other', _audience],
            }),
          );

          final claims = await buildVerifier().verify(token);

          expect(claims.audience, ['other', _audience]);
        });

        test('rejects a mismatch', () async {
          final token = await key.mintToken(
            payload: validPayload({'aud': 'someone-else'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidAudience,
              contains('"aud"'),
            ),
          );
        });

        test('rejects a superstring rather than matching loosely', () async {
          // Guards against the substring matching the previous Firebase
          // functions implementation used.
          final token = await key.mintToken(
            payload: validPayload({'aud': 'not-$_audience-really'}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.invalidAudience,
              contains('"aud"'),
            ),
          );
        });

        test(
          'rejects a missing audience when audiences are configured',
          () async {
            final token = await key.mintToken(
              payload: validPayload({'aud': #absent}),
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(
                TokenVerificationFailure.invalidAudience,
                contains('"aud"'),
              ),
            );
          },
        );

        test('skips the check when no audiences are configured', () async {
          final token = await key.mintToken(
            payload: validPayload({'aud': 'anything'}),
          );

          final claims = await buildVerifier(
            allowedAudiences: null,
          ).verify(token);

          expect(claims.audience, ['anything']);
        });
      });

      group('expiration', () {
        test('rejects an expired token', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'exp': numericDate(_now.subtract(const Duration(hours: 1))),
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.expired,
              contains('expired'),
            ),
          );
        });

        test('accepts a token expired within the skew tolerance', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'exp': numericDate(_now.subtract(const Duration(minutes: 2))),
            }),
          );

          await expectLater(buildVerifier().verify(token), completes);
        });

        test('rejects a token expired beyond the skew tolerance', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'exp': numericDate(_now.subtract(const Duration(minutes: 6))),
            }),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.expired,
              contains('expired'),
            ),
          );
        });

        test('honors a custom skew tolerance', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'exp': numericDate(_now.subtract(const Duration(minutes: 2))),
            }),
          );

          await expectLater(
            buildVerifier(clockSkewTolerance: Duration.zero).verify(token),
            _throwsVerification(
              TokenVerificationFailure.expired,
              contains('expired'),
            ),
          );
        });

        test('rejects a token with no exp claim', () async {
          // A token without an expiry would otherwise be valid forever.
          final token = await key.mintToken(
            payload: validPayload({'exp': #absent}),
          );

          await expectLater(
            buildVerifier().verify(token),
            _throwsVerification(
              TokenVerificationFailure.missingExpiration,
              contains('no "exp"'),
            ),
          );
        });
      });

      group('issued at', () {
        test(
          'rejects a token issued beyond the skew tolerance ahead',
          () async {
            final token = await key.mintToken(
              payload: validPayload({
                'iat': numericDate(_now.add(const Duration(minutes: 6))),
              }),
            );

            await expectLater(
              buildVerifier().verify(token),
              _throwsVerification(
                TokenVerificationFailure.issuedInFuture,
                contains('in the future'),
              ),
            );
          },
        );

        test('accepts a token issued slightly ahead', () async {
          final token = await key.mintToken(
            payload: validPayload({
              'iat': numericDate(_now.add(const Duration(minutes: 2))),
            }),
          );

          await expectLater(buildVerifier().verify(token), completes);
        });

        test('accepts a token with no iat claim', () async {
          final token = await key.mintToken(
            payload: validPayload({'iat': #absent}),
          );

          final claims = await buildVerifier().verify(token);

          expect(claims.issuedAt, isNull);
        });
      });

      group('subject', () {
        test('is exposed when present', () async {
          final token = await key.mintToken(payload: validPayload());

          expect((await buildVerifier().verify(token)).subject, 'user-123');
        });

        test('is null rather than fatal when absent', () async {
          // Some Google tokens, such as Firebase beforeSendEmail events,
          // legitimately omit `sub`, and neither reference verifier requires
          // it.
          final token = await key.mintToken(
            payload: validPayload({'sub': #absent}),
          );

          expect((await buildVerifier().verify(token)).subject, isNull);
        });
      });

      group('email claims', () {
        test('exposes email', () async {
          final token = await key.mintToken(
            payload: validPayload({'email': 'user@example.com'}),
          );

          expect(
            (await buildVerifier().verify(token)).email,
            'user@example.com',
          );
        });

        test('isEmailVerified accepts the boolean true', () async {
          final token = await key.mintToken(
            payload: validPayload({'email_verified': true}),
          );

          expect((await buildVerifier().verify(token)).isEmailVerified, isTrue);
        });

        test('isEmailVerified accepts the string "true"', () async {
          // Google emits both forms; Java coerces them the same way.
          final token = await key.mintToken(
            payload: validPayload({'email_verified': 'true'}),
          );

          expect((await buildVerifier().verify(token)).isEmailVerified, isTrue);
        });

        test('isEmailVerified is false when absent or falsy', () async {
          for (final value in [false, 'false', 'yes', 0, #absent]) {
            final token = await key.mintToken(
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
              _throwsVerification(
                TokenVerificationFailure.malformed,
                contains('well-formed JWS'),
              ),
            );
          });
        }
      });

      test('surfaces a key fetch failure as a verification failure', () async {
        final verifier = IdTokenVerifier(
          jwksUri: _jwksUri,
          clock: () => _now,
          clientFactory: () =>
              MockClient((_) async => http.Response('down', 503)),
        );
        final token = await key.mintToken(payload: validPayload());

        await expectLater(
          verifier.verify(token),
          _throwsVerification(
            TokenVerificationFailure.keyUnavailable,
            contains('Failed to fetch public keys'),
          ),
        );
      });

      test('verifies against a legacy certificate map endpoint', () async {
        final verifier = IdTokenVerifier(
          jwksUri: _jwksUri,
          expectedIssuers: const {_issuer},
          allowedAudiences: const {_audience},
          clock: () => _now,
          clientFactory: () => MockClient(
            (_) async => http.Response(key.certificateMapJson(), 200),
          ),
        );
        final token = await key.mintToken(payload: validPayload());

        expect((await verifier.verify(token)).subject, 'user-123');
      });
    },
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );
}
