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

// ignore_for_file: avoid_catching_errors, doc_directive_unknown

import 'dart:async';

import 'package:meta/meta.dart';

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'retry.dart';

/// Configuration settings for acknowledging messages and modifying deadlines.
///
/// These settings govern the behavior of the background batcher used by
/// [Subscription.acknowledge] and [Subscription.modifyAckDeadline].
class AckSettings {
  /// Settings controlling how ACKs and deadline modifications are accumulated
  /// and flushed in the background.
  final BatchingSettings batching;

  /// The retry strategy used when the background batcher must fall back to
  /// unary RPCs due to active gRPC streams being unavailable.
  final RetrySettings retry;

  const AckSettings({
    this.batching = const BatchingSettings(),
    this.retry = const RetrySettings(),
  });
}

class _AckRequest {
  final String ackId;

  _AckRequest(this.ackId);
}

class _ModifyAckDeadlineRequest {
  final String ackId;
  final int ackDeadlineSeconds;

  _ModifyAckDeadlineRequest(this.ackId, this.ackDeadlineSeconds);
}

@internal
Subscription newSubscription(
  PubSub pubsub,
  String subscriptionId, {
  AckSettings? ackSettings,
}) => Subscription.unqualified(
  pubsub,
  subscriptionId,
  ackSettings: ackSettings ?? const AckSettings(),
);

@internal
Subscription newSubscriptionName(
  PubSub pubsub,
  String name, {
  AckSettings? ackSettings,
}) =>
    Subscription(pubsub, name, ackSettings: ackSettings ?? const AckSettings());

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

  /// Settings for acknowledging messages.
  final AckSettings ackSettings;

  late final Batcher<_AckRequest> _ackBatcher;
  late final Batcher<_ModifyAckDeadlineRequest> _modifyAckBatcher;

  final List<StreamController<grpc.StreamingPullRequest>> _activeStreams = [];

  /// Index for round-robin load balancing ACKs across active streams.
  int _nextStreamIndex = 0;

  /// A subscription with the given [subscriptionId] in the client's project.
  Subscription.unqualified(
    this.pubsub,
    String subscriptionId, {
    this.ackSettings = const AckSettings(),
  }) : name = 'projects/${pubsub.projectId}/subscriptions/$subscriptionId' {
    _validateName(name);
    _initBatchers();
  }

  /// A subscription with the given [name].
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  /// Useful for cross-project access.
  Subscription(
    this.pubsub,
    this.name, {
    this.ackSettings = const AckSettings(),
  }) {
    _validateName(name);
    _initBatchers();
  }

  void _initBatchers() {
    _ackBatcher = Batcher<_AckRequest>(
      settings: ackSettings.batching,
      itemSize: (req) => req.ackId.length, // Approximate size
      onBatch: _onAckBatch,
    );

    _modifyAckBatcher = Batcher<_ModifyAckDeadlineRequest>(
      settings: ackSettings.batching,
      itemSize: (req) => req.ackId.length + 4, // Approximate size
      onBatch: _onModifyAckBatch,
    );
  }

  /// Processes a batch of accumulated acknowledgments.
  ///
  /// It first attempts to send the batch over one of the active [streamingPull]
  /// gRPC streams (load-balanced via round-robin). If no active streams are
  /// available, or if all attempts fail due to concurrent stream closures,
  /// it immediately falls back to a unary `Acknowledge` RPC wrapped in [runWithRetry].
  ///
  /// Since ACKs are best-effort, any exception thrown by the unary fallback
  /// after exhausting retries is caught and suppressed.
  Future<void> _onAckBatch(List<_AckRequest> batch) async {
    try {
      final ackIds = batch.map((e) => e.ackId).toList();

      if (_activeStreams.isNotEmpty) {
        final streams = List<StreamController<grpc.StreamingPullRequest>>.from(
          _activeStreams,
        );
        for (var i = 0; i < streams.length; i++) {
          _nextStreamIndex = (_nextStreamIndex + 1) % streams.length;
          final stream = streams[_nextStreamIndex];
          if (!stream.isClosed) {
            try {
              stream.add(grpc.StreamingPullRequest()..ackIds.addAll(ackIds));
              return;
            } on StateError {
              // Stream was closed concurrently, try next one.
            }
          }
        }
      }

      await runWithRetry(
        () => pubsub.acknowledge(name, ackIds),
        settings: ackSettings.retry,
        isIdempotent: true,
      );
    } on Exception catch (_) {
      // ACKs are best-effort. If the unary fallback fails after retries,
      // the error is suppressed. The messages will eventually be redelivered.
    }
  }

  /// Processes a batch of accumulated ack deadline modifications.
  ///
  /// It first groups the requests by their target deadline seconds, since the
  /// RPC requires all message IDs in a single request to share the same deadline.
  ///
  /// For each group, it attempts to send the request over one of the active
  /// [streamingPull] gRPC streams. If no active streams are available, or if
  /// all attempts fail, it falls back to a unary `ModifyAckDeadline` RPC
  /// wrapped in [runWithRetry].
  ///
  /// Any exception thrown by the unary fallback after exhausting retries is
  /// caught and suppressed.
  Future<void> _onModifyAckBatch(List<_ModifyAckDeadlineRequest> batch) async {
    // Group by ackDeadlineSeconds, as the RPC takes one deadline for all ackIds in the request.
    final grouped = <int, List<_ModifyAckDeadlineRequest>>{};
    for (final req in batch) {
      grouped.putIfAbsent(req.ackDeadlineSeconds, () => []).add(req);
    }

    await Future.wait(
      grouped.entries.map((entry) async {
        final MapEntry(key: deadline, value: reqs) = entry;
        try {
          final ackIds = reqs.map((e) => e.ackId).toList();

          if (_activeStreams.isNotEmpty) {
            final streams =
                List<StreamController<grpc.StreamingPullRequest>>.from(
                  _activeStreams,
                );
            for (var i = 0; i < streams.length; i++) {
              _nextStreamIndex = (_nextStreamIndex + 1) % streams.length;
              final stream = streams[_nextStreamIndex];
              if (!stream.isClosed) {
                try {
                  stream.add(
                    grpc.StreamingPullRequest()
                      ..modifyDeadlineAckIds.addAll(ackIds)
                      ..modifyDeadlineSeconds.addAll(
                        List.filled(ackIds.length, deadline),
                      ),
                  );
                  return;
                } on StateError {
                  // Stream was closed concurrently, try next one.
                }
              }
            }
          }

          await runWithRetry(
            () => pubsub.modifyAckDeadline(name, ackIds, deadline),
            settings: ackSettings.retry,
            isIdempotent: true,
          );
        } on Exception catch (_) {
          // ACKs are best-effort. If the unary fallback fails after retries,
          // the error is suppressed.
        }
      }),
    );
  }

  static void _validateName(String name) {
    if (!_subscriptionNameRegExp.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be in the format projects/<project-id>/subscriptions/<subscription-id>',
      );
    }
  }

  /// The ID of this subscription.
  String get subscriptionId => name.split('/').last;

  /// Creates a subscription to a given topic.
  ///
  /// Throws a [SubscriptionAlreadyExistsException] if the subscription already
  /// exists.
  /// Throws a [TopicNotFoundException] if the corresponding topic doesn't
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  Future<Subscription> create({required String topic}) =>
      pubsub.createSubscription(name, topic: topic);

  /// Deletes an existing subscription.
  ///
  /// All messages retained in the subscription are immediately dropped.
  ///
  /// Returns `true` if the subscription was deleted, or `false` if the
  /// subscription did not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<bool> delete() => pubsub.deleteSubscription(name);

  /// Pulls messages from the server.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull({int maxMessages = 1}) {
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than 0',
      );
    }
    return pubsub.pull(name, maxMessages: maxMessages);
  }

  /// Establishes a persistent, high-throughput stream with the server to receive messages.
  ///
  /// The client automatically streams acknowledgments and ack deadline modifications
  /// back to the server. Flow control is managed by the underlying gRPC transport.
  ///
  /// **Parallel Streams:**
  /// By setting [maxConcurrentStreams] > 1, you can open multiple parallel gRPC
  /// connections. This is highly recommended for high-throughput subscriptions to
  /// bypass the throughput limitations of a single gRPC stream.
  ///
  /// **Robust Auto-Reconnection:**
  /// If an underlying stream encounters an error (including server-initiated
  /// disconnects for load balancing), it will automatically attempt to reconnect
  /// in the background using exponential backoff (configured via [retry]).
  /// Once a connection successfully yields new messages, its backoff sequence is reset.
  ///
  /// **Background Batching:**
  /// ACKs sent via [acknowledge] and deadline modifications sent via [modifyAckDeadline]
  /// are automatically batched in the background and routed over the most optimal
  /// active gRPC stream, load-balanced using round-robin. If all streams are
  /// temporarily down, they immediately fall back to unary RPCs with their own retries.
  ///
  /// **Preconditions:**
  /// - [streamAckDeadlineSeconds] must be between 10 and 600 seconds (inclusive).
  /// - [maxConcurrentStreams] must be at least 1.
  ///
  /// **Exceptions:**
  /// - Throws [ArgumentError] if preconditions are violated.
  /// - The returned stream will emit [SubscriptionNotFoundException] if the
  ///   subscription does not exist on the server.
  /// - The returned stream will emit [StreamBrokenException] if a connection
  ///   fails permanently (exhausts all retries). If all parallel streams fail
  ///   permanently, the returned stream will close.
  ///
  /// **Example:**
  /// {@example example/doc_examples.dart region=streaming_pull_example}
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

    final effectiveRetry = retry ?? ackSettings.retry;
    late StreamController<ReceivedMessage> controller;
    var isCancelled = false;

    // Track active request streams and subscriptions so we can clean them up.
    final currentSubs = <StreamSubscription<ReceivedMessage>>[];
    final requestControllers = <StreamController<grpc.StreamingPullRequest>>[];

    void connect(Iterator<Duration> delays) {
      if (isCancelled) return;

      final requestController = StreamController<grpc.StreamingPullRequest>();
      requestController.add(
        grpc.StreamingPullRequest()
          ..subscription = name
          ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
      );
      _activeStreams.add(requestController);
      requestControllers.add(requestController);

      var hasReceivedItem = false;
      late StreamSubscription<ReceivedMessage> currentSub;
      currentSub = pubsub
          .streamingPullWithStream(requestController.stream)
          .listen(
            (item) {
              hasReceivedItem = true;
              controller.add(item);
            },
            onError: (Object e) {
              _activeStreams.remove(requestController);
              requestControllers.remove(requestController);
              currentSubs.remove(currentSub);
              requestController.close();

              if (isCancelled) return;

              Iterator<Duration> nextDelays = delays;
              if (hasReceivedItem) {
                nextDelays = delaySequence(
                  maxRetries: effectiveRetry.maxRetries,
                  maxRetryInterval: effectiveRetry.maxRetryInterval,
                  initialDelay: effectiveRetry.initialDelay,
                  delayMultiplier: effectiveRetry.delayMultiplier,
                  maxDelay: effectiveRetry.maxDelay,
                ).iterator;
              }
              if (nextDelays.moveNext()) {
                Future<void>.delayed(nextDelays.current).then((_) {
                  connect(nextDelays);
                });
              } else {
                controller.addError(e);
                // If we reach max retries on one stream, should we close the whole controller?
                // For safety, we will close it if this is the last failing stream.
                if (currentSubs.isEmpty) {
                  controller.close();
                }
              }
            },
            onDone: () {
              _activeStreams.remove(requestController);
              requestControllers.remove(requestController);
              currentSubs.remove(currentSub);
              requestController.close();

              if (isCancelled) return;

              // Reconnect right away on graceful close.
              // If we had a successful connection that yielded items, reset backoff.
              var nextDelays = delays;
              if (hasReceivedItem) {
                nextDelays = delaySequence(
                  maxRetries: effectiveRetry.maxRetries,
                  maxRetryInterval: effectiveRetry.maxRetryInterval,
                  initialDelay: effectiveRetry.initialDelay,
                  delayMultiplier: effectiveRetry.delayMultiplier,
                  maxDelay: effectiveRetry.maxDelay,
                ).iterator;
              }
              Future.microtask(() => connect(nextDelays));
            },
          );
      currentSubs.add(currentSub);
    }

    controller = StreamController<ReceivedMessage>(
      onListen: () {
        for (var i = 0; i < maxConcurrentStreams; i++) {
          final delays = delaySequence(
            maxRetries: effectiveRetry.maxRetries,
            maxRetryInterval: effectiveRetry.maxRetryInterval,
            initialDelay: effectiveRetry.initialDelay,
            delayMultiplier: effectiveRetry.delayMultiplier,
            maxDelay: effectiveRetry.maxDelay,
          ).iterator;
          connect(delays);
        }
      },
      onCancel: () async {
        isCancelled = true;
        for (final sub in currentSubs.toList()) {
          await sub.cancel();
        }
        for (final rc in requestControllers.toList()) {
          _activeStreams.remove(rc);
          await rc.close();
        }
        currentSubs.clear();
        requestControllers.clear();
      },
    );

    return controller.stream;
  }

  /// Acknowledges the given [messages] immediately and awaits confirmation.
  ///
  /// Unlike [acknowledge], this method bypasses the background batcher and
  /// immediately executes a unary `Acknowledge` RPC on the server.
  ///
  /// **Exceptions:**
  /// - Throws [SubscriptionNotFoundException] if the subscription does not exist.
  /// - Throws [PubSubException] (or other GrpcError wrappers) if the RPC fails.
  ///
  /// **Example:**
  /// {@example example/doc_examples.dart region=acknowledge_now_example}
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledgeNow(List<ReceivedMessage> messages) =>
      pubsub.acknowledge(name, messages.map((m) => m.ackId).toList());

  /// Acknowledges the given [message] in the background.
  ///
  /// This method is highly optimized for performance. It does not execute an immediate
  /// RPC. Instead, it buffers the acknowledgment and batches it with other ACKs
  /// in the background according to [AckSettings.batching] settings.
  ///
  /// **Streaming Optimization:**
  /// If a [streamingPull] stream is currently active, the batched ACKs will be
  /// efficiently routed over the existing bidirectional gRPC stream. If no streams
  /// are active (or they are all temporarily reconnecting), it automatically
  /// falls back to executing a unary `Acknowledge` RPC with robust retries
  /// (configured via [AckSettings.retry]).
  ///
  /// Acknowledging a message allows the Pub/Sub system to remove it from the
  /// subscription. While best-effort, if an ACK fails permanently (even after
  /// unary retries), the message will eventually be redelivered by the server
  /// after its ack deadline expires.
  ///
  /// **Performance Considerations:**
  /// This is a non-blocking, fire-and-forget operation (returns `void`). It is
  /// the preferred way to acknowledge messages in high-throughput applications.
  ///
  /// See [acknowledgeNow] for an immediate, awaitable alternative.
  void acknowledge(ReceivedMessage message) {
    _ackBatcher.add(_AckRequest(message.ackId));
  }

  /// Modifies the acknowledgment deadline for the given [messages] immediately
  /// and awaits confirmation.
  ///
  /// Unlike [modifyAckDeadline], this method bypasses the background batcher and
  /// immediately executes a unary `ModifyAckDeadline` RPC on the server.
  ///
  /// **Preconditions:**
  /// - [ackDeadlineSeconds] must be between 0 and 600 seconds (inclusive).
  ///
  /// **Exceptions:**
  /// - Throws [SubscriptionNotFoundException] if the subscription does not exist.
  /// - Throws [PubSubException] if the RPC fails.
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
    return pubsub.modifyAckDeadline(
      name,
      messages.map((m) => m.ackId).toList(),
      ackDeadlineSeconds,
    );
  }

  /// Modifies the acknowledgment deadline for the given [message] in the background.
  ///
  /// This method is highly optimized for performance. It does not execute an immediate
  /// RPC. Instead, it buffers the request and batches it with other deadline
  /// modifications in the background according to [AckSettings.batching] settings,
  /// grouping them by [ackDeadlineSeconds].
  ///
  /// **Streaming Optimization:**
  /// If a [streamingPull] stream is currently active, the batched requests will be
  /// efficiently routed over the existing bidirectional gRPC stream. If no streams
  /// are active, it automatically falls back to executing a unary `ModifyAckDeadline`
  /// RPC with robust retries (configured via [AckSettings.retry]).
  ///
  /// **Preconditions:**
  /// - [ackDeadlineSeconds] must be between 0 and 600 seconds (inclusive).
  ///
  /// **Performance Considerations:**
  /// This is a non-blocking, fire-and-forget operation (returns `void`). It is
  /// the preferred way to extend deadlines in high-throughput applications.
  ///
  /// See [modifyAckDeadlineNow] for an immediate, awaitable alternative.
  void modifyAckDeadline(ReceivedMessage message, int ackDeadlineSeconds) {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    _modifyAckBatcher.add(
      _ModifyAckDeadlineRequest(message.ackId, ackDeadlineSeconds),
    );
  }

  /// Closes the subscription, flushing any pending acknowledgments.
  void close() {
    _ackBatcher.close();
    _modifyAckBatcher.close();
  }
}
