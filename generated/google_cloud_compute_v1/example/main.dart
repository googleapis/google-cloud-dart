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

import 'package:google_cloud_compute_v1/compute.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  const projectId = ''; // Enter your projectId here.
  if (projectId.isEmpty) {
    print('Please provide a project ID in the `projectId` constant.');
    return;
  }

  // Connects to the Google Compute Engine API using Application Default
  // Credentials (ADC).
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
  final zonesService = Zones(client: client);

  final result = await zonesService.list(ListZonesRequest(project: projectId));
  print('Zones:');
  for (final zone in result.items) {
    print(' - ${zone.name}: ${zone.status}');
  }

  zonesService.close();
}
