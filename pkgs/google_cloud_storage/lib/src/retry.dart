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

/// The default retry strategy for Google Cloud Storage operations.
///
/// Retries the errors that the [Cloud Storage retry strategy][] considers
/// transient (using [isTransientError]).
///
/// `Storage` methods use it for idempotent operations, unless they're
/// explicitly passed a `retry` argument.
///
/// To change the backoff but keep retrying the same errors, use
/// [isTransientError] as the `retryIf` predicate. For example:
///
/// ```dart
/// await storage.bucketMetadata(
///   'my-bucket',
///   retry: const ExponentialRetry(retryIf: isTransientError, maxRetries: 3),
/// );
/// ```
///
/// [Cloud Storage retry strategy]: https://docs.cloud.google.com/storage/docs/retry-strategy
const defaultRetry = ExponentialRetry(retryIf: isTransientError);

/// Returns whether [error] is a transient failure.
///
/// These are the errors that the
/// [Cloud Storage retry strategy](https://docs.cloud.google.com/storage/docs/retry-strategy)
/// considers transient:
/// - failures to communicate with the service ([http.ClientException]).
/// - HTTP 408, 429 and 5xx responses.
/// - checksum mismatches ([ChecksumValidationException]).
bool isTransientError(Object error) => switch (error) {
  ServiceException(statusCode: 408 || 429 || (>= 500 && < 600)) ||
  http.ClientException() ||
  ChecksumValidationException() => true,
  _ => false,
};
