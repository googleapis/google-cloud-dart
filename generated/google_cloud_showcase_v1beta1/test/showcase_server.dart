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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class PortInUseException implements Exception {
  final String message;

  PortInUseException(this.message);

  @override
  String toString() => 'PortInUseException: $message';
}

/// The Go package of the Showcase server to test against.
const _showcasePackage =
    'github.com/googleapis/gapic-showcase/cmd/gapic-showcase@v0.40.0';

/// The name of the Showcase executable installed by `go install`.
final _showcaseExecutable = Platform.isWindows
    ? 'gapic-showcase.exe'
    : 'gapic-showcase';

class ShowcaseServer {
  final Process _process;

  static Future<ProcessResult> _runGo(List<String> arguments) async {
    final ProcessResult result;
    result = await Process.run('go', arguments);
    if (result.exitCode != 0) {
      throw Exception(
        '`go ${arguments.join(' ')}` failed with exit code ${result.exitCode}: '
        '${result.stderr}',
      );
    }
    return result;
  }

  static Future<void> _install() async {
    // Install showcase rather than running it using `go run` because `go run`
    // will then spawn showcase as a subprocess, which means that we won't be
    // able to kill it.
    await _runGo(['install', _showcasePackage]);
  }

  /// The directory that `go install` puts executables in.
  ///
  /// That is `GOBIN`, if it is set, otherwise the `bin` subdirectory of the
  /// first entry in `GOPATH`.
  static Future<String> _goBinaryDirectory() async {
    // `go env` prints one line per requested variable, in the order that they
    // were requested. Unset variables are printed as empty lines.
    final result = await _runGo(['env', 'GOBIN', 'GOPATH']);
    final lines = const LineSplitter().convert(result.stdout as String);
    if (lines.length < 2) {
      throw Exception(
        'unexpected `go env GOBIN GOPATH` output: ${result.stdout}',
      );
    }
    final goBin = lines[0].trim();
    if (goBin.isNotEmpty) {
      return goBin;
    }

    // `GOPATH` may contain several directories; `go install` uses the first.
    final goPath = lines[1].trim().split(Platform.isWindows ? ';' : ':').first;
    if (goPath.isEmpty) {
      throw Exception('neither `GOBIN` nor `GOPATH` is set');
    }
    return p.join(goPath, 'bin');
  }

  static Future<String> _showcasePath() async =>
      p.join(await _goBinaryDirectory(), _showcaseExecutable);

  ShowcaseServer._(this._process);

  static Future<ShowcaseServer> _run() async {
    final process = await Process.start(await _showcasePath(), ['run']);
    final serverStarted = Completer<ShowcaseServer>();

    await process.stdin.close();

    unawaited(
      process.exitCode.then((exitCode) {
        if (exitCode != 0 && !serverStarted.isCompleted) {
          serverStarted.completeError(
            Exception(
              'Showcase server exited with code $exitCode before starting.',
            ),
          );
        }
      }),
    );

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          stderr.writeln(line);
          if (line.contains('Showcase failed to listen on port')) {
            process.kill(ProcessSignal.sigkill);
            serverStarted.completeError(
              PortInUseException('Showcase port already in use: $line'),
            );
          }
        });

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains('Listening for REST connections')) {
            serverStarted.complete(ShowcaseServer._(process));
          }
        });
    return serverStarted.future;
  }

  static Future<ShowcaseServer> start() async {
    await _install();
    for (var i = 0; ; ++i) {
      try {
        return await _run();
      } on PortInUseException {
        if (i >= 9) {
          rethrow;
        } else {
          stderr.writeln(
            'Showcase port already is already in use (maybe it is being used '
            'by another test?), will try again in 2s.',
          );
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> stop() async {
    _process.kill(ProcessSignal.sigkill);
  }
}
