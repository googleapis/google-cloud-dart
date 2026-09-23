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

import 'credential_exception.dart';

/// Whether the current runtime supports `dart:io` platform and file operations.
const bool isPlatformIo = false;

/// Whether the current operating system is Linux.
bool get isPlatformLinux => false;

/// Environment variables are not available on the web.
String? readPlatformEnvironment(String name) => null;

/// Local file system access is not available on the web.
Future<String> readFileAsString(String path) async {
  throw CredentialException(
    'Reading credentials from a file ($path) is not supported on the web.',
  );
}
