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
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'exceptions.dart';

/// An abstract class for running a function with retry logic.
sealed class RetryRunner {
  /// Runs the given function with retry logic.
  Future<T> run<T>(
    Future<T> Function() body, {
    required bool isIdempotent,
    Clock clock = const Clock(),
  });

  /// Returns whether [error] is considered retryable by this runner.
  bool isRetryable(Object error);

  /// Generates a sequence of wait durations for retries or reconnections.
  Iterable<Duration> delays({Clock clock = const Clock(), Random? random});
}

/// Returns whether [error] is considered a transient, retryable error by
/// default.
bool defaultIsRetryable(Object error) {
  if (error is! Exception) return false;
  return switch (error) {
    // InternalServerErrorException (HTTP 500 / gRPC INTERNAL or UNKNOWN) is
    // retryable unless it carries gRPC status DATA_LOSS (code 15).
    InternalServerErrorException(:final status) => status?.code != 15,
    // ConflictException (HTTP 409 / gRPC ALREADY_EXISTS) is not retryable
    // unless it carries gRPC status ABORTED (code 10).
    ConflictException(:final status) => status?.code == 10,
    BadGatewayException() ||
    RequestTimeoutException() ||
    ServiceUnavailableException() ||
    GatewayTimeoutException() ||
    TooManyRequestsException() => true,
    ServiceException(:final status, :final statusCode) =>
      switch (status?.code) {
        // gRPC status codes: UNKNOWN(2), DEADLINE_EXCEEDED(4),
        // RESOURCE_EXHAUSTED(8), ABORTED(10), INTERNAL(13), UNAVAILABLE(14).
        2 || 4 || 8 || 10 || 13 || 14 => true,
        null =>
          statusCode == 408 ||
              statusCode == 429 ||
              statusCode == 500 ||
              statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504,
        _ => false,
      },
    http.ClientException() => true,
    ChecksumValidationException() => true,
    _ => false,
  };
}

/// Generates a sequence of delays for exponential backoff.
///
/// For example:
///
/// ```dart
/// delaySequence(
///     maxRetries: 6,
///     initialDelay: Duration(seconds: 1),
///     maxDelay: Duration(seconds: 10),
///     delayMultiplier: 2);
/// // [
/// //   Duration(seconds: 1),
/// //   Duration(seconds: 2),
/// //   Duration(seconds: 4),
/// //   Duration(seconds: 8),
/// //   Duration(seconds: 10),
/// //   Duration(seconds: 10),
/// // ]
/// ```
///
/// If `maxRetryInterval` is set then the sequence must be iterated-over in
/// real time.
@visibleForTesting
Iterable<Duration> delaySequence({
  int? maxRetries,
  Duration? maxRetryInterval,
  required Duration initialDelay,
  required Duration maxDelay,
  required double delayMultiplier,
  double jitter = 0.0,
  Clock clock = const Clock(),
  Random? random,
}) {
  final noRetriesAfter = maxRetryInterval == null
      ? null
      : clock.fromNowBy(maxRetryInterval);
  return _delaySequence(
    maxRetries: maxRetries,
    noRetriesAfter: noRetriesAfter,
    initialDelay: initialDelay,
    maxDelay: maxDelay,
    delayMultiplier: delayMultiplier,
    jitter: jitter,
    clock: clock,
    random: random,
  );
}

Iterable<Duration> _delaySequence({
  required int? maxRetries,
  required DateTime? noRetriesAfter,
  required Duration initialDelay,
  required Duration maxDelay,
  required double delayMultiplier,
  required double jitter,
  required Clock clock,
  required Random? random,
}) sync* {
  var reachedMax = false;
  final randomGenerator = jitter == 0.0 ? null : (random ?? Random());
  for (var i = 0; (maxRetries == null) || (i < maxRetries); i++) {
    if (noRetriesAfter != null && clock.now().isAfter(noRetriesAfter)) {
      break;
    }

    final Duration baseDelay;
    if (reachedMax) {
      baseDelay = maxDelay;
    } else {
      final multiplier = pow(delayMultiplier, i);
      if (!multiplier.isFinite ||
          initialDelay.inMicroseconds * multiplier >= maxDelay.inMicroseconds) {
        reachedMax = true;
        baseDelay = maxDelay;
      } else {
        final delay = initialDelay * multiplier;
        if (delay > maxDelay) {
          reachedMax = true;
          baseDelay = maxDelay;
        } else {
          baseDelay = delay;
        }
      }
    }
    final Duration delay;
    if (randomGenerator == null) {
      delay = baseDelay;
    } else {
      final jitterFactor =
          (1.0 - jitter) + (2.0 * jitter * randomGenerator.nextDouble());
      delay = Duration(
        microseconds: (baseDelay.inMicroseconds * jitterFactor).round(),
      );
    }
    yield delay;
  }
}

@visibleForTesting
final class NoDelayRetry extends ExponentialRetry {
  const NoDelayRetry()
    : super(initialDelay: Duration.zero, maxDelay: Duration.zero);
}

/// A retry runner that implements exponential backoff.
///
/// When [run] is called, it will attempt to execute the given function. If the
/// function throws a recoverable exception (such as [RequestTimeoutException])
/// and the function is idempotent, it will retry the function with increasing
/// wait times between attempts.
final class ExponentialRetry implements RetryRunner {
  /// The maximum number of times to retry before failing.
  ///
  /// A `null` value indicates that the number of retries is unlimited.
  final int? maxRetries;

  /// The maximum amount of total time to retry before failing.
  ///
  /// A `null` value indicates that the total retry time is unlimited.
  final Duration? maxRetryInterval;

  /// The minimum amount of time to wait before retrying.
  final Duration initialDelay;

  /// The multiplier for the wait time between retries.
  final double delayMultiplier;

  /// The maximum amount of time to wait between retries.
  ///
  /// If the calculated exponential wait time between retries exceeds this
  /// value, the wait time will be clamped to this value before applying
  /// [jitter].
  final Duration maxDelay;

  /// Randomized jitter factor applied to each delay (e.g. `0.2` for ±20%).
  ///
  /// Defaults to `0.0` (no jitter).
  final double jitter;

  final bool Function(Object) _isRetryable;

  const ExponentialRetry({
    this.maxRetries,
    // Defaults taken from Python:
    // https://docs.cloud.google.com/storage/docs/retry-strategy#tools
    this.initialDelay = const Duration(seconds: 1),
    this.delayMultiplier = 2,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 2),
    this.jitter = 0.0,
    bool Function(Object) isRetryable = defaultIsRetryable,
  }) : _isRetryable = isRetryable;

  @override
  bool isRetryable(Object error) => _isRetryable(error);

  @override
  Iterable<Duration> delays({Clock clock = const Clock(), Random? random}) =>
      delaySequence(
        maxRetries: maxRetries,
        maxRetryInterval: maxRetryInterval,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: delayMultiplier,
        jitter: jitter,
        clock: clock,
        random: random,
      );

  @override
  Future<T> run<T>(
    Future<T> Function() body, {
    required bool isIdempotent,
    Clock clock = const Clock(),
  }) async {
    final iterator = delays(clock: clock).iterator;

    while (true) {
      try {
        return await body();
      } catch (e) {
        if (!isIdempotent || !isRetryable(e)) rethrow;
        if (iterator.moveNext()) {
          await Future<void>.delayed(iterator.current);
        } else {
          rethrow;
        }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExponentialRetry &&
          runtimeType == other.runtimeType &&
          maxRetries == other.maxRetries &&
          maxRetryInterval == other.maxRetryInterval &&
          initialDelay == other.initialDelay &&
          delayMultiplier == other.delayMultiplier &&
          maxDelay == other.maxDelay &&
          jitter == other.jitter &&
          _isRetryable == other._isRetryable;

  @override
  int get hashCode => Object.hash(
    maxRetries,
    maxRetryInterval,
    initialDelay,
    delayMultiplier,
    maxDelay,
    jitter,
    _isRetryable,
  );

  @override
  String toString() =>
      'ExponentialRetry('
      'maxRetries: $maxRetries, '
      'maxRetryInterval: $maxRetryInterval, '
      'initialDelay: $initialDelay, '
      'delayMultiplier: $delayMultiplier, '
      'maxDelay: $maxDelay, '
      'jitter: $jitter)';
}

/// The default retry strategy.
///
/// This strategy implements exponential backoff for idempotent operations.
const defaultRetry = ExponentialRetry();
