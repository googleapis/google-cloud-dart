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

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'crc32c.dart';
import 'object_metadata.dart';
import 'object_metadata_json.dart';
import 'retry.dart';

// Upload chunk sizes must be a multiple of 256KiB.
//
// See https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#chunked-upload
const _minWriteSize = 256 * 1024;

int _largestWriteSize(int number) => (number ~/ _minWriteSize) * _minWriteSize;

/// A sink that can be used to upload an object using a resumable upload.
class ResumableUploadSink implements StreamSink<List<int>> {
  bool _isClosing = false;
  bool _isAddStream = false;
  final _closedCompleter = Completer<ObjectMetadata>();
  final FutureOr<http.Client> _client;
  final RetryRunner _retry;

  /// The metadata of the uploaded object.
  ///
  /// This will be `null` until the [close] or [done] future is complete.
  ObjectMetadata? get metadata => _metadata;
  ObjectMetadata? _metadata;

  // An HTTP response that will contain the "Location" header used to upload
  // data to. There are two types of requests that will return the correct
  // "Location" header:
  // 1. The initial POST request to initiate the resumable upload:
  //    https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#initiate-session
  // 2. A status check request:
  //    https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#check-status
  final Future<http.Response> _locationResponse;
  final Crc32c _crc32c = Crc32c();
  final _md5Accumulator = AccumulatorSink<crypto.Digest>();
  late final _md5Sink = crypto.md5.startChunkedConversion(_md5Accumulator);

  // The next byte position expected by Google Cloud Storage.
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
    if (data.isEmpty) return;
    _crc32c.update(data);
    _md5Sink.add(data);

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

  Future<http.Response> _uploadChunk(
    Uint8List buffer,
    int bufferSize,
    bool isClose,
    String? hashHeader,
  ) async {
    var needsStatusCheck = false;
    var initialExpectedByte = _nextExpectedByte;

    return await _retry.run(() async {
      var currentExpectedByte = initialExpectedByte;
      if (needsStatusCheck) {
        final statusRes = await (await _client).put(
          await _sessionUri,
          headers: {'Content-Range': 'bytes */*'},
        );
        if (statusRes.statusCode == 308) {
          final range = statusRes.headers['range'];
          if (range != null) {
            final match = RegExp(r'bytes=0-(\d+)').firstMatch(range);
            if (match != null) {
              currentExpectedByte = int.parse(match.group(1)!) + 1;
            }
          } else {
            currentExpectedByte = 0;
          }
        } else if (statusRes.statusCode == 200 || statusRes.statusCode == 201) {
          return statusRes;
        } else {
          throw ServiceException.fromHttpResponse(statusRes, statusRes.body);
        }
      }
      needsStatusCheck = true;

      final bytesAcked = (currentExpectedByte - initialExpectedByte).clamp(
        0,
        bufferSize,
      );
      final remainingBytes = bufferSize - bytesAcked;
      final newEnd = currentExpectedByte + remainingBytes;

      String contentRange;
      if (remainingBytes == 0) {
        contentRange = isClose ? 'bytes */$newEnd' : 'bytes */*';
      } else {
        contentRange = isClose
            ? 'bytes $currentExpectedByte-${newEnd - 1}/$newEnd'
            : 'bytes $currentExpectedByte-${newEnd - 1}/*';
      }

      final headers = {'Content-Range': contentRange};
      if (isClose && hashHeader != null) {
        headers['x-goog-hash'] = hashHeader;
      }

      final res = await (await _client).put(
        await _sessionUri,
        headers: headers,
        body: remainingBytes == 0
            ? const <int>[]
            : buffer.sublist(bytesAcked, bytesAcked + remainingBytes),
      );

      if (isClose) {
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw ServiceException.fromHttpResponse(res, res.body);
        }
      } else {
        if (res.statusCode != 308) {
          throw ServiceException.fromHttpResponse(res, res.body);
        }
      }
      return res;
    }, isIdempotent: true);
  }

  Future<void> _flush() async {
    final flushPoint = _largestWriteSize(_writeBufferSize);
    if (flushPoint == 0) return;
    final flushBuffer = _writeBuffer;
    _writeBuffer = _writeBuffer.sublist(flushPoint);
    _writeBufferSize -= flushPoint;

    await _uploadChunk(flushBuffer, flushPoint, false, null);

    // TODO(https://github.com/googleapis/google-cloud-dart/issues/218):
    // Check the "range" headers to determine if any data must be resent.
    _nextExpectedByte += flushPoint;
  }

  ResumableUploadSink._(this._client, this._locationResponse, this._retry);

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

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw UnsupportedError('ResumableUpload does not support addError');
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
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
  Future<ObjectMetadata> close() async {
    if (_isClosing || _closedCompleter.isCompleted) {
      return _closedCompleter.future;
    }
    if (_isAddStream) {
      throw StateError('ResumableUploadSink is bound to a stream');
    }
    _isClosing = true;

    try {
      _md5Sink.close();
      final calculatedCrc32c = _crc32c.toBase64();
      final calculatedMd5Hash = base64Encode(
        _md5Accumulator.events.single.bytes,
      );

      final response = await _uploadChunk(
        _writeBuffer,
        _writeBufferSize,
        true,
        'crc32c=$calculatedCrc32c,md5=$calculatedMd5Hash',
      );

      final md = objectMetadataFromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      _metadata = md;
      _closedCompleter.complete(md);
      return md;
    } finally {
      _isClosing = false;
    }
  }

  @override
  Future<ObjectMetadata> get done => _closedCompleter.future;
}

@internal
ResumableUploadSink uploadFileStream(
  FutureOr<http.Client> client,
  Uri url, {
  ObjectMetadata? metadata,
  bool isIdempotent = false,
  RetryRunner retry = defaultRetry,
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

  final response = retry.run(() async {
    final res = await Future.value(client).then(
      (client) => client.post(
        url,
        body: body,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': body.length.toString(),
        },
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(res, res.body);
    }
    return res;
  }, isIdempotent: isIdempotent);

  return ResumableUploadSink._(client, response, retry);
}
