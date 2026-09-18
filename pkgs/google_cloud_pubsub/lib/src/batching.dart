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

/// Validates [settings] against the server limits for a specific RPC and
/// narrows an unspecified default [BatchingSettings.maxBytes] if needed.
@internal
BatchingSettings resolveServerLimits(
  BatchingSettings settings, {
  required int maxBytes,
  int? maxMessages,
  required String requestDescription,
}) {
  if (settings._maxBytesWasSpecified && settings.maxBytes > maxBytes) {
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

  final resolvedBytes = math.min(settings.maxBytes, maxBytes);
  if (resolvedBytes == settings.maxBytes) return settings;
  return BatchingSettings(
    maxMessages: settings.maxMessages,
    maxBytes: resolvedBytes,
    maxDelay: settings.maxDelay,
  );
}

/// Settings for batching operations.
///
/// A batch is sent as soon as any of [maxMessages], [maxBytes], or [maxDelay]
/// is reached, whichever happens first.
///
/// [maxBytes] is measured against the serialized protobuf request size:
/// - `Publish`: up to 10,000,000 bytes and 1,000 messages.
/// - `Acknowledge` and `ModifyAckDeadline`: up to 512,000 bytes.
///
/// See the [Pub/Sub quotas and limits](https://cloud.google.com/pubsub/quotas).
final class BatchingSettings {
  /// The maximum number of items to collect before sending a batch.
  final int maxMessages;

  /// The maximum serialized size in bytes of a request before it is sent.
  ///
  /// Includes the items, their protobuf field tags and length prefixes, and
  /// the fixed fields carried by the request (such as the topic or subscription
  /// name). An item that would push a non-empty batch above [maxBytes] flushes
  /// the current batch first; a single item larger than [maxBytes] is sent in
  /// its own batch.
  final int maxBytes;

  final bool _maxBytesWasSpecified;

  /// The maximum time to wait before sending a batch that has reached
  /// neither [maxMessages] nor [maxBytes].
  final Duration maxDelay;

  /// Creates a new [BatchingSettings] instance.
  ///
  /// It is an error if [maxMessages], [maxBytes], or [maxDelay] is not greater
  /// than zero.
  BatchingSettings({
    this.maxMessages = 100,
    int? maxBytes,
    this.maxDelay = const Duration(milliseconds: 10),
  }) : maxBytes = maxBytes ?? 1024 * 1024, // 1 MiB
       _maxBytesWasSpecified = maxBytes != null {
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than zero',
      );
    }
    if (this.maxBytes <= 0) {
      throw ArgumentError.value(
        this.maxBytes,
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
          // Errors are handled by onBatch or propagated via close().
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
