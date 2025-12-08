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

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/test_http_client.dart';

void main() async {
  late GenerativeService generativeService;
  late TestHttpClient testClient;

  group('embeddings', () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/generative-language.retriever',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      generativeService = GenerativeService(client: testClient);
    });

    tearDown(() => generativeService.close());
    test('embedContent', () async {
      await testClient.startTest(
        'google_cloud_ai_generativelanguage_v1beta',
        'embeddings_embed_content',
      );

      final request = EmbedContentRequest(
        model: 'models/gemini-embedding-001',
        content: Content(
          parts: [
            Part(text: 'What is the meaning of life?'),
            Part(text: 'What is the purpose of existence?'),
            Part(text: 'How do I bake a cake?'),
          ],
        ),
      );

      final response = await generativeService.embedContent(request);
      expect(response.embedding?.values, hasLength(greaterThan(1000)));

      await testClient.endTest();
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
