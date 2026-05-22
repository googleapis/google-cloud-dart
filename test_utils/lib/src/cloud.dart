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
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

/// A real Google test account managed by bquinlan@google.com using Rhea.
const googleTestUser = 'daenerysstone.938939@gmail.com';

/// The id of the Google Cloud Project targeted by the test.
///
/// Taken from the `"GOOGLE_CLOUD_PROJECT"` environment variable.
///
/// Throws [StateError] if the environment variable is not set.
String get projectId =>
    Platform.environment['GOOGLE_CLOUD_PROJECT'] ??
    (throw StateError('Missing environment variable: GOOGLE_CLOUD_PROJECT'));

/// Polls Cloud Logging until log entries matching [filter]
/// are returned.
///
/// [filter] must be in [Logging query language][1]. For example,
/// `'textPayload:"Hello World"'`.
///
/// [1]: (https://docs.cloud.google.com/logging/docs/view/logging-query-language)
Future<List<LogEntry>> waitForLogs(String filter, int count) async {
  final client = await auth.clientViaApplicationDefaultCredentials(
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );
  final loggingService = LoggingServiceV2(client: client);

  final request = ListLogEntriesRequest(
    resourceNames: ['projects/$projectId'],
    filter: filter,
    orderBy: 'timestamp desc',
    pageSize: count,
  );

  try {
    for (var attempt = 0; attempt <= 10; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final listResult = await loggingService.listLogEntries(request);
      if (listResult.entries.isNotEmpty) {
        return listResult.entries;
      }
    }
    throw StateError(
      'Log entries matching "$filter" were not found within the timeout.',
    );
  } finally {
    loggingService.close();
  }
}
