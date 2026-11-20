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
/// - https://github.com/googleapis/google-cloud-java/blob/main/google-auth-library-java/oauth2_http/java/com/google/auth/oauth2/UserCredentials.java
/// - https://github.com/googleapis/google-cloud-python/blob/main/packages/google-auth/google/oauth2/credentials.py
library;

import 'package:http/http.dart' as http;

import 'access_token.dart';
import 'credential_exception.dart';
import 'credentials.dart';
import 'google_credentials.dart';
import 'json_utils.dart';
import 'platform_web.dart' if (dart.library.io) 'platform_io.dart';

const _infoDescription = 'authorized user info';

final _tokenUri = Uri.https('oauth2.googleapis.com', '/token');

/// Credentials for a Google user account, authorized using OAuth 2.0.
///
/// This is the credential type associated with:
///
/// ```shell
/// gcloud auth application-default login
/// ```
final class UserCredentials extends GoogleCredentials {
  /// The quota project ID associated with the credentials, if available.
  final String? quotaProjectId;

  final String _clientId;
  final String _clientSecret;
  final String _refreshToken;
  final _accessTokenCache = AccessTokenCache();

  UserCredentials._({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
    this.quotaProjectId,
  }) : _clientId = clientId,
       _clientSecret = clientSecret,
       _refreshToken = refreshToken;

  /// Creates [UserCredentials] from parsed authorized user JSON.
  ///
  /// [info] must contain `client_id`, `client_secret`, and `refresh_token`
  /// fields, and may contain a `quota_project_id` field. If present, the
  /// `type` field must be `authorized_user` and the `universe_domain` field
  /// must be `googleapis.com`. Other fields, such as `token_uri`, are ignored.
  ///
  /// Throws a [FormatException] if [info] is not valid.
  factory UserCredentials.fromAuthorizedUserInfo(Map<String, dynamic> info) {
    if (info['type'] case final type? when type != 'authorized_user') {
      throw const FormatException(
        "The value of 'type' must be 'authorized_user' or omitted.",
      );
    }

    final universeDomain = optionalString(info, 'universe_domain');
    if (universeDomain != null &&
        universeDomain.isNotEmpty &&
        universeDomain != Credentials.defaultUniverseDomain) {
      throw FormatException(
        'User credentials are only supported in the '
        "'${Credentials.defaultUniverseDomain}' universe domain, but "
        "the universe domain is '$universeDomain'.",
      );
    }

    return UserCredentials._(
      clientId: requiredString(info, 'client_id', _infoDescription),
      clientSecret: requiredString(info, 'client_secret', _infoDescription),
      refreshToken: requiredString(info, 'refresh_token', _infoDescription),
      quotaProjectId: optionalString(info, 'quota_project_id'),
    );
  }

  /// Creates [UserCredentials] from an authorized user JSON string.
  ///
  /// See [UserCredentials.fromAuthorizedUserInfo] for the supported fields.
  ///
  /// Throws a [FormatException] if [jsonString] is not valid.
  factory UserCredentials.fromAuthorizedUserString(String jsonString) =>
      .fromAuthorizedUserInfo(decodeJsonObject(jsonString));

  /// Creates [UserCredentials] from an authorized user JSON file at [path],
  /// such as the one created by `gcloud auth application-default login`.
  ///
  /// See [UserCredentials.fromAuthorizedUserInfo] for the supported fields.
  ///
  /// Throws a [CredentialException] if reading [path] fails or when running on
  /// the web, and a [FormatException] if the file contents are not valid.
  static Future<UserCredentials> fromAuthorizedUserFile(String path) async =>
      .fromAuthorizedUserString(await readCredentialFileAsString(path));

  @override
  Future<String> accessToken({
    required http.Client client,
    bool forceRefresh = false,
  }) => _accessTokenCache.accessToken(
    () => fetchAccessToken(
      source: _tokenUri.toString(),
      send: () => client.post(
        _tokenUri,
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken,
        },
      ),
    ),
    forceRefresh: forceRefresh,
  );
}
