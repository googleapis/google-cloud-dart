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

// Design based on:
// - https://github.com/googleapis/google-auth-library-java/blob/main/oauth2_http/java/com/google/auth/oauth2/GoogleCredentials.java
// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/credentials.py

/// Base class for credentials used to authenticate with Google APIs and
/// services.
abstract class GoogleCredentials {
  /// The default universe domain for Google Cloud services.
  static const defaultUniverseDomain = 'googleapis.com';

  /// The universe domain for the credentials.
  ///
  /// See [Universes, regions, and zones](https://docs.cloud.google.com/docs/overview#universes_regions_and_zones).
  final String universeDomain;

  /// Creates a [GoogleCredentials] instance with the specified
  /// [universeDomain].
  const GoogleCredentials({this.universeDomain = defaultUniverseDomain});
}
