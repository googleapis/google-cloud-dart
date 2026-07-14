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

/// Exception thrown when the server-calculated checksum does not match the
/// checksum calculated by the client.
class ChecksumValidationException implements Exception {
  final String message;

  ChecksumValidationException(this.message);

  @override
  String toString() => 'ChecksumValidationException: $message';
}

/// Exception thrown when an `ifMetagenerationNotMatch` precondition is not
/// satisfied and the requested operation was therefore not performed.
///
/// Google Cloud Storage signals this by responding with a "304 Not Modified"
/// status and an empty body, rather than with the "412 Precondition Failed"
/// status used for the `ifGenerationMatch` and `ifMetagenerationMatch`
/// preconditions.
///
/// See [request preconditions](https://cloud.google.com/storage/docs/request-preconditions).
class NotModifiedException implements Exception {
  final String message;

  NotModifiedException(this.message);

  @override
  String toString() => 'NotModifiedException: $message';
}
