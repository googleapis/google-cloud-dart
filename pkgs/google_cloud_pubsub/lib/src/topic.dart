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

import '../google_cloud_pubsub.dart';

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

  /// A topic with the given [topicId] in the client's project.
  ///
  /// It is an error if the constructed topic name is invalid (e.g. if [topicId]
  /// contains slashes).
  Topic.unqualified(this.pubsub, String topicId)
    : name = 'projects/${pubsub.projectId}/topics/$topicId' {
    _validateName(name);
  }

  /// A topic with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/topics/<topic-id>`.
  Topic(this.pubsub, this.name) {
    _validateName(name);
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
  /// Throws a [TopicAlreadyExistsException] if the topic already exists.
  ///
  /// Returns a [Topic] instance representing the created topic.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> create() => pubsub.createTopic(name);

  /// Deletes this topic on the server.
  ///
  /// Throws a [TopicNotFoundException] if the topic does not exist.
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
  /// Throws a [TopicNotFoundException] if the topic does not exist.
  ///
  /// [data] is the message content.
  /// [attributes] are optional attributes for the message.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  // TODO(sigurdm): Support batch publishing (publishMany) for high-throughput.
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) =>
      pubsub.publish(name, data, attributes: attributes);
}
