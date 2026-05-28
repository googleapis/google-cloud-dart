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

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../random.dart';
import 'cloud.dart';

const _dockerTemplate = '''
FROM debian:stable-slim

WORKDIR /app

# Copy the server
COPY server /app/server

# Start server.
EXPOSE 8080
CMD ["/app/server"]
''';

/// The absolute path of the repository on the local file system.
String get repoRoot {
  var dir = Directory.current.absolute;
  while (true) {
    if (File(p.join(dir.path, 'librarian.yaml')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  throw StateError(
    'Could not find repository root starting from ${Directory.current.path}',
  );
}

/// Runs Dart programs using Google Cloud Run.
class CloudRunner {
  final Uri serverUri;
  final String serviceName;
  final Directory _tempDir;

  CloudRunner._({
    required this.serverUri,
    required this.serviceName,
    required Directory tempDir,
  }) : _tempDir = tempDir;

  /// Runs the given Dart program using Google Cloud Run.
  ///
  /// [dartPath] must be a path, relative to the workspace root, to a Dart
  /// program. For example, `'pkgs/google_cloud_shelf/test/e2e_server.dart'`.
  static Future<CloudRunner> start(String dartPath) async {
    final dir = Directory.systemTemp.createTempSync('cloud_runner_');
    final serverPath = p.join(dir.absolute.path, 'server');
    final dockerPath = p.join(dir.absolute.path, 'Dockerfile');
    final sourcePath = p.join(repoRoot, dartPath);

    final compile = await Process.run('dart', [
      'compile',
      'exe',
      '--target-os=linux',
      '--target-arch=x64',
      '--output=$serverPath',
      sourcePath,
    ]);
    if (compile.exitCode != 0) {
      throw StateError(
        'Failed to compile server:\n'
        'STDOUT:\n${compile.stdout}\n'
        'STDERR:\n${compile.stderr}',
      );
    }

    await File(dockerPath).writeAsString(_dockerTemplate);

    final now = DateTime.now();
    final serviceName =
        'cloud-runner-${now.year}-${now.month}-${now.day}-'
        '${randomAlphaNumString(10)}';

    // Start a server using the gcloud command.
    final deploy = await Process.run('gcloud', [
      'run',
      'deploy',
      if (projectId == 'dart-sdk-testing') ...[
        '--build-service-account',
        'projects/dart-sdk-testing/serviceAccounts/integration-test-runner@dart-sdk-testing.iam.gserviceaccount.com',
      ],
      serviceName,
      '--source',
      dir.absolute.path,
      '--region',
      'us-central1',
      '--allow-unauthenticated',
      '--quiet',
      '--project',
      projectId,
    ]);

    if (deploy.exitCode != 0) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
      throw StateError(
        'Failed to deploy service to Cloud Run:\n'
        'STDOUT:\n${deploy.stdout}\n'
        'STDERR:\n${deploy.stderr}',
      );
    }

    final describe = await Process.run('gcloud', [
      'run',
      'services',
      'describe',
      serviceName,
      '--region',
      'us-central1',
      '--format',
      'value(status.url)',
      '--project',
      projectId,
    ]);

    if (describe.exitCode != 0) {
      await _deleteService(serviceName);
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
      throw StateError(
        'Failed to get Cloud Run service URL:\n'
        'STDOUT:\n${describe.stdout}\n'
        'STDERR:\n${describe.stderr}',
      );
    }

    final serverUri = Uri.parse(describe.stdout.toString().trim());

    return CloudRunner._(
      serverUri: serverUri,
      serviceName: serviceName,
      tempDir: dir,
    );
  }

  static Future<void> _deleteService(String name) async {
    await Process.run('gcloud', [
      'run',
      'services',
      'delete',
      name,
      '--region',
      'us-central1',
      '--quiet',
      '--project',
      projectId,
    ]);
  }

  /// Gets an ID token for the service URL.
  Future<String?> getIdToken() async {
    // 1. Try Metadata Server with dynamic service account discovery
    try {
      final client = HttpClient();
      final listUri = Uri.parse(
        'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/',
      );
      print('Listing service accounts from Metadata Server: $listUri');
      final listRequest = await client.getUrl(listUri);
      listRequest.headers.add('Metadata-Flavor', 'Google');
      final listResponse = await listRequest.close();
      print('Metadata Server list response status: ${listResponse.statusCode}');

      if (listResponse.statusCode == 200) {
        final listBody = await listResponse.transform(utf8.decoder).join();
        final accounts = listBody
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => e.endsWith('/') ? e.substring(0, e.length - 1) : e)
            .toList();
        print('Discovered service accounts: $accounts');

        for (final accountName in accounts) {
          try {
            final tokenUri = Uri.parse(
              'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/$accountName/identity?audience=${serverUri.toString()}',
            );
            print(
              'Trying to get ID token for account "$accountName" at: $tokenUri',
            );
            final requestToken = await client.getUrl(tokenUri);
            requestToken.headers.add('Metadata-Flavor', 'Google');
            final responseToken = await requestToken.close();
            if (responseToken.statusCode == 200) {
              final tokenBody = await responseToken
                  .transform(utf8.decoder)
                  .join();
              print('Successfully got ID token for account: $accountName');
              return tokenBody.trim();
            } else {
              final tokenBody = await responseToken
                  .transform(utf8.decoder)
                  .join();
              print(
                'Failed to get ID token for account $accountName: '
                '$tokenBody (${responseToken.statusCode})',
              );
            }
          } catch (e) {
            print('Error getting ID token for account $accountName: $e');
          }
        }
      } else {
        final listBody = await listResponse.transform(utf8.decoder).join();
        print('Listing service accounts failed: $listBody');
      }
    } catch (e, s) {
      print('Metadata Server error: $e\n$s');
    }

    // 2. Try gcloud auth print-identity-token
    try {
      print('Running gcloud auth print-identity-token...');
      final result = await Process.run('gcloud', [
        'auth',
        'print-identity-token',
        '--audiences=${serverUri.toString()}',
      ]);
      print('gcloud exitCode: ${result.exitCode}');
      print('gcloud STDOUT: ${result.stdout}');
      print('gcloud STDERR: ${result.stderr}');
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e, s) {
      print('gcloud run error: $e\n$s');
    }

    print('Failed to obtain any ID token!');
    return null;
  }

  /// Terminate the Google Cloud Run service.
  Future<void> stop() async {
    await _deleteService(serviceName);
    try {
      await _tempDir.delete(recursive: true);
    } catch (_) {}
  }
}
