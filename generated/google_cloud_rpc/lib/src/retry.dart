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

import '../rpc.dart';
import 'exceptions.dart';

/// Decides which failures are retried and how long to wait between attempts.
///
/// A [RetryRunner] does not know whether an operation is safe to repeat. That
/// is decided by the code that chooses the runner for each operation, as in
/// the Google Cloud client libraries for other languages. For example, a
/// generated client uses its default runner only for the methods that the
/// service's retry configuration marks as retryable, and [noRetry] for the
/// others, unless the caller provides a runner for the call.
sealed class RetryRunner {
  const RetryRunner();

  /// Runs [body], retrying it while it fails with an error that
  /// [isRetryable] accepts and the retry budget allows.
  ///
  /// Only [Exception]s are retried. An [Error], which indicates a bug, is
  /// always rethrown.
  Future<T> run<T>(Future<T> Function() body, {Clock clock = const Clock()});

  /// Returns whether a failure with [error] should be retried.
  bool isRetryable(Object error);

  /// Generates a sequence of wait durations for retries or reconnections.
  Iterable<Duration> delays({Clock clock = const Clock(), Random? random});
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
/// A non-zero `jitter` randomizes the delays, so that clients that fail at the
/// same time don't all retry at the same time. Each delay is multiplied by its
/// own random factor between `1 - jitter` and `1 + jitter`. The factor is
/// applied after the delay is capped at `maxDelay`, so a delay can be up to
/// `jitter * maxDelay` longer than `maxDelay`. For example, with a `jitter` of
/// `0.2`:
///
/// ```dart
/// delaySequence(
///     maxRetries: 6,
///     initialDelay: Duration(seconds: 1),
///     maxDelay: Duration(seconds: 10),
///     delayMultiplier: 2,
///     jitter: 0.2);
/// // [
/// //   between 0.8 and 1.2 seconds,
/// //   between 1.6 and 2.4 seconds,
/// //   between 3.2 and 4.8 seconds,
/// //   between 6.4 and 9.6 seconds,
/// //   between 8 and 12 seconds,
/// //   between 8 and 12 seconds,
/// // ]
/// ```
///
/// The random factors are taken from `random`, or from a new [Random] if
/// `random` is omitted. Passing a seeded [Random] makes the sequence
/// reproducible.
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

/// A [RetryRunner] that never retries.
///
/// Use the [noRetry] constant rather than creating new instances.
final class NoRetry extends RetryRunner {
  const NoRetry();

  @override
  Future<T> run<T>(
    Future<T> Function() body, {
    Clock clock = const Clock(),
  }) async => body();

  @override
  bool isRetryable(Object error) => false;

  @override
  Iterable<Duration> delays({Clock clock = const Clock(), Random? random}) =>
      const [];

  @override
  bool operator ==(Object other) => other is NoRetry;

  @override
  int get hashCode => (NoRetry).hashCode;

  @override
  String toString() => 'NoRetry()';
}

/// A [RetryRunner] that never retries.
///
/// Pass this to disable retries, for a single call or for a whole client.
const noRetry = NoRetry();

@visibleForTesting
final class NoDelayRetry extends ExponentialRetry {
  const NoDelayRetry({super.retryIf, super.maxRetries})
    : super(initialDelay: Duration.zero, maxDelay: Duration.zero);
}

/// A retry runner that implements exponential backoff.
///
/// When [run] is called, it will attempt to execute the given function. If the
/// function throws an exception that [retryIf] accepts, it will retry the
/// function with increasing wait times between attempts, until the function
/// succeeds or the retry budget ([maxRetries] and [maxRetryInterval]) is
/// exhausted.
///
/// This corresponds to `google.api_core.retry.Retry` in the Python client
/// libraries: [retryIf] is `predicate`, [initialDelay] is `initial`,
/// [maxDelay] is `maximum`, [delayMultiplier] is `multiplier` and
/// [maxRetryInterval] is `timeout`.
final class ExponentialRetry extends RetryRunner {
  /// Returns whether a failure with the given error should be retried.
  ///
  /// Defaults to [isTransientError]. To retry the status codes from a
  /// service's retry configuration, use [hasStatusCode]. For example:
  ///
  /// ```dart
  /// final retry = ExponentialRetry(
  ///   retryIf: (e) => hasStatusCode(e, const [Code.unavailable]),
  /// );
  /// ```
  final bool Function(Object error) retryIf;

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

  /// The fraction, between `0.0` and `1.0`, by which each delay is randomly
  /// lengthened or shortened.
  ///
  /// Each delay is multiplied by its own random factor between `1 - jitter`
  /// and `1 + jitter`, so a [jitter] of `0.2` varies each delay by up to ±20%.
  /// This spreads out the retries of clients that failed at the same time, so
  /// that they don't all retry at once.
  ///
  /// The factor is applied after the delay is capped at [maxDelay], so a delay
  /// can be up to `jitter * maxDelay` longer than [maxDelay].
  ///
  /// Defaults to `0.0` (no jitter).
  final double jitter;

  const ExponentialRetry({
    this.retryIf = isTransientError,
    this.maxRetries,
    // Defaults taken from Python:
    // https://docs.cloud.google.com/storage/docs/retry-strategy#tools
    this.initialDelay = const Duration(seconds: 1),
    this.delayMultiplier = 2,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 2),
    this.jitter = 0.0,
  });

  @override
  bool isRetryable(Object error) => retryIf(error);

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
    Clock clock = const Clock(),
  }) async {
    final iterator = delays(clock: clock).iterator;

    while (true) {
      try {
        return await body();
      } on Exception catch (e) {
        if (!retryIf(e)) rethrow;
        if (!iterator.moveNext()) rethrow;
        await Future<void>.delayed(iterator.current);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExponentialRetry &&
          runtimeType == other.runtimeType &&
          retryIf == other.retryIf &&
          maxRetries == other.maxRetries &&
          maxRetryInterval == other.maxRetryInterval &&
          initialDelay == other.initialDelay &&
          delayMultiplier == other.delayMultiplier &&
          maxDelay == other.maxDelay &&
          jitter == other.jitter;

  @override
  int get hashCode => Object.hash(
    retryIf,
    maxRetries,
    maxRetryInterval,
    initialDelay,
    delayMultiplier,
    maxDelay,
    jitter,
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

/// Returns whether [error] is a transient failure, which is usually worth
/// retrying.
///
/// These are the errors that the
/// [Cloud Storage retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)
/// considers transient:
///
/// - failures to communicate with the service ([http.ClientException]).
/// - HTTP 408, 429, 500, 502, 503 and 504 responses, and errors with the
///   equivalent gRPC status codes (`UNKNOWN`, `DEADLINE_EXCEEDED`,
///   `RESOURCE_EXHAUSTED`, `INTERNAL` and `UNAVAILABLE`), except for
///   `DATA_LOSS`.
/// - errors with the gRPC status code `ABORTED`.
/// - checksum mismatches ([ChecksumValidationException]).
///
/// This is the default [ExponentialRetry.retryIf], in the same way that
/// `if_transient_error` is the default `predicate` of `Retry` in the Python
/// client libraries.
bool isTransientError(Object error) {
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

/// The numeric value and the HTTP status code of each `google.rpc.Code`,
/// keyed by name.
///
/// See [`google/rpc/code.proto`](https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto).
const _statusCodes = <String, (int, int)>{
  'CANCELLED': (1, 499),
  'UNKNOWN': (2, 500),
  'INVALID_ARGUMENT': (3, 400),
  'DEADLINE_EXCEEDED': (4, 504),
  'NOT_FOUND': (5, 404),
  'ALREADY_EXISTS': (6, 409),
  'PERMISSION_DENIED': (7, 403),
  'RESOURCE_EXHAUSTED': (8, 429),
  'FAILED_PRECONDITION': (9, 400),
  'ABORTED': (10, 409),
  'OUT_OF_RANGE': (11, 400),
  'UNIMPLEMENTED': (12, 501),
  'INTERNAL': (13, 500),
  'UNAVAILABLE': (14, 503),
  'DATA_LOSS': (15, 500),
  'UNAUTHENTICATED': (16, 401),
};

/// Returns whether [error] reports one of the canonical status [codes].
///
/// This is used to retry the status codes in a service's retry configuration
/// (its `retryableStatusCodes`), as the generated clients for other languages
/// do. For example:
///
/// ```dart
/// final retry = ExponentialRetry(
///   retryIf: (e) => hasStatusCode(e, const [Code.unavailable]),
/// );
/// ```
///
/// An error from a gRPC transport is matched by its gRPC status code. An
/// error from a REST transport is matched by the HTTP status code that
/// `google.rpc.Code` maps each code to, such as 503 for [Code.unavailable].
/// So for REST, codes that share an HTTP status code, such as [Code.aborted]
/// and [Code.alreadyExists] (409), can't be told apart.
///
/// A failure to communicate with the service ([http.ClientException]) counts
/// as [Code.unavailable], which is how gRPC reports it.
bool hasStatusCode(Object error, Iterable<Code> codes) {
  switch (error) {
    case http.ClientException():
      return codes.contains(Code.unavailable);
    case ServiceException(:final status, :final statusCode):
      final grpcCode = status?.code;
      // A REST error's `status` carries the HTTP status code instead.
      final isGrpc = grpcCode != null && grpcCode > 0 && grpcCode <= 16;
      return codes.any((code) {
        if (_statusCodes[code.value] case (final number, final httpStatus)) {
          return isGrpc ? grpcCode == number : statusCode == httpStatus;
        }
        return false;
      });
    default:
      return false;
  }
}
