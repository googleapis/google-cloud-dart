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
/// - https://github.com/googleapis/google-cloud-java/blob/main/google-auth-library-java/credentials/java/com/google/auth/ApiKeyCredentials.java
/// - https://github.com/googleapis/google-cloud-python/blob/main/packages/google-auth/google/auth/api_key.py
library;

import 'credentials.dart';

/// The header used to send an API key.
///
/// See [Use API keys to access APIs](https://docs.cloud.google.com/docs/authentication/api-keys-use).
const _apiKeyHeader = 'x-goog-api-key';

/// Credentials used to authorize calls to Google APIs using an
/// [API key](https://docs.cloud.google.com/docs/authentication/api-keys).
///
/// API keys associate requests with a Google Cloud project for billing and
/// quota purposes. Only some Google APIs accept API keys.
///
/// API keys are not OAuth 2.0 credentials, so these credentials do not provide
/// an access token.
final class ApiKeyCredentials extends Credentials {
  final String _apiKey;

  /// Creates [ApiKeyCredentials] that authorize requests using [apiKey].
  ///
  /// Throws an [ArgumentError] if [apiKey] is empty.
  ApiKeyCredentials(String apiKey) : _apiKey = apiKey {
    if (apiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'Must not be empty');
    }
  }

  /// Request metadata that authorizes a request using the API key.
  ///
  /// The returned metadata contains the API key in the `x-goog-api-key`
  /// header. API keys are never refreshed, so [forceRefresh] has no effect.
  @override
  Future<Map<String, List<String>>> requestMetadata({
    Uri? uri,
    bool forceRefresh = false,
  }) async => {
    _apiKeyHeader: [_apiKey],
  };
}
