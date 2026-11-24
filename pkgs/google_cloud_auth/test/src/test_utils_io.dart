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

import 'package:test/test.dart';

/// The value of the environment variable [name], or `null` if unset.
String? readEnvironment(String name) => Platform.environment[name];

/// Writes [content] to [filename] in a temporary directory cleaned up after the
/// test completes.
Future<String> writeTempFile(String filename, String content) async {
  final tempDir = await Directory.systemTemp.createTemp('sa_test_');
  addTearDown(() async {
    await tempDir.delete(recursive: true);
  });
  final tempFile = File('${tempDir.path}/$filename');
  await tempFile.writeAsString(content);
  return tempFile.path;
}
