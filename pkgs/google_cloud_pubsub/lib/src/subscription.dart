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
  Future<List<ReceivedMessage>> pull({int maxMessages = 1}) =>
      pubsub.pull(name, maxMessages: maxMessages);

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
  Stream<ReceivedMessage> streamingPull({int streamAckDeadlineSeconds = 10}) =>
      pubsub.streamingPull(
        name,
        streamAckDeadlineSeconds: streamAckDeadlineSeconds,
      );

  /// Acknowledges the messages associated with the `ack_ids`.
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
  Future<void> acknowledge(List<String> ackIds) =>
      pubsub.acknowledge(name, ackIds);

  /// Modifies the ack deadline for a specific message.
  ///
  /// This method is useful to indicate that more time is needed to process a
  /// message by the subscriber, or to make the message available for redelivery
  /// if the processing was interrupted. Note that this does not modify the
  /// subscription-level `ackDeadlineSeconds` used for subsequent messages.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadline(List<String> ackIds, int ackDeadlineSeconds) =>
      pubsub.modifyAckDeadline(name, ackIds, ackDeadlineSeconds);
}
