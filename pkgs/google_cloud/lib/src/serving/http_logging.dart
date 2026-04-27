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

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

import '../constants.dart';
import '../logger.dart';
import '../structured_logging.dart';
import 'http_response_exception.dart';
import 'json_request_checking.dart';
import 'trace_context_data.dart';

export '../structured_logging.dart';

/// The default message to use for internal server errors.
///
/// This is used when an exception is thrown that is not an
/// [HttpResponseException].
@internal
const internalServerErrorMessage = 'Internal Server Error';

/// Convenience [Middleware] that handles logging depending on [projectId].
///
/// [projectId] is the optional Google Cloud Project ID used for trace
/// correlation.
///
/// If [projectId] is `null`, returns the value returned by
/// [errorLoggingMiddleware].
///
/// If [projectId] is provided, returns the value returned by
/// [cloudLoggingMiddleware].
Middleware createLoggingMiddleware({String? projectId}) => projectId == null
    ? errorLoggingMiddleware
    : cloudLoggingMiddleware(projectId);

/// Wraps the [logRequests] middleware and catches exceptions and logs them to
/// stderr.
///
/// Caught exceptions are logged as unformatted text to [stderr].
///
/// {@template exceptionResponseMapping}
/// All errors that are thrown in the context of the handler are caught and
/// and logged with an appopriate response sent to the caller.
///
/// The HTTP status code sent depends on the exception type.
///
/// - [HttpResponseException] causes a response with the status code of the
///   exception.
/// - Other exceptions cause a response with a status code of 500 and the
///   default message "Internal Server Error".
///
/// The response body will be JSON if the request headers indicate that JSON
/// is expected, otherwise it will be a plain text string.
/// {@endtemplate}
Middleware get errorLoggingMiddleware => _handleResponseException;

Handler _handleResponseException(Handler innerHandler) {
  Handler exceptionHandler(Handler inner) => (request) async {
    try {
      return await inner(request);
    } catch (error, stack) {
      // CRITICAL to support standard pkg:shelf behavior!
      if (error is HijackException) rethrow;
      final errorString = switch (error) {
        HttpResponseException(innerError: final innerError?) => [
          '$error — Caused by: $innerError (${innerError.runtimeType})',
          if (error.details != null && error.details!.isNotEmpty)
            'Details: ${error.details}',
        ].join('\n'),
        HttpResponseException() => [
          '$error',
          if (error.details != null && error.details!.isNotEmpty)
            'Details: ${error.details}',
        ].join('\n'),
        _ => '$error (${error.runtimeType})',
      };

      final stackToLog = error is HttpResponseException
          ? error.innerStack ?? stack
          : stack;

      final text = [
        errorString,
        formatStackTrace(stackToLog),
      ].expand((e) => LineSplitter.split('$e'.trim())).join('\n');

      stderr.writeln(text);
      return _responseFromException(error, stack, request.headers);
    }
  };
  return logRequests()(exceptionHandler(innerHandler));
}

/// Creates a [Response] from [error] and [stack].
///
/// If [requestHeaders] indicate that JSON is expected, the response body will
/// be JSON. Otherwise, the response body will be a plain text string.
///
/// ‼️ This method is VERY CAREFUL to not leak internal implementation details!
///
/// If the error is an [HttpResponseException], the `toString` and `toJson`
/// methods are used, but they have been carefully written to not leak internal
/// implementation details.
Response _responseFromException(
  Object error,
  StackTrace stack, [
  Map<String, String>? requestHeaders,
]) {
  final statusCode = error is HttpResponseException ? error.statusCode : 500;

  if (requestHeaders != null && shouldSendJsonResponse(requestHeaders)) {
    final jsonBody = error is HttpResponseException
        // ‼️ Note we only send the `toJson` of HttpResponseException because
        // it's been vetted to be safe.
        ? error.toJson()
        : {
            'error': {
              'code': statusCode,
              'message': internalServerErrorMessage,
              'status': 'INTERNAL',
            },
          };

    return Response(
      statusCode,
      body: jsonEncode(jsonBody),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
  }

  return Response(
    statusCode,
    body: error is HttpResponseException
        ? [
            // ‼️ Note we only send the `toString` of HttpResponseException
            // because it's been vetted to be safe.
            error.toString(),
            if (error.details != null && error.details!.isNotEmpty) ...[
              'Details:',
              _formatDetailsAsPseudoYaml(error.details!),
            ],
          ].join('\n')
        : internalServerErrorMessage,
  );
}

String _formatDetailsAsPseudoYaml(List<Map<String, Object?>> details) {
  final buffer = StringBuffer();
  for (var detail in details) {
    if (detail.isEmpty) {
      buffer.writeln('  - {}');
      continue;
    }
    final entries = detail.entries.toList();

    // First entry is inline with the '-' bullet.
    final firstEntry = entries.first;
    final firstKeyPart = '  - ${firstEntry.key}: ';
    final firstValueStr = '${firstEntry.value}';
    final firstLines = firstValueStr.split('\n');
    buffer.writeln('$firstKeyPart${firstLines.first}');
    final firstIndent = ' ' * firstKeyPart.length;
    for (var i = 1; i < firstLines.length; i++) {
      buffer.writeln('$firstIndent${firstLines[i]}');
    }

    // Subsequent entries are indented to match the first property.
    for (var i = 1; i < entries.length; i++) {
      final entry = entries[i];
      final keyPart = '    ${entry.key}: ';
      final valueStr = '${entry.value}';
      final lines = valueStr.split('\n');
      buffer.writeln('$keyPart${lines.first}');
      final indent = ' ' * keyPart.length;
      for (var j = 1; j < lines.length; j++) {
        buffer.writeln('$indent${lines[j]}');
      }
    }
  }
  return buffer.toString().trimRight();
}

/// Return [Middleware] that handles exceptions and generates Google Cloud
/// structured logs.
///
/// [projectId] is the Google Cloud Project ID used for trace correlation.
///
/// Logs messages sent to [currentLogger] and calls to [print] are formatted
/// to include trace correlation.
///
/// {@macro exceptionResponseMapping}
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
      LogSeverity logSeverity, {
      Map<String, Object?>? extraPayload,
    }) => structuredLogEntry(
      '$error'.trim(),
      logSeverity,
      payload: {...?traceContext?.asPayloadMap(), ...?extraPayload},
      stackTrace: stackTrace,
    );

    final completer = Completer<Response>.sync();

    void uncaughtErrorHandler(
      Zone self,
      ZoneDelegate parent,
      _,
      Object error,
      StackTrace stackTrace,
    ) {
      if (completer.isCompleted) return;
      if (error is HijackException) {
        completer.completeError(error, stackTrace);
        return;
      }

      final mainErrorString = switch (error) {
        HttpResponseException(innerError: final innerError?) =>
          '$error — Caused by: $innerError (${innerError.runtimeType})',
        _ => '$error',
      };

      final extraPayload = error is HttpResponseException
          ? <String, Object?>{
              ...error.toJson(),
              if (error.innerError != null)
                'inner_error': '${error.innerError}',
              if (error.innerStack != null)
                'inner_stack_trace': formatStackTrace(error.innerStack!),
            }
          : null;

      final logSeverity = error is HttpResponseException
          ? (error.statusCode >= 500 ? LogSeverity.error : LogSeverity.warning)
          : LogSeverity.error;

      final logContentString = createErrorLogEntryFromRequest(
        mainErrorString,
        error is HttpResponseException
            ? error.innerStack ?? stackTrace
            : stackTrace,
        logSeverity,
        extraPayload: extraPayload,
      );

      // Serialize to a JSON string and output.
      parent.print(self, logContentString);

      if (completer.isCompleted) {
        return;
      }

      final response = _responseFromException(
        error,
        stackTrace,
        request.headers,
      );

      completer.complete(response);
    }

    void zonePrint(Zone self, ZoneDelegate parent, _, String line) {
      final logContent = structuredLogEntry(
        line,
        LogSeverity.info,
        payload: traceContext?.asPayloadMap(),
      );

      // Serialize to a JSON string and output to parent zone.
      parent.print(self, logContent);
    }

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
            handleUncaughtError: uncaughtErrorHandler,
            print: zonePrint,
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
