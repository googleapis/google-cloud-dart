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
/// repository and inject it into DEVELOPER_GUIDE.md, and generate a table of
/// packages and inject it into README.md.
///
/// It must be run from the root directory.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final result = _generateMermaidDiagram();

  // Update DEVELOPER_GUIDE.md
  _updateSection(
    filePath: 'DEVELOPER_GUIDE.md',
    startMarker: '<!-- DEPS_DIAGRAM_START -->',
    endMarker: '<!-- DEPS_DIAGRAM_END -->',
    newContent: result.content,
  );

  // Update README.md
  _updateSection(
    filePath: 'README.md',
    startMarker: '<!-- PKG_TABLE_START -->',
    endMarker: '<!-- PKG_TABLE_END -->',
    newContent: _generatePackageTable(result.publishablePackages),
  );
}

({String content, Set<String> publishablePackages}) _generateMermaidDiagram() {
  final results = Process.runSync(Platform.resolvedExecutable, [
    'pub',
    'deps',
    '--json',
  ]);

  if (results.exitCode != 0) {
    stderr
      ..writeln('Failed to get dependencies:')
      ..writeln(results.stderr);
    exitCode = results.exitCode;
    throw ProcessException(
      'pub',
      ['deps', '--json'],
      results.stderr as String,
      results.exitCode,
    );
  }

  final json = jsonDecode(results.stdout as String) as Map<String, dynamic>;
  final packageMaps = (json['packages'] as List).cast<Map<String, dynamic>>();

  final publishablePackages = <String>{};
  final dependencies = <String, Set<String>>{};

  for (final packageMap in packageMaps) {
    final packageName = packageMap['name'] as String;
    final packageVersion = packageMap['version'] as String;

    // Only consider packages in our google_cloud ecosystem that are publishable
    if (packageName.startsWith('google_cloud')) {
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

  // Compute dependency tiers (topological ranks) dynamically
  final tiers = <List<String>>[];
  final remaining = Set<String>.from(publishablePackages);
  final visited = <String>{};

  while (remaining.isNotEmpty) {
    final currentTier = <String>[];
    for (final pkg in remaining) {
      final deps = connections[pkg] ?? {};
      if (visited.containsAll(deps)) {
        currentTier.add(pkg);
      }
    }
    if (currentTier.isEmpty) {
      // Break out of potential cycle loops
      currentTier.addAll(remaining);
    }
    currentTier.sort();
    tiers.add(currentTier);
    visited.addAll(currentTier);
    remaining.removeAll(currentTier);
  }

  // Construct the Mermaid diagram block
  final buffer = StringBuffer()
    ..writeln('```mermaid')
    ..writeln('graph TD');

  // Output Subgraphs per Tier
  for (var i = 0; i < tiers.length; i++) {
    final String tierName;
    if (i == 0) {
      tierName = 'Tier 0 (Publish First)';
    } else if (i == tiers.length - 1) {
      tierName = 'Tier $i (Publish Last)';
    } else {
      tierName = 'Tier $i';
    }

    buffer.writeln('  subgraph Tier$i ["$tierName"]');
    for (final pkg in tiers[i]) {
      final label = pkg.startsWith('google_cloud_')
          ? pkg.substring('google_cloud_'.length)
          : pkg;
      buffer.writeln('    $pkg["$label"]');
    }
    buffer.writeln('  end\n');
  }

  // Sort and output Link Declarations
  final sortedPackages = publishablePackages.toList()..sort();
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

  return (content: buffer.toString(), publishablePackages: publishablePackages);
}

String _generatePackageTable(Set<String> publishablePackages) {
  final results = Process.runSync(Platform.resolvedExecutable, [
    'pub',
    'workspace',
    'list',
    '--json',
  ]);

  if (results.exitCode != 0) {
    stderr.writeln('Failed to list workspace packages');
    throw ProcessException(
      'pub',
      ['workspace', 'list', '--json'],
      results.stderr as String,
      results.exitCode,
    );
  }

  final json = jsonDecode(results.stdout as String) as Map<String, dynamic>;
  final packages =
      (json['packages'] as List)
          .cast<Map<String, dynamic>>()
          .map((m) => (name: m['name'] as String, path: m['path'] as String))
          .where((p) => publishablePackages.contains(p.name))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  final currentPath = Directory.current.absolute.path;

  final tableBuffer = StringBuffer()
    ..writeln('| Package | Version | Source |')
    ..writeln('|---|---|---|');

  for (final pkg in packages) {
    final relPath = p.posix.joinAll(
      p.split(p.relative(pkg.path, from: currentPath)),
    );
    tableBuffer.writeln(
      '| [`${pkg.name}`](https://pub.dev/packages/${pkg.name}) '
      '| [![pub package](https://img.shields.io/pub/v/${pkg.name}.svg)](https://pub.dev/packages/${pkg.name}) '
      '| [$relPath]($relPath) |',
    );
  }

  return tableBuffer.toString();
}

void _updateSection({
  required String filePath,
  required String startMarker,
  required String endMarker,
  required String newContent,
}) {
  final file = File(filePath);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: $filePath does not exist');
    exitCode = 2; // ENOENT - file not found
    return;
  }

  final content = file.readAsStringSync();

  final startIndex = content.indexOf(startMarker);
  final endIndex = content.indexOf(endMarker);

  if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
    stderr.writeln(
      'ERROR: Could not find valid markers ($startMarker, $endMarker) '
      'in $filePath',
    );
    exitCode = 75; // EPROTO - invalid protocol
    return;
  }

  final updatedContent =
      '${content.substring(0, startIndex + startMarker.length)}\n'
      '$newContent'
      '${content.substring(endIndex)}';

  file.writeAsStringSync(updatedContent);
  print('Successfully updated $filePath');
}
