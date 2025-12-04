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

class RecordedRequest {
  final Map<String, String> headers;
  final String method;
  final Uri url;
  final List<int> body;

  RecordedRequest({
    required this.headers,
    required this.method,
    required this.url,
    required this.body,
  });

  RecordedRequest.fromJson(Map<String, dynamic> json)
    : url = Uri.parse(json['url'] as String),
      method = json['method'] as String,
      headers = (json['headers'] as Map<String, dynamic>)
          .cast<String, String>(),
      body = base64.decode(json['body'] as String);

  Map<String, dynamic> toJson() => {
    'url': url.toString(),
    'method': method,
    'headers': headers,
    'body': base64.encode(body),
  };
}

class RecordedResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;
  final String? reasonPhrase;

  RecordedResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    this.reasonPhrase,
  });

  factory RecordedResponse.fromJson(Map<String, dynamic> json) =>
      RecordedResponse(
        statusCode: json['statusCode'] as int,
        headers: (json['headers'] as Map<String, dynamic>)
            .cast<String, String>(),
        body: utf8.encode(json['body'] as String),
        reasonPhrase: json['reasonPhrase'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'headers': headers,
    'body': utf8.decode(body),
    'reasonPhrase': reasonPhrase,
  };
}

class RecordedSession {
  final List<(RecordedRequest, RecordedResponse)> requestResponse;

  RecordedSession(this.requestResponse);

  factory RecordedSession.fromJson(dynamic json) => RecordedSession([
    for (var r in (json as List).cast<Map<String, dynamic>>())
      (
        RecordedRequest.fromJson(r['request'] as Map<String, dynamic>),
        RecordedResponse.fromJson(r['response'] as Map<String, dynamic>),
      ),
  ]);

  List<dynamic> toJson() => <Map<String, dynamic>>[
    for (final (request, response) in requestResponse)
      {'request': request, 'response': response},
  ];
}
