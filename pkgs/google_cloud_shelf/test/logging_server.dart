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

/// A simple server to validate the logging middleware.
library;

import 'package:google_cloud/google_cloud.dart';
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';

void main() async {
  final projectId = await computeProjectId();

  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware(projectId: projectId))
      .addHandler((Request request) {
        if (request.url.path == 'print') {
          final msg =
              request.requestedUri.queryParameters['msg'] ?? 'default print';
          print(msg);
          return Response.ok('Printed: $msg');
        }
        return Response.ok('Hello World!');
      });

  await serveHandler(handler);
}
