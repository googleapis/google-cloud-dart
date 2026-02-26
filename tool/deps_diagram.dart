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
/// repository.
///
/// It must be run from the root directory and graphviz must be installed.
library;

import 'dart:convert';
import 'dart:io';

const dotTemplate = '''
digraph "" {
  rankdir = TB;
  graph [style=rounded fontname="Arial Black" fontsize=13 penwidth=2.6];
  node [shape=rect style="filled,rounded" fontname=Arial fontsize=15 fillcolor=Lavender penwidth=1.3];
  edge [penwidth=1.3];
{{HEADERS}}
{{EDGES}}
}
''';

const noPublishVersion = '0.0.0';

class Package implements Comparable<Package> {
  static Map<String, Package> namesToPackages = {};
  final String name;
  final Set<Package> deps = {};

  static Package putIfAbsent(String packageName) => Package.namesToPackages
      .putIfAbsent(packageName, () => Package(packageName));

  Package(this.name);

  @override
  String toString() => name;

  @override
  int compareTo(Package other) => name.compareTo(other.name);
}

void main() {
  final results = Process.runSync('dart', ['pub', 'deps', '--json']);

  final json = jsonDecode(results.stdout as String) as Map<String, dynamic>;
  final packageMaps = (json['packages'] as List).cast<Map<String, dynamic>>();
  final connections = StringBuffer();
  final headers = StringBuffer();

  for (final packageMap in packageMaps) {
    final packageName = packageMap['name'] as String;
    final packageVersion = packageMap['version'] as String;
    if (packageName.startsWith('google_cloud') &&
        packageVersion != noPublishVersion &&
        // `package:google_cloud` is not (yet!) part of this workspace.
        packageName != 'google_cloud') {
      final package = Package.putIfAbsent(packageName);
      final dependencies = (packageMap['directDependencies'] as List)
          .cast<String>();
      for (final dependencyName in dependencies) {
        final dependency = Package.putIfAbsent(dependencyName);
        package.deps.add(dependency);
        connections.writeln('"$packageName" -> "$dependencyName";');
      }
    }
  }

  // Color all foreign packages grey.
  for (final package in Package.namesToPackages.values) {
    if (!package.name.startsWith('google_cloud')) {
      headers.writeln('"${package.name}" [fillcolor="grey"]');
    }
  }

  // Put all of the packages with common dependencies on the same level of the
  // graph.
  final remaining = Set<Package>.from(Package.namesToPackages.values);
  final visited = <Package>{};
  while (remaining.isNotEmpty) {
    final rank = <Package>[];
    for (final p in remaining) {
      if (visited.containsAll(p.deps)) {
        rank.add(p);
      }
    }
    headers.writeln(
      '{ rank = same; ${[for (final p in rank) '"${p.name}"'].join(" ")}}',
    );
    visited.addAll(rank);
    remaining.removeAll(rank);
  }

  final tmpDir = Directory.systemTemp.createTempSync('deps');
  final path = '${tmpDir.path}/deps.dot';
  print(path);

  File(path).writeAsStringSync(
    dotTemplate
        .replaceFirst('{{HEADERS}}', headers.toString())
        .replaceFirst('{{EDGES}}', connections.toString()),
  );

  Process.runSync('dot', ['-Tpng', path, '-o', 'deps.png']);
}
