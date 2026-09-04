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

/// Settings for batching operations.
final class BatchingSettings {
  /// The maximum number of items in a batch.
  final int maxMessages;

  /// The maximum size in bytes for a batch.
  final int maxBytes;

  /// The maximum time to wait before sending a batch.
  final Duration maxDelay;

  /// Creates a new [BatchingSettings] instance.
  ///
  /// It is an error if:
  /// - [maxMessages] is not greater than 0.
  /// - [maxBytes] is not greater than 0.
  /// - [maxDelay] is not greater than [Duration.zero].
  BatchingSettings({
    this.maxMessages = 100,
    this.maxBytes = 1024 * 1024, // 1 MB
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
  final Future<void> Function(List<T>) onBatch;

  final List<T> _buffer = [];
  final Set<Future<void>> _inFlight = {};
  int _currentSizeBytes = 0;
  Timer? _timer;
  bool _isClosed = false;
  Future<void>? _closeFuture;

  Batcher({
    required this.settings,
    required this.itemSize,
    required this.onBatch,
  });

  /// Whether this batcher is closed.
  bool get isClosed => _isClosed;

  /// Adds an item to the batch.
  ///
  /// It is an error if called on a closed [Batcher].
  void add(T item) {
    if (_isClosed) {
      throw StateError('Cannot add items to a closed Batcher.');
    }
    _buffer.add(item);
    _currentSizeBytes += itemSize(item);

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

    final batch = List<T>.from(_buffer);
    _buffer.clear();
    _currentSizeBytes = 0;

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
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.map((f) => f.catchError((_) {})));
    }
  }
}
