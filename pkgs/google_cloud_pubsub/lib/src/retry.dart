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

/// The default retry strategy for publishing messages.
///
/// Follows the `Publish` retry policy in the `google.pubsub.v1` gRPC service
/// configuration, as the Pub/Sub client libraries for other languages do. It
/// retries errors with the status codes `ABORTED`, `CANCELLED`,
/// `DEADLINE_EXCEEDED`, `INTERNAL`, `RESOURCE_EXHAUSTED`, `UNAVAILABLE` and
/// `UNKNOWN`, with a `100ms` initial delay, a `4x` multiplier, a `60s` maximum
/// delay, a `1 minute` maximum retry interval, and full jitter.
const defaultRetry = ExponentialRetry.onCodes(
  [
    Code.aborted,
    Code.cancelled,
    Code.deadlineExceeded,
    Code.internal,
    Code.resourceExhausted,
    Code.unavailable,
    Code.unknown,
  ],
  initialDelay: Duration(milliseconds: 100),
  delayMultiplier: 4,
  maxDelay: Duration(seconds: 60),
  maxRetryInterval: Duration(minutes: 1),
);
