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

import 'package:googleapis_auth/auth_io.dart' as auth;
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
  final bool _isEmulator;
  grpc.PublisherClient? _publisherClient;
  grpc.SubscriberClient? _subscriberClient;
  auth.AutoRefreshingAuthClient? _authClient;

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

  PubSub._(this._projectId, this._channel, this._isEmulator);

  /// Constructs a client used to communicate with [Google Cloud Pub/Sub][].
  factory PubSub({String? projectId, String? apiEndpoint}) {
    final emulatorHost = pubsubEmulatorHost;
    return PubSub._(
      _calculateProjectId(projectId, emulatorHost),
      _calculateChannel(apiEndpoint, emulatorHost),
      emulatorHost != null,
    );
  }

  Future<CallOptions> get _callOptions async {
    if (_isEmulator) {
      return CallOptions();
    }
    _authClient ??= await auth.clientViaApplicationDefaultCredentials(
      scopes: ['https://www.googleapis.com/auth/pubsub'],
    );
    final token = _authClient!.credentials.accessToken.data;
    return CallOptions(metadata: {'authorization': 'Bearer $token'});
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

  /// Creates the given topic with the given name.
  ///
  /// Throws a [TopicAlreadyExistsException] if the topic already exists.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  Future<Topic> createTopic(String name) async {
    final projectId = await _requiredProjectId;
    final topicName = 'projects/$projectId/topics/$name';
    final topic = grpc.Topic()..name = topicName;
    try {
      await _publisher.createTopic(topic, options: await _callOptions);
      return this.topic(name);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.alreadyExists) {
        throw TopicAlreadyExistsException(name);
      }
      rethrow;
    }
  }

  /// Deletes the topic with the given name.
  ///
  /// Returns `true` if the topic was deleted, or `false` if the topic did not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.DeleteTopic).
  Future<bool> deleteTopic(String name) async {
    final projectId = await _requiredProjectId;
    final topicName = 'projects/$projectId/topics/$name';
    final request = grpc.DeleteTopicRequest()..topic = topicName;
    try {
      await _publisher.deleteTopic(request, options: await _callOptions);
      return true;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  /// Adds one or more messages to the topic.
  ///
  /// Throws a [TopicNotFoundException] if the topic does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
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

    try {
      final response = await _publisher.publish(
        request,
        options: await _callOptions,
      );
      return response.messageIds.first;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw TopicNotFoundException(topicName);
      }
      rethrow;
    }
  }

  // TODO(sigurdm): Implement missing Publisher APIs:
  // - GetTopic
  // - UpdateTopic
  // - ListTopics
  // - ListTopicSubscriptions
  // - ListTopicSnapshots
  // - DetachSubscription

  // Subscription-related methods

  /// Creates a subscription to a given topic.
  ///
  /// Throws a [SubscriptionAlreadyExistsException] if the subscription already
  /// exists.
  /// Throws a [TopicNotFoundException] if the corresponding topic doesn't
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
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

    try {
      await _subscriber.createSubscription(
        subscription,
        options: await _callOptions,
      );
      return this.subscription(name);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.alreadyExists) {
        throw SubscriptionAlreadyExistsException(name);
      }
      if (e.code == StatusCode.notFound) {
        throw TopicNotFoundException(topic);
      }
      rethrow;
    }
  }

  /// Deletes an existing subscription.
  ///
  /// All messages retained in the subscription are immediately dropped.
  ///
  /// Returns `true` if the subscription was deleted, or `false` if the
  /// subscription did not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<bool> deleteSubscription(String name) async {
    final projectId = await _requiredProjectId;
    final subscriptionName = 'projects/$projectId/subscriptions/$name';
    final request = grpc.DeleteSubscriptionRequest()
      ..subscription = subscriptionName;
    try {
      await _subscriber.deleteSubscription(
        request,
        options: await _callOptions,
      );
      return true;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        return false;
      }
      rethrow;
    }
  }

  /// Pulls messages from the server.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
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

    try {
      final response = await _subscriber.pull(
        request,
        options: await _callOptions,
      );

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
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(subscriptionName);
      }
      rethrow;
    }
  }

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
  Stream<ReceivedMessage> streamingPull(
    String subscriptionName, {
    int streamAckDeadlineSeconds = 10,
  }) async* {
    final projectId = await _requiredProjectId;
    final fullSubscriptionName =
        'projects/$projectId/subscriptions/$subscriptionName';

    final requestController = StreamController<grpc.StreamingPullRequest>()
      ..add(
        grpc.StreamingPullRequest()
          ..subscription = fullSubscriptionName
          ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
      );

    // TODO(sigurdm): Retry on broken connections.
    final responseStream = _subscriber.streamingPull(
      requestController.stream,
      options: await _callOptions,
    );

    try {
      await for (final response in responseStream) {
        for (final m in response.receivedMessages) {
          yield ReceivedMessage(
            ackId: m.ackId,
            message: Message(
              data: m.message.data,
              attributes: m.message.attributes,
              messageId: m.message.messageId,
              publishTime: m.message.publishTime.toDateTime(),
            ),
          );
        }
      }
    } on GrpcError catch (e) {
      throw StreamBrokenException(e);
    } finally {
      await requestController.close();
    }
  }

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
  Future<void> acknowledge(String subscriptionName, List<String> ackIds) async {
    final projectId = await _requiredProjectId;
    final fullSubscriptionName =
        'projects/$projectId/subscriptions/$subscriptionName';

    final request = grpc.AcknowledgeRequest()
      ..subscription = fullSubscriptionName
      ..ackIds.addAll(ackIds);

    try {
      await _subscriber.acknowledge(request, options: await _callOptions);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(subscriptionName);
      }
      rethrow;
    }
  }

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

    try {
      await _subscriber.modifyAckDeadline(request, options: await _callOptions);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(subscriptionName);
      }
      rethrow;
    }
  }

  // TODO(sigurdm): Implement missing Subscriber APIs:
  // - GetSubscription
  // - UpdateSubscription
  // - ListSubscriptions
  // - ModifyPushConfig
  // - GetSnapshot
  // - ListSnapshots
  // - CreateSnapshot
  // - UpdateSnapshot
  // - DeleteSnapshot
  // - Seek

  // TODO(sigurdm): Implement missing Schema APIs:
  // - CreateSchema
  // - GetSchema
  // - ListSchemas
  // - ListSchemaRevisions
  // - CommitSchema
  // - RollbackSchema
  // - DeleteSchemaRevision
  // - DeleteSchema
  // - ValidateSchema
  // - ValidateMessage
}
