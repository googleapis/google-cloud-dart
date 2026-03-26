// Copyright 2026 Google LLC
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
import 'dart:typed_data';

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'object_metadata.dart';
import 'object_metadata_json.dart';

const _minWriteSize = 256 * 1024;

int _largestWriteSize(int number) => (number ~/ _minWriteSize) * _minWriteSize;

/// A sink that can be used to upload an object using a resumable upload.
class ResumableUploadSink implements StreamSink<List<int>> {
  bool _isClosing = false;
  bool _isAddStream = false;
  final Completer<bool> _closedCompleter = Completer<bool>();
  final FutureOr<http.Client> _client;
  final Future<http.Response> _locationResponse;
  int _nextExpectedByte = 0;
  Uint8List _writeBuffer = Uint8List(_minWriteSize * 2);
  int _writeBufferSize = 0;

  Future<Uri> get _sessionUri async {
    final response = await _locationResponse;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(response, response.body);
    }
    final location = response.headers['location'];
    if (location == null) throw Exception('No location header');
    return Uri.parse(location);
  }

  void _addToBuffer(List<int> data) {
    final requiredCapacity = _writeBufferSize + data.length;
    if (requiredCapacity > _writeBuffer.length) {
      var newSize = _writeBuffer.length * 2;
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

  ResumableUploadSink._(this._client, this._locationResponse);

  @override
  void add(List<int> event) {
    if (_isClosing || _closedCompleter.isCompleted) {
      throw StateError('ResumableUploadSink is already closed');
    }
    if (_isAddStream) {
      throw StateError('ResumableUploadSink is already bound to a stream');
    }

    _addToBuffer(event);
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
    throw UnsupportedError('ResumableUpload does not support addError');
  }

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    if (_isClosing || _closedCompleter.isCompleted) {
      throw StateError('ResumableUploadSink is already closed');
    }
    if (_isAddStream) {
      throw StateError('ResumableUploadSink is already bound to a stream');
    }

    _isAddStream = true;
    try {
      await for (final chunk in stream) {
        _addToBuffer(chunk);
        await _flush();
      }
    } finally {
      _isAddStream = false;
    }
  }

  @override
  Future<dynamic> close() async {
    if (_closedCompleter.isCompleted) return;
    if (_isAddStream) {
      throw StateError('ResumableUploadSink is bound to a stream');
    }
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
