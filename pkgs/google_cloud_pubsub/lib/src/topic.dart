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
import 'dart:typed_data';

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'wire_size.dart';

/// Settings for background batching and retrying of published messages.
///
/// Used by [Topic.publish].
final class PublishSettings {
  /// Settings controlling how messages are accumulated and flushed.
  ///
  /// Validated when a [Topic] is created: the [Topic] constructors, and
  /// [PubSub.topic], [PubSub.topicName], and [PubSub.createTopic], throw an
  /// [ArgumentError] if [BatchingSettings.maxBytes] exceeds 10,000,000 or
  /// [BatchingSettings.maxMessages] exceeds 1,000, the largest `Publish`
  /// request Pub/Sub accepts.
  final BatchingSettings batching;

  /// How failed `Publish` requests are retried.
  ///
  /// Defaults to [defaultRetry].
  ///
  /// A retried request can publish a message more than once if the server
  /// processed the original request but the response was lost.
  final RetryRunner retry;

  /// Creates a new [PublishSettings] instance.
  PublishSettings({BatchingSettings? batching, RetryRunner? retry})
    : batching = batching ?? BatchingSettings(),
      retry = retry ?? defaultRetry;
}

final class _PublishRequest {
  final Message message;
  final Completer<String> completer;

  _PublishRequest(this.message, this.completer);
}

/// A [Google Cloud Pub/Sub topic](https://cloud.google.com/pubsub/docs/overview#topics).
///
/// Messages passed to [publish] are buffered and sent in batches. Create one
/// [Topic] per topic and reuse it, and call and await [close] before shutdown
/// to flush buffered messages.
final class Topic {
  static final RegExp _topicNameRegExp = RegExp(
    r'^projects/[^/]+/topics/[^/]+$',
  );

  /// The [PubSub] client associated with this topic.
  final PubSub pubsub;

  /// The fully qualified resource name of this topic.
  ///
  /// It has the format `projects/<project-id>/topics/<topic-id>`.
  final String name;

  /// Settings for publishing messages.
  final PublishSettings publishSettings;

  late final Batcher<_PublishRequest> _batcher;

  /// Whether this topic is closed.
  bool get isClosed => _batcher.isClosed;

  /// A topic with the given [topicId] in the client's project.
  ///
  /// It is an error if the constructed topic name is invalid (e.g. if [topicId]
  /// contains slashes), or if [publishSettings] exceeds the limits described
  /// in [PublishSettings.batching].
  Topic.unqualified(
    this.pubsub,
    String topicId, {
    PublishSettings? publishSettings,
  }) : name = 'projects/${pubsub.projectId}/topics/$topicId',
       publishSettings = publishSettings ?? PublishSettings() {
    _validateName(name);
    _initBatcher();
  }

  /// A topic with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/topics/<topic-id>`, or if [publishSettings]
  /// exceeds the limits described in [PublishSettings.batching].
  Topic(this.pubsub, this.name, {PublishSettings? publishSettings})
    : publishSettings = publishSettings ?? PublishSettings() {
    _validateName(name);
    _initBatcher();
  }

  void _initBatcher() {
    checkServerLimits(
      publishSettings.batching,
      maxBytes: maxPublishRequestBytes,
      maxMessages: maxPublishRequestMessages,
      requestDescription: 'Publish request',
    );
    _batcher = Batcher<_PublishRequest>(
      settings: publishSettings.batching,
      // Every request carries the topic name, whatever else it contains.
      baseSize: publishRequestBaseSize(name),
      itemSize: (request) => publishRequestMessageSize(request.message),
      onBatch: _onBatch,
    );
  }

  Future<void> _onBatch(List<_PublishRequest> batch) async {
    try {
      final messages = batch.map((item) => item.message).toList();
      // `RetryRunner.run` only retries when `isIdempotent` is true. Although a
      // retried `Publish` RPC can produce duplicate messages if the server
      // processed the original request before a lost response, Pub/Sub delivery
      // is at-least-once by design and retries transient publish failures.
      final messageIds = await publishSettings.retry.run(
        () => pubsub.publishMessages(name, messages),
        isIdempotent: true,
      );

      for (var i = 0; i < batch.length; i++) {
        if (i < messageIds.length) {
          if (!batch[i].completer.isCompleted) {
            batch[i].completer.complete(messageIds[i]);
          }
        } else {
          if (!batch[i].completer.isCompleted) {
            batch[i].completer.completeError(
              InternalServerErrorException(
                'Server returned fewer message IDs (${messageIds.length}) '
                'than published messages (${batch.length}).',
              ),
            );
          }
        }
      }
    } catch (error, stackTrace) {
      for (final item in batch) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(error, stackTrace);
        }
      }
    }
  }

  static void _validateName(String name) {
    if (!_topicNameRegExp.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be in the format projects/<project-id>/topics/<topic-id>',
      );
    }
  }

  /// The unqualified ID of this topic.
  String get id => name.split('/').last;

  /// Creates this topic on the server.
  ///
  /// The topic must not already exist on the server.
  ///
  /// A topic must exist on the server before you can publish messages to it
  /// or create subscriptions for it.
  ///
  /// Throws a [ConflictException] if the topic already exists.
  ///
  /// Returns this [Topic].
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> create() async {
    await pubsub.createTopic(name, publishSettings: publishSettings);
    return this;
  }

  /// Deletes this topic on the server.
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  ///
  /// After a topic is deleted, a new topic may be created with the same name;
  /// this is an entirely new topic with none of the old configuration or
  /// subscriptions. Existing subscriptions to this topic are not deleted, but
  /// their `topic` field is set to `_deleted-topic_`.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.DeleteTopic).
  Future<void> delete() => pubsub.deleteTopic(name);

  /// Adds a message to the topic.
  ///
  /// The message is placed into a background buffer and published in a batch
  /// according to [publishSettings] batching configuration. If publishing
  /// fails with a retryable error, the batch is retried according to
  /// [publishSettings] retry configuration.
  ///
  /// Returns the server-assigned message ID once the batch containing the
  /// message has been published.
  ///
  /// Only messages published through the same [Topic] object are batched
  /// together, so create one [Topic] per topic and reuse it rather than calling
  /// [PubSub.topic] for every message.
  ///
  /// [data] and [attributes] are copied, so changing them after this call does
  /// not affect the published message.
  ///
  /// To ensure all buffered messages are published before application shutdown,
  /// call and await [close].
  ///
  /// It is an error if called on a closed [Topic].
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  /// Throws a [ServiceException] if publishing fails (after any retries).
  ///
  /// [data] is the message content.
  /// [attributes] are optional attributes for the message.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  // TODO(sigurdm): Add publisher flow control that limits the number and size
  // of outstanding messages.
  // TODO(sigurdm): Set a per-attempt deadline on `Publish` requests, so a hung
  // request cannot keep the returned future (and [close]) pending forever.
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) {
    if (isClosed) {
      throw StateError('Cannot publish to a closed Topic.');
    }
    final completer = Completer<String>();
    // Copy the caller's data and attributes: the message is sent after this
    // method returns, and its size has already been counted towards the batch.
    final message = Message(
      data: Uint8List.fromList(data),
      attributes: attributes == null ? null : Map.unmodifiable(attributes),
    );
    _batcher.add(_PublishRequest(message, completer));
    return completer.future;
  }

  /// Closes the topic, flushing any pending messages and waiting for in-flight
  /// batches to complete.
  ///
  /// Calling and awaiting [close] during application shutdown ensures that all
  /// buffered messages are published before the process exits. Publishing
  /// errors are reported through the futures returned by [publish], not by
  /// [close].
  ///
  /// Once closed, it is an error to call [publish].
  Future<void> close() => _batcher.close();
}
