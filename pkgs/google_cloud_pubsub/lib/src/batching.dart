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
import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The maximum serialized size of a `Publish` request.
///
/// Note that Pub/Sub documents this as "10MB", meaning 10,000,000 bytes rather
/// than 10 MiB.
@internal
const maxPublishRequestBytes = 10 * 1000 * 1000;

/// The maximum number of messages in a `Publish` request.
@internal
const maxPublishRequestMessages = 1000;

/// The maximum serialized size of an `Acknowledge` or `ModifyAckDeadline`
/// request.
@internal
const maxAcknowledgeRequestBytes = 512 * 1000;

/// [settings] capped to the limits the server enforces on a single request.
///
/// An oversized request is rejected outright with a non-retryable
/// `INVALID_ARGUMENT` error, failing every item in the batch, so sending
/// smaller batches than requested is always preferable to sending a batch that
/// cannot succeed. The official Python, Go, and Node.js clients cap their
/// batch settings the same way.
@internal
BatchingSettings capToServerLimits(
  BatchingSettings settings, {
  required int maxBytes,
  int? maxMessages,
}) {
  final cappedBytes = math.min(settings.maxBytes, maxBytes);
  final cappedMessages = maxMessages == null
      ? settings.maxMessages
      : math.min(settings.maxMessages, maxMessages);
  if (cappedBytes == settings.maxBytes &&
      cappedMessages == settings.maxMessages) {
    return settings;
  }
  return BatchingSettings(
    maxMessages: cappedMessages,
    maxBytes: cappedBytes,
    maxDelay: settings.maxDelay,
  );
}

/// Settings for batching operations.
///
/// A batch is sent as soon as any of [maxMessages], [maxBytes], or [maxDelay]
/// is reached, whichever happens first.
///
/// Pub/Sub enforces its own limits on each request, and it measures the
/// *serialized* request. [maxBytes] is measured the same way, so it can be
/// compared directly against those limits:
///
/// | Request | Server limit |
/// | --- | --- |
/// | `Publish` | 10,000,000 bytes, 1,000 messages |
/// | `Acknowledge`, `ModifyAckDeadline` | 512 KB |
///
/// Settings that would exceed the applicable limit are capped to it, so a
/// batch is never knowingly sent over the limit. Exceeding it would fail the
/// entire batch with a non-retryable `INVALID_ARGUMENT` error.
///
/// See the [Pub/Sub quotas and limits](https://cloud.google.com/pubsub/quotas).
final class BatchingSettings {
  /// The maximum number of items to collect before sending a batch.
  final int maxMessages;

  /// The maximum serialized size in bytes of a request before it is sent.
  ///
  /// This is the size of the whole request as it appears on the wire: the
  /// items, the protobuf field tags and length prefixes that frame them, and
  /// the fixed fields the request carries (such as the topic or subscription
  /// name). It does not include gRPC framing, which the server does not count
  /// against its limits either.
  ///
  /// An item that would push the total above [maxBytes] starts a new batch
  /// instead. A single item larger than [maxBytes] is sent on its own, in a
  /// batch that exceeds [maxBytes].
  final int maxBytes;

  /// The maximum time to wait before sending a batch that has reached
  /// neither [maxMessages] nor [maxBytes].
  final Duration maxDelay;

  /// Creates a new [BatchingSettings] instance.
  ///
  /// It is an error if:
  /// - [maxMessages] is not greater than 0.
  /// - [maxBytes] is not greater than 0.
  /// - [maxDelay] is not greater than [Duration.zero].
  BatchingSettings({
    this.maxMessages = 100,
    this.maxBytes = 1024 * 1024, // 1 MiB
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchingSettings &&
          runtimeType == other.runtimeType &&
          maxMessages == other.maxMessages &&
          maxBytes == other.maxBytes &&
          maxDelay == other.maxDelay;

  @override
  int get hashCode => Object.hash(maxMessages, maxBytes, maxDelay);

  @override
  String toString() =>
      'BatchingSettings('
      'maxMessages: $maxMessages, '
      'maxBytes: $maxBytes, '
      'maxDelay: $maxDelay)';
}

/// Generic batcher that accumulates items of type [T] and fires batches of [T]
/// according to [BatchingSettings].
@internal
final class Batcher<T> {
  final BatchingSettings settings;
  final int Function(T) itemSize;
  final Future<void> Function(List<T>) onBatch;

  /// The size in bytes that a batch occupies before any item is added.
  ///
  /// This accounts for whatever the request carries besides the items
  /// themselves, so that [BatchingSettings.maxBytes] can be compared against
  /// the size of the whole request rather than the sum of its items.
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
          // Errors should be handled by onBatch (e.g. failing the
          // completers for the items).
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
