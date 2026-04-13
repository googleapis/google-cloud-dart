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

import 'package:grpc/grpc.dart';
import '../google_cloud_pubsub.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'pubsub_emulator_host_web.dart'
    if (dart.library.io) 'pubsub_emulator_host_vm.dart';
import 'subscription.dart' show newSubscription;
import 'topic.dart' show newTopic;

/// API for flexible, reliable, large-scale messaging.
///
/// See [Google Cloud Pub/Sub](https://cloud.google.com/pubsub).
final class PubSub {
  final FutureOr<String> _projectId;
  final ClientChannel _channel;
  grpc.PublisherClient? _publisherClient;
  grpc.SubscriberClient? _subscriberClient;

  Future<String> get _requiredProjectId async {
    final id = await _projectId;
    if (id == noProject) {
      throw StateError('a project ID is required');
    }
    return id;
  }

  static const String noProject = '<none>';

  static FutureOr<String> _calculateProjectId(
    String? projectId,
    String? emulatorHost,
  ) => switch ((projectId, emulatorHost)) {
    (final String projectId, _) => projectId,
    (null, _?) => '<none>',
    (null, null) => projectFromEnvironment ?? 'unknown-project',
  };

  static ClientChannel _calculateChannel(
    String? apiEndpoint,
    String? emulatorHost,
  ) {
    if (apiEndpoint != null) {
      return ClientChannel(
        apiEndpoint,
        options: const ChannelOptions(credentials: ChannelCredentials.secure()),
      );
    }

    if (emulatorHost case String host) {
      var cleanHost = host;
      var port = 8085;
      if (host.contains(':')) {
        final parts = host.split(':');
        cleanHost = parts[0];
        port = int.parse(parts[1]);
      }
      return ClientChannel(
        cleanHost,
        port: port,
        options: const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        ),
      );
    }

    return ClientChannel(
      'pubsub.googleapis.com',
      options: const ChannelOptions(credentials: ChannelCredentials.secure()),
    );
  }

  PubSub._(this._projectId, this._channel);

  /// Constructs a client used to communicate with [Google Cloud Pub/Sub][].
  factory PubSub({String? projectId, String? apiEndpoint}) {
    final emulatorHost = pubsubEmulatorHost;
    return PubSub._(
      _calculateProjectId(projectId, emulatorHost),
      _calculateChannel(apiEndpoint, emulatorHost),
    );
  }

  grpc.PublisherClient get _publisher =>
      _publisherClient ??= grpc.PublisherClient(_channel);
  grpc.SubscriberClient get _subscriber =>
      _subscriberClient ??= grpc.SubscriberClient(_channel);

  /// Closes the client and cleans up any resources associated with it.
  Future<void> close() async {
    await _channel.shutdown();
  }

  // Topic-related methods

  /// A [Topic] object with the given [name].
  Topic topic(String name) => newTopic(this, name);

  /// A [Subscription] object with the given [name].
  Subscription subscription(String name) => newSubscription(this, name);

  /// Creates a new topic.
  Future<Topic> createTopic(String name) async {
    final projectId = await _requiredProjectId;
    final topicName = 'projects/$projectId/topics/$name';
    final topic = grpc.Topic()..name = topicName;
    await _publisher.createTopic(topic);
    return this.topic(name);
  }

  /// Deletes a topic.
  Future<void> deleteTopic(String name) async {
    final projectId = await _requiredProjectId;
    final topicName = 'projects/$projectId/topics/$name';
    final request = grpc.DeleteTopicRequest()..topic = topicName;
    await _publisher.deleteTopic(request);
  }

  /// Publishes a message to a topic.
  Future<String> publish(
    String topicName,
    List<int> data, {
    Map<String, String>? attributes,
  }) async {
    final projectId = await _requiredProjectId;
    final fullTopicName = 'projects/$projectId/topics/$topicName';

    final message = grpc.PubsubMessage()..data = data;
    if (attributes != null) {
      message.attributes.addAll(attributes);
    }

    final request = grpc.PublishRequest()
      ..topic = fullTopicName
      ..messages.add(message);

    final response = await _publisher.publish(request);
    return response.messageIds.first;
  }

  // Subscription-related methods

  /// Creates a new subscription.
  Future<Subscription> createSubscription(
    String name, {
    required String topic,
  }) async {
    final projectId = await _requiredProjectId;
    final subscriptionName = 'projects/$projectId/subscriptions/$name';
    final topicName = 'projects/$projectId/topics/$topic';

    final subscription = grpc.Subscription()
      ..name = subscriptionName
      ..topic = topicName;

    await _subscriber.createSubscription(subscription);
    return this.subscription(name);
  }

  /// Deletes a subscription.
  Future<void> deleteSubscription(String name) async {
    final projectId = await _requiredProjectId;
    final subscriptionName = 'projects/$projectId/subscriptions/$name';
    final request = grpc.DeleteSubscriptionRequest()
      ..subscription = subscriptionName;
    await _subscriber.deleteSubscription(request);
  }

  /// Pulls messages from a subscription.
  Future<List<ReceivedMessage>> pull(
    String subscriptionName, {
    int maxMessages = 1,
  }) async {
    final projectId = await _requiredProjectId;
    final fullSubscriptionName =
        'projects/$projectId/subscriptions/$subscriptionName';

    final request = grpc.PullRequest()
      ..subscription = fullSubscriptionName
      ..maxMessages = maxMessages;

    final response = await _subscriber.pull(request);

    return response.receivedMessages
        .map(
          (m) => ReceivedMessage(
            ackId: m.ackId,
            message: Message(
              data: m.message.data,
              attributes: m.message.attributes,
              messageId: m.message.messageId,
              publishTime: m.message.publishTime.toDateTime(),
            ),
          ),
        )
        .toList();
  }

  /// Acknowledges messages.
  Future<void> acknowledge(String subscriptionName, List<String> ackIds) async {
    final projectId = await _requiredProjectId;
    final fullSubscriptionName =
        'projects/$projectId/subscriptions/$subscriptionName';

    final request = grpc.AcknowledgeRequest()
      ..subscription = fullSubscriptionName
      ..ackIds.addAll(ackIds);

    await _subscriber.acknowledge(request);
  }

  /// Modifies the ack deadline for messages.
  Future<void> modifyAckDeadline(
    String subscriptionName,
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) async {
    final projectId = await _requiredProjectId;
    final fullSubscriptionName =
        'projects/$projectId/subscriptions/$subscriptionName';

    final request = grpc.ModifyAckDeadlineRequest()
      ..subscription = fullSubscriptionName
      ..ackIds.addAll(ackIds)
      ..ackDeadlineSeconds = ackDeadlineSeconds;

    await _subscriber.modifyAckDeadline(request);
  }
}
