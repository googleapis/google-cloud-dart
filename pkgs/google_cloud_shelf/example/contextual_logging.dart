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

// ignore_for_file: cascade_invocations

// #docregion contextual-logging
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:google_cloud_shelf/google_cloud_shelf.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

final _logger = Logger('user-service');

Future<void> main() async {
  // Configure standard logging with StructuredLogHandler globally.
  Logger.root.onRecord.listen(StructuredLogHandler().handleLogRecord);
  Logger.root.level = Level.ALL;

  final handler = const Pipeline()
      .addMiddleware(createLoggingMiddleware(projectId: 'my-gcp-project-id'))
      .addHandler(_userHandler);

  await serveHandler(handler);
}

Response _userHandler(Request request) {
  _logger.info('Fetching user profile from database.');

  // A simple print statement is also captured as an INFO log with trace
  // correlation
  print('This print statement is correlated too!');

  // Business logic here...
  _logger.log(Level.INFO, 'User successfully retrieved.', {
    'userId': 'user_123',
  });

  return Response.ok('User Profile');
}

// #enddocregion contextual-logging
