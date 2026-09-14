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
///
/// Note that Pub/Sub documents this as "512 KB", meaning 512,000 bytes rather
/// than 512 KiB.
@internal
const maxAcknowledgeRequestBytes = 512 * 1000;

/// [settings] checked against the limits the server enforces on a single
/// request, and narrowed to them where necessary.
///
/// [maxBytes] is the largest serialized request the server will accept, and
/// [maxMessages] the largest number of items it will accept, or null if no
/// count limit applies. [requestDescription] names the request in the error
/// message.
///
/// Throws an [ArgumentError] if the caller explicitly asked for more than the
/// server allows. Such a request can only ever fail — an oversized request is
/// rejected outright with a non-retryable `INVALID_ARGUMENT` error that takes
/// every item in the batch with it — and silently substituting a different
/// value would leave the settings object reporting a size that is not the one
/// in use.
///
/// The check cannot live in [BatchingSettings] itself, because the applicable
/// limit depends on which request the settings are used for, and one
/// [BatchingSettings] may legitimately be shared between publishing and
/// acknowledging.
///
/// A [BatchingSettings.maxBytes] that the caller never set is *not* an error.
/// Its default suits publishing and exceeds what an `Acknowledge` request
/// allows, so it is quietly narrowed rather than forcing everyone who wants to
/// set [BatchingSettings.maxMessages] on a subscription to also restate a byte
/// limit they have no opinion about.
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
  // The default is well under every count limit, so anything above one was
  // asked for deliberately.
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
/// Pub/Sub enforces its own limits on each request, and it measures the
/// *serialized* request. [maxBytes] is measured the same way, so it can be
/// compared directly against those limits:
///
/// | Request | Server limit |
/// | --- | --- |
/// | `Publish` | 10,000,000 bytes, 1,000 messages |
/// | `Acknowledge`, `ModifyAckDeadline` | 512,000 bytes |
///
/// Asking for more than the applicable limit is an error: constructing the
/// `Topic` or `Subscription` that would use the settings throws an
/// [ArgumentError], rather than quietly substituting a value you did not ask
/// for. The one exception is a [maxBytes] you never set, whose default suits
/// publishing and is narrowed silently for acknowledgments.
///
/// Within the limit, a batch of several items is never sent over [maxBytes]. A
/// single item that is larger than [maxBytes] on its own still is, and the
/// server rejects that request with a non-retryable `INVALID_ARGUMENT` error
/// that fails the whole batch, so check the size of individual messages
/// yourself if they may approach the limit.
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
  /// This is exact for `Publish`. For acknowledgments it is deliberately
  /// conservative — the subscription name is counted even on the streaming
  /// path that omits it, and each ack ID is charged for its own deadline even
  /// on the unary path that carries a single shared one — so those batches may
  /// be slightly smaller than [maxBytes] would allow.
  ///
  /// An item that would push the total above [maxBytes] starts a new batch
  /// instead. A single item larger than [maxBytes] is sent on its own, in a
  /// batch that exceeds [maxBytes].
  ///
  /// Must not exceed what the server accepts for the request being batched;
  /// see the table on [BatchingSettings].
  final int maxBytes;

  /// Whether [maxBytes] came from the caller rather than from the default.
  ///
  /// The default suits publishing and is larger than an `Acknowledge` request
  /// allows, so it has to be narrowed for that path. Narrowing a value the
  /// caller actually chose would be wrong — that is an error instead — which
  /// means the two cases have to be told apart.
  final bool _maxBytesWasSpecified;

  /// The maximum time to wait before sending a batch that has reached
  /// neither [maxMessages] nor [maxBytes].
  final Duration maxDelay;

  /// Creates a new [BatchingSettings] instance.
  ///
  /// It is an error if:
  /// - [maxMessages] is not greater than 0.
  /// - [maxBytes] is not greater than 0.
  /// - [maxDelay] is not greater than [Duration.zero].
  ///
  /// Exceeding a server limit is also an error, but is reported by the `Topic`
  /// or `Subscription` the settings are given to, which is what determines
  /// which limit applies.
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
