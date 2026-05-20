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

import 'dart:async';
import 'dart:io';
import 'package:google_cloud_logging/google_cloud_logging.dart';

void main() async {
  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.parse(portStr);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Server listening on port $port');

  await for (final request in server) {
    final traceparent =
        request.headers.value('traceparent') ??
        request.headers.value('x-cloud-trace-context');

    runZoned(() {
      const logger = CloudLogger.structuredLogger();
      logger.info('E2E_TEST_LOG_MESSAGE');

      final response = request.response;
      response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write('{"traceparent": "$traceparent"}')
        ..close();
    }, zoneValues: {'traceparent': ?traceparent});
  }
}
