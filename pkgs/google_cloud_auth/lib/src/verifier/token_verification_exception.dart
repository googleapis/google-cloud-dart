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

/// Exception thrown when a token fails verification.
///
/// This covers both tokens that are structurally or cryptographically invalid
/// and failures to obtain the public keys needed to check them. Callers should
/// not distinguish between the two when deciding whether to accept a request:
/// in either case the token has not been verified.
class TokenVerificationException implements Exception {
  /// The message explaining the failure.
  final String message;

  /// The inner exception that caused this failure, if any.
  final Object? innerException;

  /// The stack trace of the inner exception, if any.
  final StackTrace? innerStackTrace;

  TokenVerificationException(
    this.message, {
    this.innerException,
    this.innerStackTrace,
  });

  @override
  String toString() => innerException == null
      ? 'TokenVerificationException: $message'
      : 'TokenVerificationException: $message (caused by: $innerException)';
}
