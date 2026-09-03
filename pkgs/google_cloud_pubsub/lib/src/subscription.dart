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

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'retry.dart';

/// Settings for background batching and retrying of acknowledgements and
/// deadline modifications.
final class AckSettings {
  /// Settings controlling how requests are accumulated and flushed.
  final BatchingSettings batching;

  /// Settings controlling retries when flushing a batch over a unary RPC.
  final RetrySettings retry;

  const AckSettings({
    this.batching = const BatchingSettings(),
    this.retry = const RetrySettings(),
  });
}

class _AckRequest {
  final String ackId;
  final Completer<void>? completer;

  _AckRequest(this.ackId, [this.completer]);
}

class _ModifyAckDeadlineRequest {
  final String ackId;
  final int ackDeadlineSeconds;
  final Completer<void>? completer;

  _ModifyAckDeadlineRequest(
    this.ackId,
    this.ackDeadlineSeconds, [
    this.completer,
  ]);
}

/// A [Google Cloud Pub/Sub subscription](https://cloud.google.com/pubsub/docs/overview#subscriptions).
final class Subscription {
  static final RegExp _subscriptionNameRegExp = RegExp(
    r'^projects/[^/]+/subscriptions/[^/]+$',
  );

  /// The [PubSub] client associated with this subscription.
  final PubSub pubsub;

  /// The fully qualified resource name of this subscription.
  ///
  /// It has the format `projects/<project-id>/subscriptions/<subscription-id>`.
  final String name;

  /// Settings controlling background ACKs and deadline modifications.
  final AckSettings ackSettings;

  late final Batcher<_AckRequest> _ackBatcher;
  late final Batcher<_ModifyAckDeadlineRequest> _modifyAckBatcher;

  /// Active streaming pull request streams for this subscription.
  ///
  /// Used to route ACKs and deadline modifications directly over existing
  /// bidirectional streaming pull connections instead of making separate unary
  /// RPCs.
  final List<StreamController<grpc.StreamingPullRequest>> _activeStreams = [];
  final Set<StreamController<ReceivedMessage>> _activeStreamingPullControllers =
      {};

  /// Index for round-robin load balancing ACKs across active streams.
  int _nextStreamIndex = 0;
  bool _isClosed = false;
  Future<void>? _closeFuture;

  /// A subscription with the given [subscriptionId] in the client's project.
  ///
  /// It is an error if the constructed subscription name is invalid (e.g. if
  /// [subscriptionId] contains slashes).
  Subscription.unqualified(
    this.pubsub,
    String subscriptionId, {
    AckSettings? ackSettings,
  }) : ackSettings = ackSettings ?? const AckSettings(),
       name = 'projects/${pubsub.projectId}/subscriptions/$subscriptionId' {
    _validateName(name);
    _initBatchers();
  }

  /// A subscription with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  Subscription(this.pubsub, this.name, {AckSettings? ackSettings})
    : ackSettings = ackSettings ?? const AckSettings() {
    _validateName(name);
    _initBatchers();
  }

  void _initBatchers() {
    _ackBatcher = Batcher<_AckRequest>(
      settings: ackSettings.batching,
      itemSize: (_) => 1,
      onBatch: _onAckBatch,
    );
    _modifyAckBatcher = Batcher<_ModifyAckDeadlineRequest>(
      settings: ackSettings.batching,
      itemSize: (_) => 1,
      onBatch: _onModifyAckDeadlineBatch,
    );
  }

  // Sends a batch of ACKs. Prefers sending over active gRPC streams
  // (round-robin), falling back to a unary RPC with retries if no streams
  // are available. Errors are caught and suppressed since ACKs are best-effort.
  Future<void> _onAckBatch(List<_AckRequest> batch) async {
    final ackIds = batch.map((r) => r.ackId).toList();
    if (_activeStreams.isNotEmpty) {
      final startIndex = _nextStreamIndex % _activeStreams.length;
      for (var i = 0; i < _activeStreams.length; i++) {
        final index = (startIndex + i) % _activeStreams.length;
        final stream = _activeStreams[index];
        if (!stream.isClosed && stream.hasListener) {
          try {
            stream.add(grpc.StreamingPullRequest()..ackIds.addAll(ackIds));
            _nextStreamIndex = (index + 1) % _activeStreams.length;
            for (final req in batch) {
              if (req.completer != null && !req.completer!.isCompleted) {
                req.completer!.complete();
              }
            }
            return;
            // ignore: avoid_catching_errors
          } on StateError {
            // Stream was closed concurrently, try next one.
          }
        }
      }
    }
    // Fall back to unary RPC if no active streams.
    try {
      await runWithRetry(
        () => pubsub.acknowledge(name, ackIds),
        settings: ackSettings.retry,
        isIdempotent: true,
      );
      for (final req in batch) {
        if (req.completer != null && !req.completer!.isCompleted) {
          req.completer!.complete();
        }
      }
    } catch (e, st) {
      // ACKs are best-effort. If the unary fallback fails after retries,
      // the error is suppressed for fire-and-forget, but attached completers
      // must receive the error.
      for (final req in batch) {
        if (req.completer != null && !req.completer!.isCompleted) {
          req.completer!.completeError(e, st);
        }
      }
    }
  }

  // Sends a batch of deadline modifications. Groups by deadline and prefers
  // sending over active gRPC streams, falling back to unary RPCs with retries.
  Future<void> _onModifyAckDeadlineBatch(
    List<_ModifyAckDeadlineRequest> batch,
  ) async {
    // Group requests by deadline so we can send batches with the same deadline.
    final byDeadline = <int, List<_ModifyAckDeadlineRequest>>{};
    for (final req in batch) {
      byDeadline.putIfAbsent(req.ackDeadlineSeconds, () => []).add(req);
    }
    await Future.wait(
      byDeadline.entries.map((entry) async {
        final deadline = entry.key;
        final reqs = entry.value;
        final ackIds = reqs.map((r) => r.ackId).toList();
        if (_activeStreams.isNotEmpty) {
          final startIndex = _nextStreamIndex % _activeStreams.length;
          for (var i = 0; i < _activeStreams.length; i++) {
            final index = (startIndex + i) % _activeStreams.length;
            final stream = _activeStreams[index];
            if (!stream.isClosed && stream.hasListener) {
              try {
                stream.add(
                  grpc.StreamingPullRequest()
                    ..modifyDeadlineAckIds.addAll(ackIds)
                    ..modifyDeadlineSeconds.addAll(
                      List.filled(ackIds.length, deadline),
                    ),
                );
                _nextStreamIndex = (index + 1) % _activeStreams.length;
                for (final req in reqs) {
                  if (req.completer != null && !req.completer!.isCompleted) {
                    req.completer!.complete();
                  }
                }
                return;
                // ignore: avoid_catching_errors
              } on StateError {
                // Stream was closed concurrently, try next one.
              }
            }
          }
        }
        // Fall back to unary RPC if no active streams.
        try {
          await runWithRetry(
            () => pubsub.modifyAckDeadline(name, ackIds, deadline),
            settings: ackSettings.retry,
            isIdempotent: true,
          );
          for (final req in reqs) {
            if (req.completer != null && !req.completer!.isCompleted) {
              req.completer!.complete();
            }
          }
        } catch (e, st) {
          // ACKs are best-effort. If the unary fallback fails after
          // retries, the error is suppressed for fire-and-forget, but
          // attached completers must receive the error.
          for (final req in reqs) {
            if (req.completer != null && !req.completer!.isCompleted) {
              req.completer!.completeError(e, st);
            }
          }
        }
      }),
    );
  }

  static void _validateName(String name) {
    if (!_subscriptionNameRegExp.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be in the format '
            'projects/<project-id>/subscriptions/<subscription-id>',
      );
    }
  }

  /// The unqualified ID of this subscription.
  String get id => name.split('/').last;

  /// Creates this subscription on the server, associating it with the [topic].
  ///
  /// The subscription must not already exist on the server.
  /// The [topic] must exist on the server.
  ///
  /// Throws a [ConflictException] if the subscription already exists.
  /// Throws a [NotFoundException] if the corresponding topic doesn't exist.
  ///
  /// Returns a [Subscription] instance representing the created subscription.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  Future<Subscription> create({required String topic}) =>
      pubsub.createSubscription(name, topic: topic);

  /// Deletes this subscription on the server.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<void> delete() => pubsub.deleteSubscription(name);

  /// Pulls up to [maxMessages] from this subscription.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull({int maxMessages = 100}) =>
      pubsub.pull(name, maxMessages: maxMessages);

  /// Establishes a bidirectional streaming pull connection to receive
  /// messages.
  ///
  /// By default, a single stream is opened. Higher throughput can be achieved
  /// by setting [maxConcurrentStreams] to open multiple parallel streaming pull
  /// connections. Messages from all streams are multiplexed into the returned
  /// [Stream]. Multi-stream pull helps overcome throughput limits on
  /// high-volume subscriptions by bypassing single-stream limitations.
  ///
  /// The stream automatically reconnects on transient network errors using the
  /// configured [retry] settings (defaulting to [AckSettings.retry] with
  /// unlimited total duration).
  /// Reconnections use exponential backoff, which resets once a connection
  /// has been sustained and healthy (> 15 seconds) or successfully yields
  /// messages.
  ///
  /// ACKs and deadline modifications sent via [acknowledge],
  /// [modifyAckDeadline], or the message handlers are batched in the background
  /// and sent over the active streams. If all streams are down, they fall back
  /// to unary RPCs.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [streamAckDeadlineSeconds] is not between 10 and 600
  /// seconds, or if [maxConcurrentStreams] is less than 1.
  ///
  /// Any errors (such as a [NotFoundException] if the subscription does not
  /// exist, or non-retryable errors) are emitted asynchronously on the returned
  /// [Stream] rather than thrown synchronously.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.StreamingPull).
  Stream<ReceivedMessage> streamingPull({
    int streamAckDeadlineSeconds = 10,
    int maxConcurrentStreams = 1,
    RetrySettings? retry,
  }) {
    if (streamAckDeadlineSeconds < 10 || streamAckDeadlineSeconds > 600) {
      throw ArgumentError.value(
        streamAckDeadlineSeconds,
        'streamAckDeadlineSeconds',
        'Must be between 10 and 600 seconds',
      );
    }
    if (maxConcurrentStreams < 1) {
      throw ArgumentError.value(
        maxConcurrentStreams,
        'maxConcurrentStreams',
        'Must be at least 1',
      );
    }

    if (_isClosed) {
      throw StateError('Cannot stream messages on a closed Subscription.');
    }
    final RetrySettings effectiveRetry;
    if (retry != null) {
      effectiveRetry = retry.hasExplicitTotalTimeout
          ? retry
          : retry.copyWith(totalTimeout: null);
    } else {
      effectiveRetry = ackSettings.retry.copyWith(totalTimeout: null);
    }

    late StreamController<ReceivedMessage> controller;
    var isCancelled = false;
    var isPaused = false;
    var activeOrReconnectingStreams = maxConcurrentStreams;

    // Track active request streams and subscriptions so we can clean them up.
    final currentSubs = <StreamSubscription<ReceivedMessage>>[];
    final requestControllers = <StreamController<grpc.StreamingPullRequest>>[];
    final reconnectTimers = <Timer>[];

    Future<void> cancelAll() async {
      for (final timer in reconnectTimers) {
        timer.cancel();
      }
      reconnectTimers.clear();
      final subsToCancel = currentSubs.toList();
      currentSubs.clear();
      for (final sub in subsToCancel) {
        await sub.cancel();
      }
      final rcsToClose = requestControllers.toList();
      requestControllers.clear();
      for (final rc in rcsToClose) {
        _activeStreams.remove(rc);
        unawaited(rc.close());
      }
    }

    Future<void> handleAck(List<String> ackIds) async {
      if (_isClosed) {
        throw StateError(
          'Cannot acknowledge messages on a closed Subscription.',
        );
      }
      final futures = <Future<void>>[];
      for (final ackId in ackIds) {
        final completer = Completer<void>();
        _ackBatcher.add(_AckRequest(ackId, completer));
        futures.add(completer.future);
      }
      await Future.wait(futures);
    }

    Future<void> handleModifyDeadline(List<String> ackIds, int seconds) async {
      if (_isClosed) {
        throw StateError(
          'Cannot modify ack deadline on a closed Subscription.',
        );
      }
      if (seconds < 0) {
        throw ArgumentError.value(seconds, 'seconds', 'Must be non-negative');
      }
      final futures = <Future<void>>[];
      for (final ackId in ackIds) {
        final completer = Completer<void>();
        _modifyAckBatcher.add(
          _ModifyAckDeadlineRequest(ackId, seconds, completer),
        );
        futures.add(completer.future);
      }
      await Future.wait(futures);
    }

    void connect(Iterator<Duration> delays) {
      if (_isClosed || isCancelled || controller.isClosed) return;

      final requestController = StreamController<grpc.StreamingPullRequest>()
        ..add(
          grpc.StreamingPullRequest()
            ..subscription = name
            ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
        );
      _activeStreams.add(requestController);
      requestControllers.add(requestController);

      var hasReceivedItem = false;
      final stopwatch = Stopwatch()..start();
      late StreamSubscription<ReceivedMessage> currentSub;

      void cleanupCurrentConnection() {
        _activeStreams.remove(requestController);
        requestControllers.remove(requestController);
        currentSubs.remove(currentSub);
        unawaited(currentSub.cancel());
        stopwatch.stop();
        unawaited(requestController.close());
      }

      currentSub = pubsub
          .streamingPullWithStream(
            requestController.stream,
            ackHandler: handleAck,
            modifyDeadlineHandler: handleModifyDeadline,
          )
          .listen(
            (message) {
              hasReceivedItem = true;
              controller.add(message);
            },
            onError: (Object e, StackTrace st) async {
              cleanupCurrentConnection();
              if (_isClosed || isCancelled || controller.isClosed) return;

              if (!isRetryable(e)) {
                controller.addError(e, st);
                await cancelAll();
                activeOrReconnectingStreams = 0;
                _activeStreamingPullControllers.remove(controller);
                await controller.close();
                return;
              }

              var nextDelays = delays;
              final wasHealthy =
                  hasReceivedItem ||
                  stopwatch.elapsed >= const Duration(seconds: 15);
              if (wasHealthy) {
                nextDelays = delaySequence(
                  maxRetries: effectiveRetry.maxRetries,
                  totalTimeout: effectiveRetry.totalTimeout,
                  initialDelay: effectiveRetry.initialDelay,
                  delayMultiplier: effectiveRetry.delayMultiplier,
                  maxDelay: effectiveRetry.maxDelay,
                ).iterator;
              }
              if (_isClosed || isCancelled || controller.isClosed) return;
              if (nextDelays.moveNext()) {
                late Timer timer;
                timer = Timer(nextDelays.current, () {
                  reconnectTimers.remove(timer);
                  if (_isClosed || isCancelled || controller.isClosed) return;
                  connect(nextDelays);
                });
                reconnectTimers.add(timer);
              } else {
                activeOrReconnectingStreams--;
                controller.addError(e, st);
                if (activeOrReconnectingStreams == 0) {
                  await cancelAll();
                  _activeStreamingPullControllers.remove(controller);
                  await controller.close();
                }
              }
            },
            onDone: () async {
              cleanupCurrentConnection();
              if (_isClosed || isCancelled || controller.isClosed) return;

              var nextDelays = delays;
              final wasHealthy =
                  hasReceivedItem ||
                  stopwatch.elapsed >= const Duration(seconds: 15);
              if (wasHealthy) {
                nextDelays = delaySequence(
                  maxRetries: effectiveRetry.maxRetries,
                  totalTimeout: effectiveRetry.totalTimeout,
                  initialDelay: effectiveRetry.initialDelay,
                  delayMultiplier: effectiveRetry.delayMultiplier,
                  maxDelay: effectiveRetry.maxDelay,
                ).iterator;
              }
              if (_isClosed || isCancelled || controller.isClosed) return;
              if (nextDelays.moveNext()) {
                late Timer timer;
                timer = Timer(nextDelays.current, () {
                  reconnectTimers.remove(timer);
                  if (_isClosed || isCancelled || controller.isClosed) return;
                  connect(nextDelays);
                });
                reconnectTimers.add(timer);
              } else {
                activeOrReconnectingStreams--;
                if (activeOrReconnectingStreams == 0) {
                  await cancelAll();
                  _activeStreamingPullControllers.remove(controller);
                  await controller.close();
                }
              }
            },
          );

      if (isPaused) {
        currentSub.pause();
      }
      currentSubs.add(currentSub);
    }

    controller = StreamController<ReceivedMessage>(
      onListen: () {
        for (var i = 0; i < maxConcurrentStreams; i++) {
          final delays = delaySequence(
            maxRetries: effectiveRetry.maxRetries,
            totalTimeout: effectiveRetry.totalTimeout,
            initialDelay: effectiveRetry.initialDelay,
            delayMultiplier: effectiveRetry.delayMultiplier,
            maxDelay: effectiveRetry.maxDelay,
          ).iterator;
          connect(delays);
        }
      },
      onPause: () {
        isPaused = true;
        for (final sub in currentSubs) {
          sub.pause();
        }
      },
      onResume: () {
        isPaused = false;
        for (final sub in currentSubs) {
          sub.resume();
        }
      },
      onCancel: () async {
        isCancelled = true;
        _activeStreamingPullControllers.remove(controller);
        await cancelAll();
      },
    );

    _activeStreamingPullControllers.add(controller);
    return controller.stream;
  }

  /// Acknowledges the [messages] synchronously.
  ///
  /// Bypasses background batching and immediately executes a unary RPC.
  ///
  /// It is an error if called on a closed [Subscription].
  /// Throws a [NotFoundException] if the subscription does not exist.
  /// Throws a [ServiceException] if the RPC fails.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledgeNow(List<ReceivedMessage> messages) {
    if (_isClosed) {
      throw StateError('Cannot acknowledge messages on a closed Subscription.');
    }
    return pubsub.acknowledge(name, messages.map((m) => m.ackId).toList());
  }

  /// Acknowledges [message] in the background.
  ///
  /// The acknowledgment is buffered and sent in a batch according to
  /// [AckSettings.batching]. If active [streamingPull] connections exist for
  /// this subscription, batches are sent directly over an active request
  /// stream. Otherwise, they are sent via a unary RPC with retries configured
  /// by [AckSettings.retry].
  ///
  /// It is an error if called on a closed [Subscription].
  ///
  /// This is a non-blocking, fire-and-forget operation. If a background ACK
  /// fails permanently, the message will eventually be redelivered by the
  /// server after its ack deadline expires.
  ///
  /// See [acknowledgeNow] for an immediate, awaitable alternative.
  void acknowledge(ReceivedMessage message) {
    if (_isClosed) {
      throw StateError('Cannot acknowledge messages on a closed Subscription.');
    }
    _ackBatcher.add(_AckRequest(message.ackId));
  }

  /// Modifies the ack deadline for [messages] synchronously.
  ///
  /// Bypasses background batching and immediately executes a unary RPC.
  ///
  /// It is an error if [ackDeadlineSeconds] is negative.
  /// It is an error if called on a closed [Subscription].
  /// Throws a [NotFoundException] if the subscription does not exist.
  /// Throws a [ServiceException] if the RPC fails.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadlineNow(
    List<ReceivedMessage> messages,
    int ackDeadlineSeconds,
  ) {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    return pubsub.modifyAckDeadline(
      name,
      messages.map((m) => m.ackId).toList(),
      ackDeadlineSeconds,
    );
  }

  /// Modifies the ack deadline for [message] in the background.
  ///
  /// The request is buffered and sent in a batch according to
  /// [AckSettings.batching]. If active [streamingPull] connections exist for
  /// this subscription, batches are sent directly over an active request
  /// stream. Otherwise, they are sent via a unary RPC with retries
  /// configured by [AckSettings.retry].
  ///
  /// It is an error if [ackDeadlineSeconds] is negative.
  /// It is an error if called on a closed [Subscription].
  ///
  /// This is a non-blocking, fire-and-forget operation. See
  /// [modifyAckDeadlineNow] for an immediate, awaitable alternative.
  void modifyAckDeadline(ReceivedMessage message, int ackDeadlineSeconds) {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    _modifyAckBatcher.add(
      _ModifyAckDeadlineRequest(message.ackId, ackDeadlineSeconds),
    );
  }

  /// Closes the subscription, flushing any pending acknowledgments and
  /// deadline modifications and waiting for in-flight batches to complete.
  Future<void> close() {
    _isClosed = true;
    return _closeFuture ??= () async {
      final controllers = _activeStreamingPullControllers.toList();
      _activeStreamingPullControllers.clear();
      for (final controller in controllers) {
        if (controller.onCancel case final onCancel?) {
          await onCancel();
        }
        if (!controller.isClosed) {
          await controller.close();
        }
      }
      await Future.wait([_ackBatcher.close(), _modifyAckBatcher.close()]);
    }();
  }
}
