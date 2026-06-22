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

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pbgrpc.dart'
    as grpc;
import 'retry.dart';

/// Settings for acknowledging messages and modifying ack deadlines.
class AckSettings {
  final BatchingSettings batching;
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

  /// Number of active calls to [streamingPull].
  int _streamingPullSubscriptionCount = 0;

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

  Future<void> _onAckBatch(List<_AckRequest> batch) async {
    try {
      final ackIds = batch.map((e) => e.ackId).toList();

      if (_streamingPullSubscriptionCount > 0 && _activeStreams.isNotEmpty) {
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

  Future<void> _onModifyAckBatch(List<_ModifyAckDeadlineRequest> batch) async {
    // Group by ackDeadlineSeconds, as the RPC takes one deadline for all ackIds in the request.
    final grouped = <int, List<_ModifyAckDeadlineRequest>>{};
    for (final req in batch) {
      grouped.putIfAbsent(req.ackDeadlineSeconds, () => []).add(req);
    }

    await Future.wait(
      grouped.entries.map((entry) async {
        final deadline = entry.key;
        final reqs = entry.value;
        try {
          final ackIds = reqs.map((e) => e.ackId).toList();

          if (_streamingPullSubscriptionCount > 0 &&
              _activeStreams.isNotEmpty) {
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

  /// Establishes a stream with the server, which sends messages down to the
  /// client.
  ///
  /// The client streams acknowledgments and ack deadline modifications
  /// back to the server. If an error occurs (including when the server closes
  /// the stream with status `UNAVAILABLE` to reassign resources), the stream
  /// will throw a [StreamBrokenException]. In this case, the caller should
  /// re-establish the stream. Flow control can be achieved by configuring the
  /// underlying RPC channel.
  ///
  /// The [streamAckDeadlineSeconds] specifies the deadline in seconds for
  /// acknowledging messages on the stream.
  ///
  /// The [maxConcurrentStreams] parameter specifies how many underlying gRPC
  /// connections to open to maximize throughput. It defaults to 1.
  ///
  /// The [retry] parameter specifies the retry strategy for transient network errors.
  /// If not provided, it defaults to the `ackSettings.retry` configuration.
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
          _streamingPullSubscriptionCount++;
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
        _streamingPullSubscriptionCount -= maxConcurrentStreams;
      },
    );

    return controller.stream;
  }

  /// Acknowledges the given [messages] immediately.
  ///
  /// The Pub/Sub system can remove the relevant messages from the subscription.
  ///
  /// Acknowledging a message whose ack deadline has expired may succeed,
  /// but such a message may be redelivered later. Acknowledging a message more
  /// than once will not result in an error.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledgeNow(List<ReceivedMessage> messages) =>
      pubsub.acknowledge(name, messages.map((m) => m.ackId).toList());

  /// Acknowledges a single message.
  ///
  /// This method uses the configured `ackSettings` to buffer and batch multiple
  /// acknowledgment requests together in the background. If one or more
  /// [streamingPull] streams are currently active, the batched acknowledgments
  /// will be routed over the existing bidirectional stream.
  ///
  /// If no streaming streams are active, the client falls back to executing
  /// standard unary `Acknowledge` RPCs, and automatically retries on transient
  /// network errors according to the `ackSettings.retry` configuration.
  ///
  /// This operation is "fire-and-forget" and does not wait for server
  /// confirmation. If an error occurs that exhausts all retries, the error is
  /// suppressed and the message will eventually be redelivered. If you require
  /// explicit confirmation of acknowledgment, use [acknowledgeNow].
  void acknowledge(ReceivedMessage message) {
    _ackBatcher.add(_AckRequest(message.ackId));
  }

  /// Modifies the ack deadline for a list of specific messages immediately.
  ///
  /// This method is useful to indicate that more time is needed to process a
  /// message by the subscriber, or to make the message available for redelivery
  /// if the processing was interrupted. Note that this does not modify the
  /// subscription-level `ackDeadlineSeconds` used for subsequent messages.
  ///
  /// Modifying the ack deadline for messages whose deadline has already expired
  /// may succeed, but those messages may have already been redelivered or
  /// made available for redelivery.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
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

  /// Modifies the ack deadline for a single message.
  ///
  /// This method uses the configured `ackSettings` to buffer and batch multiple
  /// modification requests together in the background. If one or more
  /// [streamingPull] streams are currently active, the batched modifications
  /// will be routed over the existing bidirectional stream.
  ///
  /// If no streaming streams are active, the client falls back to executing
  /// standard unary `ModifyAckDeadline` RPCs, and automatically retries on
  /// transient network errors according to the `ackSettings.retry` configuration.
  ///
  /// This operation is "fire-and-forget" and does not wait for server
  /// confirmation. If an error occurs that exhausts all retries, the error is
  /// suppressed. If you require explicit confirmation, use [modifyAckDeadlineNow].
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
