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

/// @docImport 'structured_logging.dart';
library;

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

/// See https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#logseverity
enum LogSeverity implements Comparable<LogSeverity> {
  defaultSeverity._(0, 'DEFAULT'),
  debug._(100, 'DEBUG'),
  info._(200, 'INFO'),
  notice._(300, 'NOTICE'),
  warning._(400, 'WARNING'),
  error._(500, 'ERROR'),
  critical._(600, 'CRITICAL'),
  alert._(700, 'ALERT'),
  emergency._(800, 'EMERGENCY');

  final int value;
  final String name;

  const LogSeverity._(this.value, this.name);

  @override
  int compareTo(LogSeverity other) => value.compareTo(other.value);

  bool operator <(LogSeverity other) => value < other.value;

  bool operator <=(LogSeverity other) => value <= other.value;

  bool operator >(LogSeverity other) => value > other.value;

  bool operator >=(LogSeverity other) => value >= other.value;

  @override
  String toString() => 'LogSeverity $name ($value)';

  String toJson() => name;
}

/// Allows logging at a specified severity.
///
/// Compatible with the
/// [log severities](https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#logseverity)
/// supported by Google Cloud.
abstract base class CloudLogger {
  /// Const constructor for subclasses.
  const CloudLogger();

  /// The default logger.
  ///
  /// This logger prints messages to the console.
  ///
  /// The output format is:
  /// `[SEVERITY_NAME: ]<message>[ payload][ labels][\nstack_trace]`
  ///
  /// The `SEVERITY_NAME: ` prefix is omitted when the severity is
  /// [LogSeverity.defaultSeverity].
  const factory CloudLogger.defaultLogger() = _DefaultLogger;

  /// Logs [message] at the given [severity].
  ///
  /// {@template google_cloud.CloudLogger.log_params}
  /// Details on how the parameters are handled can be found depend on the
  /// implementation.
  ///
  /// See [CloudLogger.defaultLogger] and [structuredLogEntry] for more
  /// information.
  /// {@endtemplate}
  void log(
    Object message,
    LogSeverity severity, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  });

  /// Logs [message] at [LogSeverity.debug] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void debug(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.debug,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.info] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void info(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.info,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.notice] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void notice(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.notice,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.warning] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void warning(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.warning,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.error] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void error(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.error,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.critical] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void critical(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.critical,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.alert] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void alert(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.alert,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );

  /// Logs [message] at [LogSeverity.emergency] severity.
  ///
  /// {@macro google_cloud.CloudLogger.log_params}
  void emergency(
    Object message, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) => log(
    message,
    LogSeverity.emergency,
    payload: payload,
    labels: labels,
    stackTrace: stackTrace,
  );
}

/// The implementation for [CloudLogger.defaultLogger].
final class _DefaultLogger extends CloudLogger {
  /// Const constructor.
  const _DefaultLogger();

  @override
  void log(
    Object message,
    LogSeverity severity, {
    Map<String, Object?>? payload,
    Map<String, String>? labels,
    StackTrace? stackTrace,
  }) {
    final payloadStr = payload != null && payload.isNotEmpty ? ' $payload' : '';
    final labelsStr = labels != null && labels.isNotEmpty ? ' $labels' : '';
    final traceStr = stackTrace != null
        ? '\n${formatStackTrace(stackTrace)}'
        : '';
    if (severity == LogSeverity.defaultSeverity) {
      print('$message$payloadStr$labelsStr$traceStr');
    } else {
      print('${severity.name}: $message$payloadStr$labelsStr$traceStr');
    }
  }
}

@internal
bool frameFolder(Frame frame) =>
    frame.isCore || frame.package == 'google_cloud';

@internal
Chain formatStackTrace(StackTrace? stackTrace) =>
    (stackTrace == null ? Chain.current() : Chain.forTrace(stackTrace))
        .foldFrames(frameFolder, terse: true);
