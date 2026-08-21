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

import 'package:google_cloud_compute_v1/compute.dart' hide Duration, Tags;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() {
  group('addresses', () {
    late Addresses addressesService;
    late RegionOperations operationsService;

    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> createClient() =>
          auth.clientViaApplicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/cloud-platform'],
          );

      addressesService = Addresses(client: await createClient());
      operationsService = RegionOperations(client: await createClient());
    });

    tearDown(() {
      addressesService.close();
      operationsService.close();
    });

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

      while (true) {
        final currentOp = await operationsService.get(
          GetRegionOperationRequest(
            project: projectId,
            region: region,
            operation: op.name!,
          ),
        );
        if (currentOp.status == Operation_Status.done) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }

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
