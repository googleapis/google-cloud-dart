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

@TestOn('vm')
library;

import 'dart:io';

import 'package:google_cloud_storage/src/version.dart';
import 'package:test/test.dart';

void main() {
  test('packageVersion matches pubspec.yaml', () {
    final pkgPubspec = File('pkgs/google_cloud_storage/pubspec.yaml');
    final pubspecFile = pkgPubspec.existsSync()
        ? pkgPubspec
        : File('pubspec.yaml');
    expect(pubspecFile.existsSync(), isTrue, reason: 'pubspec.yaml must exist');

    final content = pubspecFile.readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(content);
    expect(
      match,
      isNotNull,
      reason: 'version must be declared in pubspec.yaml',
    );

    final pubspecVersion = match!.group(1);
    expect(
      packageVersion,
      pubspecVersion,
      reason:
          'packageVersion in lib/src/version.dart ($packageVersion) must match '
          'version in pubspec.yaml ($pubspecVersion).',
    );
  });
}
