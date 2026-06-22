import 'dart:math';

import 'package:clock/clock.dart';
import 'package:grpc/grpc.dart';
import 'package:meta/meta.dart';

/// Settings for configuring retry logic with exponential backoff.
final class RetrySettings {
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
  /// value, the wait time will be clamped to this value.
  final Duration maxDelay;

  const RetrySettings({
    this.maxRetries,
    this.initialDelay = const Duration(milliseconds: 100),
    this.delayMultiplier = 1.3,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 1),
  });
}

@internal
Iterable<Duration> delaySequence({
  int? maxRetries,
  Duration? maxRetryInterval,
  required Duration initialDelay,
  required Duration maxDelay,
  required double delayMultiplier,
  Clock clock = const Clock(),
}) sync* {
  var reachedMax = false;
  final noRetriesAfter = maxRetryInterval == null
      ? null
      : clock.fromNowBy(maxRetryInterval);
  for (var i = 0; (maxRetries == null) || (i < maxRetries); i++) {
    if (noRetriesAfter != null && clock.now().isAfter(noRetriesAfter)) {
      break;
    }
    if (reachedMax) {
      yield maxDelay;
    } else {
      final delay = initialDelay * pow(delayMultiplier, i);
      if (delay > maxDelay) {
        reachedMax = true;
        yield maxDelay;
      } else {
        yield delay;
      }
    }
  }
}

/// Runs the given function with retry logic based on [settings].
Future<T> runWithRetry<T>(
  Future<T> Function() body, {
  required RetrySettings settings,
  required bool isIdempotent,
}) async {
  final delays = delaySequence(
    maxRetries: settings.maxRetries,
    maxRetryInterval: settings.maxRetryInterval,
    initialDelay: settings.initialDelay,
    maxDelay: settings.maxDelay,
    delayMultiplier: settings.delayMultiplier,
  ).iterator;

  while (true) {
    try {
      return await body();
    } catch (e) {
      if (!isIdempotent) rethrow;

      if (e is GrpcError) {
        switch (e.code) {
          case StatusCode.aborted:
          case StatusCode.deadlineExceeded:
          case StatusCode.internal:
          case StatusCode.resourceExhausted:
          case StatusCode.unavailable:
          case StatusCode.unknown:
            break;
          default:
            rethrow;
        }
      } else {
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
