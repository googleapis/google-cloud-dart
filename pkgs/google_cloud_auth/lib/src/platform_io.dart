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

import 'dart:io';

import 'credential_exception.dart';

/// Whether the current runtime supports `dart:io` platform and file operations.
const bool isPlatformIo = true;

/// Whether the current operating system is Linux.
bool get isPlatformLinux => Platform.isLinux;

/// Reads an environment variable from [Platform.environment].
String? readPlatformEnvironment(String name) => Platform.environment[name];

/// Reads the credentials file at [path] as a UTF-8 string.
///
/// Throws a [CredentialException] if reading fails.
Future<String> readCredentialFileAsString(String path) async {
  try {
    return await File(path).readAsString();
  } on IOException catch (e, stackTrace) {
    throw CredentialException(
      'Failed to read credentials file at $path: $e',
      innerException: e,
      innerStackTrace: stackTrace,
    );
  }
}
