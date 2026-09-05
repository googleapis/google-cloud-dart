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

import 'dart:typed_data';

import 'credential_exception.dart';

// Design based on:
// - https://github.com/googleapis/google-cloud-java/blob/main/google-auth-library-java/credentials/java/com/google/auth/ServiceAccountSigner.java
// - https://github.com/googleapis/google-cloud-python/blob/main/packages/google-auth/google/auth/credentials.py

/// Interface for a service account signer.
///
/// A signer for a service account is capable of signing bytes using the private
/// key associated with its service account, either locally using a private key
/// or remotely via the Google Cloud IAM credentials API.
abstract interface class ServiceAccountSigner {
  /// The email address of the service account associated with the signer.
  String get clientEmail;

  /// Signs [message].
  ///
  /// Throws [SigningException] on failure.
  Future<Uint8List> sign(List<int> message);
}

/// Exception thrown when cryptographic signing fails.
class SigningException extends CredentialException {
  SigningException(
    super.message, {
    super.innerException,
    super.innerStackTrace,
  });

  @override
  String toString() => innerException == null
      ? 'SigningException: $message'
      : 'SigningException: $message (caused by: $innerException)';
}
