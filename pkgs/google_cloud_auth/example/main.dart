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

import 'package:google_cloud_auth/google_cloud_auth.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run example/main.dart <path-to-service-account.json>',
    );
    exitCode = 1;
    return;
  }

  final path = args.first;
  final credentials = await ServiceAccountCredentials.fromServiceAccountFile(
    path,
  );

  print('Service Account Email : ${credentials.clientEmail}');
  print('Project ID            : ${credentials.projectId ?? '(not set)'}');
  print('Client ID             : ${credentials.clientId ?? '(not set)'}');
  print('Private Key ID        : ${credentials.privateKeyId ?? '(not set)'}');
  print('Token URI             : ${credentials.tokenUri}');
  print('Universe Domain       : ${credentials.universeDomain}');

  final sampleMessage = utf8.encode('Hello from google_cloud_auth');
  final signature = await credentials.sign(sampleMessage);
  print(
    'Sample Signature (b64): ${base64.encode(signature).substring(0, 32)}...',
  );
}
