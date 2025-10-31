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

import 'package:google_cloud_aiplatform_v1beta1/aiplatform.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  // Before running this example, you need to authenticate with gcloud:
  //
  // ```shell
  // $ gcloud auth application-default login
  // ```
  //
  // For more detailed instructions, complete these "Before you begin"
  // instructions:
  // https://cloud.google.com/vertex-ai/docs/start/client-libraries#before_you_begin
  const projectId = ''; // Enter your projectId here.
  if (projectId.isEmpty) {
    print('Please provide a project ID in the `projectId` constant.');
    return;
  }

  final client = await auth.clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );
  final service = PredictionService(client: client);

  final request = GenerateContentRequest(
    model:
        'projects/$projectId/locations/global/'
        'publishers/google/models/gemini-2.5-flash',
    contents: [
      Content(
        parts: [Part(text: "Explain how AI works in a few words")],
        role: "user",
      ),
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
