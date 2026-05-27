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

/// General Google Cloud Logging.
///
/// Includes:
///
/// - [StructuredLogger]: for creating and writing structured logs
/// - [createStructuredLog]: for creating structured logs
///
/// Exports [LogSeverity] and [LogEntry] from other packages for easy access.
///
/// @docImport 'package:google_cloud_logging_type/logging_type.dart';
/// @docImport 'package:google_cloud_logging_v2/logging.dart';
/// @docImport 'src/structured_logger.dart';
/// @docImport 'src/structured_logging.dart';
library;

export 'package:google_cloud_logging_type/logging_type.dart' show LogSeverity;
export 'package:google_cloud_logging_v2/logging.dart' show LogEntry;

export 'src/structured_logger.dart';
export 'src/structured_logging.dart' show createStructuredLog;
