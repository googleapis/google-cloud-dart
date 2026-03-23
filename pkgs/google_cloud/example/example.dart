// Copyright 2021 Google LLC
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

import 'package:google_cloud/google_cloud.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';

Future<void> main() async {
  final server = await _Server.create();

  try {
    await serveHandler(server.handler);
  } finally {
    server.close();
  }
}

class _Server {
  _Server._({
    required this.projectId,
    required this.client,
    required this.hosted,
  });

  static Future<_Server> create() async {
    final projectId = await computeProjectId();

    var hosted = true;
    try {
      await projectIdFromMetadataServer();
    } on MetadataServerException catch (_) {
      hosted = false;
    }

    print('Current GCP project id: $projectId');

    final authClient = await clientViaApplicationDefaultCredentials(
      scopes: [FirestoreApi.datastoreScope],
    );

    return _Server._(projectId: projectId, client: authClient, hosted: hosted);
  }

  final String projectId;
  final AutoRefreshingAuthClient client;
  final bool hosted;

  late final FirestoreApi api = FirestoreApi(client);
  late final handler = createLoggingMiddleware(
    projectId: hosted ? projectId : null,
  ).addMiddleware(_onlyGetRootMiddleware).addHandler(_incrementHandler);

  Future<Response> _incrementHandler(Request request) async {
    final result = await api.projects.databases.documents.commit(
      _incrementRequest(projectId),
      'projects/$projectId/databases/(default)',
    );

    return Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {'content-type': 'application/json'},
    );
  }

  void close() {
    client.close();
  }
}

/// For `GET` `request` objects to [handler], otherwise sends a 404.
Handler _onlyGetRootMiddleware(Handler handler) => (Request request) async {
  if (request.method == 'GET' && request.url.pathSegments.isEmpty) {
    return await handler(request);
  }

  throw BadRequestException(404, 'Not found');
};

CommitRequest _incrementRequest(String projectId) => CommitRequest(
  writes: [
    Write(
      transform: DocumentTransform(
        document:
            'projects/$projectId/databases/(default)/documents/settings/count',
        fieldTransforms: [
          FieldTransform(
            fieldPath: 'count',
            increment: Value(integerValue: '1'),
          ),
        ],
      ),
    ),
  ],
);
