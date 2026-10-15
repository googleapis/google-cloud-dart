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

/// Tests [TokenVerifier] against the RSA JSON Web Signature test vectors from
/// [Project Wycheproof](https://github.com/C2SP/wycheproof).
library;

import 'dart:convert';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../test_utils.dart';
import 'wycheproof_vectors.dart';

void main() {
  final vectors =
      jsonDecode(wycheproofJsonWebSignatureVectors) as Map<String, Object?>;
  final groups = (vectors['testGroups']! as List).cast<Map<String, Object?>>();

  List<Map<String, Object?>> testsIn(Map<String, Object?> group) =>
      (group['tests'] as List).cast<Map<String, Object?>>();

  group(
    'Wycheproof JSON Web Signature',
    () {
      var testCount = 0;
      for (final group in groups) {
        final verifier = TokenVerifier(
          jwksUri: Uri.https('example.com', '/certs'),
          clientFactory: () => MockClient(
            (_) async => http.Response(
              jsonEncode({
                'keys': [group['public']],
              }),
              200,
            ),
          ),
        );

        for (final vector in testsIn(group)) {
          testCount++;
          final tcId = vector['tcId']! as int;
          // `verify` throws for every vector, even the valid ones because
          // Wycheproof tests JWS signatures, not JWTs, so its payloads (such
          // as "foo" or random bytes) are never JWT claims sets.
          //
          // But `verify` only parses the claims after verifying the signature,
          // so the reason it throws shows whether the signature was accepted:
          // - A valid vector must be rejected because its payload is not a JWT
          //   claims set, i.e. only after its signature was accepted.
          // - An invalid vector must be rejected for any other reason, such as
          //   a malformed token, an unusable key or a bad signature, before
          //   its claims are parsed.
          final isValid = vector['result'] == 'valid';
          test('tcId $tcId: ${vector['comment']}', () async {
            await expectLater(
              verifier.verify(vector['jws']! as String),
              throwsA(
                isA<TokenVerificationException>().having(
                  (e) => e.message,
                  'message',
                  isValid
                      ? contains('not a JWT claims set')
                      : isNot(contains('not a JWT claims set')),
                ),
              ),
            );
          });
        }
      }
      assert(testCount > 200, 'fewer tests than expected: $testCount');
    },
    skip: canUseWebCrypto
        ? null
        : 'Requires Dart 3.13 or later for native assets',
  );
}
