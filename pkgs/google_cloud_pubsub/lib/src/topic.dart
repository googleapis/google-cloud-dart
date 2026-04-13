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

  /// Creates this topic.
  Future<Topic> create() => pubsub.createTopic(name);

  /// Deletes this topic.
  Future<void> delete() => pubsub.deleteTopic(name);

  /// Publishes a message to this topic.
  ///
  /// [data] is the message content.
  /// [attributes] are optional attributes for the message.
  Future<String> publish(List<int> data, {Map<String, String>? attributes}) =>
      pubsub.publish(name, data, attributes: attributes);
}
