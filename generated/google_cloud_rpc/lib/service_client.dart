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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:http/http.dart' as http;

import 'rpc.dart';
import 'src/versions.dart';

export 'dart:typed_data' show Uint8List;

export 'src/web.dart'
    if (dart.library.io) 'src/vm.dart'
    show httpClientFromApiKey;

const String _clientKey = 'x-goog-api-client';

// ignore: prefer_const_declarations
final String _clientName =
    'gl-dart/$clientDartVersion gax/$gaxVersion rest/$gaxVersion gapic/$gaxVersion';

const String _contentTypeKey = 'content-type';
const String _typeJson = 'application/json';

/// Exception thrown when a method is called without correct configuration.
final class ConfigurationException implements Exception {
  /// A message describing the cause of the exception.
  final String message;

  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Exception thrown when calling an API through [ServiceClient] fails.
final class ServiceException implements Exception {
  /// A message describing the cause of the exception.
  final String message;

  /// The HTTP status code that the server returned (e.g. 404).
  final int statusCode;

  /// The server response that caused the exception.
  final http.BaseResponse response;

  final String? responseBody;

  final Status? status;

  ServiceException(
    this.message, {
    required this.statusCode,
    required this.response,
    this.responseBody,
    this.status,
  });

  factory ServiceException._fromDecodedResponse(
    String message, {
    required http.BaseResponse response,
    String? responseBody,
    Status? status,
  }) => switch (response.statusCode) {
    400 => BadRequestException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    409 => ConflictException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    _ => ServiceException(
      message,
      statusCode: response.statusCode,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
  };

  factory ServiceException.fromHttpResponse(
    http.BaseResponse response,
    String? responseBody,
  ) {
    final dynamic json;

    if (responseBody == null || responseBody.isEmpty) {
      return ServiceException._fromDecodedResponse(
        'unknown error',
        response: response,
        responseBody: responseBody,
      );
    }

    try {
      json = jsonDecode(responseBody);
    } on FormatException {
      return ServiceException._fromDecodedResponse(
        responseBody,
        response: response,
        responseBody: responseBody,
      );
    }

    // We use `dynamic` and catch `TypeError` to simply JSON decoding.
    final Status status;
    try {
      // ignore: avoid_dynamic_calls
      status = Status.fromJson(json['error'] as Map<String, dynamic>);
      // ignore: avoid_catching_errors
    } on TypeError {
      return ServiceException._fromDecodedResponse(
        responseBody,
        response: response,
        responseBody: responseBody,
      );
    }

    return ServiceException._fromDecodedResponse(
      status.message,
      response: response,
      responseBody: responseBody,
      status: status,
    );
  }

  String get _name => 'ServiceException';

  @override
  String toString() => '$_name: $message';
}

final class BadRequestException extends ServiceException {
  BadRequestException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 400);

  @override
  String get _name => 'BadRequestException';
}

final class ConflictException extends ServiceException {
  ConflictException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 409);

  @override
  String get _name => 'ConflictException';
}

/// A low-level mechanism to communicate with Google APIs.
class ServiceClient {
  final http.Client client;

  /// Creates a `ServiceClient` using [client] for transport.
  ///
  /// The provided [http.Client] must be configured to provide whatever
  /// authentication is required by the API being accessed. You can do that
  /// using
  /// [`package:googleapis_auth`](https://pub.dev/packages/googleapis_auth).
  ServiceClient({required this.client});

  Future<Map<String, dynamic>> get(Uri url) => _makeRequest(url, 'GET');

  Stream<Map<String, dynamic>> getStreaming(Uri url) =>
      _makeStreamingRequest(url, 'GET');

  Future<Map<String, dynamic>> delete(Uri url) => _makeRequest(url, 'DELETE');

  Stream<Map<String, dynamic>> deleteStreaming(Uri url) =>
      _makeStreamingRequest(url, 'DELETE');

  Future<Map<String, dynamic>> patch(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'PATCH', body);

  Stream<Map<String, dynamic>> patchStreaming(Uri url, {JsonEncodable? body}) =>
      _makeStreamingRequest(url, 'PATCH', body);

  Future<Map<String, dynamic>> post(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'POST', body);

  Stream<Map<String, dynamic>> postStreaming(Uri url, {JsonEncodable? body}) =>
      _makeStreamingRequest(url, 'POST', body);

  Future<Map<String, dynamic>> put(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'PUT', body);

  Stream<Map<String, dynamic>> putStreaming(Uri url, {JsonEncodable? body}) =>
      _makeStreamingRequest(url, 'PUT', body);

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// Once [close] is called, no other methods should be called.
  void close() => client.close();

  Future<Map<String, dynamic>> _makeRequest(
    Uri url,
    String method, [
    JsonEncodable? requestBody,
  ]) async {
    final request = http.Request(method, url);
    if (requestBody != null) {
      request.body = requestBody._asEncodedJson;
    }
    request.headers.addAll({
      _clientKey: _clientName,
      if (requestBody != null) _contentTypeKey: _typeJson,
    });

    final response = await client.send(request);
    final responseBody = await response.stream.bytesToString();
    final statusOK = response.statusCode >= 200 && response.statusCode < 300;
    if (!statusOK) {
      throw ServiceException.fromHttpResponse(response, responseBody);
    }
    return responseBody.isEmpty
        ? {}
        : jsonDecode(responseBody) as Map<String, dynamic>;
  }

  /// Make a request that streams its results using
  /// [Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html).
  ///
  /// NOTE: most Google APIs do not support Server-sent events.
  Stream<Map<String, dynamic>> _makeStreamingRequest(
    Uri url,
    String method, [
    JsonEncodable? requestBody,
  ]) async* {
    final request = http.Request(method, _makeUrlStreaming(url));
    if (requestBody != null) {
      request.body = requestBody._asEncodedJson;
    }
    request.headers.addAll({
      _clientKey: _clientName,
      if (requestBody != null) _contentTypeKey: _typeJson,
    });

    final response = await client.send(request);
    final statusOK = response.statusCode >= 200 && response.statusCode < 300;
    if (!statusOK) {
      throw ServiceException.fromHttpResponse(
        response,
        await response.stream.bytesToString(),
      );
    }

    final lines = response.stream.toStringStream().transform(
      const LineSplitter(),
    );
    await for (final line in lines) {
      // Google APIs only generate "data" events.
      // The SSE specification does not require a space after the colon but
      // Google APIs always generate one.
      const dataPrefix = 'data: ';
      if (line.startsWith(dataPrefix)) {
        final jsonText = line.substring(dataPrefix.length);
        final json = jsonDecode(jsonText) as Map<String, dynamic>;
        yield json;
      }
    }
  }

  static Uri _makeUrlStreaming(Uri url) {
    final query = Map.of(url.queryParameters);
    query['alt'] = 'sse';
    return url.replace(queryParameters: query);
  }
}

extension on JsonEncodable {
  String get _asEncodedJson => jsonEncode(toJson());
}
