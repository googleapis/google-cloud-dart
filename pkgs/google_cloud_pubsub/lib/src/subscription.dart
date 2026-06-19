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
  final Completer<void> completer;

  _AckRequest(this.ackId, this.completer);
}

class _ModifyAckDeadlineRequest {
  final String ackId;
  final int ackDeadlineSeconds;
  final Completer<void> completer;

  _ModifyAckDeadlineRequest(
    this.ackId,
    this.ackDeadlineSeconds,
    this.completer,
  );
}

@internal
Subscription newSubscription(PubSub pubsub, String subscriptionId) =>
    Subscription.unqualified(pubsub, subscriptionId);

@internal
Subscription newSubscriptionName(PubSub pubsub, String name) =>
    Subscription(pubsub, name);

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
      await runWithRetry(
        () => pubsub.acknowledge(name, ackIds),
        settings: ackSettings.retry,
        isIdempotent: true,
      );
      for (final req in batch) {
        req.completer.complete();
      }
    } catch (e, st) {
      for (final req in batch) {
        req.completer.completeError(e, st);
      }
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
          await runWithRetry(
            () => pubsub.modifyAckDeadline(name, ackIds, deadline),
            settings: ackSettings.retry,
            isIdempotent: true,
          );
          for (final req in reqs) {
            req.completer.complete();
          }
        } catch (e, st) {
          for (final req in reqs) {
            req.completer.completeError(e, st);
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
  /// Throws a [StreamBrokenException] if the stream is broken by the server or
  /// network.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.StreamingPull).
  Stream<ReceivedMessage> streamingPull({int streamAckDeadlineSeconds = 10}) {
    if (streamAckDeadlineSeconds < 10 || streamAckDeadlineSeconds > 600) {
      throw ArgumentError.value(
        streamAckDeadlineSeconds,
        'streamAckDeadlineSeconds',
        'Must be between 10 and 600 seconds',
      );
    }
    return pubsub.streamingPull(
      name,
      streamAckDeadlineSeconds: streamAckDeadlineSeconds,
    );
  }

  /// Acknowledges the messages associated with the `ack_ids` immediately.
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
  Future<void> acknowledgeNow(List<String> ackIds) =>
      pubsub.acknowledge(name, ackIds);

  /// Acknowledges a list of messages.
  ///
  /// This method uses the configured `ackSettings` to batch multiple
  /// acknowledgment requests together and retry on transient errors.
  Future<void> acknowledge(List<String> ackIds) async {
    final futures = <Future<void>>[];
    for (final ackId in ackIds) {
      final completer = Completer<void>();
      _ackBatcher.add(_AckRequest(ackId, completer));
      futures.add(completer.future);
    }
    await Future.wait(futures);
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
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    return pubsub.modifyAckDeadline(name, ackIds, ackDeadlineSeconds);
  }

  /// Modifies the ack deadline for a list of specific messages.
  ///
  /// This method uses the configured `ackSettings` to batch multiple
  /// modification requests together and retry on transient errors.
  Future<void> modifyAckDeadline(
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) async {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    final futures = <Future<void>>[];
    for (final ackId in ackIds) {
      final completer = Completer<void>();
      _modifyAckBatcher.add(
        _ModifyAckDeadlineRequest(ackId, ackDeadlineSeconds, completer),
      );
      futures.add(completer.future);
    }
    await Future.wait(futures);
  }

  /// Closes the subscription, flushing any pending acknowledgments.
  void close() {
    _ackBatcher.close();
    _modifyAckBatcher.close();
  }
}
