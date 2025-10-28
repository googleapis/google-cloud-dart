// Copyright 2025 Google LLC
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

/// Web-specific implementations.
library;

import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

/// The Dart version to use in "x-goog-api-client" headers.
///
/// The format is either `major.minor.patch` or the special value `0`, which
/// indicates that the version is unknown.
const String clientDartVersion = '0';

/// A [http.Client] authenticated using an API key.
///
/// If `apiKey` is not `null` then that API key is used. If `apiKey` is `null`,
/// then the first set environment variables in `envKeys`
/// (e.g. `['GOOGLE_API_KEY', 'GEMINI_API_KEY']`) is used.
///
/// On the web, `apiKey` must be provided and `envKeys` is ignored.
///
/// Throws [ArgumentError] `apiKey` is `null` and no API key is found in the
/// given environment variables.
http.Client httpClientFromApiKey(String? apiKey, List<String> envKeys) {
  if (apiKey == null) {
    throw ArgumentError('apiKey must be set to an API key');
  }
  return auth.clientViaApiKey(apiKey);
}
