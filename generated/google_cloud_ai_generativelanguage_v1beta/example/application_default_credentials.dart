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

import 'dart:io';

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  // Connects to the Generative Language API using Application Default
  // Connections (ADC).
  //
  // Before running this example, you need to authenticate with gcloud:
  //
  // ```
  // $ gcloud auth application-default login \
  //   --scopes=https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/generative-language.retriever
  // ```
  //
  // See https://cloud.google.com/docs/authentication/application-default-credentials
  final client = await auth.clientViaApplicationDefaultCredentials(
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/generative-language.retriever',
    ],
  );
  final service = GenerativeService(client: client);

  final request = GenerateContentRequest(
    model: 'models/gemini-2.5-flash',
    contents: [
      Content(parts: [Part(text: "Explain how AI works in a few words")]),
    ],
  );

  final result = await service.generateContent(request);
  final parts = result.candidates.firstOrNull?.content?.parts;
  if (parts == null) {
    print('<No textual response>');
  } else {
    print(parts.map((p) => p.text!).join(''));
  }

  service.close();
}
