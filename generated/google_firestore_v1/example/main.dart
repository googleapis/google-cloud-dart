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

import 'package:google_cloud_firestore_v1/firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  // Connects to the Generative Language API using Application Default
  // Connections (ADC).
  //
  // Before running this example, you need to authenticate with gcloud:
  //
  // ```
  // $ gcloud auth application-default login
  // ```
  //
  // See https://cloud.google.com/docs/authentication/application-default-credentials
  final client = await auth.clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );
  final service = Firestore(client: client);

  final result = await service.createDocument(
    CreateDocumentRequest(
      parent: 'projects/<project id>/databases/<database id>/documents',
      collectionId: 'users',
      document: Document(fields: {'firstName': Value(stringValue: 'Brian')}),
    ),
  );
  print('Created document: ${result.name}');
  service.close();
}
