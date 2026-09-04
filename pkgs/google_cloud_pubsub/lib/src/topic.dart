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
import 'dart:convert';

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'retry.dart';

/// Settings for background batching and retrying of published messages.
final class PublishSettings {
  /// Settings controlling how requests are accumulated and flushed.
  final BatchingSettings batching;

  /// Settings controlling retries when flushing a batch over a unary RPC.
  final RetrySettings retry;

  PublishSettings({BatchingSettings? batching, RetrySettings? retry})
    : batching = batching ?? BatchingSettings(),
      retry = retry ?? RetrySettings();
}

final class _PublishRequest {
  final Message message;
  final Completer<String> completer;

  _PublishRequest(this.message, this.completer);
}

/// A [Google Cloud Pub/Sub topic](https://cloud.google.com/pubsub/docs/overview#topics).
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
  bool _isClosed = false;
  Future<void>? _closeFuture;

  /// A topic with the given [topicId] in the client's project.
  ///
  /// It is an error if the constructed topic name is invalid (e.g. if [topicId]
  /// contains slashes).
  Topic.unqualified(
    this.pubsub,
    String topicId, {
    PublishSettings? publishSettings,
  }) : publishSettings = publishSettings ?? PublishSettings(),
       name = 'projects/${pubsub.projectId}/topics/$topicId' {
    _validateName(name);
    _initBatcher();
  }

  /// A topic with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/topics/<topic-id>`.
  Topic(this.pubsub, this.name, {PublishSettings? publishSettings})
    : publishSettings = publishSettings ?? PublishSettings() {
    _validateName(name);
    _initBatcher();
  }

  void _initBatcher() {
    _batcher = Batcher<_PublishRequest>(
      settings: publishSettings.batching,
      itemSize: (req) {
        var size = req.message.data.length;
        for (final entry in req.message.attributes.entries) {
          size +=
              utf8.encode(entry.key).length + utf8.encode(entry.value).length;
        }
        return size;
      },
      onBatch: _onBatch,
    );
  }

  Future<void> _onBatch(List<_PublishRequest> batch) async {
    try {
      final messages = batch.map((e) => e.message).toList();
      final messageIds = await runWithRetry(
        () => pubsub.publishMessages(name, messages),
        settings: publishSettings.retry,
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
              StateError(
                'Server returned fewer message IDs (${messageIds.length}) '
                'than published messages (${batch.length}).',
              ),
            );
          }
        }
      }
    } catch (e, st) {
      for (final item in batch) {
        if (!item.completer.isCompleted) {
          item.completer.completeError(e, st);
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
  /// Returns a [Topic] instance representing the created topic.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> create() => pubsub.createTopic(name);

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

  /// Adds one or more messages to the topic.
  ///
  /// Messages are placed into a background buffer and published in batches
  /// according to the [publishSettings] batching configuration. If transient
  /// network errors occur during publishing, the batch is automatically
  /// retried according to [publishSettings] retry configuration.
  ///
  /// It is an error if called on a closed [Topic].
  /// Throws a [NotFoundException] if the topic does not exist.
  /// Throws a [ServiceException] if publishing fails after retries.
  ///
  /// [data] is the message content.
  /// [attributes] are optional attributes for the message.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) {
    if (_isClosed) {
      throw StateError('Cannot publish to a closed Topic.');
    }
    final completer = Completer<String>();
    _batcher.add(
      _PublishRequest(Message(data: data, attributes: attributes), completer),
    );
    return completer.future;
  }

  /// Closes the topic, flushing any pending messages and waiting for in-flight
  /// batches to complete.
  Future<void> close() {
    _isClosed = true;
    return _closeFuture ??= _batcher.close();
  }
}
