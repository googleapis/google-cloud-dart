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
import 'package:meta/meta.dart';
import '../google_cloud_pubsub.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'message.dart' show createReceivedMessage;
import 'pubsub_emulator_host_vm.dart';
import 'subscription.dart' show newSubscription, newSubscriptionName;
import 'topic.dart' show newTopic, newTopicName;

/// API for flexible, reliable, large-scale messaging.
///
/// See [Google Cloud Pub/Sub](https://cloud.google.com/pubsub).
final class PubSub {
  /// The project ID of this client.
  final String projectId;
  final ClientChannel _channel;
  final bool _isEmulator;
  grpc.PublisherClient? _publisherClient;
  grpc.SubscriberClient? _subscriberClient;
  final BaseAuthenticator? _authenticator;

  static String? _calculateProjectId(String? projectId, String? emulatorHost) =>
      switch ((projectId, emulatorHost)) {
        (final String projectId, _) => projectId,
        (null, _?) => projectFromEnvironment ?? 'test-project',
        (null, null) => projectFromEnvironment,
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
      final uri = host.startsWith('http://') || host.startsWith('https://')
          ? Uri.parse(host)
          : Uri.http(host);
      return ClientChannel(
        uri.host,
        port: uri.hasPort ? uri.port : 8085,
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

  PubSub._(
    this.projectId,
    this._channel,
    this._isEmulator,
    this._authenticator, {
    grpc.SubscriberClient? subscriberClient,
    grpc.PublisherClient? publisherClient,
  }) : _subscriberClient = subscriberClient,
       _publisherClient = publisherClient;

  @visibleForTesting
  factory PubSub.testing({
    required String projectId,
    required ClientChannel channel,
    grpc.SubscriberClient? subscriberClient,
    grpc.PublisherClient? publisherClient,
  }) => PubSub._(
    projectId,
    channel,
    false,
    null,
    subscriberClient: subscriberClient,
    publisherClient: publisherClient,
  );

  /// Turns the protobuf-generated [grpc.ReceivedMessage] into a
  /// [ReceivedMessage].
  static ReceivedMessage _mapReceivedMessage(
    grpc.ReceivedMessage m, {
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int seconds)?
    modifyDeadlineHandler,
  }) => createReceivedMessage(
    ackId: m.ackId,
    messageId: m.message.messageId,
    publishTime: m.message.publishTime.toDateTime(),
    message: Message(data: m.message.data, attributes: m.message.attributes),
    ackHandler: ackHandler,
    modifyDeadlineHandler: modifyDeadlineHandler,
  );

  /// Constructs a client used to communicate with [Google Cloud Pub/Sub][].
  ///
  /// The [projectId] is the Google Cloud Project ID. If not provided, it will
  /// be inferred from the environment.
  ///
  /// Project ID inference strategies:
  /// 1. Reads the `GOOGLE_CLOUD_PROJECT` environment variable.
  /// 2. If the `PUBSUB_EMULATOR_HOST` environment variable is set (indicating
  ///    the emulator is active), it defaults to `'test-project'`.
  ///
  /// Throws if [projectId] is not provided and cannot be
  /// inferred from the environment.
  ///
  /// For authentication, an [authenticator] can be supplied to obtain
  /// and refresh access credentials for authenticating gRPC requests.
  ///
  /// If no [authenticator] is provided, requests are made without
  /// authentication.
  factory PubSub({
    String? projectId,
    String? apiEndpoint,
    BaseAuthenticator? authenticator,
  }) {
    final emulatorHost = pubsubEmulatorHost;
    final resolvedProjectId = _calculateProjectId(projectId, emulatorHost);
    if (resolvedProjectId == null) {
      throw ArgumentError(
        'A project ID is required, but none was provided or could be '
        'inferred from the environment.',
      );
    }
    return PubSub._(
      resolvedProjectId,
      _calculateChannel(apiEndpoint, emulatorHost),
      emulatorHost != null,
      authenticator,
    );
  }

  Future<CallOptions> get _callOptions async {
    if (_isEmulator) {
      return CallOptions();
    }
    final authenticator = _authenticator;
    if (authenticator == null) {
      return CallOptions();
    }
    return authenticator.toCallOptions;
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

  /// A [Topic] object with the given [unqualifiedName] in the client's project.
  Topic topic(String unqualifiedName) => newTopic(this, unqualifiedName);

  /// A [Topic] object with the given [name].
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  /// Useful for cross-project access.
  Topic topicName(String name) => newTopicName(this, name);

  /// A [Subscription] object with the given [unqualifiedName] in the client's
  /// project.
  Subscription subscription(String unqualifiedName) =>
      newSubscription(this, unqualifiedName);

  /// A [Subscription] object with the given [name].
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  /// Useful for cross-project access.
  Subscription subscriptionName(String name) => newSubscriptionName(this, name);

  /// Creates the given topic with the given [name].
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [TopicAlreadyExistsException] if the topic already exists.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  // TODO(sigurdm): Support configuring topic options (labels,
  // messageStoragePolicy, kmsKeyName, schemaSettings,
  // messageRetentionDuration).
  Future<Topic> createTopic(String name) async {
    final topic = grpc.Topic()..name = name;
    try {
      await _publisher.createTopic(topic, options: await _callOptions);
      return topicName(name);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.alreadyExists) {
        throw TopicAlreadyExistsException(name);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Deletes the topic with the given [name].
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Returns `true` if the topic was deleted, or `false` if the topic did not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.DeleteTopic).
  Future<bool> deleteTopic(String name) async {
    final request = grpc.DeleteTopicRequest()..topic = name;
    try {
      await _publisher.deleteTopic(request, options: await _callOptions);
      return true;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        return false;
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Adds one or more messages to the topic.
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [TopicNotFoundException] if the topic does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  // TODO(sigurdm): Support batch publishing (publishMany) for high-throughput.
  Future<String> publish(
    String name,
    List<int> data, {
    Map<String, String>? attributes,
  }) async {
    final message = grpc.PubsubMessage()..data = data;
    if (attributes != null) {
      message.attributes.addAll(attributes);
    }

    final request = grpc.PublishRequest()
      ..topic = name
      ..messages.add(message);

    try {
      final response = await _publisher.publish(
        request,
        options: await _callOptions,
      );
      return response.messageIds.first;
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw TopicNotFoundException(name);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
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
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [SubscriptionAlreadyExistsException] if the subscription already
  /// exists.
  /// Throws a [TopicNotFoundException] if the corresponding topic doesn't
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  // TODO(sigurdm): Support configuring subscription options
  // (ackDeadlineSeconds, pushConfig, deadLetterPolicy, retryPolicy,
  // retainAckedMessages, enableExactlyOnceDelivery).
  Future<Subscription> createSubscription(
    String name, {
    required String topic,
  }) async {
    final subscription = grpc.Subscription()
      ..name = name
      ..topic = topic;

    try {
      await _subscriber.createSubscription(
        subscription,
        options: await _callOptions,
      );
      return subscriptionName(name);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.alreadyExists) {
        throw SubscriptionAlreadyExistsException(name);
      }
      if (e.code == StatusCode.notFound) {
        throw TopicNotFoundException(topic);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Deletes an existing subscription.
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// All messages retained in the subscription are immediately dropped.
  ///
  /// Returns `true` if the subscription was deleted, or `false` if the
  /// subscription did not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<bool> deleteSubscription(String name) async {
    final request = grpc.DeleteSubscriptionRequest()..subscription = name;
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
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Pulls messages from the server.
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull(String name, {int maxMessages = 1}) async {
    final request = grpc.PullRequest()
      ..subscription = name
      ..maxMessages = maxMessages;

    try {
      final response = await _subscriber.pull(
        request,
        options: await _callOptions,
      );

      return response.receivedMessages
          .map(
            (m) => _mapReceivedMessage(
              m,
              ackHandler: (ackIds) => acknowledge(name, ackIds),
              modifyDeadlineHandler: (ackIds, seconds) =>
                  modifyAckDeadline(name, ackIds, seconds),
            ),
          )
          .toList();
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(name);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Establishes a stream with the server, which sends messages down to the
  /// client.
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
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
    String name, {
    int streamAckDeadlineSeconds = 10,
  }) async* {
    final requestController = StreamController<grpc.StreamingPullRequest>();
    try {
      final options = await _callOptions;
      requestController.add(
        grpc.StreamingPullRequest()
          ..subscription = name
          ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
      );
      // TODO(sigurdm): Retry on broken connections.
      final responseStream = _subscriber.streamingPull(
        requestController.stream,
        options: options,
      );
      await for (final response in responseStream) {
        for (final m in response.receivedMessages) {
          yield _mapReceivedMessage(
            m,
            // NOTE: Using unary RPCs for acks and deadline modifications
            //
            // TODO(sigurdm): implement ack/deadline pipelining.
            ackHandler: (ackIds) => acknowledge(name, ackIds),
            modifyDeadlineHandler: (ackIds, seconds) =>
                modifyAckDeadline(name, ackIds, seconds),
          );
        }
      }
    } on GrpcError catch (e) {
      throw StreamBrokenException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    } finally {
      await requestController.close();
    }
  }

  /// Acknowledges the messages associated with the `ack_ids`.
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
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
  Future<void> acknowledge(String name, List<String> ackIds) async {
    final request = grpc.AcknowledgeRequest()
      ..subscription = name
      ..ackIds.addAll(ackIds);

    try {
      await _subscriber.acknowledge(request, options: await _callOptions);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(name);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
    }
  }

  /// Modifies the ack deadline for a list of specific messages.
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// This method is useful to indicate that more time is needed to process a
  /// message by the subscriber, or to make the message available for redelivery
  /// if the processing was interrupted. Note that this does not modify the
  /// subscription-level `ackDeadlineSeconds` used for subsequent messages.
  ///
  /// Modifying the ack deadline for messages whose deadline has already expired
  /// may succeed, but those messages may have already been redelivered or
  /// made available for redelivery.
  ///
  /// Throws a [SubscriptionNotFoundException] if the subscription does not
  /// exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadline(
    String name,
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) async {
    final request = grpc.ModifyAckDeadlineRequest()
      ..subscription = name
      ..ackIds.addAll(ackIds)
      ..ackDeadlineSeconds = ackDeadlineSeconds;

    try {
      await _subscriber.modifyAckDeadline(request, options: await _callOptions);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        throw SubscriptionNotFoundException(name);
      }
      throw PubSubOperationException(
        e.code,
        e.message ?? 'Unknown error',
        e.trailers ?? const {},
      );
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
