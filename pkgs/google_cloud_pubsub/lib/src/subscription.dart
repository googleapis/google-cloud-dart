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
Subscription newSubscription(PubSub pubsub, String name) =>
    Subscription._(pubsub, name);

/// A [Google Cloud Pub/Sub subscription](https://cloud.google.com/pubsub/docs/overview#subscriptions).
final class Subscription {
  final PubSub pubsub;
  final String name;

  Subscription._(this.pubsub, this.name);

  /// Creates this subscription.
  Future<Subscription> create({required String topic}) =>
      pubsub.createSubscription(name, topic: topic);

  /// Deletes this subscription.
  Future<void> delete() => pubsub.deleteSubscription(name);

  /// Pulls messages from this subscription.
  Future<List<ReceivedMessage>> pull({int maxMessages = 1}) =>
      pubsub.pull(name, maxMessages: maxMessages);

  /// Acknowledges messages.
  Future<void> acknowledge(List<String> ackIds) =>
      pubsub.acknowledge(name, ackIds);

  /// Modifies the ack deadline for messages.
  Future<void> modifyAckDeadline(List<String> ackIds, int ackDeadlineSeconds) =>
      pubsub.modifyAckDeadline(name, ackIds, ackDeadlineSeconds);
}
