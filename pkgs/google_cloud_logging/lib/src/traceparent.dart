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

import 'dart:async';

import 'package:meta/meta.dart';

/// The `payload` key used to correlate log entries with Cloud Trace.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const _logTraceKey = 'logging.googleapis.com/trace';

/// The `payload` key used to correlate log entries with a specific span within
/// a Cloud Trace.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const _logSpanIdKey = 'logging.googleapis.com/spanId';

/// The `payload` key used to indicate whether a trace is sampled.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const _logTraceSampledKey = 'logging.googleapis.com/trace_sampled';

/// The `payload` key used to indicate whether a trace is sampled.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields

// See:
// https://www.w3.org/TR/trace-context/#traceparent-header-field-values

const _version = r'^(?!ff)(?<version>[0-9a-f]{2})';
const _trace = r'(?!0{32})(?<trace>[0-9a-f]{32})';
const _parent = r'(?!0{16})(?<parent>[0-9a-f]{16})';
const _flags = r'(?<flags>[0-9a-f]{2})';
final _traceParentRegex = RegExp('$_version-$_trace-$_parent-$_flags');

/// Parsers a `'traceparent'` header.
///
/// See https://www.w3.org/TR/trace-context/
@visibleForTesting
({String traceId, String spanId, bool traceSampled})? parseTraceparent(
  String traceparent,
) {
  final match = _traceParentRegex.firstMatch(traceparent);
  if (match == null) return null;

  final flags = int.parse(match.namedGroup('flags')!, radix: 16);
  return (
    traceId: match.namedGroup('trace')!,
    spanId: match.namedGroup('parent')!,
    traceSampled: flags & 1 == 1,
  );
}

@internal
Map<String, Object> formatTraceparent(String? projectId, String? traceparent) {
  if (traceparent == null) return {};
  final x = parseTraceparent(traceparent);
  if (x == null) return {};

  return {
    if (projectId != null)
      _logTraceKey: 'projects/$projectId/traces/${x.traceId}',
    _logSpanIdKey: x.spanId,
    _logTraceSampledKey: x.traceSampled,
  };
}

@internal
Map<String, Object> structuredTraceFromZone(String? projectId, [Zone? zone]) {
  final traceparent = (zone ?? Zone.current)['traceparent'];
  final String? calculatedProjectId;
  if (projectId == null) {
    calculatedProjectId =
        (zone ?? Zone.current)['google_cloud_project'] as String?;
  } else {
    calculatedProjectId = projectId;
  }

  if (traceparent is String) {
    return formatTraceparent(calculatedProjectId, traceparent);
  } else {
    return {};
  }
}
