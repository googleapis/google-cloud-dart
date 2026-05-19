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
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('CloudLogger.printLogger()', () {
    test('string message', () async {
      const cloudLogger = CloudLogger.printLogger();
      final log = Logger('CloudLogger');

      await expectLater(() async {
        log.onRecord.listen(cloudLogger.handleLog);
        log.info('hello');
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }, prints('INFO: hello\n'));
    });

    test('object message', () async {
      const cloudLogger = CloudLogger.printLogger();
      final log = Logger('CloudLogger');

      await expectLater(() async {
        log.onRecord.listen(cloudLogger.handleLog);
        log.info([1, 2, 3]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }, prints('INFO: [1, 2, 3]\n'));
    });

    test('with error', () async {
      const cloudLogger = CloudLogger.printLogger();
      final log = Logger('CloudLogger');

      await expectLater(() async {
        log.onRecord.listen(cloudLogger.handleLog);
        log.info('hello', [1, 2, 3]);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }, prints('INFO: hello\nPayload: {error: [1, 2, 3]}\n'));
    });

    test('with stacktrace', testOn: '!browser', () async {
      const cloudLogger = CloudLogger.printLogger();
      final log = Logger('CloudLogger');
      final caught = catchingFunction();

      await expectLater(
        () async {
          log.onRecord.listen(cloudLogger.handleLog);
          log.info('hello', null, caught.stackTrace);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        prints(
          allOf(startsWith('INFO: hello\n'), contains('test/test_utils.dart')),
        ),
      );
    });
  });

  group('CloudLogger.structuredLogger()', () {
    test('string message', () async {
      const cloudLogger = CloudLogger.structuredLogger();
      final log = Logger('CloudLogger');

      await expectLater(
        () async {
          log.onRecord.listen(cloudLogger.handleLog);
          log.info('hello');
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {'message': 'hello', 'severity': 'INFO'},
          ),
        ),
      );
    });

    test('object message', () async {
      const cloudLogger = CloudLogger.structuredLogger();
      final log = Logger('CloudLogger');

      await expectLater(
        () async {
          log.onRecord.listen(cloudLogger.handleLog);
          log.info([1, 2, 3]);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'message': [1, 2, 3],
              'severity': 'INFO',
            },
          ),
        ),
      );
    });

    test('with error', () async {
      const cloudLogger = CloudLogger.structuredLogger();
      final log = Logger('CloudLogger');

      await expectLater(
        () async {
          log.onRecord.listen(cloudLogger.handleLog);
          log.info('hello', [1, 2, 3]);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'message': 'hello',
              'severity': 'INFO',
              'error': [1, 2, 3],
            },
          ),
        ),
      );
    });

    test('with stacktrace', testOn: '!browser', () async {
      const cloudLogger = CloudLogger.structuredLogger();
      final log = Logger('CloudLogger');
      final caught = catchingFunction();

      await expectLater(
        () async {
          log.onRecord.listen(cloudLogger.handleLog);
          log.info('hello', null, caught.stackTrace);
          await Future<void>.delayed(const Duration(milliseconds: 10));
        },
        prints(
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'message': 'hello',
              'severity': 'INFO',
              'stack_trace': contains('logging_test.dart'),
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
