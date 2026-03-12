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
@Tags(['google-cloud'])
library;

import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() async {
  late PredictionService predictionService;
  late http.Client client;

  group('generative', tags: ['google-cloud'], () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/cloud-platform'],
          );

      client = await authClient();
      predictionService = PredictionService(client: client);
    });

    tearDown(() => predictionService.close());
    test('streamed', () async {
      final request = GenerateContentRequest(
        model:
            'projects/$projectId/locations/us-central1/'
            'publishers/google/models/gemini-2.5-flash',
        contents: [
          Content(
            parts: [Part(text: 'Explain how AI works in extensive detail')],
            role: 'user',
          ),
        ],
      );

      final results = predictionService.streamGenerateContent(request);
      final text = StringBuffer();
      await for (final result in results) {
        final parts = result.candidates.firstOrNull?.content?.parts;
        if (parts != null) {
          for (final p in parts) {
            text.write(p.text ?? '');
          }
        }
      }
      expect(text.toString(), hasLength(greaterThan(1000)));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
