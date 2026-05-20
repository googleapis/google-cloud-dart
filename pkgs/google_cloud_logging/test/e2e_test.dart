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

@Tags(['google-cloud'])
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

void main() {
  late String serviceName;
  late String projectIdVal;
  late String serviceUrl;

  setUpAll(() async {
    projectIdVal = projectId;

    // Generate a unique service name for Cloud Run.
    final rand = Random().nextInt(1000000);
    serviceName = 'e2e-trace-test-$rand';

    final workspaceRoot = findWorkspaceRoot();

    // Write a temporary Dockerfile in the root directory for Cloud Build.
    final dockerfile = File('${workspaceRoot.path}/Dockerfile');
    await dockerfile.writeAsString('''
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe pkgs/google_cloud_logging/test/e2e_server.dart -o /app/e2e_server

FROM dart:stable
COPY --from=build /app/e2e_server /app/e2e_server
EXPOSE 8080
CMD ["/app/e2e_server"]
''');

    print('Submitting build to Google Cloud Build...');
    final buildResult = await Process.run('gcloud', [
      'builds',
      'submit',
      '--tag',
      'gcr.io/$projectIdVal/$serviceName',
      workspaceRoot.path,
    ]);

    // Clean up the temporary Dockerfile.
    if (await dockerfile.exists()) {
      await dockerfile.delete();
    }

    if (buildResult.exitCode != 0) {
      fail(
        'Failed to build container using Cloud Build: '
        '${buildResult.stderr}\n${buildResult.stdout}',
      );
    }

    print('Deploying to Cloud Run...');
    final deployResult = await Process.run('gcloud', [
      'run',
      'deploy',
      serviceName,
      '--image',
      'gcr.io/$projectIdVal/$serviceName',
      '--platform',
      'managed',
      '--region',
      'us-central1',
      '--allow-unauthenticated',
      '--quiet',
    ]);

    if (deployResult.exitCode != 0) {
      fail(
        'Failed to deploy to Cloud Run: '
        '${deployResult.stderr}\n${deployResult.stdout}',
      );
    }

    // Get the URL of the deployed service.
    final urlResult = await Process.run('gcloud', [
      'run',
      'services',
      'describe',
      serviceName,
      '--platform',
      'managed',
      '--region',
      'us-central1',
      '--format',
      'value(status.url)',
    ]);

    if (urlResult.exitCode != 0) {
      fail('Failed to get Cloud Run service URL: ${urlResult.stderr}');
    }

    serviceUrl = urlResult.stdout.toString().trim();
    print('Deployed E2E service URL: $serviceUrl');
  });

  tearDownAll(() async {
    // Ensure the deployed Cloud Run service and container image are cleaned up.
    print('Cleaning up Cloud Run service: $serviceName');
    await Process.run('gcloud', [
      'run',
      'services',
      'delete',
      serviceName,
      '--platform',
      'managed',
      '--region',
      'us-central1',
      '--quiet',
    ]);

    print('Cleaning up container image: gcr.io/$projectIdVal/$serviceName');
    await Process.run('gcloud', [
      'container',
      'images',
      'delete',
      'gcr.io/$projectIdVal/$serviceName',
      '--force-delete-tags',
      '--quiet',
    ]);
  });

  test('Google Cloud sets traceparent header and server handles it', () async {
    // Send an HTTP request without traceparent header.
    // Google Cloud Load Balancer will set traceparent.
    final response = await http.get(Uri.parse(serviceUrl));
    expect(response.statusCode, HttpStatus.ok);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final traceparent = body['traceparent'] as String?;
    expect(traceparent, isNotNull);
    print('Google Cloud injected traceparent: $traceparent');

    // Extract the trace-id and span-id.
    // W3C format: version-traceId-parentId-flags
    final parts = traceparent!.split('-');
    expect(parts.length, greaterThanOrEqualTo(4));
    final traceId = parts[1];
    final spanId = parts[2];

    print('Polling Cloud Logging for traceId: $traceId and spanId: $spanId');

    // Poll Cloud Logging for the ingested stdout structured log.
    final filter =
        'resource.type="cloud_run_revision" AND '
        'resource.labels.service_name="$serviceName" AND '
        'textPayload:"E2E_TEST_LOG_MESSAGE"';

    Map<String, dynamic>? foundLog;
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final result = await Process.run('gcloud', [
        'logging',
        'read',
        filter,
        '--format=json',
      ]);
      if (result.exitCode == 0) {
        print(result.stdout.toString());
        final entries = jsonDecode(result.stdout.toString()) as List<dynamic>;
        if (entries.isNotEmpty) {
          foundLog = entries.first as Map<String, dynamic>;
          break;
        }
      }
    }

    expect(
      foundLog,
      isNotNull,
      reason: 'Ingested log entry not found in Cloud Logging',
    );
    expect(foundLog!['trace'], contains(traceId));
    expect(foundLog['spanId'], spanId);
  });

  test('Server handles propagated traceparent header set by user', () async {
    // Generate custom valid W3C traceparent.
    const customTraceId = '123456789012345678901234567890ab';
    const customSpanId = '1234567890123456';
    const customTraceparent = '00-$customTraceId-$customSpanId-01';

    final response = await http.get(
      Uri.parse(serviceUrl),
      headers: {'traceparent': customTraceparent},
    );
    expect(response.statusCode, HttpStatus.ok);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final receivedTraceparent = body['traceparent'] as String?;
    expect(receivedTraceparent, isNotNull);
    print('Received traceparent: $receivedTraceparent');

    // W3C format: version-traceId-parentId-flags
    final parts = receivedTraceparent!.split('-');
    expect(parts.length, greaterThanOrEqualTo(4));
    expect(parts[1], customTraceId);

    // Note: the spanId might have been regenerated by the load balancer,
    // but the traceId remains!
    final finalSpanId = parts[2];

    print('Polling Cloud Logging for custom traceId: $customTraceId');

    final filter =
        'resource.type="cloud_run_revision" AND '
        'resource.labels.service_name="$serviceName" AND '
        'textPayload:"E2E_TEST_LOG_MESSAGE"';

    Map<String, dynamic>? foundLog;
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      final result = await Process.run('gcloud', [
        'logging',
        'read',
        filter,
        '--format=json',
      ]);
      if (result.exitCode == 0) {
        final entries = jsonDecode(result.stdout.toString()) as List<dynamic>;
        // Find the entry matching our specific trace ID.
        for (final entry in entries) {
          final map = entry as Map<String, dynamic>;
          if (map['trace'] != null &&
              map['trace'].toString().contains(customTraceId)) {
            foundLog = map;
            break;
          }
        }
      }
      if (foundLog != null) break;
    }

    expect(
      foundLog,
      isNotNull,
      reason: 'Ingested custom log entry not found in Cloud Logging',
    );
    expect(foundLog!['trace'], contains(customTraceId));
    expect(foundLog['spanId'], finalSpanId);
  });
}

Directory findWorkspaceRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/librarian.yaml').existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'Could not find workspace root (librarian.yaml not found)',
      );
    }
    dir = parent;
  }
}
