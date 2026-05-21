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

/// Formats a log entry for Google Cloud structured logging on stdout.
String createStructuredLog(
  Object message,
  LogSeverity severity, {
  Map<String, Object?> extraFields = const {},
  String? traceparent,
  Zone? zone,
  StackTrace? stackTrace,
}) {
  final payload = <String, Object?>{
    'severity': severity.value,
    ...(traceparent == null
        ? structuredTraceFromZone(zone)
        : formatTraceparent(traceparent)),
  };

  if (message is Map) {
    payload.addAll({
      for (final entry in message.entries)
        if (!_structuredLoggingFields.contains(entry.key.toString()))
          entry.key.toString(): entry.value,
    });
  } else {
    payload['message'] = message.toString();
  }

  if (stackTrace case final stackTrace?) {
    payload['logging.googleapis.com/sourceLocation'] = sourceLocation(
      stackTrace,
    );
  }

  return jsonEncode(sanitize(payload), toEncodable: toEncodableFallback,
    );
}

/// Recursively traverses [value] and ensures all values are JSON primitives
/// (String, num, bool, null) or lists/maps of them, making it safe to pass to
/// [Struct.fromJson].
///
/// Objects that are not JSON primitives are converted using
/// [toEncodableFallback].
///
/// Throws a [FormatException] if a cyclic reference is detected.
Object? sanitize(Object? value, [Set<Object>? seen]) {
  if (value == null || value is num || value is String || value is bool) {
    return value;
  }
  seen ??= <Object>{};
  if (seen.contains(value)) {
    return '[CIRCULAR]';
  }
  seen.add(value);

  try {
    if (value is List) {
      return value.map((e) => sanitize(e, seen)).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), sanitize(v, seen)));
    }
    return sanitize(toEncodableFallback(value), seen);
  } finally {
    seen.remove(value);
  }
}

/// A fallback function for non-JSON-primitive objects.
///
/// Attempts to call `toJson()` on the object, and if that fails or is not
/// available, falls back to `toString()`.
Object? toEncodableFallback(Object? nonEncodable) {
  try {
    return (nonEncodable as dynamic).toJson();
  } catch (_) {
    return nonEncodable.toString();
  }
}

/// Creates a [LogEntrySourceLocation] from the given [trace] by finding the
/// first frame that does not belong to this package.
LogEntrySourceLocation sourceLocation(StackTrace trace) {
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
  final chain = formatStackTrace(stackTrace);
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
Chain formatStackTrace(StackTrace stackTrace) =>
    Chain.forTrace(stackTrace).foldFrames(_frameFolder, terse: true);
