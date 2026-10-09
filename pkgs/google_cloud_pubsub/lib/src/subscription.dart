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
import 'wire_size.dart';

/// Settings for background batching and retrying of acknowledgments and
/// deadline modifications.
final class AckSettings {
  /// Settings controlling how requests are accumulated and flushed.
  ///
  /// Pub/Sub accepts at most 512,000 bytes in an `Acknowledge` or
  /// `ModifyAckDeadline` request, which is also the default
  /// [BatchingSettings.maxBytes]. Creating a [Subscription] with a larger
  /// [BatchingSettings.maxBytes] throws an [ArgumentError].
  final BatchingSettings batching;

  /// How failed `Acknowledge` and `ModifyAckDeadline` requests are retried.
  ///
  /// Defaults to [defaultRetry].
  final RetryRunner retry;

  /// Creates a new [AckSettings] instance.
  AckSettings({BatchingSettings? batching, RetryRunner? retry})
    : batching = batching ?? BatchingSettings(),
      retry = retry ?? defaultRetry;
}

final class _AckRequest {
  final String ackId;

  _AckRequest(this.ackId);
}

final class _ModifyAckDeadlineRequest {
  final String ackId;
  final int ackDeadlineSeconds;

  _ModifyAckDeadlineRequest(this.ackId, this.ackDeadlineSeconds);
}

/// A [Google Cloud Pub/Sub subscription](https://cloud.google.com/pubsub/docs/overview#subscriptions).
///
/// Acknowledgments and deadline modifications passed to [acknowledge] and
/// [modifyAckDeadline] are buffered and sent in batches. Create one
/// [Subscription] per subscription and reuse it, and call and await [close]
/// before shutdown to flush buffered requests.
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

  /// Settings controlling background acknowledgment and deadline modification
  /// batching and retries.
  final AckSettings ackSettings;

  late final Batcher<_AckRequest> _ackBatcher;
  late final Batcher<_ModifyAckDeadlineRequest> _modifyAckBatcher;

  bool _isClosed = false;
  Future<void>? _closeFuture;

  /// Whether this subscription has been closed via [close].
  bool get isClosed => _isClosed;

  /// A subscription with the given [subscriptionId] in the client's project.
  ///
  /// It is an error if the constructed subscription name is invalid (e.g. if
  /// [subscriptionId] contains slashes), or if [ackSettings] exceeds the
  /// limits described in [AckSettings.batching].
  Subscription.unqualified(
    this.pubsub,
    String subscriptionId, {
    AckSettings? ackSettings,
  }) : name = 'projects/${pubsub.projectId}/subscriptions/$subscriptionId',
       ackSettings = ackSettings ?? AckSettings() {
    _validateName(name);
    _initBatchers();
  }

  /// A subscription with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`, or if
  /// [ackSettings] exceeds the limits described in [AckSettings.batching].
  Subscription(this.pubsub, this.name, {AckSettings? ackSettings})
    : ackSettings = ackSettings ?? AckSettings() {
    _validateName(name);
    _initBatchers();
  }

  void _initBatchers() {
    checkServerLimits(
      ackSettings.batching,
      maxBytes: maxAcknowledgeRequestBytes,
      requestDescription: 'Acknowledge or ModifyAckDeadline request',
    );
    final settings = ackSettings.batching;

    _ackBatcher = Batcher<_AckRequest>(
      settings: settings,
      baseSize: acknowledgeRequestBaseSize(name),
      itemSize: (request) => acknowledgeRequestItemSize(request.ackId),
      onBatch: _onAckBatch,
    );
    _modifyAckBatcher = Batcher<_ModifyAckDeadlineRequest>(
      settings: settings,
      baseSize: modifyAckDeadlineRequestBaseSize(name),
      itemSize: (request) => modifyAckDeadlineRequestItemSize(
        request.ackId,
        request.ackDeadlineSeconds,
      ),
      onBatch: _onModifyAckBatch,
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
  /// Returns this [Subscription].
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  Future<Subscription> create({required String topic}) async {
    await pubsub.createSubscription(
      name,
      topic: topic,
      ackSettings: ackSettings,
    );
    return this;
  }

  /// Deletes this subscription on the server.
  ///
  /// All messages retained in the subscription are immediately dropped.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<void> delete() => pubsub.deleteSubscription(name);

  /// Pulls messages from the server.
  ///
  /// It is an error if [maxMessages] is not greater than 0.
  /// It is an error if called on a closed [Subscription].
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull({int maxMessages = 1}) {
    if (_isClosed) {
      throw StateError('Cannot pull messages on a closed Subscription.');
    }
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than zero',
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
  /// will throw a [ServiceException]. In this case, the caller should
  /// re-establish the stream. Flow control can be achieved by configuring the
  /// underlying RPC channel.
  ///
  /// Throws a [ServiceException] if the stream is broken by the server or
  /// network.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [streamAckDeadlineSeconds] is not between 10 and 600
  /// seconds.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.StreamingPull).
  Stream<ReceivedMessage> streamingPull({int streamAckDeadlineSeconds = 10}) {
    if (_isClosed) {
      throw StateError('Cannot stream messages on a closed Subscription.');
    }
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

  Future<void> _onAckBatch(List<_AckRequest> batch) async {
    final ackIds = batch.map((item) => item.ackId).toSet().toList();
    try {
      await ackSettings.retry.run(
        () => pubsub.acknowledge(name, ackIds),
        isIdempotent: true,
      );
    } catch (_) {
      // Best effort: unacknowledged messages will be redelivered upon
      // deadline expiry.
    }
  }

  Future<void> _onModifyAckBatch(List<_ModifyAckDeadlineRequest> batch) async {
    // If the same ackId was modified multiple times within the batch (e.g.
    // lease extension followed by nack), preserve only the latest deadline.
    final latestByAckId = <String, int>{};
    for (final request in batch) {
      latestByAckId[request.ackId] = request.ackDeadlineSeconds;
    }
    // Group requests by deadline since each ModifyAckDeadlineRequest carries a
    // single ackDeadlineSeconds value for all of its ackIds.
    final byDeadline = <int, List<String>>{};
    for (final entry in latestByAckId.entries) {
      byDeadline.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    await Future.wait(
      byDeadline.entries.map((entry) async {
        final deadlineSeconds = entry.key;
        final ackIds = entry.value;
        try {
          await ackSettings.retry.run(
            () => pubsub.modifyAckDeadline(name, ackIds, deadlineSeconds),
            isIdempotent: true,
          );
        } catch (_) {
          // Best effort.
        }
      }),
    );
  }

  /// Acknowledges the [messages] immediately in a single unary RPC without
  /// batching or retry.
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
    if (messages.isEmpty) return Future.value();
    return pubsub.acknowledge(
      name,
      messages.map((message) => message.ackId).toList(),
    );
  }

  /// Acknowledges [message] in the background.
  ///
  /// The acknowledgment is buffered and sent in a batch according to
  /// [AckSettings.batching] via a unary RPC with retries configured
  /// by [AckSettings.retry].
  ///
  /// To ensure all buffered acknowledgments are delivered before application
  /// shutdown, call and await [close].
  ///
  /// It is an error if called on a closed [Subscription].
  ///
  /// This is a non-blocking, fire-and-forget operation. If a background
  /// acknowledgment fails permanently, the message will eventually be
  /// redelivered by the server after its ack deadline expires.
  ///
  /// See [acknowledgeNow] for an immediate, awaitable alternative.
  void acknowledge(ReceivedMessage message) {
    if (_isClosed) {
      throw StateError('Cannot acknowledge messages on a closed Subscription.');
    }
    _ackBatcher.add(_AckRequest(message.ackId));
  }

  /// Modifies the ack deadline for [messages] immediately in a single unary
  /// RPC without batching or retry.
  ///
  /// [ackDeadlineSeconds] must be the new ack deadline in seconds, relative to
  /// the time the request is received. For example, if [ackDeadlineSeconds] is
  /// 10, the new ack deadline is 10 seconds from now. Specifying 0 makes the
  /// message immediately available for redelivery.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [ackDeadlineSeconds] is not between 0 and 600 seconds.
  /// Throws a [NotFoundException] if the subscription does not exist.
  /// Throws a [ServiceException] if the RPC fails.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadlineNow(
    List<ReceivedMessage> messages,
    int ackDeadlineSeconds,
  ) {
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be between 0 and 600 seconds',
      );
    }
    if (messages.isEmpty) return Future.value();
    return pubsub.modifyAckDeadline(
      name,
      messages.map((message) => message.ackId).toList(),
      ackDeadlineSeconds,
    );
  }

  /// Modifies the ack deadline for [message] in the background.
  ///
  /// The request is buffered and sent in a batch according to
  /// [AckSettings.batching] via a unary RPC with retries configured
  /// by [AckSettings.retry].
  ///
  /// [ackDeadlineSeconds] must be the new ack deadline in seconds, relative to
  /// the time the request is received. For example, if [ackDeadlineSeconds] is
  /// 10, the new ack deadline is 10 seconds from now. Specifying 0 makes the
  /// message immediately available for redelivery.
  ///
  /// To ensure all buffered deadline modifications are delivered before
  /// application shutdown, call and await [close].
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [ackDeadlineSeconds] is not between 0 and 600 seconds.
  ///
  /// This is a non-blocking, fire-and-forget operation. See
  /// [modifyAckDeadlineNow] for an immediate, awaitable alternative.
  void modifyAckDeadline(ReceivedMessage message, int ackDeadlineSeconds) {
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be between 0 and 600 seconds',
      );
    }
    _modifyAckBatcher.add(
      _ModifyAckDeadlineRequest(message.ackId, ackDeadlineSeconds),
    );
  }

  /// Closes the subscription, flushing any pending acknowledgments and
  /// deadline modifications and waiting for in-flight batches to complete.
  ///
  /// Calling and awaiting [close] during application shutdown ensures that all
  /// buffered acknowledgments and deadline modifications are sent before the
  /// process exits, preventing message redelivery.
  ///
  /// Once closed, it is an error to call [acknowledge], [acknowledgeNow],
  /// [modifyAckDeadline], [modifyAckDeadlineNow], [pull], or [streamingPull].
  Future<void> close() {
    _isClosed = true;
    return _closeFuture ??= _doClose();
  }

  Future<void> _doClose() async {
    await Future.wait([_ackBatcher.close(), _modifyAckBatcher.close()]);
  }
}
