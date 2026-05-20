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

import 'package:google_cloud_logging_type/logging_type.dart';
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:logger/logger.dart' as logger;
import 'package:logging/logging.dart' as logging;

import 'structured_logging.dart';

/// Handler to format logs into the Cloud Logging structured log format, and
/// write them to standard output.
final class StructuredLogHandler {
  /// Outputs a [LogEntry] to stdout in the Google Cloud structured log format.
  void handleLogEntry(LogEntry entry) {
    stdout.writeln(createStructuredLogFromEntry(entry));
  }

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
  ///   Logger.root.onRecord.listen(StructuredLogHandler().handleLogRecord);
  ///   Logger.root.level = Level.ALL;
  ///
  ///   // Use `package:logging` as normal.
  /// }
  /// ```
  void handleLogRecord(logging.LogRecord record) {
    final severity = _severityFromLoggingLevel(record.level);

    // Determine if there's structured payload data.
    Map<String, Object?>? payload;
    final error = record.error;
    final object = record.object;

    if (object is Map) {
      payload = {
        for (final entry in object.entries) entry.key.toString(): entry.value,
      };
    } else if (error is Map) {
      payload = {
        for (final entry in error.entries) entry.key.toString(): entry.value,
      };
    } else {
      if (object != null) {
        payload = {'object': object};
      }
      if (error != null) {
        payload = {...?payload, 'error': error.toString()};
      }
    }

    // If they logged a Map directly, e.g., logger.info({'foo': 'bar'}),
    // standard logging's message is the stringified map. In that case,
    // we pass an empty string to avoid a redundant stringified map message.
    final message = (object is Map && record.message == object.toString())
        ? ''
        : record.message;

    final logStr = createStructuredLog(
      message,
      severity,
      payload: payload,
      stackTrace:
          record.stackTrace ?? (error is! Map ? record.stackTrace : null),
    );

    stdout.writeln(logStr);
  }

  /// Returns a [logger.LogOutput] for use with `package:logger`'s `Logger`.
  ///
  /// ```dart
  /// import 'package:google_cloud_logging/google_cloud_logging.dart';
  /// import 'package:logger/logger.dart';
  ///
  /// void main() {
  ///   final logger = Logger(
  ///     output: StructuredLogHandler().asLogOutput(),
  ///   );
  ///
  ///   // Use logger as normal.
  /// }
  /// ```
  logger.LogOutput asLogOutput() => _StructuredLogOutput();

  LogSeverity _severityFromLoggingLevel(logging.Level level) {
    if (level <= logging.Level.FINE) {
      return LogSeverity.debug;
    } else if (level <= logging.Level.INFO) {
      return LogSeverity.info;
    } else if (level <= logging.Level.WARNING) {
      return LogSeverity.warning;
    } else if (level <= logging.Level.SEVERE) {
      return LogSeverity.error;
    } else if (level <= logging.Level.SHOUT) {
      return LogSeverity.critical;
    } else {
      return LogSeverity.emergency;
    }
  }
}

/// Internal implementation of `logger.LogOutput` for `package:logger`.
class _StructuredLogOutput extends logger.LogOutput {
  _StructuredLogOutput();

  @override
  void output(logger.OutputEvent event) {
    final origin = event.origin;
    final severity = _severityFromLoggerLevel(origin.level);

    Map<String, Object?>? payload;
    final error = origin.error;
    if (error is Map) {
      payload = {
        for (final entry in error.entries) entry.key.toString(): entry.value,
      };
    } else if (error != null) {
      payload = {'error': error.toString()};
    }

    final logStr = createStructuredLog(
      origin.message as Object,
      severity,
      payload: payload,
      stackTrace: origin.stackTrace,
    );

    stdout.writeln(logStr);
  }

  LogSeverity _severityFromLoggerLevel(logger.Level level) => switch (level) {
    logger.Level.trace => LogSeverity.debug,
    logger.Level.debug => LogSeverity.debug,
    logger.Level.info => LogSeverity.info,
    logger.Level.warning => LogSeverity.warning,
    logger.Level.error => LogSeverity.error,
    logger.Level.fatal => LogSeverity.critical,
    _ => LogSeverity.$default,
  };
}
