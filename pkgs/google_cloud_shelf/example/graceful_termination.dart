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

// #docregion graceful-termination
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware())
      .addHandler((_) => Response.ok('Custom setup'));

  // Start the server manually
  final server = await shelf_io.serve(handler, '0.0.0.0', 8080);

  // Await a shutdown signal (SIGTERM or SIGINT)
  await waitForTerminate();

  // Gracefully shut down the server
  await server.close();
}

// #enddocregion graceful-termination
