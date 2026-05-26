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
abstract base class CloudLogger {
  const CloudLogger();

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
  });

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
}

final class StructuredLogger extends CloudLogger {
  final String? _projectId;
  const StructuredLogger({String? projectId}) : _projectId = projectId;

  @override
  void log(
    Object message,
    logging_type.LogSeverity severity, {
    StackTrace? stackTrace,
  }) {
    final logEntry = createStructuredLog(
      message,
      severity,
      projectId: _projectId,
      stackTrace: stackTrace,
    );
    print(logEntry);
  }
}
