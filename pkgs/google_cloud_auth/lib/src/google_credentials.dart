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
/// - https://github.com/googleapis/google-auth-library-java/blob/main/oauth2_http/java/com/google/auth/oauth2/GoogleCredentials.java
/// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/credentials.py
library;

import 'credentials.dart';
import 'oauth2_credentials.dart';

/// Credentials used to authorize calls to
/// [Google APIs using OAuth 2.0](https://developers.google.com/identity/protocols/oauth2).
abstract base class GoogleCredentials extends OAuth2Credentials {
  const GoogleCredentials({
    super.universeDomain = Credentials.defaultUniverseDomain,
  });

  // TODO(https://github.com/googleapis/google-cloud-dart/issues/392):
  // implement a mechanism to insert `x-goog-user-project`.
}
