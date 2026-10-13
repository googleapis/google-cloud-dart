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

export 'package:google_cloud_rpc/retry.dart';

/// The default retry strategy for Google Cloud Storage operations.
///
/// Retries the errors that the [Cloud Storage retry strategy][] considers
/// transient ([isTransientError]), with the same exponential backoff as the
/// Python client library: a `1s` initial delay, a `2x` multiplier, a `60s`
/// maximum delay, and a `2 minute` maximum retry interval.
///
/// `Storage` only uses it for idempotent operations, unless a method is passed
/// a `retry` argument.
///
/// [Cloud Storage retry strategy]: https://docs.cloud.google.com/storage/docs/retry-strategy
const defaultRetry = ExponentialRetry();
