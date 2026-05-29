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

/// Features for serving HTTP requests on Google Cloud Platform.
///
/// This library provides functions to run a `shelf` server that handles
/// requests in a way that is compatible with Google Cloud environments like
/// Cloud Run and Cloud Functions. It includes middleware for logging requests
/// in the format expected by Google Cloud Logging.
///
/// ## Example
///
/// ```dart
/// import 'package:google_cloud_shelf/google_cloud_shelf.dart';
/// import 'package:shelf/shelf.dart';
///
/// Future<void> main() async {
///   final handler = const Pipeline()
///       .addMiddleware(createLoggingMiddleware())
///       .addHandler((_) => Response.ok('Hello, World!'));
///
///   await serveHandler(handler);
/// }
/// ```
library;

export 'src/constants.dart'
    show
        cloudTraceContextHeader,
        defaultListenPort,
        logSpanIdKey,
        logTraceKey,
        logTraceSampledKey,
        portEnvironmentVariable;

export 'src/http_logging.dart'
    show
        cloudLoggingMiddleware,
        createLoggingMiddleware,
        errorLoggingMiddleware;
export 'src/http_response_exception.dart' show HttpResponseException;
export 'src/serve.dart' show listenPortFromEnvironment, serveHandler;
export 'src/terminate.dart' show waitForTerminate;
