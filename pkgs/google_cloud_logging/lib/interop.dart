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

/// A library that allows framework developers to interoperate with Google
/// Cloud Logging.
///
/// ### How Log Correlation Works
///
/// Log correlation associates individual application logs with the HTTP
/// request that triggered them, allowing GCP Cloud Logging to group them in
/// the log viewer. To achieve this without requiring application developers to
/// manually pass logging context through their call stack, this package uses
/// Dart [Zone] variables:
///
/// 1. **Framework Middleware**: An HTTP framework or middleware (such as
///    `package:google_cloud_shelf`) extracts the W3C `traceparent` header
///    from an incoming HTTP request and determines the Google Cloud Project
///    ID.
/// 2. **Zone Forking**: The middleware forks a new [Zone] containing these
///    values keyed by [googleCloudProjectIdZoneVariable] and
///    [traceparentHeaderValueZoneVariable].
/// 3. **Log Resolution**: When application code logs a message via
///    `package:google_cloud_logging`, the logger implicitly reads these
///    values from the current zone and formats them into GCP structured
///    logging fields (`logging.googleapis.com/trace` and
///    `logging.googleapis.com/spanId`).
///
/// For a detailed visual representation and description of this
/// request-to-zone-to-logging flow, see the
/// [Architecture Document][1].
///
/// > [!TIP]
/// > Application developers should not to use this library, instead use
/// > `package:google_cloud_logging/google_cloud_logging.dart`.
///
/// [1]: https://github.com/googleapis/google-cloud-dart/tree/main/pkgs/google_cloud_logging/ARCHITECTURE.md
///
/// @docImport 'dart:async';
/// @docImport 'src/interop.dart';

library;

export 'src/interop.dart';
export 'src/structured_logging.dart' show createStructuredLog;
