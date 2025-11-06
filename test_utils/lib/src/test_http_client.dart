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

import 'package:http/http.dart';

import 'proxy_http_client.dart';
import 'recording_http_client.dart';
import 'replay_http_client.dart';

/// An HTTP client that can be used record requests/responses and replay them
/// later.
///
/// This works similarly to `package:dartvcr` but fixes some issues, e.g.
/// https://github.com/nwithan8/dartvcr/issues/3
///
/// It has 3 modes:
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
abstract class TestHttpClient extends BaseClient {
  final Client client;

  TestHttpClient({required this.client});

  Future<void> startTest(String path);
  Future<void> endTest();

  // ignore: prefer_expression_function_bodies
  factory TestHttpClient.fromEnvironment(Client client) {
    return switch (const String.fromEnvironment(
      'http',
      defaultValue: 'replay',
    )) {
      'replay' => ReplayHttpClient(client: client),
      'record' => RecordingHttpClient(client: client),
      'proxy' => ProxyHttpClient(client: client),
      final x => throw ArgumentError.value(
        x,
        'http',
        'unexpected environment setting',
      ),
    };
  }
}
