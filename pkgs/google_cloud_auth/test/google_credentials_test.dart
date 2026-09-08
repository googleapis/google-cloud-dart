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

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:test/test.dart';

final class _CustomCredentials extends GoogleCredentials {
  const _CustomCredentials({super.universeDomain});
}

void main() {
  group('GoogleCredentials', () {
    test('defaultUniverseDomain is googleapis.com', () {
      expect(GoogleCredentials.defaultUniverseDomain, 'googleapis.com');
    });

    test('defaults universeDomain to defaultUniverseDomain', () {
      const creds = _CustomCredentials();
      expect(creds.universeDomain, 'googleapis.com');
    });

    test('preserves custom universeDomain', () {
      const creds = _CustomCredentials(universeDomain: 'custom.domain.com');
      expect(creds.universeDomain, 'custom.domain.com');
    });
  });
}
