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

import 'package:google_cloud_rpc/retry.dart';
import 'package:grpc/grpc.dart';
import 'package:meta/meta.dart';

export 'package:google_cloud_rpc/retry.dart';

/// Returns whether [error] is considered a transient, retryable Pub/Sub error.
bool isPubSubRetryable(Object error) {
  if (error is GrpcError) {
    return switch (error.code) {
      StatusCode.aborted ||
      StatusCode.deadlineExceeded ||
      StatusCode.internal ||
      StatusCode.resourceExhausted ||
      StatusCode.unavailable ||
      StatusCode.unknown => true,
      _ => false,
    };
  }
  return defaultIsRetryable(error);
}

/// The default retry strategy for Pub/Sub unary operations.
///
/// Implements exponential backoff with ±20% jitter for idempotent operations.
const defaultPubSubRetry = ExponentialRetry(
  initialDelay: Duration(milliseconds: 100),
  delayMultiplier: 1.3,
  maxDelay: Duration(seconds: 60),
  maxRetryInterval: Duration(minutes: 1),
  jitter: 0.2,
  isRetryable: isPubSubRetryable,
);

/// Normalizes a [RetryRunner] for Pub/Sub by substituting [isPubSubRetryable]
/// whenever an [ExponentialRetry] uses [defaultIsRetryable].
@internal
RetryRunner normalizePubSubRetry(
  RetryRunner? retry, {
  RetryRunner fallback = defaultPubSubRetry,
  bool clearMaxRetryInterval = false,
}) {
  final target = retry ?? fallback;
  return switch (target) {
    final ExponentialRetry exp => ExponentialRetry(
      maxRetries: exp.maxRetries,
      maxRetryInterval: clearMaxRetryInterval ? null : exp.maxRetryInterval,
      initialDelay: exp.initialDelay,
      delayMultiplier: exp.delayMultiplier,
      maxDelay: exp.maxDelay,
      jitter: exp.jitter,
      isRetryable: exp.isRetryable == defaultIsRetryable
          ? isPubSubRetryable
          : exp.isRetryable,
    ),
    final other => other,
  };
}
