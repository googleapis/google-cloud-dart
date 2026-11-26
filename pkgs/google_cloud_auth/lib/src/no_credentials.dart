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

/// Design based on:
/// - https://github.com/googleapis/google-cloud-java/blob/main/sdk-platform-java/java-core/google-cloud-core/src/main/java/com/google/cloud/NoCredentials.java
/// - https://github.com/googleapis/google-cloud-python/blob/main/packages/google-auth/google/auth/credentials.py
///
/// Unlike Java, [NoCredentials] does not subclass [OAuth2Credentials]. This
/// allows it to satisfy Liskov-substitutability (which it could not as an
/// [OAuth2Credentials] because it can not support
/// [OAuth2Credentials.accessToken]).
library;

import 'credentials.dart';

/// Credentials that do not provide any authentication metadata.
///
/// Useful when accessing public resources that allow anonymous access or when
/// connecting to local service emulators that do not require authentication.
final class NoCredentials extends Credentials {
  /// Creates [NoCredentials] that provide no authentication metadata.
  const NoCredentials();

  /// Empty request metadata, since unauthenticated requests send no
  /// credential headers.
  ///
  /// [uri] and [forceRefresh] have no effect.
  @override
  Future<Map<String, List<String>>> requestMetadata({
    Uri? uri,
    bool forceRefresh = false,
  }) => Future.value(const {});

  @override
  bool operator ==(Object other) => other is NoCredentials;

  @override
  int get hashCode => (NoCredentials).hashCode;
}
