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

  const BatchingSettings({
    this.maxMessages = 100,
    this.maxBytes = 1024 * 1024, // 1 MB
    this.maxDelay = const Duration(milliseconds: 10),
  });
}

/// Generic batcher that accumulates items of type [T] and fires batches of [T]
/// according to [BatchingSettings].
@internal
class Batcher<T> {
  final BatchingSettings settings;
  final int Function(T) itemSize;
  final Future<void> Function(List<T>) onBatch;

  final List<T> _buffer = [];
  int _currentSizeBytes = 0;
  Timer? _timer;

  Batcher({
    required this.settings,
    required this.itemSize,
    required this.onBatch,
  });

  /// Adds an item to the batch.
  void add(T item) {
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

    // Fire and forget
    onBatch(batch).catchError((_) {
      // Errors should be handled by onBatch (e.g. failing the completers for
      // the items).
    });
  }

  /// Closes the batcher, flushing any remaining items immediately.
  void close() {
    _flush();
  }
}
