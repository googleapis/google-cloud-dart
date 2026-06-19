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

/// Settings for publishing messages.
class PublishSettings {
  final BatchingSettings batching;
  final RetrySettings retry;

  const PublishSettings({
    this.batching = const BatchingSettings(),
    this.retry = const RetrySettings(),
  });
}

class _PublishRequest {
  final Message message;
  final Completer<String> completer;

  _PublishRequest(this.message, this.completer);
}

@internal
Topic newTopic(PubSub pubsub, String topicId) =>
    Topic.unqualified(pubsub, topicId);

@internal
Topic newTopicName(PubSub pubsub, String name) => Topic(pubsub, name);

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

  /// A topic with the given [topicId] in the client's project.
  Topic.unqualified(
    this.pubsub,
    String topicId, {
    this.publishSettings = const PublishSettings(),
  }) : name = 'projects/${pubsub.projectId}/topics/$topicId' {
    _validateName(name);
    _initBatcher();
  }

  /// A topic with the given [name].
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  /// Useful for cross-project access.
  Topic(
    this.pubsub,
    this.name, {
    this.publishSettings = const PublishSettings(),
  }) {
    _validateName(name);
    _initBatcher();
  }

  void _initBatcher() {
    _batcher = Batcher<_PublishRequest>(
      settings: publishSettings.batching,
      itemSize: (req) => req.message.data.length, // approximate size
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
        batch[i].completer.complete(messageIds[i]);
      }
    } catch (e, st) {
      for (final item in batch) {
        item.completer.completeError(e, st);
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

  /// The ID of this topic.
  String get topicId => name.split('/').last;

  /// Creates the given topic.
  ///
  /// Throws a [TopicAlreadyExistsException] if the topic already exists.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> create() => pubsub.createTopic(name);

  /// Deletes the topic.
  ///
  /// Returns `true` if the topic was deleted, or `false` if the topic did not
  /// exist.
  ///
  /// After a topic is deleted, a new topic may be created with the same name;
  /// this is an entirely new topic with none of the old configuration or
  /// subscriptions. Existing subscriptions to this topic are not deleted, but
  /// their `topic` field is set to `_deleted-topic_`.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.DeleteTopic).
  Future<bool> delete() => pubsub.deleteTopic(name);

  /// Adds one or more messages to the topic.
  ///
  /// Throws a [TopicNotFoundException] if the topic does not exist.
  ///
  /// [data] is the message content.
  /// [attributes] are optional attributes for the message.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) {
    final completer = Completer<String>();
    _batcher.add(
      _PublishRequest(Message(data: data, attributes: attributes), completer),
    );
    return completer.future;
  }

  /// Closes the topic, flushing any pending messages.
  void close() {
    _batcher.close();
  }
}
