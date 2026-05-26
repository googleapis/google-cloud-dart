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
import 'dart:collection';
import 'dart:convert';

import 'package:google_cloud_logging_type/logging_type.dart' show LogSeverity;
import 'package:google_cloud_logging_v2/logging.dart'
    show LogEntry, LogEntrySourceLocation;
import 'package:google_cloud_protobuf/protobuf.dart' show Struct;
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'traceparent.dart';

const _structuredLoggingFields = {
  'severity',
  'httpRequest',
  'time',
  'timestamp',
  'timestampSeconds',
  'timestampNanos',
  'logging.googleapis.com/insertId',
  'logging.googleapis.com/labels',
  'logging.googleapis.com/operation',
  'logging.googleapis.com/sourceLocation',
  'logging.googleapis.com/spanId',
  'logging.googleapis.com/trace',
  'logging.googleapis.com/trace_sampled',
};

Map<String, Object?> _filter(Map<dynamic, dynamic> m) => {
    for (final entry in m.entries)
      if (!_structuredLoggingFields.contains(entry.key.toString()))
        entry.key.toString(): entry.value,
};

/// Formats a log entry for Google Cloud structured logging on stdout.
String createStructuredLog(
  Object message,
  LogSeverity severity, {
  Map<String, Object?>? payload,
  String? traceparent,
  Zone? zone,
  StackTrace? stackTrace,
  String? projectId,
}) {
  final messageMap = switch (message) {
    '' => <String, Object?>{},
    Map() => _filter(message),
    _ => {'message': message},
  };

  final result = <String, Object?>{
    ...messageMap,
    ...(payload ?? {}),
    'severity': severity.value,
    ...(traceparent == null
        ? structuredTraceFromZone(projectId, zone)
        : formatTraceparent(projectId, traceparent)),
  };

  if (stackTrace case final stackTrace?) {
    result['stack_trace'] = _formatStackTrace(stackTrace).toString();
    result['logging.googleapis.com/sourceLocation'] = _sourceLocation(
      stackTrace,
    );
  }

  return jsonEncode(_sanitize(result), toEncodable: _toEncodableFallback);
}

/// Recursively traverses [value] and ensures all values are JSON primitives
/// (String, num, bool, null) or lists/maps of them, making it safe to pass to
/// [Struct.fromJson].
///
/// Objects that are not JSON primitives are converted using
/// [_toEncodableFallback].
Object? _sanitize(Object? value, [Set<Object>? seen]) {
  if (value == null || value is num || value is String || value is bool) {
    return value;
  }
  seen ??= HashSet.identity();
  if (seen.contains(value)) {
    return '[CIRCULAR]';
  }
  seen.add(value);

  try {
    if (value is List) {
      return value.map((e) => _sanitize(e, seen)).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v, seen)));
    }
    return _sanitize(_toEncodableFallback(value), seen);
  } finally {
    seen.remove(value);
  }
}

/// A fallback function for non-JSON-primitive objects.
///
/// Attempts to call `toJson()` on the object, and if that fails or is not
/// available, falls back to `toString()`.
Object? _toEncodableFallback(Object? nonEncodable) {
  try {
    return (nonEncodable as dynamic).toJson();
  } catch (_) {
    return nonEncodable.toString();
  }
}

/// Creates a [LogEntrySourceLocation] from the given [trace] by finding the
/// first frame that does not belong to this package.
LogEntrySourceLocation _sourceLocation(StackTrace trace) {
  final frame = _debugFrame(trace);
  return LogEntrySourceLocation(
    file: frame.uri.toString(),
    line: frame.line ?? 0,
    function: frame.member ?? '',
  );
}

/// Finds the first stack frame that is not considered a "folder" frame (i.e.,
/// not core or from this package).
Frame _debugFrame(StackTrace stackTrace) {
  final chain = _formatStackTrace(stackTrace);
  final stackFrame = chain.traces
      .expand((t) => t.frames)
      .firstWhere(
        (f) => !_frameFolder(f),
        orElse: () => chain.traces.first.frames.first,
      );

  return stackFrame;
}

/// Returns true if the frame is from `dart:` libraries or from this package.
bool _frameFolder(Frame frame) =>
    frame.isCore || frame.package == 'google_cloud_logging';

/// Formats the stack trace by folding frames that belong to this package or
/// core.
@internal
Chain _formatStackTrace(StackTrace stackTrace) =>
    Chain.forTrace(stackTrace).foldFrames(_frameFolder, terse: true);
