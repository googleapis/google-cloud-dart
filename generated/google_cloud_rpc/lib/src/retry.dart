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

/// An abstract class for running a function with retry logic.
///
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
  Future<T> run<T>(Future<T> Function() body, {Clock clock = const Clock()});

  /// Whether a failure with [error] should be retried.
  bool isRetryable(Object error);

  /// A sequence of wait durations for retries or reconnections.
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
/// own random factor between `1 - jitter` and `1`, so delays never exceed
/// `maxDelay`. [ExponentialRetry] uses a `jitter` of `1.0` ("full jitter"), so
/// each delay is chosen uniformly between zero and the computed delay, as in
/// the Google Cloud client libraries for Python, Go and Java. For example,
/// with a `jitter` of `0.2`:
///
/// ```dart
/// delaySequence(
///     maxRetries: 6,
///     initialDelay: Duration(seconds: 1),
///     maxDelay: Duration(seconds: 10),
///     delayMultiplier: 2,
///     jitter: 0.2);
/// // [
/// //   between 0.8 and 1 seconds,
/// //   between 1.6 and 2 seconds,
/// //   between 3.2 and 4 seconds,
/// //   between 6.4 and 8 seconds,
/// //   between 8 and 10 seconds,
/// //   between 8 and 10 seconds,
/// // ]
/// ```
///
/// The random factors are taken from `random`, or from a new [Random] if
/// `random` is omitted. Passing a seeded [Random] makes the sequence
/// reproducible.
///
/// If `maxRetryInterval` is set then the sequence must be iterated-over in
/// real time.
@internal
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
      // `nextDouble` is in [0, 1), so the factor is in (1 - jitter, 1].
      final jitterFactor = 1.0 - jitter * randomGenerator.nextDouble();
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
  const NoDelayRetry({required super.retryIf, super.maxRetries})
    : super(initialDelay: Duration.zero, maxDelay: Duration.zero);

  const NoDelayRetry.onCodes(super.retryableCodes, {super.maxRetries})
    : super.onCodes(initialDelay: Duration.zero, maxDelay: Duration.zero);
}

/// A retry runner that implements exponential backoff.
///
/// When [run] is called, it will attempt to execute the given function. If the
/// function throws an exception that [isRetryable] accepts, it will retry the
/// function with increasing wait times between attempts, until the function
/// succeeds or the retry budget ([maxRetries] and [maxRetryInterval]) is
/// exhausted.
///
/// Before each retry, it waits for a random time between zero and the current
/// delay ("full jitter"), so that clients that fail at the same time don't all
/// retry at once. The delay starts at [initialDelay], is multiplied by
/// [delayMultiplier] after each retry, and never exceeds [maxDelay]. This is
/// the backoff that the Google Cloud client libraries for Go, Java and Python
/// use.
///
/// There are two ways to choose which failures are retried:
///
/// - [ExponentialRetry.onCodes] retries errors with the given status codes, as
///   `gax.OnCodes` does in Go and the retryable codes of a method's settings
///   do in Java. For example:
///
///   ```dart
///   const retry = ExponentialRetry.onCodes(
///     [Code.unavailable],
///     initialDelay: Duration(milliseconds: 100),
///     delayMultiplier: 1.3,
///   );
///   ```
///
/// - [ExponentialRetry.new] takes a `retryIf` predicate, as
///   `google.api_core.retry.Retry` does in Python.
///
/// The backoff parameters also correspond to Python's `Retry`: [initialDelay]
/// is `initial`, [maxDelay] is `maximum`, [delayMultiplier] is `multiplier` and
/// [maxRetryInterval] is `timeout`. Their defaults are the same as Python's.
final class ExponentialRetry extends RetryRunner {
  final bool Function(Object error)? _retryIf;

  /// The status codes that are retried, if this runner was created with
  /// [ExponentialRetry.onCodes].
  ///
  /// `null` if a `retryIf` predicate decides which errors are retried.
  final List<Code>? retryableCodes;

  /// The maximum number of times to retry before failing.
  ///
  /// A `null` value indicates that the number of retries is unlimited.
  final int? maxRetries;

  /// The maximum amount of total time to retry before failing.
  ///
  /// A `null` value indicates that the total retry time is unlimited.
  final Duration? maxRetryInterval;

  /// The delay before the first retry.
  ///
  /// The actual wait is a random time between zero and this delay.
  final Duration initialDelay;

  /// The multiplier for the wait time between retries.
  final double delayMultiplier;

  /// The maximum amount of time to wait between retries.
  ///
  /// If the calculated exponential wait time between retries exceeds this
  /// value, the wait time will be clamped to this value.
  final Duration maxDelay;

  /// Creates a retry runner that retries the errors that [retryIf] accepts.
  ///
  /// For example, to retry `UNAVAILABLE` errors and timeouts:
  ///
  /// ```dart
  /// final retry = ExponentialRetry(
  ///   retryIf: (e) =>
  ///       hasStatusCode(e, const [Code.unavailable]) || e is TimeoutException,
  /// );
  /// ```
  const ExponentialRetry({
    required bool Function(Object error) retryIf,
    this.maxRetries,
    this.initialDelay = const Duration(seconds: 1),
    this.delayMultiplier = 2,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 2),
  }) : _retryIf = retryIf,
       retryableCodes = null;

  /// Creates a retry runner that retries errors with one of the status
  /// [retryableCodes].
  ///
  /// [hasStatusCode] decides whether an error has one of the codes.
  const ExponentialRetry.onCodes(
    List<Code> this.retryableCodes, {
    this.maxRetries,
    this.initialDelay = const Duration(seconds: 1),
    this.delayMultiplier = 2,
    this.maxDelay = const Duration(seconds: 60),
    this.maxRetryInterval = const Duration(minutes: 2),
  }) : _retryIf = null;

  @override
  bool isRetryable(Object error) => switch ((retryableCodes, _retryIf)) {
    (final codes?, _) => hasStatusCode(error, codes),
    (_, final retryIf?) => retryIf(error),
    _ => false,
  };

  @override
  Iterable<Duration> delays({Clock clock = const Clock(), Random? random}) =>
      delaySequence(
        maxRetries: maxRetries,
        maxRetryInterval: maxRetryInterval,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        delayMultiplier: delayMultiplier,
        jitter: 1.0,
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
        if (!isRetryable(e)) rethrow;
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
          _retryIf == other._retryIf &&
          _listEquals(retryableCodes, other.retryableCodes) &&
          maxRetries == other.maxRetries &&
          maxRetryInterval == other.maxRetryInterval &&
          initialDelay == other.initialDelay &&
          delayMultiplier == other.delayMultiplier &&
          maxDelay == other.maxDelay;

  @override
  int get hashCode => Object.hash(
    _retryIf,
    switch (retryableCodes) {
      final codes? => Object.hashAll(codes),
      null => null,
    },
    maxRetries,
    maxRetryInterval,
    initialDelay,
    delayMultiplier,
    maxDelay,
  );

  @override
  String toString() {
    final codes = retryableCodes?.map((code) => code.value).join(', ');
    return 'ExponentialRetry('
        '${codes == null ? '' : 'retryableCodes: [$codes], '}'
        'maxRetries: $maxRetries, '
        'maxRetryInterval: $maxRetryInterval, '
        'initialDelay: $initialDelay, '
        'delayMultiplier: $delayMultiplier, '
        'maxDelay: $maxDelay)';
  }
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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

/// Whether [error] reports one of the canonical status [codes].
///
/// [ExponentialRetry.onCodes] uses this to retry the status codes in a
/// service's retry configuration (its `retryableStatusCodes`), as the generated
/// clients for other languages do. It can also be combined with other
/// conditions in an [ExponentialRetry] `retryIf` predicate.
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
