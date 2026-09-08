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

@TestOn('vm')
@Tags(['google-cloud'])
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_protobuf/protobuf.dart' hide Duration;
import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

const location = 'us-central1';

void main() {
  group('tasks', () {
    late CloudTasks tasksService;
    late String queueName;

    setUp(() async {
      final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      );
      tasksService = CloudTasks(client: client);
      final parent = 'projects/$projectId/locations/$location';
      final queueId = 'queue-${Random().nextInt(999999999)}';
      queueName = '$parent/queues/$queueId';

      await tasksService.createQueue(
        CreateQueueRequest(
          parent: parent,
          queue: Queue(name: queueName),
        ),
      );
    });

    tearDown(() async {
      await tasksService.deleteQueue(DeleteQueueRequest(name: queueName));
      tasksService.close();
    });

    test('create', () async {
      final createdTask = await tasksService.createTask(
        CreateTaskRequest(
          parent: queueName,
          task: Task(
            httpRequest: HttpRequest(
              url: 'https://example.com/worker',
              httpMethod: HttpMethod.post,
              headers: {'Content-Type': 'application/json'},
              body: Uint8List.fromList(
                utf8.encode(jsonEncode({'message': 'Hello from test'})),
              ),
            ),
            scheduleTime: DateTime.now()
                .toUtc()
                .add(const Duration(hours: 1))
                .toTimestamp(),
          ),
        ),
      );
      expect(createdTask.name, startsWith('$queueName/tasks/'));
    });
  });
}
