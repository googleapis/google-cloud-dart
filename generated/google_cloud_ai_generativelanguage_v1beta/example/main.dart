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

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';

void main() async {
  // Pass your API key here if the GEMINI_API_KEY environment variable is not set.
  // See https://ai.google.dev/gemini-api/docs/api-key
  final service = GenerativeService.fromApiKey();

  final request = GenerateContentRequest(
    model: 'models/gemini-2.5-flash',
    contents: [
      Content(parts: [Part(text: "Explain how AI works in a few words")]),
    ],
  );

  final result = await service.generateContent(request);
  final parts = result.candidates.first.content?.parts;
  if (parts == null) {
    print('<No textual response>');
  } else {
    print(parts.map((p) => p.text!).join(''));
  }

  service.close();
}
