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
  {{EDGES}}
}
''';

void main() {
  final results = Process.runSync('dart', ['pub', 'deps', '--json']);

  final json = jsonDecode(results.stdout as String) as Map<String, dynamic>;
  final packages = (json['packages'] as List).cast<Map<String, dynamic>>();
  final connections = StringBuffer();

  for (final package in packages) {
    final packageName = package['name'] as String;
    if (packageName.startsWith('google_cloud')) {
      final dependencies = (package['directDependencies'] as List)
          .cast<String>();
      for (final dependency in dependencies) {
        if (!dependency.startsWith('google_cloud')) {
          connections.writeln('"$dependency" [fillcolor="grey"]');
        }

        connections.writeln('"$packageName" -> "$dependency";');
      }
    }
  }

  final tmpDir = Directory.systemTemp.createTempSync('deps');
  final path = '${tmpDir.path}/deps.dot';

  File(path).writeAsStringSync(
    dotTemplate.replaceFirst('{{EDGES}}', connections.toString()),
  );

  Process.runSync('dot', ['-Tpng', path, '-o', 'deps.png']);
}
