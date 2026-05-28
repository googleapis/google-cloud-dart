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
  group('StructuredLogger', () {
    group('convenience methods', () {
      final output = StringBuffer();
      final logger = StructuredLogger(writeln: output.writeln);

      setUp(output.clear);

      for (final (method, severity) in [
        (logger.debug, 'DEBUG'),
        (logger.info, 'INFO'),
        (logger.notice, 'NOTICE'),
        (logger.warning, 'WARNING'),
        (logger.error, 'ERROR'),
        (logger.critical, 'CRITICAL'),
        (logger.alert, 'ALERT'),
        (logger.emergency, 'EMERGENCY'),
      ]) {
        test(severity, () {
          method('hello');
          expect(
            output.toString(),
            isA<String>().having(
              (s) => jsonDecode(s) as Map<String, Object?>,
              'parsed json',
              {'message': 'hello', 'severity': severity},
            ),
          );
        });
      }
    });

    test('error with stack trace', testOn: '!browser', () {
      final output = StringBuffer();
      final logger = StructuredLogger(writeln: output.writeln);

      final caught = catchingFunction();
      logger.error(caught.error.toString(), stackTrace: caught.stackTrace);

      expect(
        output.toString(),
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
      );
    });

    group('package:logging', () {
      test('shout with string message', () async {
        final output = StringBuffer();
        final structuredLogger = StructuredLogger(writeln: output.writeln);
        final logger = Logger('MyClass');
        logger.onRecord.listen(structuredLogger.handleLogRecord);

        logger.log(Level.SHOUT, 'Hello');
        await pumpEventQueue();

        expect(
          output.toString(),
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'loggerName': 'MyClass',
              'message': 'Hello',
              'severity': 'CRITICAL',
            },
          ),
        );
      });

      test('shout with map message', () async {
        final output = StringBuffer();
        final structuredLogger = StructuredLogger(writeln: output.writeln);
        final logger = Logger('MyClass');
        logger.onRecord.listen(structuredLogger.handleLogRecord);

        logger.log(Level.SHOUT, {
          'happy': true,
          'animals': ['cat', 'dog'],
        });
        await pumpEventQueue();

        expect(
          output.toString(),
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'animals': ['cat', 'dog'],
              'happy': true,
              'loggerName': 'MyClass',
              'severity': 'CRITICAL',
            },
          ),
        );
      });

      test('shout with string error', () async {
        final output = StringBuffer();
        final structuredLogger = StructuredLogger(writeln: output.writeln);
        final logger = Logger('MyClass');
        logger.onRecord.listen(structuredLogger.handleLogRecord);

        logger.log(Level.SHOUT, 'Hello', 'something bad');
        await pumpEventQueue();

        expect(
          output.toString(),
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'error': 'something bad',
              'loggerName': 'MyClass',
              'message': 'Hello',
              'severity': 'CRITICAL',
            },
          ),
        );
      });

      test('shout with map error', () async {
        final output = StringBuffer();
        final structuredLogger = StructuredLogger(writeln: output.writeln);
        final logger = Logger('MyClass');
        logger.onRecord.listen(structuredLogger.handleLogRecord);

        logger.log(Level.SHOUT, 'Hello', {'line': 23, 'file': 'foo.cc'});
        await pumpEventQueue();

        expect(
          output.toString(),
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'error': {'line': 23, 'file': 'foo.cc'},
              'loggerName': 'MyClass',
              'message': 'Hello',
              'severity': 'CRITICAL',
            },
          ),
        );
      });

      test('shout with stacktrace', testOn: '!browser', () async {
        final output = StringBuffer();
        final structuredLogger = StructuredLogger(writeln: output.writeln);
        final logger = Logger('MyClass');
        logger.onRecord.listen(structuredLogger.handleLogRecord);

        final caught = catchingFunction();
        logger.log(Level.SHOUT, 'Hello', null, caught.stackTrace);
        await pumpEventQueue();

        expect(
          output.toString(),
          isA<String>().having(
            (s) => jsonDecode(s) as Map<String, Object?>,
            'parsed json',
            {
              'loggerName': 'MyClass',
              'message': 'Hello',
              'severity': 'CRITICAL',
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
        );
      });
    });
  });
}
