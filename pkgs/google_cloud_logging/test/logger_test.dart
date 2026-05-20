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

import 'dart:async';
import 'dart:convert';

import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('CloudLogger.printLogger()', () {
    const logger = CloudLogger.printLogger();

    test('log with default severity', () {
      expect(
        () => logger.log('hello', LogSeverity.$default),
        prints('hello\n'),
      );
    });

    test('log with explicit severity', () {
      expect(
        () => logger.log('hello', LogSeverity.error),
        prints('ERROR: hello\n'),
      );
    });

    test('log with payload', () {
      expect(
        () => logger.log('hello', LogSeverity.error, payload: {'foo': 'bar'}),
        prints('''
ERROR: hello
Payload: {foo: bar}
'''),
      );
    });

    test('convenience methods', () {
      expect(() => logger.debug('hello'), prints('DEBUG: hello\n'));
      expect(() => logger.info('hello'), prints('INFO: hello\n'));
      expect(() => logger.notice('hello'), prints('NOTICE: hello\n'));
      expect(() => logger.warning('hello'), prints('WARNING: hello\n'));
      expect(() => logger.error('hello'), prints('ERROR: hello\n'));
      expect(() => logger.critical('hello'), prints('CRITICAL: hello\n'));
      expect(() => logger.alert('hello'), prints('ALERT: hello\n'));
      expect(() => logger.emergency('hello'), prints('EMERGENCY: hello\n'));
    });

    test('log with stack trace', testOn: '!browser', () {
      expect(
        () {
          final caught = catchingFunction();
          logger.error(
            caught.error.toString(),
            payload: {'a': 2, 'b': 3},
            stackTrace: caught.stackTrace,
          );
        },
        prints(
          allOf(
            startsWith('ERROR: Invalid argument(s): sample\n'),
            contains('test/test_utils.dart'),
          ),
        ),
      );
    });
  });

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
            payload: {'a': 2, 'b': 3},
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
              'a': 2,
              'b': 3,
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

    group('traceparent correlation', () {
      test('valid version 00 traceparent, sampled true', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {
                  'message': 'hello',
                  'severity': 'INFO',
                  'logging.googleapis.com/trace':
                      '4bf92f3577b34da6a3ce929d0e0e4736',
                  'logging.googleapis.com/spanId': '00f067aa0ba902b7',
                  'logging.googleapis.com/trace_sampled': true,
                },
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          },
        );
      });

      test('valid version 00 traceparent, sampled false', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {
                  'message': 'hello',
                  'severity': 'INFO',
                  'logging.googleapis.com/trace':
                      '4bf92f3577b34da6a3ce929d0e0e4736',
                  'logging.googleapis.com/spanId': '00f067aa0ba902b7',
                },
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00',
          },
        );
      });

      test('valid higher version traceparent with extra fields', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {
                  'message': 'hello',
                  'severity': 'INFO',
                  'logging.googleapis.com/trace':
                      '4bf92f3577b34da6a3ce929d0e0e4736',
                  'logging.googleapis.com/spanId': '00f067aa0ba902b7',
                  'logging.googleapis.com/trace_sampled': true,
                },
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'
                '-extra-fields',
          },
        );
      });

      test('invalid traceparent: empty or too short', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {'traceparent': '00-123'},
        );
      });

      test('invalid traceparent: version ff', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                'ff-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          },
        );
      });

      test('invalid traceparent: version 00 too long', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01-extra',
          },
        );
      });

      test('invalid traceparent: uppercase characters', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-4bf92f3577B34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          },
        );
      });

      test('invalid traceparent: all zeroes trace-id', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-00000000000000000000000000000000-00f067aa0ba902b7-01',
          },
        );
      });

      test('invalid traceparent: all zeroes parent-id', () {
        runZoned(
          () => expect(
            () => logger.info('hello'),
            prints(
              isA<String>().having(
                (s) => jsonDecode(s) as Map<String, Object?>,
                'parsed json',
                {'message': 'hello', 'severity': 'INFO'},
              ),
            ),
          ),
          zoneValues: {
            'traceparent':
                '00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01',
          },
        );
      });
    });
  });
}
