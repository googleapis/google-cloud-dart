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

import 'package:http/http.dart' as http;

import 'credential_exception.dart';
import 'google_credentials.dart';

/// Provides the Application Default Credential from the environment.
///
/// Always throws a [CredentialException] on the web, where environment
/// variables, local credential files, and the Compute Engine metadata server
/// are unavailable.
Future<GoogleCredentials> defaultCredentials({http.Client? client}) async {
  throw CredentialException(
    'Application Default Credentials are not supported on the web.',
  );
}
