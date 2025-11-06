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

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';

import 'model.dart';
import 'test_http_client.dart';

class ReplayHttpClient extends TestHttpClient {
  List<(RecordedRequest, RecordedResponse)> _requestResponse = [];

  ReplayHttpClient({required super.client});

  @override
  Future<void> startTest(String path) async {
    _requestResponse = RecordedSession.fromJson(
      jsonDecode(await File(path).readAsString()),
    ).requestResponse;
  }

  @override
  Future<void> endTest() async {
    if (_requestResponse.isNotEmpty) {
      throw StateError('test completed without sending all expected requests');
    }
  }

  void _matchRequest(
    RecordedRequest recordedRequest,
    BaseRequest request,
    List<int> body,
  ) {
    if (recordedRequest.url != request.url) {
      throw StateError(
        'recorded request URL ${recordedRequest.url} '
        'does not match ${request.url}',
      );
    }

    if (recordedRequest.method != request.method) {
      throw StateError(
        'recorded request method ${recordedRequest.method} '
        'does not match ${request.method}',
      );
    }

    if (!const MapEquality<void, void>().equals(
      recordedRequest.headers,
      request.headers,
    )) {
      throw StateError(
        'recorded headers ${recordedRequest.headers} '
        'do not match ${request.headers}',
      );
    }

    if (!const ListEquality<void>().equals(recordedRequest.body, body)) {
      try {
        throw StateError(
          'recorded body ${utf8.decode(recordedRequest.body)} '
          'does not match ${utf8.decode(body)}',
        );
      } on FormatException {
        throw StateError(
          'recorded body ${recordedRequest.body} does not match $body',
        );
      }
    }
  }

  @override
  Future<StreamedResponse> send(BaseRequest originalRequest) async {
    final stream = originalRequest.finalize();
    final requestBody = await stream.expand((i) => i).toList();

    final (savedRequest, savedResponse) = _requestResponse.removeAt(0);
    _matchRequest(savedRequest, originalRequest, requestBody);

    return StreamedResponse(
      Stream.fromIterable([savedResponse.body]),
      savedResponse.statusCode,
      headers: savedResponse.headers,
      reasonPhrase: savedResponse.reasonPhrase,
    );
  }

  @override
  void close() {
    client.close();
  }
}
