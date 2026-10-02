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
import 'disposable_stream_controller.dart';
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
  bool _isClosed = false;

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
  ///
  /// This does not flush messages buffered by [Topic.publish] or
  /// acknowledgments and deadline modifications buffered by
  /// [Subscription.acknowledge] and [Subscription.modifyAckDeadline]. Call and
  /// await [Topic.close] and [Subscription.close] on every [Topic] and
  /// [Subscription] you used before closing the client. Once the client is
  /// closed, publishing, acknowledging, and modifying ack deadlines fail
  /// immediately with a [StateError], including for operations that a [Topic]
  /// or [Subscription] still has buffered.
  Future<void> close() async {
    _isClosed = true;
    await _channel.shutdown();
  }

  // Topic-related methods

  /// A [Topic] object with the given [unqualifiedName] in the client's project.
  ///
  /// It is an error if [publishSettings] exceeds the limits described in
  /// [PublishSettings.batching].
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
  ///
  /// It is an error if [publishSettings] exceeds the limits described in
  /// [PublishSettings.batching].
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
  /// It is an error if [publishSettings] exceeds the limits described in
  /// [PublishSettings.batching]; this is checked before the topic is created.
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
    // Construct the `Topic` first so that invalid arguments are reported
    // before the topic exists on the server.
    final result = topicName(topic, publishSettings: publishSettings);
    final topicProto = grpc.Topic()..name = topic;
    try {
      await _publisher.createTopic(topicProto, options: await _callOptions);
      return result;
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    }
  }

  /// Adds a message to the topic in a single RPC without batching or retry.
  ///
  /// For background batching and automatic retries, use [Topic.publish].
  ///
  /// The [topic] must be in the format `projects/<project-id>/topics/<topic-id>`.
  ///
  /// It is an error to call this after [close].
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
  /// It is an error to call this after [close].
  ///
  /// Throws a [NotFoundException] if the topic does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Publisher.Publish).
  @internal
  Future<List<String>> publishMessages(
    String topic,
    List<Message> messages,
  ) async {
    // A shut-down channel fails every call with UNAVAILABLE, which `Topic`
    // would otherwise retry until its retry budget runs out. A `StateError`
    // is not retried.
    if (_isClosed) {
      throw StateError('Cannot publish using a closed PubSub client.');
    }
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
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
    // Construct the `Subscription` first so that invalid arguments are
    // reported before the subscription exists on the server.
    final result = subscriptionName(subscription, ackSettings: ackSettings);
    final subscriptionProto = grpc.Subscription()
      ..name = subscription
      ..topic = topic;

    try {
      await _subscriber.createSubscription(
        subscriptionProto,
        options: await _callOptions,
      );
      return result;
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    }
  }

  /// Opens a `StreamingPull` bidirectional stream using [requestStream] for
  /// client-to-server requests (initial subscription setup, acknowledgments,
  /// and deadline modifications) and returns the server-to-client stream of
  /// [ReceivedMessage]s.
  ///
  /// Invokes [onConnected] when the server sends the initial response headers,
  /// and attaches [ackHandler] and [modifyDeadlineHandler] to each yielded
  /// [ReceivedMessage].
  ///
  /// Used internally by [streamingPull] and [Subscription.streamingPull].
  @internal
  Stream<ReceivedMessage> streamingPullWithStream(
    Stream<grpc.StreamingPullRequest> requestStream, {
    void Function()? onConnected,
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int ackDeadlineSeconds)?
    modifyDeadlineHandler,
  }) async* {
    if (_isClosed) {
      throw StateError('Cannot stream messages using a closed PubSub client.');
    }
    final responseStream = _subscriber.streamingPull(
      requestStream,
      options: await _callOptions,
    );
    if (onConnected != null) {
      // Any RPC or connection errors are forwarded to `responseStream` below.
      // Suppress errors on this unawaited `headers` future to avoid uncaught
      // asynchronous errors in the zone.
      unawaited(
        responseStream.headers.then((_) => onConnected()).catchError((_) {}),
      );
    }
    yield* responseStream
        .expand(
          (response) => response.receivedMessages.map(
            (receivedMessage) => _mapReceivedMessage(
              receivedMessage,
              ackHandler: ackHandler,
              modifyDeadlineHandler: modifyDeadlineHandler,
            ),
          ),
        )
        .handleError((Object e, StackTrace stackTrace) {
          if (_isClosed) {
            Error.throwWithStackTrace(
              StateError(
                'Cannot stream messages using a closed PubSub client.',
              ),
              stackTrace,
            );
          }
          if (e is GrpcError) {
            Error.throwWithStackTrace(_mapGrpcError(e), stackTrace);
          }
          Error.throwWithStackTrace(e, stackTrace);
        });
  }

  /// Establishes a single streaming pull connection with the server.
  ///
  /// For automatic reconnection and parallel streams, use
  /// [Subscription.streamingPull].
  ///
  /// The [subscription] must be in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`.
  ///
  /// The client streams acknowledgments and ack deadline modifications
  /// back to the server while the stream is open, falling back to unary
  /// RPCs if the stream is closed. If an error occurs (including when the
  /// server closes the stream with `UNAVAILABLE` to reassign resources),
  /// the stream emits a [ServiceException] and closes.
  ///
  /// It is an error if [subscription] is empty, or if
  /// [streamAckDeadlineSeconds] is not between 10 and 600 seconds.
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
    final requestController =
        DisposableStreamController<grpc.StreamingPullRequest>();
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
          if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
            throw ArgumentError.value(
              ackDeadlineSeconds,
              'ackDeadlineSeconds',
              'Must be between 0 and 600 seconds',
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
      unawaited(requestController.dispose());
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
  /// It is an error to call this after [close].
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledge(String subscription, List<String> ackIds) async {
    // A shut-down channel fails every call with UNAVAILABLE, which
    // `Subscription` would otherwise retry until its retry budget runs out. A
    // `StateError` is not retried.
    if (_isClosed) {
      throw StateError('Cannot acknowledge using a closed PubSub client.');
    }
    if (ackIds.isEmpty) return;
    final request = grpc.AcknowledgeRequest()
      ..subscription = subscription
      ..ackIds.addAll(ackIds);

    try {
      await _subscriber.acknowledge(request, options: await _callOptions);
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
  /// It is an error if [ackDeadlineSeconds] is not between 0 and 600 seconds.
  /// It is an error to call this after [close].
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadline(
    String subscription,
    List<String> ackIds,
    int ackDeadlineSeconds,
  ) async {
    if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be between 0 and 600 seconds',
      );
    }
    if (_isClosed) {
      throw StateError(
        'Cannot modify ack deadline using a closed PubSub client.',
      );
    }
    if (ackIds.isEmpty) return;
    final request = grpc.ModifyAckDeadlineRequest()
      ..subscription = subscription
      ..ackIds.addAll(ackIds)
      ..ackDeadlineSeconds = ackDeadlineSeconds;

    try {
      await _subscriber.modifyAckDeadline(request, options: await _callOptions);
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
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
  Exception _mapGrpcError(GrpcError e) {
    final message = e.message ?? 'Unknown gRPC error';
    // Preserve the gRPC status code on `ServiceException.status` (matching how
    // `ServiceException.fromHttpResponse` populates it for REST errors).
    // Because multiple gRPC codes map to the same HTTP exception class (e.g.
    // both `ALREADY_EXISTS` and `ABORTED` map to `ConflictException`, and
    // `INTERNAL`, `UNKNOWN`, and `DATA_LOSS` all map to
    // `InternalServerErrorException`), `ExponentialRetry.isRetryable` inspects
    // `status.code` to retry `ABORTED` and avoid retrying `DATA_LOSS`.
    final status = Status(code: e.code, message: message);
    return switch (e.code) {
      StatusCode.invalidArgument => BadRequestException(
        message,
        status: status,
      ),
      StatusCode.unauthenticated => UnauthorizedException(
        message,
        status: status,
      ),
      StatusCode.permissionDenied => ForbiddenException(
        message,
        status: status,
      ),
      StatusCode.notFound => NotFoundException(message, status: status),
      StatusCode.alreadyExists ||
      StatusCode.aborted => ConflictException(message, status: status),
      StatusCode.failedPrecondition => PreconditionFailedException(
        message,
        status: status,
      ),
      StatusCode.outOfRange => RequestRangeNotSatisfiableException(
        message,
        status: status,
      ),
      StatusCode.resourceExhausted => TooManyRequestsException(
        message,
        status: status,
      ),
      StatusCode.cancelled => CancelledException(message, status: status),
      StatusCode.deadlineExceeded => GatewayTimeoutException(
        message,
        status: status,
      ),
      StatusCode.internal || StatusCode.dataLoss || StatusCode.unknown =>
        InternalServerErrorException(message, status: status),
      StatusCode.unimplemented => NotImplementedException(
        message,
        status: status,
      ),
      StatusCode.unavailable => ServiceUnavailableException(
        message,
        status: status,
      ),
      _ => ServiceException(message, statusCode: e.code, status: status),
    };
  }
}
