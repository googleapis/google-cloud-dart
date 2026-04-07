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
import 'package:google_cloud_logging_v2/google_cloud_logging_v2.dart';
import 'package:test/test.dart';

void main() {
  group('structuredLogEntry', () {
    test('simple message', () {
      final entry = structuredLogEntry('hello', LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'hello', 'severity': 'INFO'});
    });

    test('message with traceId in payload', () {
      final entry = structuredLogEntry(
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
      final entry = structuredLogEntry(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': message, 'severity': 'INFO'});
    });

    test('map message is merged into payload', () {
      final message = {'foo': 'bar', 'count': 42};
      final entry = structuredLogEntry(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'count': 42, 'severity': 'INFO'});
    });

    test('map message with message key extracts message', () {
      final message = {'foo': 'bar', 'message': 'my msg'};
      final entry = structuredLogEntry(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'message': 'my msg', 'severity': 'INFO'});
    });

    test('payload overrides map message', () {
      final message = {'foo': 'bar', 'count': 42, 'message': 'original'};
      final entry = structuredLogEntry(
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
      final entry = structuredLogEntry(message, LogSeverity.info);
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'I am not encodable', 'severity': 'INFO'});
    });

    test('with payload', () {
      final entry = structuredLogEntry(
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
      final entry = structuredLogEntry(
        '',
        LogSeverity.info,
        payload: {'foo': 'bar', 'count': 42},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'foo': 'bar', 'count': 42, 'severity': 'INFO'});
    });

    test('payload does not override core fields', () {
      final entry = structuredLogEntry(
        'hello',
        LogSeverity.info,
        payload: {'message': 'overridden', 'severity': 'CRITICAL'},
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'hello', 'severity': 'INFO'});
    });

    test('non-encodable payload is stringified', () {
      final payload = {'foo': _NonEncodable()};
      final entry = structuredLogEntry(
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
      final entry = structuredLogEntry(
        message,
        LogSeverity.info,
        payload: payload,
      );
      final map = jsonDecode(entry) as Map<String, dynamic>;
      expect(map, {'message': 'I am not encodable', 'severity': 'INFO'});
    });
  });
}

class _NonEncodable {
  @override
  String toString() => 'I am not encodable';
}
