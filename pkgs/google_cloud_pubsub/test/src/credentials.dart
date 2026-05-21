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
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// Exception thrown when security credentials cannot be obtained or
/// refreshed.
final class CredentialsException implements Exception {
  /// A message describing the credential failure.
  final String message;

  /// The underlying exception or error that caused this failure, if any.
  final Object? innerException;

  /// Creates a [CredentialsException] with the specified [message] and optional
  /// [innerException].
  CredentialsException(this.message, [this.innerException]);

  @override
  String toString() {
    final cause = innerException != null ? ' (caused by: $innerException)' : '';
    return 'CredentialsException: $message$cause';
  }
}

/// Resolves and returns a function that returns a valid access token,
/// refreshing it if it has expired or is about to expire within 5 minutes.
///
/// Preconditions:
/// * [scopes] must not be empty.
///
/// Throws a [CredentialsException] if security credentials cannot be
/// obtained or refreshed.
Future<String> Function() applicationDefaultCredentials({
  required List<String> scopes,
  http.Client? httpClient,
}) {
  if (scopes.isEmpty) {
    throw ArgumentError.value(scopes, 'scopes', 'Must not be empty.');
  }

  Future<auth.AccessCredentials>? credentialsFuture;

  Future<auth.AccessCredentials> obtainFromFile(
    File file,
    http.Client client,
  ) async {
    final jsonContent = await file.readAsString();
    final credentialsMap = json.decode(jsonContent) as Map<String, dynamic>;

    final type = credentialsMap['type'] as String?;
    if (type == 'authorized_user') {
      final clientIdString = credentialsMap['client_id'] as String;
      final clientSecret = credentialsMap['client_secret'] as String?;
      final refreshToken = credentialsMap['refresh_token'] as String?;
      final clientId = auth.ClientId(clientIdString, clientSecret);

      return await auth.refreshCredentials(
        clientId,
        auth.AccessCredentials(
          auth.AccessToken('Bearer', '', DateTime(0).toUtc()),
          refreshToken,
          scopes,
        ),
        client,
      );
    }

    if (type == 'service_account') {
      final sac = auth.ServiceAccountCredentials.fromJson(credentialsMap);
      return await auth.obtainAccessCredentialsViaServiceAccount(
        sac,
        scopes,
        client,
      );
    }

    throw CredentialsException('Unsupported credential type: $type');
  }

  Future<auth.AccessCredentials> obtainCredentials() async {
    final client = httpClient ?? http.Client();
    try {
      final credsEnv = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
      if (credsEnv != null && credsEnv.isNotEmpty) {
        return await obtainFromFile(File(credsEnv), client);
      }

      File credFile;
      if (Platform.isWindows) {
        final appData = Platform.environment['APPDATA'];
        if (appData == null) {
          throw StateError(
            'The expected environment variable APPDATA must be set.',
          );
        }
        credFile = File.fromUri(
          Uri.directory(
            appData,
          ).resolve('gcloud/application_default_credentials.json'),
        );
      } else {
        final homeVar = Platform.environment['HOME'];
        if (homeVar == null) {
          throw StateError(
            'The expected environment variable HOME must be set.',
          );
        }
        credFile = File.fromUri(
          Uri.directory(
            homeVar,
          ).resolve('.config/gcloud/application_default_credentials.json'),
        );
      }

      if (await credFile.exists()) {
        return await obtainFromFile(credFile, client);
      }

      return await auth.obtainAccessCredentialsViaMetadataServer(client);
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  return () async {
    try {
      var future = credentialsFuture ??= obtainCredentials();
      var creds = await future;

      final threshold = DateTime.now().toUtc().add(const Duration(minutes: 5));
      if (creds.accessToken.expiry.isBefore(threshold)) {
        future = credentialsFuture = obtainCredentials();
        creds = await future;
      }

      return creds.accessToken.data;
    } on Exception catch (e) {
      credentialsFuture = null;
      throw CredentialsException('Failed to obtain or refresh access token', e);
    }
  };
}
