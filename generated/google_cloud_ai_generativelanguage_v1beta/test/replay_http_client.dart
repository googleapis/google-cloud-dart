import 'dart:convert';
import 'dart:io' as io;

import 'package:async/async.dart';
import 'package:http/http.dart';
import 'package:collection/collection.dart';

enum Mode { Record, Reply, Proxy }

// https://github.com/nwithan8/dartvcr/issues/3
// Betamax
class SavedRequest {
  final Map<String, String> headers;
  final String method;
  final Uri url;
  final List<int> body;

  SavedRequest({
    required this.headers,
    required this.method,
    required this.url,
    required this.body,
  });

  SavedRequest.fromJson(Map<String, dynamic> json)
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

class SavedResponse {
  final int statusCode;
  final Map<String, String> headers;
  final List<int> body;
  final String? reasonPhrase;

  SavedResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    this.reasonPhrase,
  });

  factory SavedResponse.fromJson(Map<String, dynamic> json) {
    return SavedResponse(
      statusCode: json['statusCode'] as int,
      headers: (json['headers'] as Map<String, dynamic>).cast<String, String>(),
      body: base64.decode(json['body'] as String),
      reasonPhrase: json['reasonPhrase'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'statusCode': statusCode,
    'headers': headers,
    'body': base64.encode(body),
    'reasonPhrase': reasonPhrase,
  };
}

class Recording {
  final List<(SavedRequest, SavedResponse)> requestResponse;

  Recording(this.requestResponse);

  factory Recording.fromJson(List<dynamic> json) {
    final requestResponse = <(SavedRequest, SavedResponse)>[];
    for (var r in json.cast<Map<String, dynamic>>()) {
      requestResponse.add((
        SavedRequest.fromJson(r['request']),
        SavedResponse.fromJson(r['response']),
      ));
    }
    return Recording(requestResponse);
  }

  List<dynamic> toJson() {
    final d = <Map<String, dynamic>>[];
    for (final (request, response) in requestResponse) {
      d.add({'request': request, 'response': response});
    }
    return d;
  }
}

class ReplayHttpClient extends BaseClient {
  final Client client;
  final Mode mode;
  String? _path;
  List<(SavedRequest, SavedResponse)> requestResponse =
      <(SavedRequest, SavedResponse)>[];

  ReplayHttpClient({required this.client})
    : mode = bool.fromEnvironment('record') ? Mode.Record : Mode.Reply;

  Future<void> setUp(String path) async {
    _path = path;
    switch (mode) {
      case Mode.Reply:
        final json = jsonDecode(await io.File(path).readAsString()) as List;
        requestResponse = Recording.fromJson(json).requestResponse;
      case Mode.Record:
        break;
      case Mode.Proxy:
        break;
    }
  }

  void _match(SavedRequest savedRequest, BaseRequest request, List<int> body) {
    if (!ListEquality().equals(savedRequest.body, body)) {
      throw Exception('body does not match');
    }

    if (!MapEquality().equals(savedRequest.headers, request.headers)) {
      throw Exception('headers do not match');
    }

    if (savedRequest.url != request.url) {
      throw Exception('url do not match');
    }

    if (savedRequest.method != request.method) {
      throw Exception('method does not match');
    }
  }

  Future<StreamedResponse> replaySend(BaseRequest originalRequest) async {
    final stream = originalRequest.finalize();
    final requestBody = await stream.expand((i) => i).toList();

    final (savedRequest, savedResponse) = requestResponse.removeAt(0);
    _match(savedRequest, originalRequest, requestBody);

    return StreamedResponse(
      Stream.fromIterable([savedResponse.body]),
      savedResponse.statusCode,
      headers: savedResponse.headers,
      reasonPhrase: savedResponse.reasonPhrase,
    );
  }

  Future<StreamedResponse> recordSend(BaseRequest originalRequest) async {
    final stream = originalRequest.finalize();
    final requestBody = await stream.expand((i) => i).toList();

    final forwardedRequest = Request(
      originalRequest.method,
      originalRequest.url,
    );
    forwardedRequest.bodyBytes = requestBody;
    forwardedRequest.headers.addAll(originalRequest.headers);
    final response = await this.client.send(forwardedRequest);
    final responseStream = StreamSplitter(response.stream);
    final r = SavedRequest(
      url: originalRequest.url,
      method: originalRequest.method,
      headers: originalRequest.headers,
      body: requestBody,
    );
    // I don't like how no results are streamed until the end.
    final responseBody = await responseStream.split().expand((i) => i).toList();
    final re = SavedResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: responseBody,
      reasonPhrase: response.reasonPhrase,
    );
    requestResponse.add((r, re));

    return StreamedResponse(
      // TODO: More here!
      responseStream.split(),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest originalRequest) async {
    switch (mode) {
      case Mode.Proxy:
        return client.send(originalRequest);
      case Mode.Record:
        return recordSend(originalRequest);
      case Mode.Reply:
        return replaySend(originalRequest);
    }
  }

  @override
  void close() {
    if (mode == Mode.Record) {
      io.File(
        _path!,
      ).writeAsStringSync(jsonEncode(Recording(requestResponse).toJson()));
    }
    client.close();
  }
}
