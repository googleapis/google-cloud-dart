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
import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('createStructuredLog', () {
    test('simple message', () {
      final entry = createStructuredLog('hello', LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'hello', 'severity': 'INFO'});
    });

    test('message with traceId in payload', () {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        payload: {'logging.googleapis.com/trace': 'trace-123'},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'message': 'hello',
        'severity': 'INFO',
        'logging.googleapis.com/trace': 'trace-123',
      });
    });

    test('list message remains in message key', () {
      final message = ['foo', 'bar'];
      final entry = createStructuredLog(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': message, 'severity': 'INFO'});
    });

    test('map message is merged into payload', () {
      final message = {'foo': 'bar', 'count': 42};
      final entry = createStructuredLog(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'count': 42, 'severity': 'INFO'});
    });

    test('map message with message key extracts message', () {
      final message = {'foo': 'bar', 'message': 'my msg'};
      final entry = createStructuredLog(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'message': 'my msg', 'severity': 'INFO'});
    });

    test('payload overrides map message', () {
      final message = {'foo': 'bar', 'count': 42, 'message': 'original'};
      final entry = createStructuredLog(
        message,
        LogSeverity.info,
        payload: {'count': 99, 'env': 'prod', 'message': 'overridden'},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'foo': 'bar',
        'count': 99,
        'env': 'prod',
        'message': 'overridden',
        'severity': 'INFO',
      });
    });

    test('non-encodable message is stringified', () {
      final message = _NonEncodable();
      final entry = createStructuredLog(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'I am not encodable', 'severity': 'INFO'});
    });

    test('with payload', () {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        payload: {'foo': 'bar', 'count': 42},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'foo': 'bar',
        'count': 42,
        'message': 'hello',
        'severity': 'INFO',
      });
    });

    test('with empty message', () {
      final entry = createStructuredLog(
        '',
        LogSeverity.info,
        payload: {'foo': 'bar', 'count': 42},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'count': 42, 'severity': 'INFO'});
    });

    test('payload does not override core fields', () {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        payload: {'message': 'overridden', 'severity': 'CRITICAL'},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'hello', 'severity': 'INFO'});
    });

    test('non-encodable payload is stringified', () {
      final payload = {'foo': _NonEncodable()};
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        payload: payload,
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'foo': 'I am not encodable',
        'message': 'hello',
        'severity': 'INFO',
      });
    });

    test('cyclic payload drops payload and stringifies message', () {
      final payload = <String, dynamic>{};
      payload['cycle'] = payload;
      final message = _NonEncodable();
      final entry = createStructuredLog(
        message,
        LogSeverity.info,
        payload: payload,
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'I am not encodable', 'severity': 'INFO'});
    });

    test(
      'shared references in non-cyclic payload (DAG) serialize correctly',
      () {
        final shared = {'foo': 'bar'};
        final payload = {'first': shared, 'second': shared};
        final entry = createStructuredLog(
          'hello',
          LogSeverity.info,
          payload: payload,
        );
        final map = jsonDecode(entry) as Map<String, dynamic>;
        expect(map, {
          'message': 'hello',
          'severity': 'INFO',
          'first': {'foo': 'bar'},
          'second': {'foo': 'bar'},
        });
      },
    );

    // https://github.com/GoogleCloudPlatform/google-fluentd
    test('missing severity infers DEFAULT', () {
      final entry = LogEntry(
        logName: '',
        resource: null,
        jsonPayload: Struct(fields: {'foo': Value(stringValue: 'bar')}),
      );
      final result = createStructuredLogFromEntry(entry);
      final map = jsonDecode(result) as Map<String, dynamic>;
      // XXX do the JSON fields get mapped?
      print(map);
      expect(map, containsPair('severity', 'DEFAULT'));
    });

    test(
      'cyclic payload with stack trace attaches source location',
      testOn: '!browser',
      () {
        final payload = <String, dynamic>{};
        payload['cycle'] = payload;
        final caught = catchingFunction();
        final entry = createStructuredLog(
          caught.error,
          LogSeverity.info,
          payload: payload,
          stackTrace: caught.stackTrace,
        );
        expect(jsonDecode(entry), {
          'severity': 'INFO',
          'logging.googleapis.com/sourceLocation': {
            'file': endsWith('test_utils.dart'),
            'line': isNotEmpty,
            'function': 'throwingFunction',
          },
          'message': caught.error.toString(),
        });
      },
    );

    test('all-filtered stack trace falls back to first frame', () {
      // Create a trace consisting entirely of filtered core frames
      final trace = StackTrace.fromString('dart:core 10:11 String.split\n');
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        stackTrace: trace,
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(
        map['logging.googleapis.com/sourceLocation'],
        containsPair('file', 'dart:core'),
      );
    });
  });
}

class _NonEncodable {
  @override
  String toString() => 'I am not encodable';
}
