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
library model_test;

import 'package:test/test.dart';

import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

void main() async {
  late ModelService modelService;
  late TestHttpClient testClient;

  group('model', () {
    setUp(() async {
      final authClient = () async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/generative-language.retriever',
            ],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      modelService = ModelService(client: testClient);
    });

    tearDown(() => modelService.close());

    test('list', () async {
      await testClient.startTest(
        'google_cloud_ai_generativelanguage_v1beta',
        'model_list',
      );

      final request = ListModelsRequest(
        parent: 'projects/$projectId/locations/global',
      );

      final result = await modelService.listModels(request);
      expect(result.models.first.name, isNotEmpty);

      await testClient.endTest();
    });
  });
}
