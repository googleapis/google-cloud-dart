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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_cloud/http_serving.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const internalServerErrorMessage = 'Internal Server Error';

void main() {
  for (var environment in _Environment.values) {
    for (var responseType in _ResponseType.values) {
      for (var responseScenario in _ResponseScenarios.values) {
        final name = [
          responseScenario.name,
          responseType.name,
          environment.name,
        ].join(' | ');

        test('[$name]', () async {
          final middleware = createLoggingMiddleware(
            projectId: environment.projectId,
          );

          final handler = middleware(responseScenario.handler);

          final logMatchers = _logMatcherFactory(responseScenario, environment);

          final stdoutLines = <String>[];
          final stderrLines = <String>[];
          late Response response;

          await IOOverrides.runZoned(
            () => runZoned(
              zoneSpecification: ZoneSpecification(
                print: (_, _, _, String line) => stdoutLines.add(line),
              ),
              () async {
                response = await handler(
                  responseType.toRequest(
                    responseScenario == _ResponseScenarios.successfulWithLogs,
                  ),
                );
              },
            ),
            stdout: () => _MockStdout(stdoutLines),
            stderr: () => _MockStdout(stderrLines),
          );

          expect(
            stdoutLines.join('\n'),
            logMatchers.stdout,
            reason: 'stdout matcher',
          );
          expect(
            stderrLines.join('\n'),
            logMatchers.stderr,
            reason: 'stderr matcher',
          );

          expect(
            response,
            _responseScenarioFactory(responseScenario, responseType),
            reason: 'response matcher',
          );
        });
      }
    }
  }

  test('Middleware rethrows HijackException', () async {
    final middleware = createLoggingMiddleware();
    final handler = middleware((request) => throw const HijackException());

    expect(
      () => handler(Request('GET', Uri.parse('http://localhost/'))),
      throwsA(isA<HijackException>()),
    );
  });

  test(
    'cloudLoggingMiddleware propagates HijackException and does not log',
    () async {
      final middleware = cloudLoggingMiddleware('project-id');
      final handler = middleware((request) => throw const HijackException());

      final stdoutLines = <String>[];

      await runZoned(
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, String line) => stdoutLines.add(line),
        ),
        () async {
          final future = handler(
            Request('GET', Uri.parse('http://localhost/')),
          );
          await expectLater(future, throwsA(isA<HijackException>()));
        },
      );

      expect(stdoutLines, isEmpty);
    },
  );

  test(
    'HttpResponseException with multi-line details is formatted pretty',
    () async {
      final middleware = createLoggingMiddleware();
      final handler = middleware(
        (request) => throw HttpResponseException(
          400,
          'with multi-line details',
          details: [
            {'message': 'line 1\nline 2', 'code': 42},
            {'message2': 'line 3\nline 4', 'code2': 43},
          ],
        ),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(
        body,
        contains('''
Details:
  - message: line 1
             line 2
    code: 42
  - message2: line 3
              line 4
    code2: 43'''),
      );
    },
  );

  test(
    'HttpResponseException with empty details maps outputs empty map literal',
    () async {
      final middleware = createLoggingMiddleware();
      final handler = middleware(
        (request) => throw HttpResponseException(
          400,
          'with empty details',
          details: [
            {},
            {'message': 'line 1'},
          ],
        ),
      );

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 400);
      final body = await response.readAsString();
      expect(
        body,
        contains('''
Details:
  - {}
  - message: line 1'''),
      );
    },
  );

  test('cloudLoggingMiddleware uncaughtErrorHandler handles HijackException '
      'safely after completion', () async {
    final middleware = cloudLoggingMiddleware('project-id');

    final handler = middleware((request) {
      // Throw asynchronously after returning response.
      Timer.run(() {
        Zone.current.handleUncaughtError(
          const HijackException(),
          StackTrace.current,
        );
      });
      return Response.ok('done');
    });

    final response = await handler(
      Request('GET', Uri.parse('http://localhost/')),
    );

    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'done');

    // Wait a bit for the timer to fire and ensure no crash happens.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}

enum _ResponseScenarios {
  httpResponseErrorMinimal(_throwHttpResponseMinimal),
  httpResponseErrorWithDetails(_throwHttpResponseWithDetails),
  nonHttpResponseError(_throwNonHttpResponseError),
  successfulWithLogs(_respondSuccessfullyWithLogs);

  final Handler handler;

  const _ResponseScenarios(this.handler);
}

enum _Environment {
  cloud('project-id'),
  normal(null);

  final String? projectId;

  const _Environment(this.projectId);
}

enum _ResponseType {
  json('application/json'),
  text('text/plain');

  final String contentType;

  const _ResponseType(this.contentType);

  Request toRequest(bool includeTraceContext) => Request(
    'GET',
    Uri.parse('http://localhost/'),
    headers: {
      'content-type': contentType,
      if (includeTraceContext)
        'x-cloud-trace-context': '0123456789abcdef0123456789abcdef/123;o=1',
    },
  );
}

TypeMatcher<Response> _responseScenarioFactory(
  _ResponseScenarios responseScenario,
  _ResponseType responseType,
) => switch ((responseScenario, responseType)) {
  (_ResponseScenarios.httpResponseErrorMinimal, _ResponseType.text) =>
    _responseMatcher(
      statusCode: 400,
      contentType: anyOf(isNull, contains('text/plain')),
      body: contains('HttpResponseException: minimal'),
    ),
  (_ResponseScenarios.httpResponseErrorMinimal, _ResponseType.json) =>
    _responseMatcher(
      statusCode: 400,
      contentType: contains('application/json'),
      body: _jsonStringMatcher({
        'error': {'code': 400, 'message': 'minimal'},
      }),
    ),
  (_ResponseScenarios.httpResponseErrorWithDetails, _ResponseType.text) =>
    _responseMatcher(
      statusCode: 400,
      contentType: anyOf(isNull, contains('text/plain')),
      body: allOf([
        contains('HttpResponseException: with details'),
        contains('Details:'),
        contains('type: type.googleapis.com/google.rpc.BadRequest'),
      ]),
    ),
  (_ResponseScenarios.httpResponseErrorWithDetails, _ResponseType.json) =>
    _responseMatcher(
      statusCode: 400,
      contentType: contains('application/json'),
      body: _jsonStringMatcher({
        'error': {
          'code': 400,
          'message': 'with details',
          'status': 'BAD_REQUEST',
          'details': [
            {
              'type': 'type.googleapis.com/google.rpc.BadRequest',
              'fieldViolations': <Never>[],
            },
          ],
        },
      }),
    ),
  (_ResponseScenarios.nonHttpResponseError, _ResponseType.text) =>
    _responseMatcher(
      statusCode: 500,
      contentType: anyOf(isNull, contains('text/plain')),
      body: contains(internalServerErrorMessage),
    ),
  (_ResponseScenarios.nonHttpResponseError, _ResponseType.json) =>
    _responseMatcher(
      statusCode: 500,
      contentType: contains('application/json'),
      body: _jsonStringMatcher({
        'error': {
          'code': 500,
          'message': internalServerErrorMessage,
          'status': 'INTERNAL',
        },
      }),
    ),
  (_ResponseScenarios.successfulWithLogs, _) => _responseMatcher(
    statusCode: 200,
    contentType: contains('text/plain'),
    body: equals('done'),
  ),
};

({Matcher stdout, Matcher stderr}) _logMatcherFactory(
  _ResponseScenarios responseScenario,
  _Environment environment,
) => switch ((responseScenario, environment)) {
  (_ResponseScenarios.httpResponseErrorMinimal, _Environment.cloud) => (
    stdout: _jsonStringMatcher({
      'message': 'HttpResponseException: minimal (400)',
      'severity': 'WARNING',
      'error': {'code': 400, 'message': 'minimal'},
      'stack_trace': _stackTraceMatcher,
      'logging.googleapis.com/sourceLocation': isA<Map<String, dynamic>>(),
    }),
    stderr: isEmpty,
  ),
  (_ResponseScenarios.httpResponseErrorWithDetails, _Environment.cloud) => (
    stdout: _jsonStringMatcher({
      'message': startsWith('HttpResponseException: with details'),
      'severity': 'WARNING',
      'error': {
        'code': 400,
        'message': 'with details',
        'status': 'BAD_REQUEST',
        'details': [
          {
            'type': 'type.googleapis.com/google.rpc.BadRequest',
            'fieldViolations': <Never>[],
          },
        ],
      },
      'inner_error': 'Invalid argument(s): inner error',
      'inner_stack_trace': _stackTraceMatcher,
      'stack_trace': _stackTraceMatcher,
      'logging.googleapis.com/sourceLocation': isA<Map<String, dynamic>>(),
    }),
    stderr: isEmpty,
  ),
  (_ResponseScenarios.nonHttpResponseError, _Environment.cloud) => (
    stdout: _jsonStringMatcher({
      'message': 'Exception: non http error',
      'severity': 'ERROR',
      'stack_trace': _stackTraceMatcher,
      'logging.googleapis.com/sourceLocation': isA<Map<String, dynamic>>(),
    }),
    stderr: isEmpty,
  ),
  (_ResponseScenarios.httpResponseErrorMinimal, _Environment.normal) => (
    stdout: endsWith('[400] /'),
    stderr: allOf([
      contains('HttpResponseException: minimal (400)'),
      _stackTraceMatcher,
    ]),
  ),
  (_ResponseScenarios.httpResponseErrorWithDetails, _Environment.normal) => (
    stdout: endsWith('[400] /'),
    stderr: allOf([
      contains('HttpResponseException: with details (400) [BAD_REQUEST]'),
      contains('Invalid argument(s): inner error (ArgumentError)'),
      _stackTraceMatcher,
    ]),
  ),
  (_ResponseScenarios.nonHttpResponseError, _Environment.normal) => (
    stdout: endsWith('[500] /'),
    stderr: allOf([contains('Exception: non http error'), _stackTraceMatcher]),
  ),
  (_ResponseScenarios.successfulWithLogs, _Environment.cloud) => (
    stdout: isA<String>().having(
      (s) => s
          .trim()
          .split('\n')
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList(),
      'parsed JSON lines',
      [
        {
          'message': 'trace me',
          'severity': 'INFO',
          'logging.googleapis.com/trace':
              'projects/project-id/traces/0123456789abcdef0123456789abcdef',
          'logging.googleapis.com/spanId': '000000000000007b',
          'logging.googleapis.com/trace_sampled': true,
        },
        {
          'message': 'print me',
          'severity': 'INFO',
          'logging.googleapis.com/trace':
              'projects/project-id/traces/0123456789abcdef0123456789abcdef',
          'logging.googleapis.com/spanId': '000000000000007b',
          'logging.googleapis.com/trace_sampled': true,
        },
        {
          'message': 'default me',
          'severity': 'DEFAULT',
          'logging.googleapis.com/trace':
              'projects/project-id/traces/0123456789abcdef0123456789abcdef',
          'logging.googleapis.com/spanId': '000000000000007b',
          'logging.googleapis.com/trace_sampled': true,
        },
        {
          'message': 'warning me',
          'severity': 'WARNING',
          'logging.googleapis.com/trace':
              'projects/project-id/traces/0123456789abcdef0123456789abcdef',
          'logging.googleapis.com/spanId': '000000000000007b',
          'logging.googleapis.com/trace_sampled': true,
        },
      ],
    ),
    stderr: isEmpty,
  ),
  (_ResponseScenarios.successfulWithLogs, _Environment.normal) => (
    stdout: allOf([
      contains('trace me'),
      contains('print me'),
      contains('default me'),
      contains('WARNING: warning me'),
      endsWith('[200] /'),
    ]),
    stderr: isEmpty,
  ),
};

TypeMatcher<Response> _responseMatcher({
  required int statusCode,
  required Matcher contentType,
  required Matcher body,
}) => isA<Response>()
    .having((r) => r.statusCode, 'statusCode', statusCode)
    .having((r) => r.headers['content-type'], 'contentType', contentType)
    .having((r) => r.readAsString(), 'body', completion(body));

Matcher _jsonStringMatcher(Object expected) => isA<String>().having(
  (output) => jsonDecode(output) as Map<String, dynamic>,
  'decoded as a JSON map',
  expected,
);

final _stackTraceMatcher = matches(RegExp(r'test/logging_test.dart \d+:\d+'));

Future<Response> _throwHttpResponseMinimal(_) =>
    throw HttpResponseException(400, 'minimal');

Future<Response> _throwHttpResponseWithDetails(_) {
  try {
    throw ArgumentError('inner error');
  } catch (error, stack) {
    throw HttpResponseException(
      400,
      'with details',
      status: 'BAD_REQUEST',
      details: [
        {
          'type': 'type.googleapis.com/google.rpc.BadRequest',
          'fieldViolations': [],
        },
      ],
      innerError: error,
      innerStack: stack,
    );
  }
}

Future<Response> _throwNonHttpResponseError(_) =>
    throw Exception('non http error');

Future<Response> _respondSuccessfullyWithLogs(_) async {
  currentLogger.info('trace me');
  print('print me');
  currentLogger
    ..log('default me', LogSeverity.defaultSeverity)
    ..warning('warning me');
  return Response.ok('done', headers: {'content-type': 'text/plain'});
}

class _MockStdout implements Stdout {
  _MockStdout(this._lines);

  final List<String> _lines;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  void writeln([Object? object = '']) => _lines.add('$object');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
