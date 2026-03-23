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

@Tags(['google-cloud'])
library;

import 'dart:async';
import 'dart:io';

import 'package:google_cloud/constants.dart' as cloud_constants;
import 'package:google_cloud/google_cloud.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

void main() {
  group('E2E Validation', () {
    late HttpServer server;
    late Uri rootUri;

    setUpAll(() async {
      final projectId = await computeProjectId();

      FutureOr<Response> handler(Request request) {
        switch (request.url.path) {
          case 'project_id':
            return Response.ok(projectId);
          case 'service_account':
            return Future.microtask(() async {
              final email = await serviceAccountEmailFromMetadataServer();
              return Response.ok(email);
            });
          case 'logging':
            currentLogger.info('Hello from google_cloud e2e test');
            return Response.ok('Logged');
          case 'metadata':
            return Future.microtask(() async {
              try {
                final client = HttpClient();
                final req = await client.getUrl(gceMetadataUrl(''));
                final res = await req.close();
                await res.drain<void>();
                return Response.ok('Metadata OK');
              } catch (e) {
                return Response.internalServerError(
                  body: 'Metadata failed: $e',
                );
              }
            });
          case 'bad_request':
            throw BadRequestException(400, 'Bad Request Intentional');
          case 'server_error':
            throw ArgumentError('Server Error Intentional');
          default:
            return Response.notFound('Not found');
        }
      }

      final pipeline = const Pipeline()
          .addMiddleware(createLoggingMiddleware(projectId: projectId))
          .addHandler(handler);

      server = await serve(pipeline, 'localhost', 0);
      rootUri = Uri.parse('http://localhost:${server.port}');
    });

    tearDownAll(() async {
      await server.close();
    });

    test('get project_id', () async {
      final response = await http.get(rootUri.replace(path: '/project_id'));
      expect(response.statusCode, 200);
      expect(response.body, isNotEmpty);
      print('Project ID: ${response.body}');
    });

    test('get service_account', () async {
      final response = await http.get(
        rootUri.replace(path: '/service_account'),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('@'));
      print('Service Account: ${response.body}');
    });

    test('logging', () async {
      const startBit = 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6';
      final response = await http.get(
        rootUri.replace(path: '/logging'),
        headers: {
          cloud_constants.cloudTraceContextHeader: '$startBit/12345;o=1',
        },
      );
      expect(response.statusCode, 200);
      expect(response.body, 'Logged');
    });

    test('metadata checks', () async {
      final response = await http.get(rootUri.replace(path: '/metadata'));
      expect(response.statusCode, 200);
      expect(response.body, 'Metadata OK');
    });

    test('bad request', () async {
      final response = await http.get(rootUri.replace(path: '/bad_request'));
      expect(response.statusCode, 400);
      expect(response.body, contains('Bad Request Intentional'));
    });

    test('server error', () async {
      final response = await http.get(rootUri.replace(path: '/server_error'));
      expect(response.statusCode, 500);
      print('Server Error Body: ${response.body}');
    });
  });
}
