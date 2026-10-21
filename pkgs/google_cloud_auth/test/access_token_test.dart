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

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:google_cloud_auth/src/access_token.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final _tokenUri = Uri.https('oauth2.example.com', '/token');

void main() {
  group('fetchAccessToken', () {
    test('success', () async {
      final response = await fetchAccessToken(
        clientFactory: () => MockClient(
          (request) async => http.Response(
            jsonEncode({
              'access_token': 'test-token',
              'expires_in': 3599,
              'token_type': 'Bearer',
            }),
            200,
          ),
        ),
        send: (client) => client.get(_tokenUri),
        source: 'test endpoint',
      );

      expect(response.accessToken, 'test-token');
      expect(response.expiresIn, const Duration(seconds: 3599));
    });

    test('truncates fractional expires_in', () async {
      final response = await fetchAccessToken(
        clientFactory: () => MockClient(
          (request) async => http.Response(
            jsonEncode({'access_token': 'test-token', 'expires_in': 3599.9}),
            200,
          ),
        ),
        send: (client) => client.get(_tokenUri),
        source: 'test endpoint',
      );

      expect(response.expiresIn, const Duration(seconds: 3599));
    });

    test('throws CredentialException on network error', () async {
      await expectLater(
        fetchAccessToken(
          clientFactory: () => MockClient(
            (request) async => throw http.ClientException('Network down'),
          ),
          send: (client) => client.get(_tokenUri),
          source: 'test endpoint',
        ),
        throwsA(
          isA<CredentialException>()
              .having(
                (e) => e.message,
                'message',
                contains('Failed to get access token from test endpoint'),
              )
              .having(
                (e) => e.innerException,
                'innerException',
                isA<http.ClientException>(),
              ),
        ),
      );
    });

    test('throws CredentialException when clientFactory throws', () async {
      await expectLater(
        fetchAccessToken(
          clientFactory: () => throw http.ClientException('No client'),
          send: (client) => client.get(_tokenUri),
          source: 'test endpoint',
        ),
        throwsA(
          isA<CredentialException>().having(
            (e) => e.innerException,
            'innerException',
            isA<http.ClientException>(),
          ),
        ),
      );
    });

    test('throws CredentialException on HTTP error', () async {
      await expectLater(
        fetchAccessToken(
          clientFactory: () => MockClient(
            (request) async => http.Response('{"error": "invalid_grant"}', 400),
          ),
          send: (client) => client.get(_tokenUri),
          source: 'test endpoint',
        ),
        throwsA(
          isA<CredentialException>().having(
            (e) => e.message,
            'message',
            'Bad HTTP status response when fetching access token from test '
                'endpoint: 400',
          ),
        ),
      );
    });

    for (final (description, body, message) in [
      // The message from `jsonDecode` differs between platforms.
      ('invalid JSON', 'not valid json', anything),
      ('non-object JSON', '[1, 2, 3]', 'Expected a JSON object.'),
      (
        'missing access_token',
        '{"expires_in": 3600}',
        "Missing required 'access_token' in token response.",
      ),
      (
        'empty access_token',
        '{"access_token": "", "expires_in": 3600}',
        "Missing required 'access_token' in token response.",
      ),
      (
        'missing expires_in',
        '{"access_token": "test-token"}',
        "Missing required 'expires_in' in token response.",
      ),
      (
        'non-numeric expires_in',
        '{"access_token": "test-token", "expires_in": "3600"}',
        "Invalid 'expires_in' in token response.",
      ),
      (
        'infinite expires_in',
        '{"access_token": "test-token", "expires_in": 1e400}',
        "Invalid 'expires_in' in token response.",
      ),
    ]) {
      test('throws CredentialException on $description', () async {
        await expectLater(
          fetchAccessToken(
            clientFactory: () =>
                MockClient((request) async => http.Response(body, 200)),
            send: (client) => client.get(_tokenUri),
            source: 'test endpoint',
          ),
          throwsA(
            isA<CredentialException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to parse token response from test endpoint'),
                )
                .having(
                  (e) => e.innerException,
                  'innerException',
                  isA<FormatException>().having(
                    (e) => e.message,
                    'message',
                    message,
                  ),
                ),
          ),
        );
      });
    }
  });

  group('AccessTokenCache', () {
    late DateTime now;
    late int fetchCount;

    AccessTokenCache newCache({
      Duration expiresIn = const Duration(hours: 1),
    }) => AccessTokenCache(() async {
      fetchCount++;
      return (accessToken: 'token-$fetchCount', expiresIn: expiresIn);
    }, clock: () => now);

    setUp(() {
      now = DateTime.utc(2026);
      fetchCount = 0;
    });

    test('fetches a token on first use', () async {
      final cache = newCache();

      expect(await cache.accessToken(), 'token-1');
      expect(fetchCount, 1);
    });

    test('reuses a token until a minute before it expires', () async {
      final cache = newCache();
      await cache.accessToken();

      now = now.add(const Duration(minutes: 58, seconds: 59));
      expect(await cache.accessToken(), 'token-1');
      expect(fetchCount, 1);

      now = now.add(const Duration(seconds: 1));
      expect(await cache.accessToken(), 'token-2');
      expect(fetchCount, 2);
    });

    test('does not reuse a token that expires within a minute', () async {
      final cache = newCache(expiresIn: const Duration(seconds: 30));

      expect(await cache.accessToken(), 'token-1');
      expect(await cache.accessToken(), 'token-2');
      expect(fetchCount, 2);
    });

    test('fetches a new token when forceRefresh is true', () async {
      final cache = newCache();
      await cache.accessToken();

      expect(await cache.accessToken(forceRefresh: true), 'token-2');
      expect(fetchCount, 2);
    });

    test('keeps the cached token when a fetch fails', () async {
      var fail = false;
      var count = 0;
      final cache = AccessTokenCache(() async {
        count++;
        if (fail) throw CredentialException('Fetch failed');
        return (
          accessToken: 'token-$count',
          expiresIn: const Duration(hours: 1),
        );
      }, clock: () => now);

      expect(await cache.accessToken(), 'token-1');

      fail = true;
      await expectLater(
        cache.accessToken(forceRefresh: true),
        throwsA(isA<CredentialException>()),
      );
      expect(await cache.accessToken(), 'token-1');

      // The failed fetch is not shared with later callers.
      fail = false;
      expect(await cache.accessToken(forceRefresh: true), 'token-3');
    });
  });
}
