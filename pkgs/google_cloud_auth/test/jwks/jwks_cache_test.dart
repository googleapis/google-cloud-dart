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

import 'package:google_cloud_auth/src/jwks/jwks_cache.dart';
import 'package:google_cloud_auth/src/verifier/token_verification_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

final _jwksUri = Uri.https('example.com', '/certs');
const _keyId = 'test-key-1';

late Map<String, Object?> _jwk;

/// A clock the test advances explicitly.
final class FakeClock {
  DateTime now = DateTime.utc(2026, 1, 1, 12);

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

void main() {
  late FakeClock clock;

  setUpAll(() async {
    if (!canUseWebCrypto) return;
    _jwk = {
      ...await (await getTestPublicKey()).exportJsonWebKey(),
      'kid': _keyId,
      'alg': 'RS256',
      'use': 'sig',
    };
  });

  setUp(() {
    clock = FakeClock();
  });

  /// Builds a cache over a client that records how many requests it received.
  ({JwksCache cache, List<http.Request> requests}) buildCache(
    FutureOr<http.Response> Function(http.Request request) handler,
  ) {
    final requests = <http.Request>[];
    final cache = JwksCache(
      uri: _jwksUri,
      clock: clock.call,
      clientFactory: () => MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
    return (cache: cache, requests: requests);
  }

  group('freshnessLifetime', () {
    test('reads max-age', () {
      expect(
        freshnessLifetime({'cache-control': 'public, max-age=3600'}),
        const Duration(seconds: 3600),
      );
    });

    test('subtracts Age', () {
      expect(
        freshnessLifetime({
          'cache-control': 'public, max-age=3600',
          'age': '600',
        }),
        const Duration(seconds: 3000),
      );
    });

    test('is case insensitive and tolerates spacing and quotes', () {
      expect(
        freshnessLifetime({'cache-control': 'PUBLIC, MAX-AGE = "120"'}),
        const Duration(seconds: 120),
      );
    });

    test('clamps to zero when Age exceeds max-age', () {
      expect(
        freshnessLifetime({'cache-control': 'max-age=60', 'age': '600'}),
        Duration.zero,
      );
    });

    test('returns zero for no-store and no-cache', () {
      expect(freshnessLifetime({'cache-control': 'no-store'}), Duration.zero);
      expect(
        freshnessLifetime({'cache-control': 'no-cache, max-age=600'}),
        Duration.zero,
      );
    });

    test('returns null when there is nothing useful', () {
      expect(freshnessLifetime({}), isNull);
      expect(freshnessLifetime({'cache-control': 'public'}), isNull);
    });

    test('does not match max-age or no-cache inside another directive', () {
      expect(freshnessLifetime({'cache-control': 's-maxage=600'}), isNull);
      expect(
        freshnessLifetime({'cache-control': 'x-no-cache=1, max-age=60'}),
        const Duration(seconds: 60),
      );
    });

    test('ignores malformed max-age values', () {
      expect(freshnessLifetime({'cache-control': 'max-age=120abc'}), isNull);
      expect(freshnessLifetime({'cache-control': 'max-age="120'}), isNull);
    });

    test('clamps extreme max-age values to 2^31 - 1 seconds', () {
      expect(
        freshnessLifetime({
          'cache-control': 'max-age=999999999999999999999999999',
        }),
        const Duration(seconds: 0x7fffffff),
      );
    });
  });

  group(
    'JwksCache',
    () {
      test('fetches and returns a key by id', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
          ),
        );

        expect(await cache.lookupKey(_keyId), isNotNull);
        expect(requests, hasLength(1));
        expect(requests.single.url, _jwksUri);
      });

      test('serves later lookups from cache', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
            headers: {'cache-control': 'max-age=3600'},
          ),
        );

        await cache.lookupKey(_keyId);
        await cache.lookupKey(_keyId);
        await cache.lookupKey(_keyId);

        expect(requests, hasLength(1));
      });

      test('re-fetches once the max-age has elapsed', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
            headers: {'cache-control': 'max-age=600'},
          ),
        );

        await cache.lookupKey(_keyId);
        clock.advance(const Duration(seconds: 599));
        await cache.lookupKey(_keyId);
        expect(requests, hasLength(1));

        clock.advance(const Duration(seconds: 2));
        await cache.lookupKey(_keyId);
        expect(requests, hasLength(2));
      });

      test('Age shortens the cache lifetime', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
            headers: {'cache-control': 'max-age=600', 'age': '540'},
          ),
        );

        await cache.lookupKey(_keyId);
        clock.advance(const Duration(seconds: 61));
        await cache.lookupKey(_keyId);

        expect(requests, hasLength(2));
      });

      test('falls back to a one hour lifetime with no cache headers', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
          ),
        );

        await cache.lookupKey(_keyId);
        clock.advance(const Duration(minutes: 59));
        await cache.lookupKey(_keyId);
        expect(requests, hasLength(1));

        clock.advance(const Duration(minutes: 2));
        await cache.lookupKey(_keyId);
        expect(requests, hasLength(2));
      });

      test('concurrent lookups share a single request', () async {
        final completer = Completer<http.Response>();
        final (:cache, :requests) = buildCache((_) => completer.future);

        final lookups = Future.wait([
          Future.value(cache.lookupKey(_keyId)),
          Future.value(cache.lookupKey(_keyId)),
          Future.value(cache.lookupKey(_keyId)),
        ]);
        completer.complete(
          http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
          ),
        );

        expect(await lookups, everyElement(isNotNull));
        expect(requests, hasLength(1));
      });

      group('unknown key id', () {
        test('does not trigger a fetch while the cache is fresh', () async {
          final (:cache, :requests) = buildCache(
            (_) => http.Response(
              jsonEncode({
                'keys': [_jwk],
              }),
              200,
              headers: {'cache-control': 'max-age=3600'},
            ),
          );

          expect(await cache.lookupKey(_keyId), isNotNull);
          expect(await cache.lookupKey('never-existed'), isNull);
          expect(await cache.lookupKey('also-never-existed'), isNull);

          expect(requests, hasLength(1));
        });

        test('returns null from a cold cache after a single fetch', () async {
          final (:cache, :requests) = buildCache(
            (_) => http.Response(
              jsonEncode({
                'keys': [_jwk],
              }),
              200,
              headers: {'cache-control': 'max-age=3600'},
            ),
          );

          expect(await cache.lookupKey('never-existed'), isNull);
          expect(requests, hasLength(1));
        });

        test('rotated keys are picked up once the cache expires', () async {
          var fetchCount = 0;
          final (:cache, :requests) = buildCache((_) async {
            // Serve the original key first, the rotated key afterwards.
            fetchCount++;
            return http.Response(
              fetchCount == 1
                  ? jsonEncode({
                      'keys': [_jwk],
                    })
                  : jsonEncode({
                      'keys': [
                        {..._jwk, 'kid': 'rotated-key'},
                      ],
                    }),
              200,
              headers: {'cache-control': 'max-age=3600'},
            );
          });

          expect(await cache.lookupKey(_keyId), isNotNull);
          expect(await cache.lookupKey('rotated-key'), isNull);
          expect(requests, hasLength(1));

          clock.advance(const Duration(hours: 1));
          expect(await cache.lookupKey('rotated-key'), isNotNull);
          expect(requests, hasLength(2));
        });
      });

      group('failures', () {
        // A failed fetch is never cached, matching the reference clients: the
        // next lookup always tries the endpoint again.
        for (final status in [404, 500, 429]) {
          test('are not cached for HTTP $status', () async {
            final (:cache, :requests) = buildCache(
              (_) => http.Response('nope', status),
            );

            await expectLater(
              cache.lookupKey(_keyId),
              throwsA(isA<TokenVerificationException>()),
            );
            await expectLater(
              cache.lookupKey(_keyId),
              throwsA(isA<TokenVerificationException>()),
            );

            expect(requests, hasLength(2));
          });
        }

        test('do not prevent recovery on the next lookup', () async {
          var fail = true;
          final (:cache, :requests) = buildCache(
            (_) => fail
                ? http.Response('nope', 404)
                : http.Response(
                    jsonEncode({
                      'keys': [_jwk],
                    }),
                    200,
                  ),
          );

          await expectLater(
            cache.lookupKey(_keyId),
            throwsA(isA<TokenVerificationException>()),
          );

          fail = false;
          expect(await cache.lookupKey(_keyId), isNotNull);
          expect(requests, hasLength(2));
        });
      });

      group('parsing', () {
        test('reads the legacy certificate map format', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response(
              jsonEncode({_keyId: testGoogleSecureTokenCertificatePem}),
              200,
            ),
          );

          expect(await cache.lookupKey(_keyId), isNotNull);
        });

        test('skips non-RSA keys but keeps usable ones', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response(
              jsonEncode({
                'keys': [
                  _jwk,
                  {
                    'kid': 'ec-key',
                    'kty': 'EC',
                    'crv': 'P-256',
                    'x': 'a',
                    'y': 'b',
                  },
                ],
              }),
              200,
            ),
          );

          expect(await cache.lookupKey(_keyId), isNotNull);
          expect(await cache.lookupKey('ec-key'), isNull);
        });

        test('skips keys that declare a non-RS256 algorithm', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response(
              jsonEncode({
                'keys': [
                  {..._jwk, 'alg': 'RS512'},
                ],
              }),
              200,
            ),
          );

          await expectLater(
            cache.lookupKey(_keyId),
            throwsA(
              isA<TokenVerificationException>().having(
                (e) => e.message,
                'message',
                contains('no usable RSA keys'),
              ),
            ),
          );
        });

        test('skips an individually malformed key', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response(
              jsonEncode({
                'keys': [
                  _jwk,
                  {'kid': 'broken', 'kty': 'RSA', 'n': '!!!', 'e': 'AQAB'},
                ],
              }),
              200,
            ),
          );

          expect(await cache.lookupKey(_keyId), isNotNull);
          expect(await cache.lookupKey('broken'), isNull);
        });

        test('throws on a response with no usable keys', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response(jsonEncode({'keys': const <Object?>[]}), 200),
          );

          await expectLater(
            cache.lookupKey(_keyId),
            throwsA(isA<TokenVerificationException>()),
          );
        });

        test('throws on malformed JSON', () async {
          final (:cache, requests: _) = buildCache(
            (_) => http.Response('not json', 200),
          );

          await expectLater(
            cache.lookupKey(_keyId),
            throwsA(
              isA<TokenVerificationException>().having(
                (e) => e.message,
                'message',
                contains('not valid JSON'),
              ),
            ),
          );
        });
      });

      test('wraps a transport failure', () async {
        final (:cache, requests: _) = buildCache(
          (_) => throw http.ClientException('connection refused'),
        );

        await expectLater(
          cache.lookupKey(_keyId),
          throwsA(
            isA<TokenVerificationException>().having(
              (e) => e.message,
              'message',
              contains('Failed to fetch public keys'),
            ),
          ),
        );
      });

      test('refresh discards cached keys', () async {
        final (:cache, :requests) = buildCache(
          (_) => http.Response(
            jsonEncode({
              'keys': [_jwk],
            }),
            200,
            headers: {'cache-control': 'max-age=3600'},
          ),
        );

        await cache.lookupKey(_keyId);
        await cache.refresh();

        expect(requests, hasLength(2));
      });
    },
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );

  test(
    'JSON Web Key Set',
    testOn: 'vm',
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
    () async {
      // Will not work in the browser because this endpoint does not support
      // CORS.
      final cache = JwksCache(
        uri: Uri.https('www.googleapis.com', '/oauth2/v3/certs'),
      );
      await cache.refresh();
      expect(cache.keys, isNotEmpty);
    },
  );

  test(
    'PEM-encoded X.509 certificates',
    testOn: 'vm',
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
    () async {
      // Will not work in the browser because this endpoint does not support
      // CORS.
      final cache = JwksCache(
        uri: Uri.https('www.googleapis.com', '/oauth2/v1/certs'),
      );
      await cache.refresh();
      expect(cache.keys, isNotEmpty);
    },
  );
}
