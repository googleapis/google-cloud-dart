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
import 'dart:io';

import 'package:google_cloud_logging/google_cloud_logging.dart';
import 'package:logger/logger.dart' as logger;
import 'package:logging/logging.dart' as logging;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('StructuredLogHandler - package:logging', () {
    final handler = StructuredLogHandler();

    test('handleLogRecord formats standard message', () {
      final lines = <String>[];

      IOOverrides.runZoned(() {
        final record = logging.LogRecord(
          logging.Level.INFO,
          'A routine message',
          'my-logger',
        );
        handler.handleLogRecord(record);
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map, {'message': 'A routine message', 'severity': 'INFO'});
    });

    test('handleLogRecord handles Map object payload', () {
      final lines = <String>[];

      IOOverrides.runZoned(() {
        final record = logging.LogRecord(
          logging.Level.WARNING,
          'Request failed',
          'my-logger',
          null,
          null,
          null,
          {'userId': 'user_123', 'attempts': 3},
        );
        handler.handleLogRecord(record);
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map, {
        'message': 'Request failed',
        'severity': 'WARNING',
        'userId': 'user_123',
        'attempts': 3,
      });
    });

    test('handleLogRecord extracts zone-based trace context', () {
      final lines = <String>[];

      IOOverrides.runZoned(() {
        runZoned(
          () {
            final record = logging.LogRecord(
              logging.Level.INFO,
              'Request parsed',
              'my-logger',
            );
            handler.handleLogRecord(record);
          },
          zoneValues: {
            logContextZoneKey: {
              'logging.googleapis.com/trace':
                  'projects/my-project/traces/12345',
              'logging.googleapis.com/spanId': '67890',
            },
          },
        );
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map, {
        'message': 'Request parsed',
        'severity': 'INFO',
        'logging.googleapis.com/trace': 'projects/my-project/traces/12345',
        'logging.googleapis.com/spanId': '67890',
      });
    });

    test('handleLogRecord formats stack trace and error', () {
      final lines = <String>[];

      IOOverrides.runZoned(() {
        final caught = catchingFunction();
        final record = logging.LogRecord(
          logging.Level.SEVERE,
          'An error occurred',
          'my-logger',
          caught.error,
          caught.stackTrace,
        );
        handler.handleLogRecord(record);
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map['message'], 'An error occurred');
      expect(map['severity'], 'ERROR');
      expect(map['error'], contains('Invalid argument'));
      expect(map['stack_trace'], contains('test_utils.dart'));
      expect(
        map['logging.googleapis.com/sourceLocation'],
        isA<Map<String, Object?>>(),
      );
    });
  });

  group('StructuredLogHandler - package:logger', () {
    final handler = StructuredLogHandler();

    test('asLogOutput formats standard message', () {
      final lines = <String>[];
      final output = handler.asLogOutput();

      IOOverrides.runZoned(() {
        final event = logger.OutputEvent(
          logger.LogEvent(logger.Level.info, 'Some trace message'),
          ['ignored formatted text'],
        );
        output.output(event);
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map, {'message': 'Some trace message', 'severity': 'INFO'});
    });

    test('asLogOutput extracts zone-based trace context', () {
      final lines = <String>[];
      final output = handler.asLogOutput();

      IOOverrides.runZoned(() {
        runZoned(
          () {
            final event = logger.OutputEvent(
              logger.LogEvent(logger.Level.warning, 'Some warning'),
              ['ignored formatted text'],
            );
            output.output(event);
          },
          zoneValues: {
            logContextZoneKey: {
              'logging.googleapis.com/trace': 'projects/my-project/traces/abc',
              'logging.googleapis.com/spanId': 'def',
            },
          },
        );
      }, stdout: () => _MockStdout(lines));

      expect(lines, hasLength(1));
      final map = jsonDecode(lines.first) as Map<String, dynamic>;
      expect(map, {
        'message': 'Some warning',
        'severity': 'WARNING',
        'logging.googleapis.com/trace': 'projects/my-project/traces/abc',
        'logging.googleapis.com/spanId': 'def',
      });
    });
  });
}

class _MockStdout implements Stdout {
  final List<String> lines;
  _MockStdout(this.lines);

  @override
  void write(Object? object) => lines.add('$object'.trimRight());

  @override
  void writeln([Object? object = '']) => lines.add('$object'.trimRight());

  @override
  bool get supportsAnsiEscapes => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
