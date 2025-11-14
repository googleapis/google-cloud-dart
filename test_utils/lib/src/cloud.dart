// Copyright 2025 Google LLC
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

/// The id of the Google Cloud Project targeted by the test.
///
/// Taken from the `"GOOGLE_CLOUD_PROJECT"` environment variable.
///
/// Throws [StateError] if the environment variable is not set.
String get projectId =>
    Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
    (throw StateError('Missing environment variable: GOOGLE_CLOUD_PROJECT'));
