// Copyright 2021 Google LLC
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

import 'package:io/ansi.dart';
import 'package:shelf/shelf.dart';

import '../constants.dart';
import '../logger.dart';
import '../structured_logging.dart';
import 'bad_request_exception.dart';
import 'trace_context_data.dart';

export '../structured_logging.dart';

const _badRequestExceptionContextKey = 'google_cloud.bad_request_exception';
const _badStackTraceContextKey = 'google_cloud.bad_stack_trace';

/// Convenience [Middleware] that handles logging depending on [projectId].
///
/// [projectId] is the optional Google Cloud Project ID used for trace
/// correlation.
///
/// If [projectId] is `null`, returns [Middleware] composed of [logRequests] and
/// [badRequestMiddleware].
///
/// If [projectId] is provided, returns the value from [cloudLoggingMiddleware].
Middleware createLoggingMiddleware({String? projectId}) => projectId == null
    ? _errorWriter.addMiddleware(logRequests()).addMiddleware(_handleBadRequest)
    : cloudLoggingMiddleware(projectId);

/// Adds logic which catches [BadRequestException], logs details to [stderr] and
/// returns a corresponding [Response].
Middleware get badRequestMiddleware => _handleBadRequest;

Handler _handleBadRequest(Handler innerHandler) => (request) async {
  try {
    final response = await innerHandler(request);
    return response;
  } on BadRequestException catch (error, stack) {
    return _responseFromBadRequest(error, stack);
  }
};

Handler _errorWriter(Handler innerHandler) => (request) async {
  final response = await innerHandler(request);

  final error =
      response.context[_badRequestExceptionContextKey] as BadRequestException?;

  if (error != null) {
    final stack = response.context[_badStackTraceContextKey] as StackTrace?;
    final output = [
      error,
      if (error.innerError != null)
        '${error.innerError} (${error.innerError.runtimeType})',
      if (error.innerStack ?? stack case final s?) formatStackTrace(s),
    ];

    final bob = output
        .expand((e) => LineSplitter.split('$e'.trim()))
        .join('\n');

    stderr.writeln(lightRed.wrap(bob));
  }
  return response;
};

Response _responseFromBadRequest(BadRequestException e, StackTrace stack) =>
    Response(
      e.statusCode,
      body: 'Bad request. ${e.message}',
      context: {
        _badRequestExceptionContextKey: e,
        _badStackTraceContextKey: stack,
      },
    );

/// Return [Middleware] that logs errors using Google Cloud structured logs and
/// returns the correct response.
///
/// [projectId] is the Google Cloud Project ID used for trace correlation.
///
/// Log messages of type [Map] are logged as structured logs (`jsonPayload`);
/// all other logs messages are logged as text logs (`textPayload`).
Middleware cloudLoggingMiddleware(String projectId) {
  Handler hostedLoggingMiddleware(Handler innerHandler) => (request) async {
    // Add log correlation to nest all log messages beneath request log in
    // Log Viewer.

    final traceHeader = request.headers[cloudTraceContextHeader];
    final traceContext = traceHeader != null
        ? TraceContextData.tryParse(
            projectId: projectId,
            traceHeader: traceHeader,
          )
        : null;

    String createErrorLogEntryFromRequest(
      Object error,
      StackTrace? stackTrace,
      LogSeverity logSeverity,
    ) => structuredLogEntry(
      '$error'.trim(),
      logSeverity,
      payload: traceContext?.asPayloadMap(),
      stackTrace: stackTrace,
    );

    final completer = Completer<Response>.sync();

    final currentZone = Zone.current;

    Zone.current
        .fork(
          zoneValues: {
            _loggerKey: _CloudLogger(
              zone: currentZone,
              traceContext: traceContext,
            ),
          },
          specification: ZoneSpecification(
            handleUncaughtError: (self, parent, zone, error, stackTrace) {
              if (error is HijackException) {
                completer.completeError(error, stackTrace);
              }

              final logContentString = error is BadRequestException
                  ? createErrorLogEntryFromRequest(
                      'Bad request. ${error.message}',
                      error.innerStack ?? stackTrace,
                      LogSeverity.warning,
                    )
                  : createErrorLogEntryFromRequest(
                      error,
                      stackTrace,
                      LogSeverity.error,
                    );

              // Serialize to a JSON string and output.
              parent.print(self, logContentString);

              if (completer.isCompleted) {
                return;
              }

              final response = error is BadRequestException
                  ? _responseFromBadRequest(error, stackTrace)
                  : Response.internalServerError();

              completer.complete(response);
            },
            print: (self, parent, zone, line) {
              final logContent = structuredLogEntry(
                line,
                LogSeverity.info,
                payload: traceContext?.asPayloadMap(),
              );

              // Serialize to a JSON string and output to parent zone.
              parent.print(self, logContent);
            },
          ),
        )
        .runGuarded(() async {
          final response = await innerHandler(request);
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        });

    return completer.future;
  };

  return hostedLoggingMiddleware;
}

/// Returns the current [CloudLogger].
///
/// If called within a context configured with a [CloudLogger], the returned
/// [CloudLogger] will be used.
///
/// Otherwise, the returned [CloudLogger] will simply [print] log entries,
/// with entries having a [LogSeverity] different than
/// [LogSeverity.defaultSeverity] being prefixed as such.
CloudLogger get currentLogger =>
    Zone.current[_loggerKey] as CloudLogger? ??
    const CloudLogger.defaultLogger();

/// Used to represent the [CloudLogger] in [Zone] values.
final _loggerKey = Object();

/// A [CloudLogger] that prints messages using Google Cloud structured
/// logging.
final class _CloudLogger extends CloudLogger {
  final Zone zone;

  final TraceContextData? traceContext;

  /// Creates a new [_CloudLogger] that prints structured logs to [this.zone].
  _CloudLogger({required this.zone, this.traceContext});

  /// If [message] is a [Map], it is used as the log entry payload. Otherwise,
  /// it is passed directly to [structuredLogEntry], which handles
  /// serialization.
  @override
  void log(
    Object message,
    LogSeverity severity, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => zone.print(
    structuredLogEntry(
      message,
      severity,
      payload: traceContext?.asPayloadMap(payload) ?? payload,
      stackTrace: stackTrace,
    ),
  );
}
