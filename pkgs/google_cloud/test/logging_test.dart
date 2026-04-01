// Copyright 2022 Google LLC
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

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:google_cloud/general.dart';
import 'package:google_cloud/http_serving.dart';
import 'package:shelf/shelf.dart';
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

  group('LogSeverity', () {
    test('toJson returns name', () {
      expect(LogSeverity.info.toJson(), 'INFO');
      expect(LogSeverity.error.toJson(), 'ERROR');
    });

    test('comparable', () {
      expect(LogSeverity.info.compareTo(LogSeverity.error), isNegative);
      expect(LogSeverity.critical.compareTo(LogSeverity.warning), isPositive);
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
  });

  group('middleware', () {
    test('cloudLoggingMiddleware logs structured entries', () async {
      final handler = const Pipeline()
          .addMiddleware(cloudLoggingMiddleware('test-project'))
          .addHandler((request) {
            currentLogger.info('inner log');
            return Response.ok('done');
          });

      await expectLater(
        () => handler(
          Request(
            'GET',
            Uri.parse('http://localhost/'),
            headers: {
              'x-cloud-trace-context':
                  '0123456789abcdef0123456789abcdef/123;o=1',
            },
          ),
        ),
        prints(
          predicate<String>((output) {
            final map = jsonDecode(output) as Map<String, dynamic>;
            return map['message'] == 'inner log' &&
                map['severity'] == 'INFO' &&
                map['logging.googleapis.com/trace'] ==
                    'projects/test-project/traces/0123456789abcdef0123456789abcdef' &&
                map['logging.googleapis.com/spanId'] == '000000000000007b' &&
                map['logging.googleapis.com/trace_sampled'] == true;
          }),
        ),
      );
    });

    test('badRequestMiddleware handles BadRequestException', () async {
      final handler = const Pipeline()
          .addMiddleware(badRequestMiddleware)
          .addHandler((request) {
            throw BadRequestException(400, 'Custom bad request');
          });

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );
      expect(response.statusCode, 400);
      expect(
        await response.readAsString(),
        contains('Custom bad request (400)'), // toString() output
      );
    });

    test('badRequestMiddleware handles BadRequestException (JSON)', () async {
      final handler = const Pipeline()
          .addMiddleware(badRequestMiddleware)
          .addHandler((request) {
            throw BadRequestException(400, 'Custom bad request');
          });

      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'Accept': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        contains('application/json'),
      );

      final body = await response.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json, {
        'error': {'code': 400, 'message': 'Custom bad request'},
      });
    });

    test('skips empty details in toJson', () {
      final e = BadRequestException(400, 'Custom bad request');
      expect(e.toJson(), {
        'error': {'code': 400, 'message': 'Custom bad request'},
      });
    });

    test('badRequestMiddleware handles expanded BadRequestException', () async {
      final handler = const Pipeline()
          .addMiddleware(badRequestMiddleware)
          .addHandler((request) {
            throw BadRequestException.badRequest(
              'Custom bad request',
              status: 'INVALID_ARGUMENT',
              details: [
                {'field': 'name', 'message': 'required'},
              ],
            );
          });

      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'Accept': 'application/json'},
        ),
      );
      expect(response.statusCode, 400);

      final body = await response.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      expect(json, {
        'error': {
          'code': 400,
          'message': 'Custom bad request',
          'status': 'INVALID_ARGUMENT',
          'details': [
            {'field': 'name', 'message': 'required'},
          ],
        },
      });
    });

    test('badRequestMiddleware logs to stderr', () async {
      final stderrLines = <String>[];
      final handler = const Pipeline()
          .addMiddleware(createLoggingMiddleware())
          .addHandler((request) {
            throw BadRequestException(400, 'Custom bad request');
          });

      await IOOverrides.runZoned(() async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/')),
        );
        expect(response.statusCode, 400);
      }, stderr: () => _MockStdout(stderrLines));

      expect(stderrLines, hasLength(1));
      final lines = stderrLines.single.split('\n');
      expect(lines.first, contains('Custom bad request (400)'));
      expect(lines[1], contains('logging_test.dart'));
    });
  });

  group('BadRequestException', () {
    test('valid status code', () {
      final ex = BadRequestException(400, 'Bad');
      expect(ex.statusCode, 400);
      expect(ex.message, 'Bad');
      expect(ex.toString(), 'Bad (400)');
    });

    test('invalid status code low', () {
      expect(() => BadRequestException(399, 'Bad'), throwsArgumentError);
    });

    test('invalid status code high', () {
      expect(() => BadRequestException(500, 'Bad'), throwsArgumentError);
    });

    test('empty message', () {
      // ignore: prefer_const_constructors
      expect(
        () => BadRequestException(400, ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('parseTraceContext', () {
    test('parses full context', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef/1054454457908058113;o=1',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, '0ea22cbe236fd801');
      expect(context.traceSampled, true);
    });

    test('parses without sampled flag', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef/123',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, '000000000000007b');
      expect(context.traceSampled, isFalse);
    });

    test(
      'parses format without trace options but trailing semicolon flag off',
      () {
        final context = TraceContextData.parse(
          projectId: 'test-project',
          traceHeader: '0123456789abcdef0123456789abcdef/123;o=0',
        );
        expect(
          context.traceId,
          'projects/test-project/traces/0123456789abcdef0123456789abcdef',
        );
        expect(context.spanId, '000000000000007b');
        expect(context.traceSampled, false);
      },
    );

    test('parses minimal trace', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, isNull);
      expect(context.traceSampled, isFalse);
    });
  });

  group('TraceContextData.asPayloadMap', () {
    test('full context includes everything', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
        traceSampled: true,
      );
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
        'logging.googleapis.com/trace_sampled': true,
      });
    });

    test('omits spanId when null', () {
      final context = TraceContextData(traceId: 'test-trace');
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
      });
    });

    test('omits traceSampled when false', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
        // traceSampled: false, // Default
      );
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
      });
    });

    test('merges with existing payload', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
      );
      final payload = {'message': 'hello', 'count': 42};
      expect(context.asPayloadMap(payload), {
        'message': 'hello',
        'count': 42,
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
      });
    });
  });
}

class _NonEncodable {
  @override
  String toString() => 'I am not encodable';
}

class _MockStdout implements Stdout {
  final List<String> _lines;

  _MockStdout(this._lines);

  @override
  bool get supportsAnsiEscapes => false;

  @override
  void writeln([Object? object = '']) {
    _lines.add('$object');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
