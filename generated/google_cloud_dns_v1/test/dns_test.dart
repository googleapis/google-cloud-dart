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

@TestOn('vm')
@Tags(['google-cloud'])
library;

import 'package:google_cloud_dns_v1/dns.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() {
  group('dns', () {
    late managedZones managedZonesService;

    setUp(() async {
      final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      );
      managedZonesService = managedZones(client: client);
    });

    tearDown(() => managedZonesService.close());

    test('list managed zones', () async {
      final response = await managedZonesService.list(
        ManagedZones_ListRequest(project: projectId),
      );
      expect(response.managedZones, isA<List<ManagedZone>>());
    });
  });
}
