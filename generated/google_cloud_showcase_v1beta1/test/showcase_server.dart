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

class ShowcaseServer {
  final Process _process;

  static Future<void> _install() async {
    // Install showcase rather than running it using `go run` because `go run`
    // will then spawn showcase as a subprocess, which means that we don't be
    // able to kill it.
    final result = await Process.run('go', [
      'install',
      'github.com/googleapis/gapic-showcase/cmd/gapic-showcase@latest',
    ]);
    if (result.exitCode != 0) {
      throw Exception('showcase installation failed ${result.stderr}');
    }
  }

  static Future<String> _goBinaryPath() async {
    final result = await Process.run('go', ['env', 'GOPATH']);
    if (result.exitCode != 0) {
      throw Exception('go env GOPATH failed ${result.stderr}');
    }
    return (result.stdout as String).trim();
  }

  static Future<String> _showcasePath() async =>
      p.join(await _goBinaryPath(), 'bin', 'gapic-showcase');

  ShowcaseServer._(this._process);

  static Future<ShowcaseServer> _run() async {
    final process = await Process.start(await _showcasePath(), ['run']);
    final serverStarted = Completer<ShowcaseServer>();

    await process.stdin.close();

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains('Showcase failed to listen on port')) {
            process.kill(ProcessSignal.sigkill);
            serverStarted.completeError(
              PortInUseException('Showcase port already in use: $line'),
            );
          }
          if (serverStarted.isCompleted) stderr.writeln(line);
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
      } on PortInUseException catch (e) {
        if (i == 10) {
          rethrow;
        } else {
          stderr.writeln(
            'Showcase port already is use (maybe it is being used by '
            'another test?), will try again in 2s.',
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
