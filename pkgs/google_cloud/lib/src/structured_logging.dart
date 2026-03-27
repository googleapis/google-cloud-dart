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

import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';

import 'logger.dart';

/// Creates a JSON-encoded log entry that conforms with
/// [structured logging](https://docs.cloud.google.com/logging/docs/structured-logging).
///
/// [message] is the log message. If it is a [Map], it is treated as the base
/// [payload], merging with any keys explicitly provided in the [payload]
/// parameter (with the parameter taking precedence). If the resulting merged
/// map contains a `"message"` key, it will be extracted and used as the entry's
/// message. If [message] is an empty `String` (or omitted via Map merging),
/// the message field is omitted from the resulting JSON completely.
/// For all other types, [Object.toString] or `toJson()` will be called.
///
/// [payload] is an optional map of additional fields to include in the log
/// entry. These fields will be merged into the JSON root.
///
/// [stackTrace] is an optional stack trace to include in the log entry.
/// It is serialized into the `stack_trace` field at the root of the JSON
/// payload. Google Cloud Error Reporting automatically parses this specific
/// field to group and track error events. See
/// [Formatting error messages](https://cloud.google.com/error-reporting/docs/formatting-error-messages)
/// for more details.
String structuredLogEntry(
  Object message,
  LogSeverity severity, {
  Map<String, Object?>? payload,
  StackTrace? stackTrace,
}) {
  var actualMessage = message;
  var actualPayload = payload;

  if (message is Map) {
    actualPayload = {
      for (final entry in message.entries) entry.key.toString(): entry.value,
      ...?payload,
    };
    if (actualPayload.containsKey('message')) {
      actualMessage = actualPayload.remove('message') ?? '';
    } else {
      actualMessage = '';
    }
  }

  final stackFrame = _debugFrame(severity, stackTrace: stackTrace);

  // https://cloud.google.com/logging/docs/agent/logging/configuration#special-fields
  String encode(Object innerMessage, Map<String, Object?>? innerPayload) =>
      jsonEncode(toEncodable: _toEncodableFallback, <String, dynamic>{
        ...?innerPayload,
        if (innerMessage != '') 'message': innerMessage,
        'severity': severity,
        if (stackTrace != null) 'stack_trace': formatStackTrace(stackTrace),
        if (stackFrame != null)
          'logging.googleapis.com/sourceLocation': _sourceLocation(stackFrame),
      });

  try {
    return encode(actualMessage, actualPayload);
    // ignore: avoid_catching_errors
  } on JsonUnsupportedObjectError catch (_) {
    // Fallback if there are cyclic errors parsing `payload` or `actualMessage`.
    // We omit the payload to guarantee a safe serialization.
    return encode(actualMessage.toString(), null);
  }
}

Object? _toEncodableFallback(Object? nonEncodable) {
  try {
    return (nonEncodable as dynamic).toJson();
  } catch (_) {
    return nonEncodable.toString();
  }
}

/// Returns a [Map] representing the source location of the given [frame].
///
/// See https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogEntrySourceLocation
Map<String, dynamic> _sourceLocation(Frame frame) => {
  // TODO: Will need to fix `package:` URIs to file paths when possible
  // GoogleCloudPlatform/functions-framework-dart#40
  'file': frame.uri.toString(),
  if (frame.line != null) 'line': frame.line.toString(),
  'function': frame.member,
};

Frame? _debugFrame(LogSeverity severity, {StackTrace? stackTrace}) {
  if (stackTrace == null) {
    if (severity >= LogSeverity.warning) {
      stackTrace = StackTrace.current;
    } else {
      return null;
    }
  }

  final chain = formatStackTrace(stackTrace);
  final stackFrame = chain.traces
      .expand((t) => t.frames)
      .firstWhere(
        (f) => !frameFolder(f),
        orElse: () => chain.traces.first.frames.first,
      );

  return stackFrame;
}
