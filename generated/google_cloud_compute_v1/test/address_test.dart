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

import 'dart:math';

import 'package:google_cloud_compute_v1/compute.dart' hide Tags;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() {
  group('addresses', () {
    late Addresses addressesService;

    setUp(() async {
      final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      );
      addressesService = Addresses(client: client);
    });

    tearDown(() => addressesService.close());

    test('create and delete address', () async {
      final addressName = 'addr-${Random().nextInt(99999999)}';
      const region = 'us-central1';

      final op = await addressesService.insert(
        InsertAddressRequest(
          project: projectId,
          region: region,
          addressResource: Address(
            name: addressName,
            description: 'Test address created by automated test',
          ),
        ),
      );
      expect(op.name, isNotEmpty);

      addTearDown(
        () => addressesService.delete(
          DeleteAddressRequest(
            project: projectId,
            region: region,
            address: addressName,
          ),
        ),
      );

      final address = await addressesService.get(
        GetAddressRequest(
          project: projectId,
          region: region,
          address: addressName,
        ),
      );
      expect(address.name, addressName);
      expect(address.description, 'Test address created by automated test');
    });
  });
}
