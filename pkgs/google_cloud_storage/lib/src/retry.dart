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

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:google_cloud_rpc/retry.dart';
import 'package:http/http.dart' as http;

export 'package:google_cloud_rpc/retry.dart';

/// The default retry strategy for Google Cloud Storage operations.
///
/// Retries the errors that the [Cloud Storage retry strategy][] considers
/// transient ([isTransientError]), with the same exponential backoff as the
/// Python client library: a `1s` initial delay, a `2x` multiplier, a `60s`
/// maximum delay, a `2 minute` maximum retry interval, and full jitter.
///
/// `Storage` only uses it for idempotent operations, unless a method is passed
/// a `retry` argument.
///
/// To change the backoff but keep retrying the same errors, use
/// [isTransientError] as the predicate. For example:
///
/// ```dart
/// final storage = Storage(
///   retry: const ExponentialRetry(retryIf: isTransientError, maxRetries: 3),
/// );
/// ```
///
/// [Cloud Storage retry strategy]: https://docs.cloud.google.com/storage/docs/retry-strategy
const defaultRetry = ExponentialRetry(retryIf: isTransientError);

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
/// This is the predicate of [defaultRetry]. It corresponds to `_should_retry`
/// in the Python client library and `ShouldRetry` in the Go client library.
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
