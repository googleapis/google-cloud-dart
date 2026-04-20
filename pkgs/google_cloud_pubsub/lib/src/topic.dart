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

import 'package:meta/meta.dart';

import '../google_cloud_pubsub.dart';

@internal
Topic newTopic(PubSub pubsub, String name) => Topic._(pubsub, name);

/// A [Google Cloud Pub/Sub topic](https://cloud.google.com/pubsub/docs/overview#topics).
final class Topic {
  final PubSub pubsub;
  final String name;

  Topic._(this.pubsub, this.name);

  /// Creates the given topic with the given name.
  ///
  /// Throws a [TopicAlreadyExistsException] if the topic already exists.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> create() => pubsub.createTopic(name);

  /// Deletes the topic with the given name.
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
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) =>
      pubsub.publish(name, data, attributes: attributes);
}
