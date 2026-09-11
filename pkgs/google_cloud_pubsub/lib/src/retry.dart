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

// TODO(https://github.com/googleapis/google-cloud-dart/issues/346): share
// this with `google_cloud_storage`'s retry implementation. Until then, any
// change to which errors are considered retryable must be made in both.

/// Settings for configuring retry logic with exponential backoff.
final class RetrySettings {
  /// The maximum number of times to retry before failing.
  ///
  /// A `null` value indicates that the number of retries is unlimited.
  final int? maxRetries;

  /// The maximum amount of total time to retry before failing.
  ///
  /// This is the wall-clock budget across all attempts, as opposed to
  /// [maxDelay], which caps an individual wait.
  ///
  /// A `null` value indicates that the total retry time is unlimited.
  /// If the calculated backoff delay for an attempt would cause execution to
  /// exceed this timeout, retries are halted immediately.
  final Duration? totalTimeout;

  /// The minimum amount of time to wait before retrying.
  final Duration initialDelay;

  /// The multiplier for the wait time between retries.
  final double delayMultiplier;

  /// The maximum base delay between retries, before jitter is applied.
  ///
  /// If the calculated exponential wait time between retries exceeds this
  /// value, the base wait time will be clamped to this value before applying
  /// randomized jitter (±20%).
  final Duration maxDelay;

  /// Creates a new [RetrySettings] instance.
  ///
  /// It is an error if:
  /// - [maxRetries] is negative.
  /// - [initialDelay] is not greater than [Duration.zero].
  /// - [maxDelay] is not greater than [Duration.zero].
  /// - [initialDelay] is greater than [maxDelay].
  /// - [delayMultiplier] is less than 1.0 or not finite.
  /// - [totalTimeout] is not greater than [Duration.zero].
  RetrySettings({
    this.maxRetries,
    this.totalTimeout = const Duration(minutes: 1),
    this.initialDelay = const Duration(milliseconds: 100),
    this.delayMultiplier = 1.3,
    this.maxDelay = const Duration(seconds: 60),
  }) {
    if (maxRetries != null && maxRetries! < 0) {
      throw ArgumentError.value(
        maxRetries,
        'maxRetries',
        'Must be non-negative',
      );
    }
    if (initialDelay <= Duration.zero) {
      throw ArgumentError.value(
        initialDelay,
        'initialDelay',
        'Must be greater than zero',
      );
    }
    if (maxDelay <= Duration.zero) {
      throw ArgumentError.value(
        maxDelay,
        'maxDelay',
        'Must be greater than zero',
      );
    }
    if (initialDelay > maxDelay) {
      throw ArgumentError.value(
        initialDelay,
        'initialDelay',
        'Must not be greater than maxDelay',
      );
    }
    if (delayMultiplier < 1.0 || !delayMultiplier.isFinite) {
      throw ArgumentError.value(
        delayMultiplier,
        'delayMultiplier',
        'Must be at least 1.0',
      );
    }
    if (totalTimeout != null && totalTimeout! <= Duration.zero) {
      throw ArgumentError.value(
        totalTimeout,
        'totalTimeout',
        'Must be greater than zero',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetrySettings &&
          runtimeType == other.runtimeType &&
          maxRetries == other.maxRetries &&
          totalTimeout == other.totalTimeout &&
          initialDelay == other.initialDelay &&
          delayMultiplier == other.delayMultiplier &&
          maxDelay == other.maxDelay;

  @override
  int get hashCode => Object.hash(
    maxRetries,
    totalTimeout,
    initialDelay,
    delayMultiplier,
    maxDelay,
  );

  @override
  String toString() =>
      'RetrySettings('
      'maxRetries: $maxRetries, '
      'totalTimeout: $totalTimeout, '
      'initialDelay: $initialDelay, '
      'delayMultiplier: $delayMultiplier, '
      'maxDelay: $maxDelay)';
}

/// Generates wait durations for exponential backoff according to
/// [RetrySettings].
///
/// Uses [clock] to enforce [totalTimeout] or [deadline].
@internal
Iterable<Duration> delaySequence({
  int? maxRetries,
  Duration? totalTimeout,
  DateTime? deadline,
  required Duration initialDelay,
  required Duration maxDelay,
  required double delayMultiplier,
  Clock clock = const Clock(),
  Random? random,
}) sync* {
  final noRetriesAfter =
      deadline ?? (totalTimeout == null ? null : clock.fromNowBy(totalTimeout));
  final randomGenerator = random ?? Random();
  var currentDelay = initialDelay;
  for (var i = 0; (maxRetries == null) || (i < maxRetries); i++) {
    if (noRetriesAfter != null && clock.now().isAfter(noRetriesAfter)) {
      break;
    }
    final jitterFactor = 0.8 + 0.4 * randomGenerator.nextDouble();
    var delay = Duration(
      microseconds: (currentDelay.inMicroseconds * jitterFactor).round(),
    );
    if (noRetriesAfter != null) {
      final remaining = noRetriesAfter.difference(clock.now());
      if (delay > remaining) break;
    }
    yield delay;
    if (currentDelay < maxDelay) {
      final nextMicroseconds = currentDelay.inMicroseconds * delayMultiplier;
      currentDelay =
          (!nextMicroseconds.isFinite ||
              nextMicroseconds >= maxDelay.inMicroseconds)
          ? maxDelay
          : Duration(microseconds: nextMicroseconds.round());
    }
  }
}

/// Returns whether [error] is considered a retryable error.
@internal
bool isRetryable(Object error) {
  if (error is! Exception) return false;
  return switch (error) {
    GrpcError(:final code) => switch (code) {
      StatusCode.aborted ||
      StatusCode.deadlineExceeded ||
      StatusCode.internal ||
      StatusCode.resourceExhausted ||
      StatusCode.unavailable ||
      StatusCode.unknown => true,
      _ => false,
    },
    InternalServerErrorException(:final status) => switch (status?.code) {
      null => true,
      StatusCode.aborted ||
      StatusCode.deadlineExceeded ||
      StatusCode.internal ||
      StatusCode.resourceExhausted ||
      StatusCode.unavailable ||
      StatusCode.unknown => true,
      _ => false,
    },
    BadGatewayException() ||
    RequestTimeoutException() ||
    ServiceUnavailableException() ||
    GatewayTimeoutException() ||
    TooManyRequestsException() => true,
    ServiceException(:final status, :final statusCode) =>
      switch (status?.code) {
        StatusCode.aborted ||
        StatusCode.deadlineExceeded ||
        StatusCode.internal ||
        StatusCode.resourceExhausted ||
        StatusCode.unavailable ||
        StatusCode.unknown => true,
        null =>
          statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504 ||
              statusCode == 429 ||
              statusCode == 408,
        _ => false,
      },
    _ => false,
  };
}

/// Runs [body] with exponential backoff retries.
///
/// Only transient gRPC errors and retryable [ServiceException]s are retried.
/// If [isIdempotent] is `false`, the operation is never retried and the first
/// error is rethrown.
@internal
Future<T> runWithRetry<T>(
  Future<T> Function() body, {
  required RetrySettings settings,
  required bool isIdempotent,
  Clock clock = const Clock(),
}) async {
  final deadline = settings.totalTimeout == null
      ? null
      : clock.fromNowBy(settings.totalTimeout!);
  final delays = delaySequence(
    maxRetries: settings.maxRetries,
    totalTimeout: settings.totalTimeout,
    deadline: deadline,
    initialDelay: settings.initialDelay,
    maxDelay: settings.maxDelay,
    delayMultiplier: settings.delayMultiplier,
    clock: clock,
  ).iterator;

  while (true) {
    try {
      return await body();
    } on Exception catch (error) {
      if (!isIdempotent || !isRetryable(error)) rethrow;

      if (deadline != null && clock.now().isAfter(deadline)) {
        rethrow;
      }

      if (delays.moveNext()) {
        await Future<void>.delayed(delays.current);
      } else {
        rethrow;
      }
    }
  }
}
