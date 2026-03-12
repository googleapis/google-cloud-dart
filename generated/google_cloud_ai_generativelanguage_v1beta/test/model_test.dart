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
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() async {
  late ModelService modelService;
  late http.Client client;

  group('model', tags: ['integration'], () {
    setUp(() async {
      Future<auth.AutoRefreshingAuthClient> authClient() async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: [
              'https://www.googleapis.com/auth/cloud-platform',
              'https://www.googleapis.com/auth/generative-language',
              'https://www.googleapis.com/auth/generative-language.retriever',
            ],
          );

      client = await authClient();
      modelService = ModelService(client: client);
    });

    tearDown(() => modelService.close());

    test('list', () async {
      final request = ListModelsRequest();

      final result = await modelService.listModels(request);
      expect(result.models.first.name, isNotEmpty);
    });
  });
}
