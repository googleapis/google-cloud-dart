// Copyright 2022 Google LLC
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
import 'dart:isolate';

import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

void main() {
  group('listenPort', () {
    late String listenPortPrint;

    setUpAll(() async {
      final packageUri = await Isolate.resolvePackageUri(
        Uri.parse('package:shelf_google_cloud/'),
      );
      listenPortPrint = packageUri!
          .resolve('../test/src/listen_port_print.dart')
          .toFilePath();
    });

    test(
      'no environment',
      onPlatform: {
        'windows': const Skip('TODO: no idea why this is failing on windows'),
      },
      () async {
        final proc = await _run(listenPortPrint);

        await expectLater(proc.stderr, emitsDone);
        await expectLater(proc.stdout, emits('8080'));

        await proc.shouldExit(0);
      },
    );

    test('environment set', () async {
      final proc = await _run(listenPortPrint, environment: {'PORT': '8123'});

      await expectLater(proc.stderr, emitsDone);
      await expectLater(proc.stdout, emits('8123'));

      await proc.shouldExit(0);
    });
  });

  group(
    'waitForTerminate',
    onPlatform: {'windows': const Skip('Cannot validate tests on windows.')},
    () {
      late String terminatePrint;

      setUpAll(() async {
        final packageUri = await Isolate.resolvePackageUri(
          Uri.parse('package:shelf_google_cloud/'),
        );
        terminatePrint = packageUri!
            .resolve('../test/src/terminate_print.dart')
            .toFilePath();
      });

      test('sigint', () async {
        final proc = await _run(terminatePrint);

        await expectLater(proc.stdout, emits('waiting for termination'));
        await Future<void>.delayed(const Duration(seconds: 1));
        proc.signal(ProcessSignal.sigint);
        await expectLater(
          proc.stdout,
          emitsInOrder([
            '',
            'Received signal SIGINT - closing',
            'done!',
            emitsDone,
          ]),
        );

        await proc.shouldExit(0);
      });

      test('sigterm', () async {
        final proc = await _run(terminatePrint);

        await expectLater(proc.stdout, emits('waiting for termination'));

        await Future<void>.delayed(const Duration(seconds: 1));

        proc.signal(ProcessSignal.sigterm);
        await expectLater(
          proc.stdout,
          emitsInOrder([
            '',
            'Received signal SIGTERM - closing',
            'done!',
            emitsDone,
          ]),
        );

        await proc.shouldExit(0);
      });
    },
  );
}

Future<TestProcess> _run(
  String dartScript, {
  Map<String, String>? environment,
}) {
  final env = {
    if (Platform.isWindows) ..._minimalWindowsEnvironment,
    ...?environment,
  };
  return TestProcess.start(
    Platform.resolvedExecutable,
    [dartScript],
    environment: env,
    includeParentEnvironment: false,
  );
}

/// A minimal set of environment variables required for basic system and
/// networking functionality on Windows when `includeParentEnvironment` is set
/// to `false`.
///
/// Without these, even loopback connections and basic file operations may fail.
Map<String, String> get _minimalWindowsEnvironment => {
  for (var key in ['SystemRoot', 'SystemDrive', 'TEMP', 'TMP'])
    if (Platform.environment.containsKey(key)) key: Platform.environment[key]!,
};
