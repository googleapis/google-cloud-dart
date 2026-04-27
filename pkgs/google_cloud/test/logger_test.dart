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

import 'package:google_cloud/google_cloud.dart';
import 'package:test/test.dart';

void main() {
  group('LogSeverity', () {
    test('toJson returns name', () {
      expect(LogSeverity.info.toJson(), 'INFO');
      expect(LogSeverity.error.toJson(), 'ERROR');
    });

    test('comparable', () {
      expect(LogSeverity.info.compareTo(LogSeverity.error), isNegative);
      expect(LogSeverity.critical.compareTo(LogSeverity.warning), isPositive);
    });

    test('operators', () {
      expect(LogSeverity.debug, lessThan(LogSeverity.info));
      expect(LogSeverity.info, lessThanOrEqualTo(LogSeverity.info));
      expect(LogSeverity.error, greaterThan(LogSeverity.warning));
      expect(LogSeverity.critical, greaterThanOrEqualTo(LogSeverity.critical));
    });

    test('toString returns description', () {
      expect(LogSeverity.info.toString(), 'LogSeverity INFO (200)');
    });
  });

  group('CloudLogger.defaultLogger()', () {
    const logger = CloudLogger.defaultLogger();

    test('log with default severity', () {
      expect(
        () => logger.log('hello', LogSeverity.defaultSeverity),
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
        prints('ERROR: hello {foo: bar}\n'),
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

    test('log with stack trace', () {
      final trace = StackTrace.current;
      expect(
        () => logger.log('hello', LogSeverity.error, stackTrace: trace),
        prints(
          allOf([startsWith('ERROR: hello\n'), contains('logger_test.dart')]),
        ),
      );
    });
  });
}
