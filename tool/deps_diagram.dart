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

/// Generate a diagram showing the relationship between packages in this
/// repository and inject it into target markdown files.
///
/// It must be run from the root directory.
library;

import 'dart:convert';
import 'dart:io';

void main() {
  final results = Process.runSync(Platform.resolvedExecutable, [
    'pub',
    'deps',
    '--json',
  ]);

  if (results.exitCode != 0) {
    print('Failed to get dependencies:');
    print(results.stderr);
    exitCode = results.exitCode;
    return;
  }

  final json = jsonDecode(results.stdout as String) as Map<String, dynamic>;
  final packageMaps = (json['packages'] as List).cast<Map<String, dynamic>>();

  final publishablePackages = <String>{};
  final dependencies = <String, Set<String>>{};

  for (final packageMap in packageMaps) {
    final packageName = packageMap['name'] as String;
    final packageVersion = packageMap['version'] as String;

    // Only consider packages in our google_cloud ecosystem that are publishable
    if (packageName.startsWith('google_cloud') ||
        packageName == 'google_cloud') {
      if (packageVersion != '0.0.0') {
        publishablePackages.add(packageName);
        final directDeps = (packageMap['directDependencies'] as List)
            .cast<String>();
        dependencies[packageName] = directDeps.toSet();
      }
    }
  }

  // Build connections only between publishable workspace packages
  final connections = <String, Set<String>>{};
  for (final packageName in publishablePackages) {
    final directDeps = dependencies[packageName] ?? {};
    for (final dep in directDeps) {
      if (publishablePackages.contains(dep)) {
        connections.putIfAbsent(packageName, () => {}).add(dep);
      }
    }
  }

  // Construct the Mermaid diagram block
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph TD');

  // Sort packages alphabetically to ensure deterministic output
  final sortedPackages = publishablePackages.toList()..sort();

  // Output Node Declarations with clean, short labels
  for (final pkg in sortedPackages) {
    final label = pkg == 'google_cloud'
        ? 'google_cloud'
        : pkg.substring('google_cloud_'.length);
    buffer.writeln('  $pkg["$label"]');
  }

  buffer.writeln();

  // Sort and output Link Declarations
  final sortedConnections = <String>[];
  for (final pkg in sortedPackages) {
    final targets = connections[pkg] ?? {};
    final sortedTargets = targets.toList()..sort();
    for (final target in sortedTargets) {
      sortedConnections.add('  $pkg --> $target');
    }
  }
  buffer
    ..write(sortedConnections.join('\n'))
    ..writeln()
    ..writeln('```');

  final mermaidDiagram = buffer.toString();

  // Update the target markdown files
  _updateFile('DEVELOPER_GUIDE.md', mermaidDiagram);
}

void _updateFile(String filePath, String mermaidDiagram) {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('Skipped: $filePath does not exist');
    return;
  }

  final content = file.readAsStringSync();
  const startMarker = '<!-- DEPS_DIAGRAM_START -->';
  const endMarker = '<!-- DEPS_DIAGRAM_END -->';

  final startIndex = content.indexOf(startMarker);
  final endIndex = content.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1) {
    print('Warning: Could not find markers in $filePath');
    return;
  }

  final updatedContent =
      '${content.substring(0, startIndex + startMarker.length)}\n'
      '$mermaidDiagram\n'
      '${content.substring(endIndex)}';

  file.writeAsStringSync(updatedContent);
  print('Successfully updated $filePath');
}
