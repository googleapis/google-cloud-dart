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

import 'package:google_cloud_tasks_v2/cloudtasks.dart';
import 'package:google_cloud_tasks_v2/testing.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

final class SubclassedFakeCloudTasks extends FakeCloudTasks {
  @override
  Future<Queue> getQueue(GetQueueRequest request) async =>
      Queue(name: request.name, state: Queue_State.running);
}

void main() {
  group('FakeCloudTasks', () {
    test('callback override works', () async {
      final fake = FakeCloudTasks(
        getTask: (request) async => Task(name: request.name),
      );
      final task = await fake.getTask(
        GetTaskRequest(name: 'projects/p/locations/l/queues/q/tasks/t'),
      );
      expect(task.name, 'projects/p/locations/l/queues/q/tasks/t');
    });

    test('subclass override works', () async {
      final fake = SubclassedFakeCloudTasks();
      final queue = await fake.getQueue(
        GetQueueRequest(name: 'projects/p/locations/l/queues/q'),
      );
      expect(queue.name, 'projects/p/locations/l/queues/q');
      expect(queue.state, Queue_State.running);
    });

    test('unimplemented method throws UnsupportedError', () async {
      final fake = FakeCloudTasks();
      expect(
        () => fake.getTask(GetTaskRequest(name: 'test')),
        throwsUnsupportedError,
      );
    });

    test('calling method after close throws StateError', () async {
      final fake = FakeCloudTasks(
        getTask: (request) async => Task(name: request.name),
      )..close();
      expect(
        () => fake.getTask(GetTaskRequest(name: 'test')),
        throwsStateError,
      );
    });
  });

  group('CloudTasks client', () {
    test('listQueues sends correct request and parses response', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/v2/projects/my-project/locations/us-central1/queues',
        );
        expect(request.url.queryParameters['pageSize'], '10');
        return http.Response(
          jsonEncode({
            'queues': [
              {
                'name':
                    'projects/my-project/locations/us-central1/queues/queue-1',
                'state': 'RUNNING',
              },
            ],
            'nextPageToken': 'token-123',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = CloudTasks(client: mock);
      final response = await client.listQueues(
        ListQueuesRequest(
          parent: 'projects/my-project/locations/us-central1',
          pageSize: 10,
        ),
      );

      expect(response.queues, hasLength(1));
      expect(
        response.queues.first.name,
        'projects/my-project/locations/us-central1/queues/queue-1',
      );
      expect(response.queues.first.state, Queue_State.running);
      expect(response.nextPageToken, 'token-123');
      client.close();
    });

    test('getQueue sends correct request and parses response', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/v2/projects/my-project/locations/us-central1/queues/queue-1',
        );
        return http.Response(
          jsonEncode({
            'name': 'projects/my-project/locations/us-central1/queues/queue-1',
            'state': 'PAUSED',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = CloudTasks(client: mock);
      final queue = await client.getQueue(
        GetQueueRequest(
          name: 'projects/my-project/locations/us-central1/queues/queue-1',
        ),
      );

      expect(
        queue.name,
        'projects/my-project/locations/us-central1/queues/queue-1',
      );
      expect(queue.state, Queue_State.paused);
      client.close();
    });

    test('createTask sends correct body and parses response', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/v2/projects/my-project/locations/us-central1/queues/queue-1/tasks',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['task'], isNotNull);
        final taskMap = body['task'] as Map<String, dynamic>;
        final httpReq = taskMap['httpRequest'] as Map<String, dynamic>;
        expect(httpReq['url'], 'https://example.com/handler');

        return http.Response(
          jsonEncode({
            'name':
                'projects/my-project/locations/us-central1/queues/queue-1/tasks/task-1',
            'httpRequest': {
              'url': 'https://example.com/handler',
              'httpMethod': 'POST',
            },
            'view': 'FULL',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = CloudTasks(client: mock);
      final task = await client.createTask(
        CreateTaskRequest(
          parent: 'projects/my-project/locations/us-central1/queues/queue-1',
          task: Task(
            httpRequest: HttpRequest(
              url: 'https://example.com/handler',
              httpMethod: HttpMethod.post,
            ),
          ),
        ),
      );

      expect(
        task.name,
        'projects/my-project/locations/us-central1/queues/queue-1/tasks/task-1',
      );
      expect(task.httpRequest?.url, 'https://example.com/handler');
      expect(task.httpRequest?.httpMethod, HttpMethod.post);
      client.close();
    });

    test('error response throws ServiceException subclass', () async {
      final mock = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 404,
              'message': 'Queue not found',
              'status': 'NOT_FOUND',
            },
          }),
          404,
          headers: {'content-type': 'application/json'},
        ),
      );

      final client = CloudTasks(client: mock);
      await expectLater(
        () => client.getQueue(GetQueueRequest(name: 'invalid-queue')),
        throwsA(isA<NotFoundException>()),
      );
      client.close();
    });
  });
}
