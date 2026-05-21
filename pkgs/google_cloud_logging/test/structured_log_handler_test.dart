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

void main() {
  group('StructuredLogHandler', () {
    group('handleLogRecord', () {
      test('string message', () {
        final output = StringBuffer();
        StructuredLogHandler(
          writeln: output.writeln,
        ).handleLogRecord(LogRecord(Level.WARNING, 'Hello', 'MyClass'));
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
          'message': 'Hello',
        });
      });

      test('empty map message', () {
        final output = StringBuffer();
        final object = <Object, Object>{};
        StructuredLogHandler(writeln: output.writeln).handleLogRecord(
          LogRecord(
            Level.WARNING,
            object.toString(),
            'MyClass',
            null,
            null,
            null,
            object,
          ),
        );
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
        });
      });

      test('map message', () {
        final output = StringBuffer();
        final object = {'k1': 'v1', 'k2': 'v2'};
        StructuredLogHandler(writeln: output.writeln).handleLogRecord(
          LogRecord(
            Level.WARNING,
            object.toString(),
            'MyClass',
            null,
            null,
            null,
            object,
          ),
        );
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
          'k1': 'v1',
          'k2': 'v2',
        });
      });

      test('recursive map message', () {
        final output = StringBuffer();
        final object = <String, Object>{'k1': 'v1', 'k2': 'v2'};
        object['k3'] = object;
        StructuredLogHandler(writeln: output.writeln).handleLogRecord(
          LogRecord(
            Level.WARNING,
            object.toString(),
            'MyClass',
            null,
            null,
            null,
            object,
          ),
        );
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
          'k1': 'v1',
          'k2': 'v2',
          'k3': {'k1': 'v1', 'k2': 'v2', 'k3': '{...}'},
        });
      });

      test('recursive list message', () {
        final output = StringBuffer();
        final object = {
          'k1': ['hello', 5],
        };

        object['k1']!.add(object['k1']!);
        StructuredLogHandler(writeln: output.writeln).handleLogRecord(
          LogRecord(
            Level.WARNING,
            object.toString(),
            'MyClass',
            null,
            null,
            null,
            object,
          ),
        );
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
          'k1': ['hello', 5, '[...]'],
        });
      });

      test('recursive list message', () {
        final output = StringBuffer();
        final object = {
          'k1': ['hello', 5],
        };

        object['k1']!.add(object['k1']!);
        StructuredLogHandler(writeln: output.writeln).handleLogRecord(
          LogRecord(
            Level.WARNING,
            object.toString(),
            'MyClass',
            null,
            null,
            null,
            object,
          ),
        );
        expect(jsonDecode(output.toString()), {
          'severity': 'WARNING',
          'loggerName': 'MyClass',
          'k1': ['hello', 5, '[...]'],
        });
      });
    });
  });
}

/*
  LogRecord(this.level, this.message, this.loggerName,
      [this.error, this.stackTrace, this.zone, this.object])
      : time = DateTime.now(),
        sequenceNumber = LogRecord._nextNumber++;
*/
