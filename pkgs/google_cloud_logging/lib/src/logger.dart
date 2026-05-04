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

import 'package:google_cloud_logging_type/logging_type.dart' as logging_type;

import 'structured_logging.dart' show createStructuredLog;

/// Base class for logging.
///
/// Extend this class to create your own logger or use the
/// [CloudLogger.printLogger] factory.
abstract base class CloudLogger {
  const CloudLogger();

  /// Creates a logger that outputs log messages using [print].
  const factory CloudLogger.printLogger() = _DefaultLogger;

  /// Creates a logger that outputs log messages in Cloud Logging structured
  /// format.
  const factory CloudLogger.structuredLogger() = _StructuredLogger;

  /// Logs a message at the given [severity].
  ///
  /// The available severity levels represent the standard Google Cloud logging
  /// severities:
  /// * `DEFAULT` (0): The log entry has no assigned severity level.
  /// * `DEBUG` (100): Debug or trace information.
  /// * `INFO` (200): Routine information, such as ongoing status or
  ///   performance.
  /// * `NOTICE` (300): Normal but significant events, such as start up,
  ///   shut down, or a configuration change.
  /// * `WARNING` (400): Warning events might cause problems.
  /// * `ERROR` (500): Error events are likely to cause problems.
  /// * `CRITICAL` (600): Critical events cause more severe problems or
  ///   outages.
  /// * `ALERT` (700): A person must take an action immediately.
  /// * `EMERGENCY` (800): One or more systems are unusable.
  ///
  /// See [Google Cloud LogSeverity documentation](https://docs.cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity).
  void log(
    Object message,
    logging_type.LogSeverity severity, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  });

  /// Logs [message] using [log] at [logging_type.LogSeverity.debug] severity.
  void debug(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.debug,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.info] severity.
  void info(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.info,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.notice] severity.
  void notice(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.notice,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.warning] severity.
  void warning(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.warning,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.error] severity.
  void error(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.error,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.critical]
  /// severity.
  void critical(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.critical,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.alert] severity.
  void alert(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.alert,
    payload: payload,
    stackTrace: stackTrace,
  );

  /// Logs [message] using [log] at [logging_type.LogSeverity.emergency]
  /// severity.
  void emergency(
    Object message, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) => log(
    message,
    logging_type.LogSeverity.emergency,
    payload: payload,
    stackTrace: stackTrace,
  );
}

final class _DefaultLogger extends CloudLogger {
  const _DefaultLogger();

  @override
  void log(
    Object message,
    logging_type.LogSeverity severity, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) {
    final payloadStr = payload != null && payload.isNotEmpty ? ' $payload' : '';
    final traceStr = stackTrace != null ? '\n$stackTrace' : '';
    if (severity == logging_type.LogSeverity.$default) {
      print('$message$payloadStr$traceStr');
    } else {
      print('${severity.value}: $message$payloadStr$traceStr');
    }
  }
}

final class _StructuredLogger extends CloudLogger {
  const _StructuredLogger();

  @override
  void log(
    Object message,
    logging_type.LogSeverity severity, {
    Map<String, Object?>? payload,
    StackTrace? stackTrace,
  }) {
    final logEntry = createStructuredLog(
      message,
      severity,
      payload: payload,
      stackTrace: stackTrace,
    );
    print(logEntry);
  }
}
