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

import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() {
  group('queues', () {
    late CloudTasks tasksService;

    setUp(() async {
      final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: ['https://www.googleapis.com/auth/cloud-platform'],
      );
      tasksService = CloudTasks(client: client);
    });

    tearDown(() => tasksService.close());

    test('listQueues', () async {
      final response = await tasksService.listQueues(
        ListQueuesRequest(parent: 'projects/$projectId/locations/us-central1'),
      );
      expect(response.queues, isNotNull);
    });
  });
}
