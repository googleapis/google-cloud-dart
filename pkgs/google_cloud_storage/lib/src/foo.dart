import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;

import 'object_metadata.dart';
import 'object_metadata_json.dart';

class ResumableUpload implements StreamSink<List<int>> {
  final FutureOr<http.Client> _client;
  final Future<http.Response> _locationResponse;
  int _end = 0;
  Uint8List buffer = Uint8List(256 * 1024 * 2);
  int _nextBufferByte = 0;

  ResumableUpload(this._client, this._locationResponse);

  Future<Uri> get _sessionUri async {
    final response = await _locationResponse;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(response, response.body);
    }
    final location = response.headers['location'];
    if (location == null) throw Exception('No location header');
    return Uri.parse(location);
  }

  @override
  void add(List<int> event) {
    if (_nextBufferByte + event.length > buffer.length) {
      final newBuffer = Uint8List(buffer.length * 2);
      newBuffer.setRange(0, _nextBufferByte, buffer);
      buffer = newBuffer;
    }
    buffer.setRange(_nextBufferByte, _nextBufferByte + event.length, event);
    _nextBufferByte += event.length;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) {
    // TODO: implement addStream
    throw UnimplementedError();
  }

  @override
  Future<dynamic> close() async {
    final newEnd = _end + _nextBufferByte;
    final response = await (await _client).put(
      await _sessionUri,
      headers: {'Content-Range': 'bytes $_end-+${newEnd - 1}/$newEnd'},
      body: buffer.sublist(0, _nextBufferByte),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(response, response.body);
    }
  }

  @override
  // TODO: implement done
  Future<dynamic> get done => throw UnimplementedError();
}

ResumableUpload uploadFileStream(
  FutureOr<http.Client> client,
  Uri url, {
  ObjectMetadata? metadata,
}) {
  final metadataJson = metadata == null
      ? <String, Object?>{}
      : objectMetadataToJson(metadata);

  final body = jsonEncode(metadataJson);

  final response = Future.value(client).then(
    (client) => client.post(
      url,
      body: body,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': body.length.toString(),
      },
    ),
  );

  return ResumableUpload(client, response);
}
