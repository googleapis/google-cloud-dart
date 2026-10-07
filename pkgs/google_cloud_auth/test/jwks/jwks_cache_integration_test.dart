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

// Loads keys from Google's public key endpoints, covering both formats that
// `JwksCache` accepts.
//
// Run with: dart test -P google-cloud test/jwks/jwks_cache_integration_test.dart

@TestOn('vm')
@Tags(['google-cloud'])
library;

import 'dart:convert';

import 'package:google_cloud_auth/src/jwks/jwks_cache.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

final _jwksEndpoints = {
  'Google OAuth 2.0': Uri.https('www.googleapis.com', '/oauth2/v3/certs'),
  'Firebase ID token': Uri.https(
    'www.googleapis.com',
    '/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
};

final _pemEndpoints = {
  'Google OAuth 2.0': Uri.https('www.googleapis.com', '/oauth2/v1/certs'),
  'Firebase ID token': Uri.https(
    'www.googleapis.com',
    '/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  ),
  'Firebase session cookie': Uri.https(
    'www.googleapis.com',
    '/identitytoolkit/v3/relyingparty/publicKeys',
  ),
};

void main() {
  late http.Client client;

  setUp(() {
    client = http.Client();
  });

  tearDown(() {
    client.close();
  });

  /// Fetches [uri] directly, independently of [JwksCache], and returns the
  /// decoded JSON object.
  Future<Map<String, Object?>> fetchJson(Uri uri) async {
    final response = await client.get(uri);
    expect(response.statusCode, 200, reason: 'GET $uri');
    return jsonDecode(response.body) as Map<String, Object?>;
  }

  /// Checks that [JwksCache] can load every key published at [uri].
  Future<void> expectAllKeysLoad(Uri uri, Iterable<String> keyIds) async {
    expect(keyIds, isNotEmpty);

    final cache = JwksCache(uri: uri);
    for (final keyId in keyIds) {
      expect(await cache.lookupKey(keyId), isNotNull, reason: 'kid $keyId');
    }
    // Every endpoint sends Cache-Control: max-age, which should be honored.
    expect(cache.expiry, isNotNull);
    expect(cache.expiry!.isAfter(DateTime.now()), isTrue);
  }

  group('JSON Web Key Set', () {
    for (final MapEntry(key: name, value: uri) in _jwksEndpoints.entries) {
      test('$name ($uri)', () async {
        final json = await fetchJson(uri);
        final keys = json['keys'] as List<Object?>;
        final keyIds = [
          for (final key in keys)
            (key as Map<String, Object?>)['kid'] as String,
        ];

        await expectAllKeysLoad(uri, keyIds);
      });
    }
  });

  group('PEM-encoded X.509 certificates', () {
    for (final MapEntry(key: name, value: uri) in _pemEndpoints.entries) {
      test('$name ($uri)', () async {
        final json = await fetchJson(uri);
        expect(json, isNot(contains('keys')), reason: 'expected a PEM map');
        for (final value in json.values) {
          expect(value, startsWith('-----BEGIN CERTIFICATE-----'));
        }

        await expectAllKeysLoad(uri, json.keys);
      });
    }
  });
}
