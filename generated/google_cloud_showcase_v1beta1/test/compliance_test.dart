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

@TestOn('vm')
library;

import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/insecure_proxy_http_client.dart';
import 'package:test_utils/matchers.dart';

import 'showcase_server.dart';

// https://github.com/googleapis/gapic-showcase/blob/main/schema/google/showcase/v1beta1/compliance.proto

// https://github.com/googleapis/gapic-showcase/blob/main/server/services/compliance_suite.json
void main() async {
  late Compliance complianceService;
  late ShowcaseServer showcaseServer;
  group('compliance', () {
    setUpAll(() async {
      showcaseServer = await ShowcaseServer.start();
      complianceService = Compliance(
        client: InsecureProxyHttpClient(http.Client()),
      );
    });

    tearDownAll(() async {
      complianceService.close();
      await showcaseServer.stop();
    });

    group('Fully working conversions, no resources', () {
      test('Basic data types', () async {
        final complianceData = ComplianceData(
          fString: 'Hello',
          fInt32: -1,
          fSint32: -2,
          fSfixed32: -3,
          fUint32: 5,
          fFixed32: 7,
          fInt64: -11,
          fSint64: -13,
          fSfixed64: -17,
          fUint64: 19,
          fFixed64: 23,
          fDouble: -29e4,
          fFloat: -31,
          fBool: true,
          fKingdom: ComplianceData_LifeKingdom.animalia,
          fChild: ComplianceDataChild(fString: 'second/bool/salutation'),
          pString: 'Goodbye',
          pInt32: -37,
          pDouble: -41.43,
          pBool: true,
          pKingdom: ComplianceData_LifeKingdom.plantae,
        );
        final response = await complianceService.repeatDataBody(
          RepeatRequest(
            name: 'Basic data types',
            info: complianceData,
            serverVerify: true,
          ),
        );
        expect(response.request!.info, messageEquals(complianceData));
      });
    });
  });
}
