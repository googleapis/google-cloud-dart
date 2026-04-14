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

/// The upper bound of the range header. For example, if the range header is
/// "bytes=0-255", the upper bound is `256`.
///
/// From https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#chunked-upload
///
/// > Repeat the above steps for each remaining chunk of data that you want
/// > to upload, using the upper value contained in the Range header of each
/// > response to determine where to start each successive chunk; you should
/// > not assume that the server received all bytes sent in any given request.
int? _parseRange(String? rangeHeader) {
  if (rangeHeader == null) return null;
  final match = RegExp(r'bytes=0-(\d+)').firstMatch(rangeHeader);
  if (match != null) {
    return int.parse(match.group(1)!) + 1;
  }
  return null;
}

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
  final BytesBuilder _buffer = BytesBuilder();

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
    _buffer.add(data);
  }

  Future<http.Response> _uploadChunk(
    Uint8List chunk,
    bool isClose,
    String? hashHeader,
  ) async {
    final sessionUri = await _sessionUri;
    final client = await _client;

    var loopExpectedByte = _nextExpectedByte;
    var needsStatusCheck = false;

    return await _retry.run(() async {
      var checkStatus = needsStatusCheck;
      needsStatusCheck = true;

      while (true) {
        if (checkStatus) {
          // From https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#resume-upload
          // > If an upload request is terminated before receiving a response,
          // > or if you receive a 503 or 500 response, then you need to resume
          // > the interrupted upload from where it left off.
          //
          // See https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#status-check
          final statusRes = await client.put(
            sessionUri,
            headers: {'Content-Range': 'bytes */*'},
          );
          if (statusRes.statusCode == 308) {
            loopExpectedByte = _parseRange(statusRes.headers['range']) ?? 0;
          } else if (statusRes.statusCode == 200 ||
              statusRes.statusCode == 201) {
            return statusRes;
          } else {
            throw ServiceException.fromHttpResponse(statusRes, statusRes.body);
          }
          checkStatus = false;
        }

        if (loopExpectedByte < _nextExpectedByte) {
          throw StateError(
            'The server has acknowledged fewer bytes ($loopExpectedByte) '
            'than previously acknowledged ($_nextExpectedByte).',
          );
        }

        final newBytesAcked = (loopExpectedByte - _nextExpectedByte).clamp(
          0,
          chunk.length,
        );
        var remainingBytes = chunk.length - newBytesAcked;
        var startOffset = newBytesAcked;

        if (!isClose && remainingBytes % _minWriteSize != 0) {
          // Upload chunk sizes must be a multiple of 256KiB.
          // If the server acknowledged a non-multiple of 256KiB, we extend the
          // range backwards to include already acknowledged bytes to make the
          // request size a multiple of 256KiB.
          //
          // For example, if we sent 524288-1310720 and the server
          // acknowledged up to 1000000, then we would resend:
          //
          // newBytesAcked = 1000000 - 524288 = 475712
          // remainingBytes = 786432 - 475712 = 310720
          // blocks = (310720 / 262144).ceil() = 2
          // remainingBytes = 2 * 262144 = 524288
          // startOffset = 786432 - 524288 = 262144
          // startByte = 524288 + 262144 = 786432
          // newEnd = 786432 + 524288 = 1310720 (the same as it was before)
          final blocks = (remainingBytes / _minWriteSize).ceil();
          remainingBytes = blocks * _minWriteSize;
          startOffset = chunk.length - remainingBytes;
        }

        final startByte = _nextExpectedByte + startOffset;
        final newEnd = startByte + remainingBytes;

        final range = remainingBytes == 0 ? '*' : '$startByte-${newEnd - 1}';
        final size = isClose ? '$newEnd' : '*';
        final contentRange = 'bytes $range/$size';

        final headers = {'Content-Range': contentRange};
        if (hashHeader != null) {
          assert(isClose);
          headers['x-goog-hash'] = hashHeader;
        }

        final body = remainingBytes == 0
            ? const <int>[]
            : Uint8List.sublistView(chunk, startOffset);

        final res = await client.put(sessionUri, headers: headers, body: body);

        if (res.statusCode == 308) {
          final parsed = _parseRange(res.headers['range']);
          if (parsed == null) {
            // Range header was missing from the 308 response.
            // We must do a status check to verify the true state of the upload.
            checkStatus = true;
            continue;
          }
          if (parsed > newEnd) {
            throw StateError(
              'Server acknowledged more bytes ($parsed) than sent ($newEnd).',
            );
          }
          if (isClose && parsed == newEnd) {
            throw StateError(
              'Server returned 308 but all bytes were sent and acknowledged.',
            );
          }
          loopExpectedByte = parsed;
          if (parsed == newEnd) return res;
        } else if (res.statusCode >= 200 && res.statusCode < 300) {
          return res;
        } else {
          throw ServiceException.fromHttpResponse(res, res.body);
        }
      }
    }, isIdempotent: true);
  }

  Future<void> _flush() async {
    final flushPoint = _largestWriteSize(_buffer.length);
    if (flushPoint == 0) return;

    final allBytes = _buffer.takeBytes();
    final flushData = Uint8List.sublistView(allBytes, 0, flushPoint);
    final remaining = Uint8List.sublistView(allBytes, flushPoint);
    _buffer.add(remaining);

    await _uploadChunk(flushData, false, null);
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
        _buffer.takeBytes(),
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
    final resolvedClient = await client;
    final res = await resolvedClient.post(
      url,
      body: body,
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ServiceException.fromHttpResponse(res, res.body);
    }
    return res;
  }, isIdempotent: isIdempotent);

  return ResumableUploadSink._(client, response, retry);
}
