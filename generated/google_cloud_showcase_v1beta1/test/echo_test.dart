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

@TestOn('vm')
library echo_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_cloud_protobuf/protobuf.dart' show Any;
import 'package:google_cloud_rpc/rpc.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test_utils/insecure_proxy_http_client.dart';
import 'package:test_utils/test_http_client.dart';
import 'package:path/path.dart' as p;

class AnyTypeName extends CustomMatcher {
  AnyTypeName(dynamic matcher) : super('', 'typeName', matcher);

  @override
  Object? featureValueOf(dynamic actual) {
    return (actual as Any).typeName;
  }
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

  static Future<String> _showcasePath() async {
    return p.join(await _goBinaryPath(), 'bin', 'gapic-showcase');
  }

  ShowcaseServer._(this._process);

  static Future<ShowcaseServer> start() async {
    await _install();
    final process = await Process.start(await _showcasePath(), ["run"]);
    final serverStarted = Completer<void>();
    stderr.addStream(process.stderr);
    process.stdin.close();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains("Listening for REST connections")) {
            serverStarted.complete();
          }
        });
    await serverStarted.future;

    return ShowcaseServer._(process);
  }

  Future<void> stop() async {
    _process.kill(ProcessSignal.sigkill);
  }
}

void main() async {
  late Echo echoService;
  late ShowcaseServer showcaseServer;
  group('echo', () {
    setUpAll(() async {
      showcaseServer = await ShowcaseServer.start();
      echoService = Echo(client: InsecureProxyHttpClient(http.Client()));
    });

    tearDownAll(() async {
      echoService.close();
      showcaseServer.stop();
    });

    test('error details', () async {
      const text = 'the quick brown fox jumps over the lazy dog';
      final request = EchoErrorDetailsRequest(
        singleDetailText: text,
        multiDetailText: [text, text],
      );

      final response = await echoService.echoErrorDetails(request);

      final details = response.singleDetail!.error!.details!;
      final info = details.unpackFrom(ErrorInfo.fromJson);
      expect(info.reason, text);
    });

    test('fail with details', () async {
      const text = 'the quick brown fox jumps over the lazy dog';
      final request = FailEchoWithDetailsRequest(message: text);

      await expectLater(
        () => echoService.failEchoWithDetails(request),
        throwsA(
          isA<StatusException>()
              .having(
                (e) => e.status.code,
                'status.code',
                409, // Aborted
              )
              .having((e) => e.status.details, 'status.details', [
                AnyTypeName('google.rpc.ErrorInfo'),
                AnyTypeName('google.rpc.LocalizedMessage'),
                wrapMatcher((Any x) {
                  final poetryError = x.unpackFrom(PoetryError.fromJson);
                  return poetryError.poem == text;
                }),
                AnyTypeName('google.rpc.RetryInfo'),
                AnyTypeName('google.rpc.DebugInfo'),
                AnyTypeName('google.rpc.QuotaFailure'),
                AnyTypeName('google.rpc.PreconditionFailure'),
                AnyTypeName('google.rpc.BadRequest'),
                AnyTypeName('google.rpc.RequestInfo'),
                AnyTypeName('google.rpc.ResourceInfo'),
                AnyTypeName('google.rpc.Help'),
              ]),
        ),
      );
    });
  });
}
