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
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final class FakeCredentials extends OAuth2Credentials {
  final accessTokenCalls = <({bool forceRefresh, http.Client? client})>[];

  @override
  Future<String> accessToken({
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    accessTokenCalls.add((forceRefresh: forceRefresh, client: client));
    return 'abc123';
  }
}

void main() {
  group('OAuth2Credentials', () {
    test('requestMetadata without forceRefresh or client', () async {
      final creds = FakeCredentials();
      expect(await creds.requestMetadata(), {
        'authorization': ['Bearer abc123'],
      });
      expect(creds.accessTokenCalls, [(forceRefresh: false, client: null)]);
    });

    test('requestMetadata forwards forceRefresh and client', () async {
      final client = MockClient(
        (_) async => throw StateError('unexpected HTTP request'),
      );
      final creds = FakeCredentials();
      expect(await creds.requestMetadata(forceRefresh: true, client: client), {
        'authorization': ['Bearer abc123'],
      });
      expect(creds.accessTokenCalls, [(forceRefresh: true, client: client)]);
    });
  });
}
