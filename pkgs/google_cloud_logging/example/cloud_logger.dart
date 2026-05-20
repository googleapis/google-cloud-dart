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

// #docregion cloud-logger
import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logging/logging.dart';

final _logger = Logger('my-service');

void main() {
  // Configure the standard logger with StructuredLogHandler.
  Logger.root.onRecord.listen(StructuredLogHandler().handleLogRecord);
  Logger.root.level = Level.ALL;

  _logger.info('Processing item.', {'itemId': 'A-987'});
  try {
    throw Exception('Failed to connect to DB');
  } catch (error, stack) {
    _logger.severe('Database connection failure - $error', error, stack);
  }
}

// #enddocregion cloud-logger
