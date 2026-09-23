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

/// Whether `package:webcrypto` can be used on the current platform.
///
/// The browser always provides the Web Crypto API, so this is always true.
const canUseWebCrypto = true;

/// Stub for [writeTempFile] on the web.
Future<String> writeTempFile(String filename, String content) =>
    throw UnsupportedError('writeTempFile is only supported on the VM.');
