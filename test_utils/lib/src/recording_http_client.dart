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

import 'package:async/async.dart';
import 'package:http/http.dart';

import 'model.dart';
import 'test_http_client.dart';

class RecordingHttpClient extends TestHttpClient {
  final Client client;
  String? _path;
  List<(RecordedRequest, RecordedResponse)> requestResponse = [];
  Future<void>? _lastSave;

  RecordingHttpClient({required this.client});

  @override
  Future<void> startTest(Symbol library, String test) async {
    _path = TestHttpClient.recordPath(library, test);
  }

  @override
  Future<void> endTest() async {
    await _lastSave;
    await File(_path!).writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(RecordedSession(requestResponse).toJson()),
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest originalRequest) async {
    await _lastSave;
    _lastSave = null;

    final stream = originalRequest.finalize();
    final requestBody = await stream.expand((i) => i).toList();

    final forwardedRequest = Request(
      originalRequest.method,
      originalRequest.url,
    )..bodyBytes = requestBody;

    forwardedRequest.headers.addAll(originalRequest.headers);
    final response = await client.send(forwardedRequest);
    final responseStream = StreamSplitter(response.stream);
    final recordedRequest = RecordedRequest(
      url: originalRequest.url,
      method: originalRequest.method,
      headers: originalRequest.headers,
      body: requestBody,
    );

    _lastSave = responseStream.split().expand((i) => i).toList().then((
      responseBody,
    ) {
      final recordedResponse = RecordedResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: responseBody,
        reasonPhrase: response.reasonPhrase,
      );
      requestResponse.add((recordedRequest, recordedResponse));
    });

    return StreamedResponse(
      // TODO: More here!
      responseStream.split(),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() => client.close();
}
