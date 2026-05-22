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

import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('CloudLogger.structuredLogger()', () {
    const logger = CloudLogger.structuredLogger();

    test('basic log', () {
      expect(
        () => logger.info('hello'),
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {'message': 'hello', 'severity': 'INFO'},
          ),
        ),
      );
    });

    test('log with stack trace', testOn: '!browser', () {
      expect(
        () {
          final caught = catchingFunction();
          logger.error(
            caught.error.toString(),
            stackTrace: caught.stackTrace,
          );
        },
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'message': 'Invalid argument(s): sample',
              'severity': 'ERROR',
              'stack_trace': contains('logger_test.dart'),
              'logging.googleapis.com/sourceLocation': {
                'file': endsWith('test_utils.dart'),
                'function': endsWith('throwingFunction'),
                'line': isA<String>().having(
                  int.parse,
                  'parsed line',
                  greaterThan(1),
                ),
              },
            },
          ),
        ),
      );
    });
  });
}
