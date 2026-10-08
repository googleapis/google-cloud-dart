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

import 'package:meta/meta.dart';

/// The maximum serialized size of a `Publish` request (10,000,000 bytes).
@internal
const maxPublishRequestBytes = 10 * 1000 * 1000;

/// The maximum number of messages in a `Publish` request.
@internal
const maxPublishRequestMessages = 1000;

/// The maximum serialized size of an `Acknowledge` or `ModifyAckDeadline`
/// request (512,000 bytes).
@internal
const maxAcknowledgeRequestBytes = 512 * 1000;

/// Throws an [ArgumentError] if [settings] asks for larger batches than
/// Pub/Sub accepts in one request of the kind described by
/// [requestDescription].
@internal
void checkServerLimits(
  BatchingSettings settings, {
  required int maxBytes,
  int? maxMessages,
  required String requestDescription,
}) {
  if (settings.maxBytes > maxBytes) {
    throw ArgumentError.value(
      settings.maxBytes,
      'batching.maxBytes',
      'Must be at most $maxBytes, the largest $requestDescription Pub/Sub '
          'accepts',
    );
  }
  if (maxMessages != null && settings.maxMessages > maxMessages) {
    throw ArgumentError.value(
      settings.maxMessages,
      'batching.maxMessages',
      'Must be at most $maxMessages, the most messages Pub/Sub accepts in '
          'one $requestDescription',
    );
  }
}

/// Settings for batching operations.
///
/// A batch is sent as soon as any of [maxMessages], [maxBytes], or [maxDelay]
/// is reached, whichever happens first.
///
/// [maxBytes] is compared with the size of the serialized protobuf request.
/// Pub/Sub accepts at most:
/// - `Publish`: 10,000,000 bytes and 1,000 messages.
/// - `Acknowledge` and `ModifyAckDeadline`: 512,000 bytes.
///
/// See the [Pub/Sub quotas and limits](https://cloud.google.com/pubsub/quotas).
final class BatchingSettings {
  /// The maximum number of items to collect before sending a batch.
  ///
  /// Defaults to 100. A `Publish` request can contain at most 1,000 messages.
  final int maxMessages;

  /// The maximum serialized size in bytes of a request before it is sent.
  ///
  /// Includes the items, their protobuf field tags and length prefixes, and
  /// the fixed fields carried by the request (such as the topic or subscription
  /// name). An item that would push a non-empty batch above [maxBytes] flushes
  /// the current batch first; a single item larger than [maxBytes] is sent in
  /// its own batch.
  ///
  /// Defaults to 512,000 bytes, the largest `Acknowledge` or
  /// `ModifyAckDeadline` request Pub/Sub accepts, so that the default fits
  /// every kind of request. `Publish` requests may be up to 10,000,000 bytes;
  /// pass a larger value to send bigger publish batches.
  final int maxBytes;

  /// The maximum time to wait, after the first item is added to a batch,
  /// before sending a batch that has reached neither [maxMessages] nor
  /// [maxBytes].
  ///
  /// Defaults to 10 milliseconds.
  final Duration maxDelay;

  /// Creates a new [BatchingSettings] instance.
  ///
  /// It is an error if [maxMessages], [maxBytes], or [maxDelay] is not greater
  /// than zero.
  BatchingSettings({
    this.maxMessages = 100,
    // `BatchingSettings` is shared by every kind of request, so the default
    // must fit the smallest server limit; see [maxBytes].
    this.maxBytes = maxAcknowledgeRequestBytes,
    this.maxDelay = const Duration(milliseconds: 10),
  }) {
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than zero',
      );
    }
    if (maxBytes <= 0) {
      throw ArgumentError.value(
        maxBytes,
        'maxBytes',
        'Must be greater than zero',
      );
    }
    if (maxDelay <= Duration.zero) {
      throw ArgumentError.value(
        maxDelay,
        'maxDelay',
        'Must be greater than zero',
      );
    }
  }
}

/// Generic batcher that accumulates items of type [T] and fires batches of [T]
/// according to [BatchingSettings].
@internal
final class Batcher<T> {
  final BatchingSettings settings;
  final int Function(T) itemSize;

  /// Sends a batch.
  ///
  /// Must report errors for the items in the batch itself (for example by
  /// completing their futures with the error). An error thrown by [onBatch]
  /// is only surfaced by [close] if the batch is still in flight when [close]
  /// is called; otherwise it is dropped.
  final Future<void> Function(List<T>) onBatch;

  /// The size in bytes that a batch occupies before any item is added.
  final int baseSize;

  final List<T> _buffer = [];
  final Set<Future<void>> _inFlight = {};
  int _currentSizeBytes;
  Timer? _timer;
  bool _isClosed = false;
  Future<void>? _closeFuture;

  Batcher({
    required this.settings,
    required this.itemSize,
    required this.onBatch,
    this.baseSize = 0,
  }) : _currentSizeBytes = baseSize;

  /// Whether this batcher is closed.
  bool get isClosed => _isClosed;

  /// Adds an item to the batch.
  ///
  /// It is an error if called on a closed [Batcher].
  void add(T item) {
    if (_isClosed) {
      throw StateError('Cannot add items to a closed Batcher.');
    }
    final size = itemSize(item);
    if (_buffer.isNotEmpty && _currentSizeBytes + size > settings.maxBytes) {
      _flush();
    }
    _buffer.add(item);
    _currentSizeBytes += size;

    if (_buffer.length >= settings.maxMessages ||
        _currentSizeBytes >= settings.maxBytes) {
      _flush();
    } else {
      _timer ??= Timer(settings.maxDelay, _flush);
    }
  }

  void _flush() {
    _timer?.cancel();
    _timer = null;

    if (_buffer.isEmpty) return;

    final batch = _buffer.toList();
    _buffer.clear();
    _currentSizeBytes = baseSize;

    final future = Future.sync(() => onBatch(batch));
    _inFlight.add(future);
    future
        .whenComplete(() {
          _inFlight.remove(future);
        })
        .catchError((_) {
          // Prevent an unhandled error; see the `onBatch` documentation.
        });
  }

  /// Closes the batcher, flushing any remaining items immediately and waiting
  /// for in-flight batches to complete.
  Future<void> close() => _closeFuture ??= _doClose();

  Future<void> _doClose() async {
    _isClosed = true;
    _flush();
    await Future.wait(_inFlight.toList());
  }
}
