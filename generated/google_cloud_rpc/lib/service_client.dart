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

import 'exceptions.dart';
import 'src/version.dart';
import 'src/web.dart' if (dart.library.io) 'src/vm.dart' show clientDartVersion;

export 'dart:typed_data' show Uint8List;

export 'src/web.dart'
    if (dart.library.io) 'src/vm.dart'
    show httpClientFromApiKey;

const String _clientKey = 'x-goog-api-client';

// ignore: prefer_const_declarations
String get _baseClientName =>
    'gl-dart/$clientDartVersion gax/$packageVersion rest/$packageVersion';

const String _contentTypeKey = 'content-type';
const String _typeJson = 'application/json';

/// A low-level mechanism to communicate with Google APIs.
class ServiceClient {
  final http.Client client;

  /// The version of the GAPIC-generated client library (e.g. `0.1.0`),
  /// which will be formatted as `gapic/<version>` in the `x-goog-api-client`
  /// header.
  ///
  /// Set this for client libraries that were generated completely by
  /// automation.
  final String? gapicVersion;

  /// The version of the hand-written client library (e.g. `0.6.4`),
  /// which will be formatted as `gccl/<version>` in the `x-goog-api-client`
  /// header.
  ///
  /// Set this if the client library includes hand-written components.
  final String? gcclVersion;

  /// Creates a `ServiceClient` using [client] for transport.
  ///
  /// The provided [http.Client] must be configured to provide whatever
  /// authentication is required by the API being accessed. You can do that
  /// using
  /// [`package:googleapis_auth`](https://pub.dev/packages/googleapis_auth).
  ///
  /// If [gapicVersion] is set, `gapic/<version>` is included in the
  /// `x-goog-api-client` header.
  ///
  /// If [gcclVersion] is set, `gccl/<version>` is included in the
  /// `x-goog-api-client` header.
  ///
  /// Both [gapicVersion] and [gcclVersion] should be set if the library
  /// includes both automatically-generated and hand-written components.
  /// For example, `package:google_cloud_firestore` (hand-written) wraps
  /// `package:google_cloud_firestore_v1` (generated).
  ServiceClient({required this.client, this.gapicVersion, this.gcclVersion});

  /// The `x-goog-api-client` header value sent with every request.
  String get clientHeader {
    final buffer = StringBuffer(_baseClientName);
    final gapic = gapicVersion?.trim();
    final hasGapic = gapic != null && gapic.isNotEmpty;
    final gccl = gcclVersion?.trim();
    final hasGccl = gccl != null && gccl.isNotEmpty;

    if (hasGapic) {
      buffer.write(' gapic/$gapic');
    }

    if (hasGccl) {
      buffer.write(' gccl/$gccl');
    }

    return buffer.toString();
  }

  Future<Map<String, dynamic>> get(Uri url) => _makeRequest(url, 'GET');

  Stream<Map<String, dynamic>> getStreaming(
    Uri url, {
    required bool enableSse,
  }) => _makeStreamingRequest(url, 'GET', enableSse: enableSse);

  Future<Map<String, dynamic>> delete(Uri url) => _makeRequest(url, 'DELETE');

  Stream<Map<String, dynamic>> deleteStreaming(
    Uri url, {
    required bool enableSse,
  }) => _makeStreamingRequest(url, 'DELETE', enableSse: enableSse);

  Future<Map<String, dynamic>> patch(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'PATCH', body);

  Stream<Map<String, dynamic>> patchStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
  }) => _makeStreamingRequest(url, 'PATCH', body: body, enableSse: enableSse);

  Future<Map<String, dynamic>> post(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'POST', body);

  Stream<Map<String, dynamic>> postStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
  }) => _makeStreamingRequest(url, 'POST', body: body, enableSse: enableSse);

  Future<Map<String, dynamic>> put(Uri url, {JsonEncodable? body}) =>
      _makeRequest(url, 'PUT', body);

  Stream<Map<String, dynamic>> putStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
  }) => _makeStreamingRequest(url, 'PUT', body: body, enableSse: enableSse);

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
      _clientKey: clientHeader,
      if (requestBody != null) _contentTypeKey: _typeJson,
    });

    final response = await client.send(request);
    final statusOK = response.statusCode >= 200 && response.statusCode < 300;
    if (!statusOK) {
      String? responseBody;
      try {
        responseBody = await response.stream.bytesToString();
      } on FormatException {
        // The response body is not valid UTF-8.
      }
      throw ServiceException.fromHttpResponse(response, responseBody);
    }
    final responseBody = await response.stream.bytesToString();
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
    String method, {
    JsonEncodable? body,
    required bool enableSse,
  }) async* {
    final request = http.Request(
      method,
      enableSse ? _makeUrlStreaming(url) : url,
    );
    if (body != null) {
      request.body = body._asEncodedJson;
    }
    request.headers.addAll({
      _clientKey: clientHeader,
      if (body != null) _contentTypeKey: _typeJson,
    });

    final response = await client.send(request);
    final statusOK = response.statusCode >= 200 && response.statusCode < 300;
    if (!statusOK) {
      String? responseBody;
      try {
        responseBody = await response.stream.bytesToString();
      } on FormatException {
        // The response body is not valid UTF-8.
      }
      throw ServiceException.fromHttpResponse(response, responseBody);
    }

    switch (http.MediaType.parse(
      response.headers['content-type'] ?? '',
    ).mimeType) {
      case 'application/json':
        // The server responded with a non-streaming response, which should be a
        // list of JSON objects.
        final responseBody = await response.stream.bytesToString();
        final json = (jsonDecode(responseBody) as List)
            .cast<Map<String, dynamic>>();
        yield* Stream.fromIterable(json);
        return;
      case 'text/event-stream':
        // The server responded with an event stream, which is what we expect.
        break;
      default:
        throw ServiceException(
          'Unsupported content type: ${response.headers['content-type']}',
          statusCode: response.statusCode,
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
