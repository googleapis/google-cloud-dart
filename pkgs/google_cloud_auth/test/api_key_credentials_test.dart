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
  group('ApiKeyCredentials', () {
    test('throws on empty API key', () {
      expect(
        () => ApiKeyCredentials(''),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'apiKey')),
      );
    });

    group('requestMetadata', () {
      test('without arguments', () async {
        final credentials = ApiKeyCredentials('test-api-key');

        expect(await credentials.requestMetadata(), {
          'x-goog-api-key': ['test-api-key'],
        });
      });

      test('with uri and forceRefresh', () async {
        // `uri` and `forceRefresh` should be ignored.
        final credentials = ApiKeyCredentials('test-api-key');

        expect(
          await credentials.requestMetadata(
            uri: Uri.https('storage.googleapis.com', '/'),
            forceRefresh: true,
          ),
          {
            'x-goog-api-key': ['test-api-key'],
          },
        );
      });

      test('API rejects an invalid API key', tags: ['google-cloud'], () async {
        // A successful request requires a valid API key.
        //
        // Instead, verify that the API finds the API key in the request
        // metadata, failing because the key is invalid (400
        // `API_KEY_INVALID`) rather than because the request is
        // unauthenticated (403 `ACCESS_DENIED`).
        final credentials = ApiKeyCredentials('invalid-api-key');
        final metadata = await credentials.requestMetadata();

        final client = http.Client();
        addTearDown(client.close);

        final response = await client.get(
          Uri.https('generativelanguage.googleapis.com', '/v1/models'),
          headers: {
            for (var MapEntry(key: key, value: values) in metadata.entries)
              key: values.join(', '),
          },
        );
        expect(response.statusCode, 400);
        expect(response.body, contains('API_KEY_INVALID'));
      });
    });
  });
}
