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

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:grpc/grpc.dart';
import 'package:meta/meta.dart';

const _sentinel = Object();
const _defaultTotalTimeout = Duration(minutes: 1);
const _sentinelTimeout = Duration(microseconds: -1);

/// Settings for configuring retry logic with exponential backoff.
final class RetrySettings {
  /// The maximum number of times to retry before failing.
  ///
  /// A `null` value indicates that the number of retries is unlimited.
  final int? maxRetries;

  /// The maximum amount of total time to retry before failing.
  ///
  /// A `null` value indicates that the total retry time is unlimited.
  final Duration? totalTimeout;

  /// Deprecated: Use [totalTimeout] instead.
  @Deprecated('Use totalTimeout instead')
  Duration? get maxRetryInterval => totalTimeout;

  /// The minimum amount of time to wait before retrying.
  final Duration initialDelay;

  /// The multiplier for the wait time between retries.
  final double delayMultiplier;

  /// The maximum amount of time to wait between retries.
  ///
  /// If the calculated exponential wait time between retries exceeds this
  /// value, the wait time will be clamped to this value.
  final Duration maxDelay;

  final bool _hasExplicitTotalTimeout;

  /// Whether [totalTimeout] (or [maxRetryInterval]) was explicitly specified.
  @internal
  bool get hasExplicitTotalTimeout => _hasExplicitTotalTimeout;

  const RetrySettings({
    this.maxRetries,
    this.initialDelay = const Duration(milliseconds: 100),
    this.delayMultiplier = 1.3,
    this.maxDelay = const Duration(seconds: 60),
    Duration? totalTimeout = _sentinelTimeout,
    @Deprecated('Use totalTimeout instead') Duration? maxRetryInterval,
  }) : totalTimeout =
           maxRetryInterval ??
           (identical(totalTimeout, _sentinelTimeout)
               ? _defaultTotalTimeout
               : totalTimeout),
       _hasExplicitTotalTimeout =
           !identical(totalTimeout, _sentinelTimeout) ||
           maxRetryInterval != null,
       assert(
         maxRetries == null || maxRetries >= 0,
         'maxRetries must be non-negative',
       ),
       assert(
         !identical(initialDelay, Duration.zero),
         'initialDelay must be greater than zero',
       ),
       assert(delayMultiplier >= 1.0, 'delayMultiplier must be at least 1.0'),
       assert(
         !identical(maxDelay, Duration.zero),
         'maxDelay must be greater than zero',
       ),
       assert(
         maxRetryInterval == null ||
             !identical(maxRetryInterval, Duration.zero),
         'maxRetryInterval must be greater than zero',
       ),
       assert(
         identical(totalTimeout, _sentinelTimeout) ||
             totalTimeout == null ||
             !identical(totalTimeout, Duration.zero),
         'totalTimeout must be greater than zero',
       );

  const RetrySettings._internal({
    required this.maxRetries,
    required this.totalTimeout,
    required this.initialDelay,
    required this.delayMultiplier,
    required this.maxDelay,
    required bool hasExplicitTotalTimeout,
  }) : _hasExplicitTotalTimeout = hasExplicitTotalTimeout,
       assert(
         maxRetries == null || maxRetries >= 0,
         'maxRetries must be non-negative',
       ),
       assert(
         !identical(initialDelay, Duration.zero),
         'initialDelay must be greater than zero',
       ),
       assert(delayMultiplier >= 1.0, 'delayMultiplier must be at least 1.0'),
       assert(
         !identical(maxDelay, Duration.zero),
         'maxDelay must be greater than zero',
       ),
       assert(
         totalTimeout == null || !identical(totalTimeout, Duration.zero),
         'totalTimeout must be greater than zero',
       );

  /// Creates a copy of this [RetrySettings] with the given fields replaced.
  RetrySettings copyWith({
    Object? maxRetries = _sentinel,
    Object? totalTimeout = _sentinel,
    Duration? initialDelay,
    double? delayMultiplier,
    Duration? maxDelay,
  }) => RetrySettings._internal(
    maxRetries: identical(maxRetries, _sentinel)
        ? this.maxRetries
        : maxRetries as int?,
    totalTimeout: identical(totalTimeout, _sentinel)
        ? this.totalTimeout
        : totalTimeout as Duration?,
    initialDelay: initialDelay ?? this.initialDelay,
    delayMultiplier: delayMultiplier ?? this.delayMultiplier,
    maxDelay: maxDelay ?? this.maxDelay,
    hasExplicitTotalTimeout:
        !identical(totalTimeout, _sentinel) || _hasExplicitTotalTimeout,
  );
}

/// Generates wait durations for exponential backoff according to
/// [RetrySettings].
///
/// Uses `clock` to enforce [totalTimeout].
@internal
Iterable<Duration> delaySequence({
  int? maxRetries,
  Duration? totalTimeout = const Duration(minutes: 1),
  @Deprecated('Use totalTimeout instead') Duration? maxRetryInterval,
  required Duration initialDelay,
  required Duration maxDelay,
  required double delayMultiplier,
  Clock clock = const Clock(),
  Random? random,
}) sync* {
  final timeout = maxRetryInterval ?? totalTimeout;
  final noRetriesAfter = timeout == null ? null : clock.fromNowBy(timeout);
  final rng = random ?? Random();
  var reachedMax = false;
  for (var i = 0; (maxRetries == null) || (i < maxRetries); i++) {
    if (noRetriesAfter != null && clock.now().isAfter(noRetriesAfter)) {
      break;
    }
    final baseDelay = reachedMax
        ? maxDelay
        : initialDelay * pow(delayMultiplier, i);
    if (!reachedMax && baseDelay >= maxDelay) {
      reachedMax = true;
    }
    final effectiveBase = reachedMax ? maxDelay : baseDelay;
    final jitterFactor = 0.8 + 0.4 * rng.nextDouble();
    yield Duration(
      microseconds: (effectiveBase.inMicroseconds * jitterFactor).round(),
    );
  }
}

/// Returns whether [e] is considered a retryable error.
@internal
bool isRetryable(Object e) {
  if (e is! Exception) return false;
  return switch (e) {
    GrpcError(:final code) => switch (code) {
      StatusCode.aborted ||
      StatusCode.deadlineExceeded ||
      StatusCode.internal ||
      StatusCode.resourceExhausted ||
      StatusCode.unavailable ||
      StatusCode.unknown => true,
      _ => false,
    },
    ConflictException(:final status) when status?.code == StatusCode.aborted =>
      true,
    ServiceException(:final statusCode) when statusCode == StatusCode.aborted =>
      true,
    ServiceUnavailableException() ||
    GatewayTimeoutException() ||
    TooManyRequestsException() => true,
    InternalServerErrorException(:final status) =>
      status?.code != StatusCode.dataLoss,
    _ => false,
  };
}

/// Runs [body] with exponential backoff retries.
///
/// Only transient gRPC errors and retryable [ServiceException]s are retried.
/// If [isIdempotent] is `false`, the operation is never retried and the first
/// error is rethrown.
Future<T> runWithRetry<T>(
  Future<T> Function() body, {
  required RetrySettings settings,
  required bool isIdempotent,
}) async {
  final delays = delaySequence(
    maxRetries: settings.maxRetries,
    totalTimeout: settings.totalTimeout,
    initialDelay: settings.initialDelay,
    maxDelay: settings.maxDelay,
    delayMultiplier: settings.delayMultiplier,
  ).iterator;

  while (true) {
    try {
      return await body();
    } on Exception catch (e) {
      if (!isIdempotent || !isRetryable(e)) rethrow;

      if (delays.moveNext()) {
        await Future<void>.delayed(delays.current);
      } else {
        rethrow;
      }
    }
  }
}
