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

import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_protobuf/protobuf.dart' hide Duration;
import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

void main() async {
  const projectId = ''; // Enter your projectId here.
  const location = 'us-central1'; // Enter your location here.
  if (projectId.isEmpty) {
    print('Please provide a project ID in the `projectId` constant.');
    return;
  }

  // Connects to the Cloud Tasks API using Application Default
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
  final tasksService = CloudTasks(client: client);

  const parent = 'projects/$projectId/locations/$location';
  const queueId = 'helloWorld';

  // Once deleted, a queue name cannot be reused for a week.
  final createdQueue = await tasksService.createQueue(
    CreateQueueRequest(
      parent: parent,
      queue: Queue(name: '$parent/queues/$queueId'),
    ),
  );

  await tasksService.createTask(
    CreateTaskRequest(
      parent: createdQueue.name,
      task: Task(
        httpRequest: HttpRequest(
          url: 'https://example.com/worker',
          httpMethod: HttpMethod.post,
          headers: {'Content-Type': 'application/json'},
          body: Uint8List.fromList(
            utf8.encode(jsonEncode({'message': 'Hello from Cloud Tasks!'})),
          ),
        ),
        scheduleTime: DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toTimestamp(),
      ),
    ),
  );
  tasksService.close();
}
