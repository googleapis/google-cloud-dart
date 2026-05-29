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
import 'package:google_cloud_logging/src/structured_logging.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('sanitize', () {
    test('null', () {
      expect(sanitize(null), null);
    });

    test('bool', () {
      expect(sanitize(true), true);
      expect(sanitize(false), false);
    });

    test('num', () {
      expect(sanitize(1), 1);
      expect(sanitize(3.14), 3.14);
    });

    test('string', () {
      expect(sanitize('Hello'), 'Hello');
    });

    test('list of primitives', () {
      expect(sanitize([1, 'two', true, null]), [1, 'two', true, null]);
    });

    test('nested lists', () {
      expect(
        sanitize([
          1,
          [2, 3],
          [
            [4],
          ],
        ]),
        [
          1,
          [2, 3],
          [
            [4],
          ],
        ],
      );
    });

    test('map with primitive keys and values', () {
      expect(sanitize({'a': 1, 'b': 'two', 'c': true, 'd': null}), {
        'a': 1,
        'b': 'two',
        'c': true,
        'd': null,
      });
    });

    test('map with non-string keys', () {
      expect(sanitize({1: 'one', true: 'yes', null: 'empty'}), {
        '1': 'one',
        'true': 'yes',
        'null': 'empty',
      });
    });

    test('nested maps', () {
      expect(
        sanitize({
          'a': {'b': 1},
        }),
        {
          'a': {'b': 1},
        },
      );
    });

    test('object with toJson', () {
      final obj = _EncodeableReference()..ref = 'value';
      expect(sanitize(obj), {'ref': 'value'});
    });

    test('object without toJson (falls back to toString)', () {
      final obj = _NonEncodable();
      expect(sanitize(obj), 'I am not encodable');
    });

    test('cyclic toJson', () {
      final cyclic = _EncodeableReference();
      cyclic.ref = cyclic;

      expect(sanitize(cyclic), {'ref': '[CIRCULAR]'});
    });

    test('cyclic list', () {
      final list = <Object>[];
      list.add(list);

      expect(sanitize(list), ['[CIRCULAR]']);
    });

    test('cyclic map', () {
      final map = <String, Object>{};
      map['self'] = map;

      expect(sanitize(map), {'self': '[CIRCULAR]'});
    });

    test('shared references in non-cyclic structure (DAG)', () {
      final shared = {'foo': 'bar'};
      final list = [shared, shared];

      expect(sanitize(list), [
        {'foo': 'bar'},
        {'foo': 'bar'},
      ]);
    });
  });

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

    test('map message filters out structured logging fields', () {
      final message = {
        'foo': 'bar',
        'severity': 'WARNING',
        'logging.googleapis.com/trace': 'trace-123',
      };
      final entry = createStructuredLog(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'severity': 'INFO'});
    });

    test('with stacktrace', testOn: '!browser', () async {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        stackTrace: catchingFunction().stackTrace,
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'message': 'hello',
        'severity': 'INFO',
        'stack_trace': contains('structured_logging_test.dart'),
        'logging.googleapis.com/sourceLocation': {
          'file': endsWith('test_utils.dart'),
          'function': endsWith('throwingFunction'),
          'line': isA<String>().having(
            int.parse,
            'parsed line',
            greaterThan(1),
          ),
        },
      });
    });

    test('with traceparent', () {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        traceparent: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'message': 'hello',
        'severity': 'INFO',
        'logging.googleapis.com/spanId': '00f067aa0ba902b7',
        'logging.googleapis.com/trace_sampled': true,
      });
    });

    test('with traceparent and parentId', () {
      final entry = createStructuredLog(
        'hello',
        LogSeverity.info,
        traceparent: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
        projectId: 'my-project',
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {
        'message': 'hello',
        'severity': 'INFO',
        'logging.googleapis.com/trace':
            'projects/my-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
        'logging.googleapis.com/spanId': '00f067aa0ba902b7',
        'logging.googleapis.com/trace_sampled': true,
      });
    });

    test('extracts trace and project from zone', () {
      runZoned(
        () {
          final entry = createStructuredLog('hello', LogSeverity.info);
          final map = jsonDecode(entry) as Map<String, dynamic>;
          expect(map, {
            'message': 'hello',
            'severity': 'INFO',
            'logging.googleapis.com/trace':
                'projects/zone-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
            'logging.googleapis.com/spanId': '00f067aa0ba902b7',
            'logging.googleapis.com/trace_sampled': true,
          });
        },
        zoneValues: {
          'traceparent':
              '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          'google_cloud_project': 'zone-project',
        },
      );
    });

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

class _EncodeableReference {
  Object? ref;

  Object toJson() => {'ref': ref};
}
