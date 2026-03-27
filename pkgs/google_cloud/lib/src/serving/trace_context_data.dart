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

import '../constants.dart';

/// Matches a 32-character hexadecimal value representing a 128-bit number.
///
/// See: https://cloud.google.com/trace/docs/setup#force-trace
final _traceIdRegExp = RegExp(r'^[a-f0-9]{32}$', caseSensitive: false);

/// Holds trace context data parsed by [TraceContextData.parse].
///
/// Used for structured logging.
final class TraceContextData {
  TraceContextData({
    required this.traceId,
    this.spanId,
    this.traceSampled = false,
  });

  /// Parses the [traceHeader] and returns a new instance.
  ///
  /// [traceHeader] is expected to be in the format
  /// `<trace-id>/<span-id>;o=<sampled>`.
  ///
  /// [traceHeader] is found in the HTTP header [cloudTraceContextHeader].
  ///
  /// Throws a [FormatException] if [traceHeader] is invalid.
  factory TraceContextData.parse({
    required String projectId,
    required String traceHeader,
  }) =>
      tryParse(projectId: projectId, traceHeader: traceHeader) ??
      (throw FormatException('Invalid trace header', traceHeader));

  /// Parses the [traceHeader] and returns a new instance, or `null` if invalid.
  ///
  /// [traceHeader] is expected to be in the format
  /// `<trace-id>/<span-id>;o=<sampled>`.
  ///
  /// [traceHeader] is found in the HTTP header [cloudTraceContextHeader].
  static TraceContextData? tryParse({
    required String projectId,
    required String traceHeader,
  }) {
    final parts = traceHeader.split('/');
    if (parts.isEmpty) return null;

    final traceId = parts[0];
    if (!_traceIdRegExp.hasMatch(traceId)) return null;

    final traceValue = 'projects/$projectId/traces/$traceId';

    String? spanId;
    var traceSampled = false;

    if (parts case [_, final optionsStr, ...]) {
      final [spanStr, ...rest] = optionsStr.split(';o=');
      spanId = BigInt.tryParse(spanStr)?.toRadixString(16).padLeft(16, '0');

      if (rest case [final sampledStr, ...]) {
        traceSampled = sampledStr == '1';
      }
    }
    return TraceContextData(
      traceId: traceValue,
      spanId: spanId,
      traceSampled: traceSampled,
    );
  }

  final String traceId;

  final String? spanId;

  final bool traceSampled;

  /// Returns a new map containing all key/value pairs from [existingPayload]
  /// plus the trace identifiers.
  ///
  /// If [existingPayload] is `null`, returns a new map containing only the
  /// trace identifiers.
  ///
  /// The returned map is a new instance and does not modify [existingPayload].
  ///
  /// The returned map is suitable for use as the payload in a structured log
  /// entry.
  Map<String, Object?> asPayloadMap([Map<String, Object?>? existingPayload]) =>
      {
        ...?existingPayload,
        logTraceKey: traceId,
        logSpanIdKey: spanId,
        if (traceSampled) logTraceSampledKey: true,
      };
}
