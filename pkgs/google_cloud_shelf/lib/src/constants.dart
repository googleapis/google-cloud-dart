// Copyright 2022 Google LLC
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

/// The standard environment variable for specifying the port a service should
/// listen on.
const portEnvironmentVariable = 'PORT';

/// The default port a service should listen on if [portEnvironmentVariable] is
/// not set.
const defaultListenPort = 8080;

/// Standard HTTP header used to correlate requests with logs.
///
/// See https://www.w3.org/TR/trace-context/
const cloudTraceContextHeader = 'traceparent';

/// The `payload` key used to correlate log entries with Cloud Trace.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const logTraceKey = 'logging.googleapis.com/trace';

/// The `payload` key used to correlate log entries with a specific span within
/// a Cloud Trace.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const logSpanIdKey = 'logging.googleapis.com/spanId';

/// The `payload` key used to indicate whether a trace is sampled.
///
/// See https://docs.cloud.google.com/logging/docs/agent/logging/configuration#special-fields
const logTraceSampledKey = 'logging.googleapis.com/trace_sampled';
