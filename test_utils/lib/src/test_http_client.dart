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
import 'dart:isolate';

import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import 'proxy_http_client.dart';
import 'recording_http_client.dart';
import 'replay_http_client.dart';

/// An HTTP client that can be used record requests/responses and replay them
/// later.
///
/// This works similarly to `package:dartvcr` but fixes some issues, e.g.
/// https://github.com/nwithan8/dartvcr/issues/3
///
/// It has 3 modes, controlled by the `http` define:
///
/// 1. `dart --define=http=record test -c vm:source`
///
///     Make real HTTP requests and record the responses for later replay.
///
/// 2. `dart --define=http=replay test -c vm:source` (the default mode)
///
///     Respond to requests with the previously recorded responses.
///
/// 3. `dart --define=http=proxy test -c vm:source`
///
///    Pass through requests/responses without recording or modifying them.
///
///
/// In replay mode, the request passed to `Client.send` must exactly match the
/// recorded request in terms of:
/// 1. request method
/// 2. request URI
/// 3. request headers (except for `'x-goog-api-client'`)
/// 4. request body
abstract class TestHttpClient extends BaseClient {
  /// Indicates that a test is about to start.
  ///
  /// `packageName` is the name of the package executing the test, e.g.
  /// `'google_cloud_ai_generativelanguage_v1beta'`.
  ///
  /// `test` is a name for the test, e.g. `'model_list'`.
  Future<void> startTest(String packageName, String test);

  /// Indicates that the test has completed.
  Future<void> endTest();

  static Future<TestHttpClient> fromEnvironment(
    Future<Client> Function() clientFn,
  ) async =>
      switch (const String.fromEnvironment('http', defaultValue: 'replay')) {
        'replay' => ReplayHttpClient(),
        'record' => RecordingHttpClient(await clientFn()),
        'proxy' => ProxyHttpClient(await clientFn()),
        final x => throw ArgumentError.value(
          x,
          'http',
          'unexpected environment setting',
        ),
      };

  static bool get isRecording =>
      const String.fromEnvironment('http', defaultValue: 'replay') == 'record';

  static bool get isReplaying =>
      const String.fromEnvironment('http', defaultValue: 'replay') == 'replay';

  static FutureOr<String> recordPath(String packageName, String test) async {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:$packageName/'),
    );

    return p.setExtension(
      p.join(p.dirname(packageUri!.path), 'test', '${test}_recording'),
      '.json',
    );
  }
}
