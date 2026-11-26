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
import 'package:test/test.dart';

void main() {
  group('NoCredentials', () {
    test('equality and hashCode', () {
      // ignore: prefer_const_constructors
      final nonConst1 = NoCredentials();
      // ignore: prefer_const_constructors
      final nonConst2 = NoCredentials();
      const constInstance = NoCredentials();

      expect(nonConst1, equals(nonConst2));
      expect(nonConst1, equals(constInstance));
      expect(constInstance, isNot(equals(Object())));
      expect(nonConst1.hashCode, equals(constInstance.hashCode));
    });

    group('requestMetadata', () {
      test('without arguments', () async {
        const credentials = NoCredentials();

        expect(await credentials.requestMetadata(), isEmpty);
      });

      test('with uri and forceRefresh', () async {
        // `uri` and `forceRefresh` should be ignored.
        const credentials = NoCredentials();

        expect(
          await credentials.requestMetadata(
            uri: Uri.https('storage.googleapis.com', '/'),
            forceRefresh: true,
          ),
          isEmpty,
        );
      });
    });
  });
}
