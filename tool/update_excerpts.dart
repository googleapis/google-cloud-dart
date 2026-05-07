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
import 'package:excerpter/excerpter.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  final isDryRun = args.contains('--dry-run');
  final isFailOnUpdate = args.contains('--fail-on-update');
  final isVerbose = args.contains('--verbose');

  final repositoryRoot = Directory.current.path;
  final pkgsDir = Directory(path.join(repositoryRoot, 'pkgs'));

  if (!pkgsDir.existsSync()) {
    stderr.writeln('Error: Run this script from the repository root.');
    exitCode = 1;
    return;
  }

  // List all package directories in `pkgs/`
  final packages = pkgsDir.listSync().whereType<Directory>().map(
    (dir) => path.basename(dir.path),
  );

  for (final pkgName in packages) {
    final pkgPath = path.join(repositoryRoot, 'pkgs', pkgName);
    final readmeFile = File(path.join(pkgPath, 'README.md'));
    if (!readmeFile.existsSync()) continue;

    if (isVerbose) {
      print('Updating excerpts for package: $pkgName...');
    }

    final updater = Updater(
      baseSourcePath: pkgPath,
      defaultPlasterContent: '···',
      validTargetExtensions: const {'.md'},
      defaultTransforms: [
        SimpleReplaceTransform('//!<br>', ''),
        SimpleReplaceTransform(RegExp(r'ellipsis(<\w+>)?(\(\))?;?'), '...'),
        BackReferenceReplaceTransform(RegExp(r'/\*(\s*\.\.\.\s*)\*/'), '\$1'),
        SimpleReplaceTransform(RegExp(r'[\r\n]+$'), ''),
      ],
    );

    final result = await updater.update(pkgPath, makeUpdates: !isDryRun);

    if (result.excerptsNeedingUpdates > 0 || isVerbose) {
      print(
        'Package $pkgName: processed ${result.filesVisited} files. '
        '${result.excerptsNeedingUpdates} excerpts '
        '${isDryRun ? 'need updates' : 'updated'}.',
      );
    }

    if (result.errors.isNotEmpty) {
      for (final error in result.errors) {
        stderr.writeln('  Error in $pkgName: $error');
      }
      exitCode = 1;
    }

    if (isFailOnUpdate && result.excerptsNeedingUpdates > 0) {
      stderr.writeln('  Error: Excerpts are out of sync in $pkgName!');
      exitCode = 1;
    }
  }

  if (exitCode == 0 && isVerbose) {
    print('All excerpts processed successfully!');
  }
}
