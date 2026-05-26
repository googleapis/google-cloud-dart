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
import 'package:logging/logging.dart' as logging;

import 'structured_logging.dart';

// https://github.com/googleapis/google-cloud-python/blob/3ef95d61995869318097e414e439da1d6c214d1f/packages/google-cloud-logging/google/cloud/logging_v2/handlers/structured_log.py#L62

/// Handler to format logs into the Cloud Logging structured log format, and
/// write them to standard output.
final class StructuredLogHandler {
  final String? _projectId;

  final void Function(String s) _writeln;

  StructuredLogHandler({String? projectId, void Function(String s)? writeln})
    : _projectId = projectId,
      _writeln = writeln ?? stdout.writeln;

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
    final extra = {'loggerName': record.loggerName, 'error': ?record.error};

    final logStr = createStructuredLog(
      record.object ?? record.message,
      severity,
      payload: extra,
      zone: record.zone,
      projectId: _projectId,
      stackTrace: record.stackTrace,
    );
    _writeln(logStr);
  }

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
