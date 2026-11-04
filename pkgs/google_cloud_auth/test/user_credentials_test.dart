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

import 'test_utils.dart';

const _testInfo = {
  'type': 'authorized_user',
  'client_id': 'test-client-id.apps.googleusercontent.com',
  'client_secret': 'test-client-secret',
  'refresh_token': 'test-refresh-token',
};

final _defaultTokenUri = Uri.https('oauth2.googleapis.com', '/token');

http.Response _tokenResponse(String accessToken) => http.Response(
  jsonEncode({
    'access_token': accessToken,
    'expires_in': 3600,
    'scope': 'https://www.googleapis.com/auth/cloud-platform',
    'token_type': 'Bearer',
  }),
  200,
);

/// A client factory whose clients add each request to [requests] and respond
/// with an access token.
http.Client Function() _recordingClientFactory(List<http.Request> requests) =>
    () => MockClient((request) async {
      requests.add(request);
      return _tokenResponse('access-token');
    });

void main() {
  group('UserCredentials', () {
    group('fromAuthorizedUserInfo', () {
      test('all keys set', () async {
        final requests = <http.Request>[];
        final creds = UserCredentials.fromAuthorizedUserInfo({
          'type': 'authorized_user',
          'client_id': 'client-123.apps.googleusercontent.com',
          'client_secret': 'secret-123',
          'refresh_token': 'refresh-123',
          'quota_project_id': 'quota-project',
          'universe_domain': 'googleapis.com',
          'account': '',
        }, clientFactory: _recordingClientFactory(requests));

        expect(creds.quotaProjectId, 'quota-project');
        expect(creds.universeDomain, 'googleapis.com');

        await creds.accessToken();
        expect(requests.single.url, _defaultTokenUri);
        expect(requests.single.bodyFields, {
          'grant_type': 'refresh_token',
          'client_id': 'client-123.apps.googleusercontent.com',
          'client_secret': 'secret-123',
          'refresh_token': 'refresh-123',
        });
      });

      test('minimal keys set', () async {
        final requests = <http.Request>[];
        final creds = UserCredentials.fromAuthorizedUserInfo({
          'client_id': 'client-123.apps.googleusercontent.com',
          'client_secret': 'secret-123',
          'refresh_token': 'refresh-123',
        }, clientFactory: _recordingClientFactory(requests));

        expect(creds.quotaProjectId, isNull);
        expect(creds.universeDomain, 'googleapis.com');

        await creds.accessToken();
        expect(requests.single.url, _defaultTokenUri);
        expect(requests.single.bodyFields, {
          'grant_type': 'refresh_token',
          'client_id': 'client-123.apps.googleusercontent.com',
          'client_secret': 'secret-123',
          'refresh_token': 'refresh-123',
        });
      });

      test('ignores token_uri', () async {
        final requests = <http.Request>[];
        final creds = UserCredentials.fromAuthorizedUserInfo({
          ..._testInfo,
          'token_uri': 'https://example.com/token',
        }, clientFactory: _recordingClientFactory(requests));

        await creds.accessToken();
        expect(requests.single.url, _defaultTokenUri);
      });

      test('accepts empty universe_domain', () {
        final creds = UserCredentials.fromAuthorizedUserInfo({
          ..._testInfo,
          'universe_domain': '',
        });

        expect(creds.universeDomain, 'googleapis.com');
      });

      test('throws on invalid type', () {
        expect(
          () => UserCredentials.fromAuthorizedUserInfo({
            ..._testInfo,
            'type': 'service_account',
          }),
          throwsFormatException,
        );
      });

      for (final key in ['client_id', 'client_secret', 'refresh_token']) {
        test('throws on missing $key', () {
          final info = Map.of(_testInfo)..remove(key);

          expect(
            () => UserCredentials.fromAuthorizedUserInfo(info),
            throwsA(
              isA<FormatException>().having(
                (e) => e.message,
                'message',
                contains("'$key'"),
              ),
            ),
          );
        });

        test('throws on empty $key', () {
          expect(
            () =>
                UserCredentials.fromAuthorizedUserInfo({..._testInfo, key: ''}),
            throwsFormatException,
          );
        });

        test('throws on non-string $key', () {
          expect(
            () => UserCredentials.fromAuthorizedUserInfo({
              ..._testInfo,
              key: 12345,
            }),
            throwsFormatException,
          );
        });
      }

      test('throws on non-string quota_project_id', () {
        expect(
          () => UserCredentials.fromAuthorizedUserInfo({
            ..._testInfo,
            'quota_project_id': 12345,
          }),
          throwsFormatException,
        );
      });

      test('throws on non-string universe_domain', () {
        expect(
          () => UserCredentials.fromAuthorizedUserInfo({
            ..._testInfo,
            'universe_domain': 12345,
          }),
          throwsFormatException,
        );
      });

      test('throws on non-default universe_domain', () {
        expect(
          () => UserCredentials.fromAuthorizedUserInfo({
            ..._testInfo,
            'universe_domain': 'custom.domain.com',
          }),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains("'custom.domain.com'"),
            ),
          ),
        );
      });
    });

    group('fromAuthorizedUserString', () {
      test('loads credentials from string', () async {
        final requests = <http.Request>[];
        final creds = UserCredentials.fromAuthorizedUserString(
          jsonEncode({..._testInfo, 'quota_project_id': 'quota-project'}),
          clientFactory: _recordingClientFactory(requests),
        );

        expect(creds.quotaProjectId, 'quota-project');

        await creds.accessToken();
        expect(
          requests.single.bodyFields,
          containsPair(
            'client_id',
            'test-client-id.apps.googleusercontent.com',
          ),
        );
      });

      test('throws on invalid JSON', () {
        expect(
          () => UserCredentials.fromAuthorizedUserString('not valid json'),
          throwsFormatException,
        );
      });

      test('throws on non-object JSON', () {
        expect(
          () => UserCredentials.fromAuthorizedUserString('[1, 2, 3]'),
          throwsFormatException,
        );
      });
    });

    group('fromAuthorizedUserFile', () {
      test('loads credentials from file', () async {
        // The format written by `gcloud auth application-default login`.
        const jsonString = '''
{
  "account": "",
  "client_id": "test-client-id.apps.googleusercontent.com",
  "client_secret": "test-client-secret",
  "quota_project_id": "test-project",
  "refresh_token": "test-refresh-token",
  "type": "authorized_user",
  "universe_domain": "googleapis.com"
}
''';
        final tempFilePath = await writeTempFile(
          'application_default_credentials.json',
          jsonString,
        );
        final requests = <http.Request>[];

        final creds = await UserCredentials.fromAuthorizedUserFile(
          tempFilePath,
          clientFactory: _recordingClientFactory(requests),
        );

        expect(creds.quotaProjectId, 'test-project');
        expect(creds.universeDomain, 'googleapis.com');

        await creds.accessToken();
        expect(requests.single.url, _defaultTokenUri);
        expect(
          requests.single.bodyFields,
          containsPair(
            'client_id',
            'test-client-id.apps.googleusercontent.com',
          ),
        );
      }, testOn: 'vm');

      test(
        'throws CredentialException when file cannot be read or on browser',
        () async {
          await expectLater(
            UserCredentials.fromAuthorizedUserFile(
              'non_existent_authorized_user.json',
            ),
            throwsA(isA<CredentialException>()),
          );
        },
      );
    });
  });
}
