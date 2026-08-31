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

import 'dart:io';

void main() async {
  final protosDir = Directory('protos');
  if (!protosDir.existsSync()) {
    print('Protos directory not found! Please run fetch_protos.dart first.');
    exit(1);
  }

  print('Compiling protos...');
  final pluginScript = Platform.isWindows
      ? 'tool/protoc-gen-dart.bat'
      : 'tool/protoc-gen-dart.sh';
  final result = Process.runSync('protoc', [
    '--plugin=protoc-gen-dart=$pluginScript',
    '--dart_out=grpc:lib/src/generated',
    '-I',
    'protos',
    'protos/google/pubsub/v1/pubsub.proto',
    'protos/google/pubsub/v1/schema.proto',
  ]);

  print(result.stdout);
  print(result.stderr);

  if (result.exitCode != 0) {
    print('Failed to compile protos!');
    exit(1);
  }

  final generatedDir = Directory('lib/src/generated');
  if (generatedDir.existsSync()) {
    final files = generatedDir.listSync(recursive: true);
    for (final file in files) {
      if (file is File && file.path.endsWith('.pbjson.dart')) {
        file.deleteSync();
      }
    }
  }

  print('Successfully compiled protos!');
}
