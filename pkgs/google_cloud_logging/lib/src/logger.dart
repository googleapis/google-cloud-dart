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

import 'dart:io';

import 'package:google_cloud_logging_type/logging_type.dart' as logging_type;
import 'package:logging/logging.dart' as logging;

import 'structured_logging.dart' show createStructuredLog;

/// A simple logger that outputs logging messages using [Structured logging][1].
///
/// When used with `package:google_cloud_shelf`, logs written using this logger
/// are automatically associated with the request that generated them.
///
/// You can also use structured logging indirectly through `package:logging`.
/// See [handleLogRecord].
///
/// [1] https://docs.cloud.google.com/logging/docs/structured-logging
final class StructuredLogger {
  final void Function(String s)? _writeln;

  void _print(String line) {
    if (_writeln == null) {
      stdout.writeln(line);
    } else {
      _writeln(line);
    }
  }

  const StructuredLogger({void Function(String s)? writeln})
    : _writeln = writeln;

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
    StackTrace? stackTrace,
  }) {
    final logEntry = createStructuredLog(
      message,
      severity,
      stackTrace: stackTrace,
    );
    _print(logEntry);
  }

  /// Logs [message] using [log] at [logging_type.LogSeverity.debug] severity.
  void debug(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.debug, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.info] severity.
  void info(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.info, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.notice] severity.
  void notice(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.notice, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.warning] severity.
  void warning(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.warning, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.error] severity.
  void error(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.error, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.critical]
  /// severity.
  void critical(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.critical, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.alert] severity.
  void alert(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.alert, stackTrace: stackTrace);

  /// Logs [message] using [log] at [logging_type.LogSeverity.emergency]
  /// severity.
  void emergency(Object message, {StackTrace? stackTrace}) =>
      log(message, logging_type.LogSeverity.emergency, stackTrace: stackTrace);

  /// A handler for streams of [logging.LogRecord] provided by a
  /// `package:logging` [logging.Logger].
  ///
  /// You can configure `package:logging` to redirect all logs globally with
  /// this setup:
  ///
  /// ```dart
  /// import 'package:google_cloud_logging/google_cloud_logging.dart';
  /// import 'package:logging/logging.dart';
  ///
  /// void main() {
  ///   Logger.root.onRecord.listen(const StructuredLogger().handleLogRecord);
  ///   Logger.root.level = Level.ALL;
  ///
  ///   // Use `package:logging` as normal.
  /// }
  /// ```
  void handleLogRecord(logging.LogRecord record) {
    final severity = _severityFromLoggingLevel(record.level);

    // Determine if there's structured payload data.
    final extra = {'loggerName': record.loggerName, 'error': ?record.error};

    final logStr = createStructuredLog(
      record.object ?? record.message,
      severity,
      payload: extra,
      zone: record.zone,
      stackTrace: record.stackTrace,
    );
    _print(logStr);
  }

  logging_type.LogSeverity _severityFromLoggingLevel(logging.Level level) {
    if (level <= logging.Level.FINE) {
      return logging_type.LogSeverity.debug;
    } else if (level <= logging.Level.INFO) {
      return logging_type.LogSeverity.info;
    } else if (level <= logging.Level.WARNING) {
      return logging_type.LogSeverity.warning;
    } else if (level <= logging.Level.SEVERE) {
      return logging_type.LogSeverity.error;
    } else if (level <= logging.Level.SHOUT) {
      return logging_type.LogSeverity.critical;
    } else {
      return logging_type.LogSeverity.emergency;
    }
  }
}
