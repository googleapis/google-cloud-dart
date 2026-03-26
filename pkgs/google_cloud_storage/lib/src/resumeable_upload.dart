import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'object_metadata.dart';
import 'object_metadata_json.dart';

class ResumableUploadSink implements StreamSink<List<int>> {
  static const _minWriteSize = 256 * 1024;
  bool _isClosing = false;
  bool _isAddStream = false;
  final Completer<bool> _closedCompleter = Completer<bool>();
  final FutureOr<http.Client> _client;
  final Future<http.Response> _locationResponse;
  int _nextExpectedByte = 0;
  Uint8List _writeBuffer = Uint8List(_minWriteSize * 2);
  int _writeBufferSize = 0;

  ResumableUploadSink._(this._client, this._locationResponse);

  Future<Uri> get _sessionUri async {
    final response = await _locationResponse;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(response, response.body);
    }
    final location = response.headers['location'];
    if (location == null) throw Exception('No location header');
    return Uri.parse(location);
  }

  void addToBuffer(List<int> data) {
    final requiredCapacity = _writeBufferSize + data.length;
    if (requiredCapacity > _writeBuffer.length) {
      int newSize = _writeBuffer.length * 2;
      if (newSize < requiredCapacity) {
        newSize = requiredCapacity;
      }
      newSize =
          ((newSize + _minWriteSize - 1) ~/ _minWriteSize) * _minWriteSize;

      final newBuffer = Uint8List(newSize)
        ..setRange(0, _writeBufferSize, _writeBuffer);
      _writeBuffer = newBuffer;
    }
    _writeBuffer.setRange(
      _writeBufferSize,
      _writeBufferSize + data.length,
      data,
    );
    _writeBufferSize += data.length;
  }

  @override
  void add(List<int> event) {
    if (_isClosing || _closedCompleter.isCompleted) {
      throw StateError('Cannot add to closed stream');
    }
    if (_isAddStream) throw StateError('Cannot add to stream after addStream');

    addToBuffer(event);
  }

  Future<void> _flush() async {
    final flushPoint = _largestWriteSize(_writeBufferSize);
    if (flushPoint == 0) return;
    final flushBuffer = _writeBuffer;
    _writeBuffer = _writeBuffer.sublist(flushPoint, _writeBufferSize);
    _writeBufferSize -= flushPoint;

    final newEnd = _nextExpectedByte + flushPoint;
    final contentRange = 'bytes $_nextExpectedByte-${newEnd - 1}/*';
    final response = await (await _client).put(
      await _sessionUri,
      headers: {'Content-Range': contentRange},
      body: flushBuffer.sublist(0, flushPoint),
    );

    if (response.statusCode != 308) {
      throw ServiceException.fromHttpResponse(response, response.body);
    }

    // TODO(https://github.com/googleapis/google-cloud-dart/issues/218):
    // Check the "range" headers to determine if any data must be resent.
    _nextExpectedByte = newEnd;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw UnsupportedError('addError not supported by ResumableUpload');
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    if (_isClosing || _closedCompleter.isCompleted) {
      throw Exception('Cannot add to closed stream');
    }
    if (_isAddStream) throw StateError('Cannot add to stream after addStream');

    _isAddStream = true;
    try {
      await for (final chunk in stream) {
        addToBuffer(chunk);
        await _flush();
      }
    } finally {
      _isAddStream = false;
    }
  }

  @override
  Future<dynamic> close() async {
    if (_isAddStream) throw StateError('Cannot add to stream after addStream');
    _isClosing = true;

    try {
      final newEnd = _nextExpectedByte + _writeBufferSize;
      final contentRange = _writeBufferSize == 0
          ? 'bytes */$newEnd'
          : 'bytes $_nextExpectedByte-${newEnd - 1}/$newEnd';
      final response = await (await _client).put(
        await _sessionUri,
        headers: {'Content-Range': contentRange},
        body: _writeBuffer.sublist(0, _writeBufferSize),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServiceException.fromHttpResponse(response, response.body);
      }
      _closedCompleter.complete(true);
    } finally {
      _isClosing = false;
    }
  }

  @override
  Future<dynamic> get done => _closedCompleter.future;

  static int _largestWriteSize(int number) =>
      (number ~/ _minWriteSize) * _minWriteSize;
}

@internal
ResumableUploadSink uploadFileStream(
  FutureOr<http.Client> client,
  Uri url, {
  ObjectMetadata? metadata,
}) {
  final md = switch (metadata) {
    ObjectMetadata(contentType: _?) => metadata,
    ObjectMetadata() => metadata.copyWith(
      contentType: 'application/octet-stream',
    ),
    null => ObjectMetadata(contentType: 'application/octet-stream'),
  };

  final metadataJson = objectMetadataToJson(md);

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

  return ResumableUploadSink._(client, response);
}
