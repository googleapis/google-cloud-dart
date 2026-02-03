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
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// An abstract class for running a function with retry logic.
sealed class RetryRunner {
  /// Runs the given function with retry logic.
  Future<T> run<T>(Future<T> Function() body, {required bool isIdempotent});
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

/// A retry runner that implements exponential backoff.
///
/// When [run] is called, it will attempt to execute the given function. If the
/// function throws an recoverable exception
/// (such as [RequestTimeoutException]) and the function is idempotent, it
/// will retry the function with increasing wait times between attempts.
///
/// See [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy).
final class ExponentialRetry implements RetryRunner {
  /// The maximim number of times to retry before failing.
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

  const ExponentialRetry({
    this.maxRetries,
    // Defaults taken from Python:
    // https://docs.cloud.google.com/storage/docs/retry-strategy#tools
    this.initialDelay = const Duration(seconds: 1),
    this.delayMultiplier = 2,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 2),
  });

  @override
  Future<T> run<T>(
    Future<T> Function() body, {
    required bool isIdempotent,
  }) async {
    final delays = delaySequence(
      maxRetries: maxRetries,
      maxRetryInterval: maxRetryInterval,
      initialDelay: initialDelay,
      maxDelay: maxDelay,
      delayMultiplier: delayMultiplier,
    ).iterator;

    while (true) {
      try {
        return await body();
      } catch (e) {
        if (!isIdempotent) rethrow;
        switch (e) {
          // Taken from:
          // https://github.com/googleapis/python-storage/blob/e730bf50c4584f737ab86b2e409ddb27b40d2cec/google/cloud/storage/retry.py#L62
          case TooManyRequestsException():
          case InternalServerErrorException():
          case BadGatewayException():
          case ServiceUnavailableException():
          case GatewayTimeoutException():
          case RequestTimeoutException():
          case http.ClientException():
            break;
          default:
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
}

/// The default retry strategy.
///
/// This strategy implements exponential backoff for [idempotent operations].
///
/// See [Retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy).
///
/// [idempotent operations]: https://docs.cloud.google.com/storage/docs/retry-strategy#idempotency-operations
const defaultRetry = ExponentialRetry();
