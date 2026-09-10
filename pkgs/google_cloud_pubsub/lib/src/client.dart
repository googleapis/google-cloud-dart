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

import 'package:google_cloud_rpc/rpc.dart';
import 'package:grpc/grpc.dart';
import 'package:meta/meta.dart';
import '../google_cloud_pubsub.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'pubsub_emulator_host_vm.dart';

const _pubsubScopes = ['https://www.googleapis.com/auth/pubsub'];

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
  final FutureOr<BaseAuthenticator>? _authenticator;

  static String? _calculateProjectId(
    String? projectId,
    Uri? emulatorHost,
  ) => switch ((projectId, emulatorHost)) {
    (final String projectId, _) => projectId,
    // When the emulator is active (emulatorHost is not null), we fall back
    // to 'test-project' if GOOGLE_CLOUD_PROJECT is not set in the environment.
    (null, _?) => projectFromEnvironment ?? 'test-project',
    (null, null) => projectFromEnvironment,
  };

  static ClientChannel _calculateChannel(
    String? apiEndpoint,
    Uri? emulatorHost,
  ) {
    if (apiEndpoint != null) {
      return ClientChannel(
        apiEndpoint,
        options: const ChannelOptions(credentials: ChannelCredentials.secure()),
      );
    }

    if (emulatorHost case final uri?) {
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
    FutureOr<BaseAuthenticator>? authenticator,
  }) => PubSub._(
    projectId,
    channel,
    false,
    authenticator,
    subscriberClient: subscriberClient,
    publisherClient: publisherClient,
  );

  /// Turns the protobuf-generated [grpc.ReceivedMessage] into a
  /// [ReceivedMessage].
  static ReceivedMessage _mapReceivedMessage(
    grpc.ReceivedMessage receivedMessage, {
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int ackDeadlineSeconds)?
    modifyDeadlineHandler,
  }) => ReceivedMessage(
    ackId: receivedMessage.ackId,
    messageId: receivedMessage.message.messageId,
    publishTime: receivedMessage.message.publishTime.toDateTime(),
    deliveryAttempt: receivedMessage.deliveryAttempt,
    ackHandler: ackHandler,
    modifyDeadlineHandler: modifyDeadlineHandler,
    message: Message(
      data: receivedMessage.message.data,
      attributes: receivedMessage.message.attributes,
    ),
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
  /// It is an error if [projectId] is not provided and cannot be
  /// inferred from the environment.
  ///
  /// For authentication, an explicit [authenticator] can be supplied to obtain
  /// and refresh access credentials for authenticating gRPC requests.
  ///
  /// If no [authenticator] is provided:
  /// - When running against the Pub/Sub emulator, requests are made without
  ///   authentication.
  /// - Otherwise, Application Default Credentials (ADC) are used automatically.
  factory PubSub({
    String? projectId,
    String? apiEndpoint,
    BaseAuthenticator? authenticator,
  }) {
    final emulatorHost = pubSubEmulatorHost;
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
      authenticator ??
          (emulatorHost != null
              ? null
              : applicationDefaultCredentialsAuthenticator(_pubsubScopes)),
    );
  }

  Future<CallOptions> get _callOptions async {
    if (_isEmulator) return CallOptions();
    final authenticator = await _authenticator;
    return authenticator?.toCallOptions ?? CallOptions();
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
  Topic topic(String unqualifiedName, {PublishSettings? publishSettings}) =>
      Topic.unqualified(
        this,
        unqualifiedName,
        publishSettings: publishSettings,
      );

  /// A [Topic] object with the given [name].
  ///
  /// The [name] must be in the format `projects/<project-id>/topics/<topic-id>`.
  /// Useful for cross-project access.
  Topic topicName(String name, {PublishSettings? publishSettings}) =>
      Topic(this, name, publishSettings: publishSettings);

  /// A [Subscription] object with the given [unqualifiedName] in the client's
  /// project.
  Subscription subscription(
    String unqualifiedName, {
    AckSettings? ackSettings,
  }) =>
      Subscription.unqualified(this, unqualifiedName, ackSettings: ackSettings);

  /// A [Subscription] object with the given [name].
  ///
  /// The [name] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  /// Useful for cross-project access.
  Subscription subscriptionName(String name, {AckSettings? ackSettings}) =>
      Subscription(this, name, ackSettings: ackSettings);

  /// Creates the given topic with the given [topic].
  ///
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [ConflictException] if the topic already exists.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.CreateTopic).
  // TODO(sigurdm): Support configuring topic options (labels,
  // messageStoragePolicy, kmsKeyName, schemaSettings,
  // messageRetentionDuration).
  Future<Topic> createTopic(
    String topic, {
    PublishSettings? publishSettings,
  }) async {
    final topicProto = grpc.Topic()..name = topic;
    try {
      await _publisher.createTopic(topicProto, options: await _callOptions);
      return topicName(topic, publishSettings: publishSettings);
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Deletes the topic with the given [topic].
  ///
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.DeleteTopic).
  Future<void> deleteTopic(String topic) async {
    final request = grpc.DeleteTopicRequest()..topic = topic;
    try {
      await _publisher.deleteTopic(request, options: await _callOptions);
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Adds a message to the topic.
  ///
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  ///
  /// Throws an [InternalServerErrorException] if the server returns no message
  /// ID.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  Future<String> publish(
    String topic,
    List<int> data, {
    Map<String, String>? attributes,
  }) async {
    final messageIds = await publishMessages(topic, [
      Message(data: data, attributes: attributes),
    ]);
    if (messageIds.isEmpty) {
      throw InternalServerErrorException(
        'Server returned no message ID for published message.',
      );
    }
    return messageIds.first;
  }

  /// Adds multiple messages to the topic in a single RPC.
  ///
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Returns a list of server-assigned message IDs matching the order of the
  /// provided [messages].
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  Future<List<String>> publishMessages(
    String topic,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) return <String>[];
    final request = grpc.PublishRequest()..topic = topic;

    for (final message in messages) {
      final pubsubMessage = grpc.PubsubMessage()..data = message.data;
      if (message.attributes.isNotEmpty) {
        pubsubMessage.attributes.addAll(message.attributes);
      }
      request.messages.add(pubsubMessage);
    }

    try {
      final response = await _publisher.publish(
        request,
        options: await _callOptions,
      );
      return response.messageIds;
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
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
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// Throws a [ConflictException] if the subscription already exists.
  /// Throws a [NotFoundException] if the corresponding topic doesn't exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  // TODO(sigurdm): Support configuring subscription options
  // (ackDeadlineSeconds, pushConfig, deadLetterPolicy, retryPolicy,
  // retainAckedMessages, enableExactlyOnceDelivery).
  Future<Subscription> createSubscription(
    String subscription, {
    required String topic,
    AckSettings? ackSettings,
  }) async {
    final subscriptionProto = grpc.Subscription()
      ..name = subscription
      ..topic = topic;

    try {
      await _subscriber.createSubscription(
        subscriptionProto,
        options: await _callOptions,
      );
      return subscriptionName(subscription, ackSettings: ackSettings);
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Deletes an existing subscription.
  ///
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<void> deleteSubscription(String subscription) async {
    final request = grpc.DeleteSubscriptionRequest()
      ..subscription = subscription;
    try {
      await _subscriber.deleteSubscription(
        request,
        options: await _callOptions,
      );
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Pulls messages from the server.
  ///
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// It is an error if [maxMessages] is not greater than 0.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull(
    String subscription, {
    int maxMessages = 1,
  }) async {
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than zero',
      );
    }
    final request = grpc.PullRequest()
      ..subscription = subscription
      ..maxMessages = maxMessages;

    try {
      final response = await _subscriber.pull(
        request,
        options: await _callOptions,
      );

      return response.receivedMessages
          .map(
            (receivedMessage) => _mapReceivedMessage(
              receivedMessage,
              ackHandler: (ackIds) => acknowledge(subscription, ackIds),
              modifyDeadlineHandler: (ackIds, ackDeadlineSeconds) =>
                  modifyAckDeadline(subscription, ackIds, ackDeadlineSeconds),
            ),
          )
          .toList();
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Low-level streaming pull over an explicit [requestStream].
  ///
  /// Used internally by [streamingPull] and [Subscription.streamingPull].
  @internal
  Stream<ReceivedMessage> streamingPullWithStream(
    Stream<grpc.StreamingPullRequest> requestStream, {
    void Function()? onConnected,
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int ackDeadlineSeconds)?
    modifyDeadlineHandler,
  }) {
    late StreamController<ReceivedMessage> controller;
    StreamSubscription<grpc.StreamingPullResponse>? streamSubscription;
    var isPaused = false;
    var isCancelled = false;
    controller = StreamController<ReceivedMessage>(
      onListen: () async {
        try {
          final options = await _callOptions;
          if (isCancelled) {
            unawaited(controller.close());
            return;
          }
          final responseStream = _subscriber.streamingPull(
            requestStream,
            options: options,
          );
          // Any RPC or connection errors are forwarded to the stream listener
          // below. Suppress errors on this unawaited headers future to avoid
          // uncaught asynchronous errors in the zone.
          unawaited(
            responseStream.headers
                .then((_) {
                  if (!isCancelled) {
                    onConnected?.call();
                  }
                })
                .catchError((_) {}),
          );
          streamSubscription = responseStream.listen(
            (response) {
              for (final receivedMessage in response.receivedMessages) {
                controller.add(
                  _mapReceivedMessage(
                    receivedMessage,
                    ackHandler: ackHandler,
                    modifyDeadlineHandler: modifyDeadlineHandler,
                  ),
                );
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (error is GrpcError) {
                controller.addError(_mapGrpcError(error), stackTrace);
              } else {
                controller.addError(error, stackTrace);
              }
              unawaited(controller.close());
            },
            onDone: () {
              unawaited(controller.close());
            },
            cancelOnError: true,
          );
          if (isPaused) {
            streamSubscription?.pause();
          }
        } catch (error, stackTrace) {
          if (!isCancelled && !controller.isClosed) {
            if (error is GrpcError) {
              controller.addError(_mapGrpcError(error), stackTrace);
            } else {
              controller.addError(error, stackTrace);
            }
            unawaited(controller.close());
          }
        }
      },
      onPause: () {
        isPaused = true;
        streamSubscription?.pause();
      },
      onResume: () {
        isPaused = false;
        streamSubscription?.resume();
      },
      onCancel: () {
        isCancelled = true;
        return streamSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Establishes a stream with the server, which sends messages down to the
  /// client.
  ///
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// The client streams acknowledgments and ack deadline modifications
  /// back to the server. If an error occurs (including when the server closes
  /// the stream with status `UNAVAILABLE` to reassign resources), the stream
  /// will emit a [ServiceException]. In this case, the caller should
  /// re-establish the stream. Flow control can be achieved by configuring the
  /// underlying RPC channel.
  ///
  /// Any errors (such as a [ServiceException] if the stream is broken by
  /// the server or network) are emitted asynchronously on the returned
  /// stream rather than thrown synchronously.
  ///
  /// It is an error if [subscription] is empty.
  /// It is an error if [streamAckDeadlineSeconds] is not between 10 and 600
  /// seconds.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.StreamingPull).
  Stream<ReceivedMessage> streamingPull(
    String subscription, {
    int streamAckDeadlineSeconds = 10,
  }) {
    if (subscription.isEmpty) {
      throw ArgumentError.value(
        subscription,
        'subscription',
        'Must not be empty',
      );
    }
    if (streamAckDeadlineSeconds < 10 || streamAckDeadlineSeconds > 600) {
      throw ArgumentError.value(
        streamAckDeadlineSeconds,
        'streamAckDeadlineSeconds',
        'Must be between 10 and 600 seconds',
      );
    }
    return _streamingPull(
      subscription,
      streamAckDeadlineSeconds: streamAckDeadlineSeconds,
    );
  }

  Stream<ReceivedMessage> _streamingPull(
    String subscription, {
    required int streamAckDeadlineSeconds,
  }) async* {
    final requestController = StreamController<grpc.StreamingPullRequest>();
    try {
      requestController.add(
        grpc.StreamingPullRequest()
          ..subscription = subscription
          ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
      );
      yield* streamingPullWithStream(
        requestController.stream,
        ackHandler: (ackIds) async {
          if (ackIds.isEmpty) return;
          if (!requestController.isClosed && requestController.hasListener) {
            requestController.add(
              grpc.StreamingPullRequest()..ackIds.addAll(ackIds),
            );
            return;
          }
          await acknowledge(subscription, ackIds);
        },
        modifyDeadlineHandler: (ackIds, ackDeadlineSeconds) async {
          if (ackDeadlineSeconds < 0) {
            throw ArgumentError.value(
              ackDeadlineSeconds,
              'ackDeadlineSeconds',
              'Must be non-negative',
            );
          }
          if (ackIds.isEmpty) return;
          if (!requestController.isClosed && requestController.hasListener) {
            requestController.add(
              grpc.StreamingPullRequest()
                ..modifyDeadlineAckIds.addAll(ackIds)
                ..modifyDeadlineSeconds.addAll(
                  List.filled(ackIds.length, ackDeadlineSeconds),
                ),
            );
            return;
          }
          await modifyAckDeadline(subscription, ackIds, ackDeadlineSeconds);
        },
      );
    } finally {
      if (!requestController.isClosed) {
        if (!requestController.hasListener) {
          unawaited(requestController.stream.drain<void>().catchError((_) {}));
        }
        unawaited(requestController.close());
      }
    }
  }

  /// Acknowledges the messages associated with the [ackIds].
  ///
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// The Pub/Sub system can remove the relevant messages from the subscription.
  ///
  /// Acknowledging a message whose ack deadline has expired may succeed,
  /// but such a message may be redelivered later. Acknowledging a message more
  /// than once will not result in an error.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledge(String subscription, List<String> ackIds) async {
    if (ackIds.isEmpty) return;
    final request = grpc.AcknowledgeRequest()
      ..subscription = subscription
      ..ackIds.addAll(ackIds);

    try {
      await _subscriber.acknowledge(request, options: await _callOptions);
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
    }
  }

  /// Modifies the ack deadline for a list of specific messages.
  ///
  /// The [subscription] must be in the format
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
  /// It is an error if [ackDeadlineSeconds] is negative.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadline(
    String subscription,
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) async {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    if (ackIds.isEmpty) return;
    final request = grpc.ModifyAckDeadlineRequest()
      ..subscription = subscription
      ..ackIds.addAll(ackIds)
      ..ackDeadlineSeconds = ackDeadlineSeconds;

    try {
      await _subscriber.modifyAckDeadline(request, options: await _callOptions);
    } on GrpcError catch (error) {
      throw _mapGrpcError(error);
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
  Exception _mapGrpcError(GrpcError error) {
    final message = error.message ?? 'Unknown gRPC error';
    return switch (error.code) {
      StatusCode.invalidArgument => BadRequestException(message),
      StatusCode.unauthenticated => UnauthorizedException(message),
      StatusCode.permissionDenied => ForbiddenException(message),
      StatusCode.notFound => NotFoundException(message),
      StatusCode.alreadyExists => ConflictException(message),
      StatusCode.aborted => ConflictException(
        message,
        status: Status(code: StatusCode.aborted, message: message),
      ),
      StatusCode.failedPrecondition => PreconditionFailedException(message),
      StatusCode.outOfRange => RequestRangeNotSatisfiableException(message),
      StatusCode.resourceExhausted => TooManyRequestsException(message),
      StatusCode.cancelled => CancelledException(message),
      StatusCode.deadlineExceeded => GatewayTimeoutException(message),
      StatusCode.internal => InternalServerErrorException(message),
      StatusCode.unimplemented => NotImplementedException(message),
      StatusCode.unavailable => ServiceUnavailableException(message),
      StatusCode.dataLoss => InternalServerErrorException(
        message,
        status: Status(code: StatusCode.dataLoss, message: message),
      ),
      StatusCode.unknown => InternalServerErrorException(message),
      _ => ServiceException(message, statusCode: error.code),
    };
  }
}
