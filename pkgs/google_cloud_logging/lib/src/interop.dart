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

/// @docImport 'dart:async';
library;

/// The unique ID [String] for the current project when run on Google Cloud.
///
/// This variable is looked up in the current [Zone] to correlate logs with the
/// GCP project context. Framework middleware should set this in a forked zone.
const googleCloudProjectIdZoneVariable = 'google_cloud_project';

/// The [String] value for the `traceparent` W3C HTTP header.
///
/// This variable is looked up in the current [Zone] to associate log entries
/// with the trace and span context of the incoming request.
///
/// See https://www.w3.org/TR/trace-context/
const traceparentHeaderValueZoneVariable = 'traceparent';
