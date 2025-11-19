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

@TestOn('vm')
library secret_test;

import 'dart:math';

import 'package:google_cloud_api/api.dart';
import 'package:google_cloud_logging_type/logging_type.dart';
import 'package:google_cloud_logging_v2/logging.dart';
import 'package:test/test.dart';
import 'package:google_cloud_protobuf/protobuf.dart' as protobuf;

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test_utils/cloud.dart';
import 'package:test_utils/test_http_client.dart';

void main() async {
  late LoggingServiceV2 logService;
  late TestHttpClient testClient;

  group('secret', () {
    setUp(() async {
      final authClient = () async =>
          await auth.clientViaApplicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/cloud-platform'],
          );

      testClient = await TestHttpClient.fromEnvironment(authClient);
      logService = LoggingServiceV2(client: testClient);
    });

    tearDown(() => logService.close());
    test('writeLogEntries', () async {
      await testClient.startTest(
        'google_cloud_logging_v2',
        'write_log_entries',
      );

      final logId = TestHttpClient.isRecording || TestHttpClient.isReplaying
          ? '1234'
          : '${Random().nextInt(999999999)}${Random().nextInt(999999999)}';
      final logName = 'projects/$projectId/logs/logging_test_$logId';

      await logService.writeLogEntries(
        WriteLogEntriesRequest(
          entries: [
            LogEntry(
              severity: LogSeverity.critical,
              logName: logName,
              resource: MonitoredResource(type: 'gce_instance'),
              textPayload: 'Hello World!',
            ),
          ],
        ),
      );

      if (!TestHttpClient.isReplaying) {
        // Writes are not always committed instantly.
        await Future.delayed(const Duration(seconds: 15));

        addTearDown(
          () => logService.deleteLog(DeleteLogRequest(logName: logName)),
        );
      }

      final list = await logService.listLogEntries(
        ListLogEntriesRequest(
          filter: 'logName:"$logName"',
          orderBy: 'timestamp desc',
          resourceNames: ['projects/$projectId'],
        ),
      );
      expect(list.entries, hasLength(1));
      expect(list.entries[0].severity, LogSeverity.critical);
      expect(list.entries[0].textPayload, 'Hello World!');

      await testClient.endTest();
    });
  });
}
