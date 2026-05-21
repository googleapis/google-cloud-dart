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

/// Key to store/retrieve trace correlation payload in the [Zone].
///
/// The value associated with this key should be a `Map<String, Object?>`
/// containing the structured log fields for trace, spanId, and traceSampled.
const logContextZoneKey = #google_cloud_logging.log_context;

/// Converts [entry] to a JSON string formatted for Google Cloud
/// structured logging on stdout.
///
/// This flattens [LogEntry.jsonPayload] into the root object and remaps special
/// fields like `trace` and `spanId` to `logging.googleapis.com/` prefixed keys.
String createStructuredLogFromEntry(LogEntry entry) {
  final map = entry.toJson() as Map<String, dynamic>;

  if (map['logName'] == '') {
    map.remove('logName');
  }

  if (!map.containsKey('severity')) {
    map['severity'] = LogSeverity.$default.value;
  }

  // Flatten jsonPayload
  if (map.containsKey('jsonPayload')) {
    final jsonPayload = map.remove('jsonPayload');
    if (jsonPayload is Map<String, Object?>) {
      // Remove fields that are already in the root to prevent overriding core
      // fields
      for (final key in map.keys) {
        jsonPayload.remove(key);
      }
      map.addAll(jsonPayload);
    }
  }

  // Remap special fields to Google Cloud structured logging format
  for (final MapEntry(key: sourceKey, value: destinationKey)
      in _specialFieldsMapping.entries) {
    if (map.containsKey(sourceKey)) {
      map[destinationKey] = map.remove(sourceKey);
    }
  }

  return jsonEncode(map, toEncodable: toEncodableFallback);
}

// Special fields that need to be mapped to google cloud format
//
// https://docs.cloud.google.com/logging/docs/structured-logging
const _specialFieldsMapping = {
  'trace': 'logging.googleapis.com/trace',
  'spanId': 'logging.googleapis.com/spanId',
  'traceSampled': 'logging.googleapis.com/trace_sampled',
  'sourceLocation': 'logging.googleapis.com/sourceLocation',
  'textPayload': 'message',
};

/// Formats a log entry for Google Cloud structured logging on stdout.
///
/// Prepares the log entry by integrating the [message], [severity], and
/// optional [payload]. If [stackTrace] is provided, it is automatically
/// stringified and safely attached to the payload.
String createStructuredLog(
  Object message,
  LogSeverity severity, {
  Map<String, Object?>? payload,
  StackTrace? stackTrace,
}) {
  var actualMessage = message;
  var actualPayload = payload;

  // Retrieve the zone trace/log context if present
  final zoneContext = Zone.current[logContextZoneKey] as Map<String, Object?>?;
  if (zoneContext != null && zoneContext.isNotEmpty) {
    actualPayload = {...zoneContext, ...?actualPayload};
  }

  if (message is Map) {
    // If the message itself is a Map, we normalize its keys to Strings and
    // merge in any explicitly provided payload entries. Explicit payload
    // values take precedence over values found in the message Map.
    actualPayload = {
      for (final entry in message.entries) entry.key.toString(): entry.value,
      ...?payload,
    };
    actualMessage = actualPayload.remove('message') ?? '';
  }

  // Add stack trace to payload as string to avoid Struct conversion failures
  if (stackTrace != null) {
    actualPayload = {
      ...?actualPayload,
      'stack_trace': formatStackTrace(stackTrace).toString(),
    };
  }

  // Add message to payload if not empty, so it supports lists and maps
  if (actualMessage != '') {
    actualPayload = {...?actualPayload, 'message': actualMessage};
  }

  try {
    final entry = LogEntry(
      logName: '',
      resource: null,
      severity: severity,
      jsonPayload: actualPayload != null && actualPayload.isNotEmpty
          ? Struct.fromJson(sanitize(actualPayload) as Map<dynamic, dynamic>)
          : null,
      sourceLocation: stackTrace != null ? sourceLocation(stackTrace) : null,
    );

    return createStructuredLogFromEntry(entry);
  } on FormatException catch (_) {
    // Fallback if there are cyclic errors parsing `payload` or invalid values.
    // We omit the payload to guarantee a safe serialization.
    final entry = LogEntry(
      logName: '',
      resource: null,
      severity: severity,
      textPayload: actualMessage != '' ? actualMessage.toString() : null,
      sourceLocation: stackTrace != null ? sourceLocation(stackTrace) : null,
    );
    return createStructuredLogFromEntry(entry);
  }
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
    throw const FormatException('Cyclic reference');
  }
  seen.add(value);

  try {
    if (value is List) {
      return value.map((e) => sanitize(e, seen)).toList();
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), sanitize(v, seen)));
    }
    return toEncodableFallback(value);
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
