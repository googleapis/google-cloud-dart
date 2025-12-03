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
/// Test using the Showcase
/// [`Compliance` service](https://github.com/googleapis/gapic-showcase/blob/main/schema/google/showcase/v1beta1/compliance.proto).
library;

import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/insecure_proxy_http_client.dart';
import 'package:test_utils/matchers.dart';

import 'showcase_server.dart';

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

    // Conformance tests that can be verified by the server.
    // See https://github.com/googleapis/gapic-showcase/blob/main/server/services/compliance_suite.json
    group('server verified', () {
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
        test('Basic types, no optional fields', () async {
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
          );
          final response = await complianceService.repeatDataBody(
            RepeatRequest(
              name: 'Basic types, no optional fields',
              info: complianceData,
              serverVerify: true,
            ),
          );
          expect(response.request!.info, messageEquals(complianceData));
        });

        test(
          'Zero values for non-string fields - explicitly set values',
          () async {
            final complianceData = ComplianceData(
              fString: 'Hello',
              fInt32: 0,
              fSint32: 0,
              fSfixed32: 0,
              fUint32: 0,
              fFixed32: 0,
              fInt64: 0,
              fSint64: 0,
              fSfixed64: 0,
              fUint64: 0,
              fFixed64: 0,
              fDouble: 0,
              fFloat: 0,
              fBool: false,
              fKingdom: ComplianceData_LifeKingdom.lifeKingdomUnspecified,
              pString: 'Goodbye',
              pInt32: 0,
              pDouble: 0,
              pBool: false,
              pKingdom: ComplianceData_LifeKingdom.lifeKingdomUnspecified,
            );
            final response = await complianceService.repeatDataBody(
              RepeatRequest(
                name: 'Zero values for non-string fields',
                info: complianceData,
                serverVerify: true,
              ),
            );
            expect(response.request!.info, messageEquals(complianceData));
          },
        );

        test(
          'Zero values for non-string fields - non-optional implicitly set',
          () async {
            final complianceData = ComplianceData(
              fString: 'Hello',
              pString: 'Goodbye',
              pInt32: 0,
              pDouble: 0,
              pBool: false,
              pKingdom: ComplianceData_LifeKingdom.lifeKingdomUnspecified,
            );
            final response = await complianceService.repeatDataBody(
              RepeatRequest(
                name: 'Zero values for non-string fields',
                info: complianceData,
                serverVerify: true,
              ),
            );
            expect(response.request!.info, messageEquals(complianceData));
          },
        );

        // TODO(https://github.com/googleapis/google-cloud-dart/issues/92):
        // Add "Extreme values" test.

        test('Strings with spaces', () async {
          final complianceData = ComplianceData(fString: 'Hello there');
          final response = await complianceService.repeatDataBody(
            RepeatRequest(
              name: 'Strings with spaces',
              info: complianceData,
              serverVerify: true,
            ),
          );
          expect(response.request!.info, messageEquals(complianceData));
        });

        test('Strings with quotes', () async {
          final complianceData = ComplianceData(fString: 'Hello "You"');
          final response = await complianceService.repeatDataBody(
            RepeatRequest(
              name: 'Strings with quotes',
              info: complianceData,
              serverVerify: true,
            ),
          );
          expect(response.request!.info, messageEquals(complianceData));
        });

        test('Strings with percents', () async {
          final complianceData = ComplianceData(fString: 'Hello 100%');
          final response = await complianceService.repeatDataBody(
            RepeatRequest(
              name: 'Strings with percents',
              info: complianceData,
              serverVerify: true,
            ),
          );
          expect(response.request!.info, messageEquals(complianceData));
        });
      });

      group('Fully working conversions, resources', () {
        test('Strings with slashes and values that resemble subsequent '
            'resource templates', () async {
          final complianceData = ComplianceData(
            fString: 'first/hello/second/greetings',
            pBool: true,
            fChild: ComplianceDataChild(fString: 'second/zzz/bool/true'),
          );
          final response = await complianceService.repeatDataBody(
            RepeatRequest(
              name:
                  'Strings with slashes and values that resemble subsequent '
                  'resource templates',
              info: complianceData,
              serverVerify: true,
            ),
          );
          expect(response.request!.info, messageEquals(complianceData));
        });
      });
    });
  });
}
