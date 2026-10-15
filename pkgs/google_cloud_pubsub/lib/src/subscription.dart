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

import '../google_cloud_pubsub.dart';
import 'batching.dart';
import 'generated/google/pubsub/v1/pubsub.pbgrpc.dart' as grpc;
import 'wire_size.dart';

/// Settings for background batching and retrying of acknowledgments and
/// deadline modifications.
final class AckSettings {
  /// Settings controlling how requests are accumulated and flushed.
  ///
  /// Pub/Sub accepts at most 512,000 bytes in an `Acknowledge` or
  /// `ModifyAckDeadline` request, which is also the default
  /// [BatchingSettings.maxBytes]. Creating a [Subscription] with a larger
  /// [BatchingSettings.maxBytes] throws an [ArgumentError].
  final BatchingSettings batching;

  /// How failed `Acknowledge` and `ModifyAckDeadline` requests are retried.
  ///
  /// Also the default reconnection strategy for [Subscription.streamingPull].
  ///
  /// Defaults to [defaultRetry].
  final RetryRunner retry;

  /// Creates a new [AckSettings] instance.
  AckSettings({BatchingSettings? batching, RetryRunner? retry})
    : batching = batching ?? BatchingSettings(),
      retry = retry ?? defaultRetry;
}

final class _AckRequest {
  final String ackId;
  final Completer<void>? completer;

  _AckRequest(this.ackId, {this.completer});
}

final class _ModifyAckDeadlineRequest {
  final String ackId;
  final int ackDeadlineSeconds;
  final Completer<void>? completer;

  _ModifyAckDeadlineRequest(
    this.ackId,
    this.ackDeadlineSeconds, {
    this.completer,
  });
}

final class _ActiveStreamingPull {
  final StreamController<ReceivedMessage> controller;
  final Future<void> Function() cancel;

  _ActiveStreamingPull({required this.controller, required this.cancel});
}

/// A [Google Cloud Pub/Sub subscription](https://cloud.google.com/pubsub/docs/overview#subscriptions).
///
/// Acknowledgments and deadline modifications passed to [acknowledge] and
/// [modifyAckDeadline] are buffered and sent in batches. Create one
/// [Subscription] per subscription and reuse it, and call and await [close]
/// before shutdown to flush buffered requests.
final class Subscription {
  static final RegExp _subscriptionNameRegExp = RegExp(
    r'^projects/[^/]+/subscriptions/[^/]+$',
  );

  /// The [PubSub] client associated with this subscription.
  final PubSub pubsub;

  /// The fully qualified resource name of this subscription.
  ///
  /// It has the format `projects/<project-id>/subscriptions/<subscription-id>`.
  final String name;

  /// Settings controlling background acknowledgment and deadline modification
  /// batching and retries.
  final AckSettings ackSettings;

  late final Batcher<_AckRequest> _ackBatcher;
  late final Batcher<_ModifyAckDeadlineRequest> _modifyAckBatcher;

  /// Active streaming pull request streams for this subscription.
  ///
  /// Used to route ACKs and deadline modifications directly over existing
  /// bidirectional streaming pull connections instead of making separate unary
  /// RPCs.
  final List<StreamController<grpc.StreamingPullRequest>> _activeStreams = [];
  final Set<_ActiveStreamingPull> _activeStreamingPulls = {};

  /// Index for round-robin load balancing ACKs across active streams.
  int _nextStreamIndex = 0;
  bool _isClosed = false;
  Future<void>? _closeFuture;

  /// Whether this subscription has been closed via [close].
  bool get isClosed => _isClosed;

  /// A subscription with the given [subscriptionId] in the client's project.
  ///
  /// It is an error if the constructed subscription name is invalid (e.g. if
  /// [subscriptionId] contains slashes), or if [ackSettings] exceeds the
  /// limits described in [AckSettings.batching].
  Subscription.unqualified(
    this.pubsub,
    String subscriptionId, {
    AckSettings? ackSettings,
  }) : name = 'projects/${pubsub.projectId}/subscriptions/$subscriptionId',
       ackSettings = ackSettings ?? AckSettings() {
    _validateName(name);
    _initBatchers();
  }

  /// A subscription with the given [name].
  ///
  /// Useful for cross-project access.
  ///
  /// It is an error if [name] is not in the format
  /// `projects/<project-id>/subscriptions/<subscription-id>`, or if
  /// [ackSettings] exceeds the limits described in [AckSettings.batching].
  Subscription(this.pubsub, this.name, {AckSettings? ackSettings})
    : ackSettings = ackSettings ?? AckSettings() {
    _validateName(name);
    _initBatchers();
  }

  void _initBatchers() {
    checkServerLimits(
      ackSettings.batching,
      maxBytes: maxAcknowledgeRequestBytes,
      requestDescription: 'Acknowledge or ModifyAckDeadline request',
    );
    final settings = ackSettings.batching;

    _ackBatcher = Batcher<_AckRequest>(
      settings: settings,
      baseSize: acknowledgeRequestBaseSize(name),
      itemSize: (request) => acknowledgeRequestItemSize(request.ackId),
      onBatch: _onAckBatch,
    );
    _modifyAckBatcher = Batcher<_ModifyAckDeadlineRequest>(
      settings: settings,
      baseSize: modifyAckDeadlineRequestBaseSize(name),
      itemSize: (request) => modifyAckDeadlineRequestItemSize(
        request.ackId,
        request.ackDeadlineSeconds,
      ),
      onBatch: _onModifyAckDeadlineBatch,
    );
  }

  StreamController<grpc.StreamingPullRequest>? _getActiveStream() {
    if (_isClosed || _activeStreams.isEmpty) return null;
    _activeStreams.removeWhere((stream) => stream.isClosed);
    if (_activeStreams.isEmpty) return null;
    final stream = _activeStreams[_nextStreamIndex % _activeStreams.length];
    _nextStreamIndex = (_nextStreamIndex + 1) % _activeStreams.length;
    return stream;
  }

  // Sends a batch of ACKs. Prefers sending over active gRPC streams
  // (round-robin), falling back to a unary RPC with retries if no streams
  // are available. Errors are caught and suppressed since ACKs are best-effort.
  Future<void> _onAckBatch(List<_AckRequest> batch) async {
    final ackIds = batch.map((request) => request.ackId).toSet().toList();
    void resolveBatch([Object? error, StackTrace? stackTrace]) {
      for (final request in batch) {
        if (request.completer != null && !request.completer!.isCompleted) {
          if (error != null) {
            request.completer!.completeError(error, stackTrace);
          } else {
            request.completer!.complete();
          }
        }
      }
    }

    final activeStream = _getActiveStream();
    if (activeStream != null) {
      activeStream.add(grpc.StreamingPullRequest()..ackIds.addAll(ackIds));
      resolveBatch();
      return;
    }
    // Fall back to unary RPC if no active streams or if subscription is
    // closing.
    try {
      await ackSettings.retry.run(
        () => pubsub.acknowledge(name, ackIds),
        isIdempotent: true,
      );
      resolveBatch();
    } catch (e, stackTrace) {
      // ACKs are best-effort. If the unary fallback fails after retries,
      // the error is suppressed for fire-and-forget, but attached completers
      // must receive the error.
      resolveBatch(e, stackTrace);
    }
  }

  // Sends a batch of deadline modifications. Groups by deadline and prefers
  // sending over active gRPC streams, falling back to unary RPCs with retries.
  Future<void> _onModifyAckDeadlineBatch(
    List<_ModifyAckDeadlineRequest> batch,
  ) async {
    // If the same ackId was modified multiple times within the batch
    // (e.g. lease extension followed by nack), preserve only the latest
    // deadline.
    final latestDeadlineByAckId = <String, int>{};
    final requestsByAckId = <String, List<_ModifyAckDeadlineRequest>>{};
    for (final request in batch) {
      latestDeadlineByAckId[request.ackId] = request.ackDeadlineSeconds;
      requestsByAckId.putIfAbsent(request.ackId, () => []).add(request);
    }
    // Group requests by deadline so we can send batches with the same deadline.
    final byDeadline = <int, List<String>>{};
    for (final entry in latestDeadlineByAckId.entries) {
      byDeadline.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    await Future.wait(
      byDeadline.entries.map((entry) async {
        final deadline = entry.key;
        final ackIds = entry.value;

        void resolveGroup([Object? error, StackTrace? stackTrace]) {
          for (final ackId in ackIds) {
            for (final request
                in requestsByAckId[ackId] ??
                    const <_ModifyAckDeadlineRequest>[]) {
              if (request.completer != null &&
                  !request.completer!.isCompleted) {
                if (error != null) {
                  request.completer!.completeError(error, stackTrace);
                } else {
                  request.completer!.complete();
                }
              }
            }
          }
        }

        final activeStream = _getActiveStream();
        if (activeStream != null) {
          activeStream.add(
            grpc.StreamingPullRequest()
              ..modifyDeadlineAckIds.addAll(ackIds)
              ..modifyDeadlineSeconds.addAll(
                List.filled(ackIds.length, deadline),
              ),
          );
          resolveGroup();
          return;
        }
        // Fall back to unary RPC if no active streams or subscription is
        // closing.
        try {
          await ackSettings.retry.run(
            () => pubsub.modifyAckDeadline(name, ackIds, deadline),
            isIdempotent: true,
          );
          resolveGroup();
        } catch (e, stackTrace) {
          // Deadline modifications are best-effort. If the unary fallback fails
          // after retries, the error is suppressed for fire-and-forget, but
          // attached completers must receive the error.
          resolveGroup(e, stackTrace);
        }
      }),
    );
  }

  static void _validateName(String name) {
    if (!_subscriptionNameRegExp.hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'Must be in the format projects/<project-id>/subscriptions/<subscription-id>',
      );
    }
  }

  /// The unqualified ID of this subscription.
  String get id => name.split('/').last;

  /// Creates this subscription on the server, associating it with the [topic].
  ///
  /// The subscription must not already exist on the server.
  /// The [topic] must exist on the server.
  ///
  /// Throws a [ConflictException] if the subscription already exists.
  /// Throws a [NotFoundException] if the corresponding topic doesn't exist.
  ///
  /// Returns this [Subscription].
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.CreateSubscription).
  Future<Subscription> create({required String topic}) async {
    await pubsub.createSubscription(
      name,
      topic: topic,
      ackSettings: ackSettings,
    );
    return this;
  }

  /// Deletes this subscription on the server.
  ///
  /// All messages retained in the subscription are immediately dropped.
  ///
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.DeleteSubscription).
  Future<void> delete() => pubsub.deleteSubscription(name);

  /// Pulls messages from the server.
  ///
  /// It is an error if [maxMessages] is not greater than 0.
  /// It is an error if called on a closed [Subscription].
  /// Throws a [NotFoundException] if the subscription does not exist.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Pull).
  Future<List<ReceivedMessage>> pull({int maxMessages = 1}) {
    if (_isClosed) {
      throw StateError('Cannot pull messages on a closed Subscription.');
    }
    if (maxMessages <= 0) {
      throw ArgumentError.value(
        maxMessages,
        'maxMessages',
        'Must be greater than zero',
      );
    }
    return pubsub.pull(name, maxMessages: maxMessages);
  }

  /// Establishes a bidirectional streaming pull connection to receive
  /// messages.
  ///
  /// Opens [maxConcurrentStreams] parallel `StreamingPull` connections and
  /// multiplexes their messages into the returned [Stream].
  ///
  /// Each connection automatically reconnects on server disconnects and
  /// retryable errors using [retry] (defaulting to [AckSettings.retry],
  /// with [ExponentialRetry.maxRetryInterval] cleared so the stream can
  /// reconnect indefinitely; an explicit [ExponentialRetry] passed to
  /// [retry] keeps its configured `maxRetryInterval`). The retry delay
  /// sequence resets once a connection receives a message or remains
  /// connected for at least 15 seconds.
  ///
  /// Acknowledgments and deadline modifications from [acknowledge],
  /// [modifyAckDeadline], [ReceivedMessage.acknowledge], and
  /// [ReceivedMessage.modifyAckDeadline] are batched and written to an
  /// active stream when one is open, or sent via unary RPCs with retries
  /// when no stream is active.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [streamAckDeadlineSeconds] is not between 10 and 600
  /// seconds, or if [maxConcurrentStreams] is less than 1.
  ///
  /// Non-retryable errors (such as [NotFoundException] if the subscription
  /// does not exist) and errors after retries are exhausted are emitted on
  /// the returned [Stream].
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.StreamingPull).
  Stream<ReceivedMessage> streamingPull({
    int streamAckDeadlineSeconds = 10,
    int maxConcurrentStreams = 1,
    RetryRunner? retry,
  }) {
    RangeError.checkValueInInterval(
      streamAckDeadlineSeconds,
      10,
      600,
      'streamAckDeadlineSeconds',
    );
    if (maxConcurrentStreams < 1) {
      throw ArgumentError.value(
        maxConcurrentStreams,
        'maxConcurrentStreams',
        'Must be at least 1',
      );
    }
    if (_isClosed) {
      throw StateError('Cannot stream messages on a closed Subscription.');
    }
    final effectiveRetry = switch (retry ?? ackSettings.retry) {
      final ExponentialRetry exponentialRetry when retry == null =>
        ExponentialRetry(
          maxRetries: exponentialRetry.maxRetries,
          maxRetryInterval: null,
          initialDelay: exponentialRetry.initialDelay,
          delayMultiplier: exponentialRetry.delayMultiplier,
          maxDelay: exponentialRetry.maxDelay,
          jitter: exponentialRetry.jitter,
        ),
      final retryRunner => retryRunner,
    };

    late final StreamController<ReceivedMessage> controller;
    late final _ActiveStreamingPull session;
    var isCancelled = false;
    var isPaused = false;
    var activeOrReconnectingStreams = maxConcurrentStreams;
    Object? lastError;
    StackTrace? lastStackTrace;

    // Track active request streams and subscriptions so we can clean them up.
    final currentSubscriptions = <StreamSubscription<ReceivedMessage>>[];
    final requestControllers = <StreamController<grpc.StreamingPullRequest>>[];
    final reconnectTimers = <Timer>[];

    Future<void> cancelAll() async {
      for (final timer in reconnectTimers) {
        timer.cancel();
      }
      reconnectTimers.clear();

      final requestControllersToClose = requestControllers.toList();
      requestControllers.clear();
      for (final requestController in requestControllersToClose) {
        _activeStreams.remove(requestController);
      }

      final subscriptionsToCancel = currentSubscriptions.toList();
      currentSubscriptions.clear();
      await Future.wait(
        subscriptionsToCancel.map(
          (subscription) => subscription.cancel().catchError((_) {}),
        ),
      );

      for (final requestController in requestControllersToClose) {
        unawaited(requestController.close());
      }
    }

    Future<void> cancelSession() async {
      isCancelled = true;
      _activeStreamingPulls.remove(session);
      await cancelAll();
    }

    Future<void> handleAck(List<String> ackIds) async {
      if (ackIds.isEmpty) return;
      if (!_isClosed && !_ackBatcher.isClosed) {
        final futures = <Future<void>>[];
        for (final ackId in ackIds) {
          final completer = Completer<void>();
          _ackBatcher.add(_AckRequest(ackId, completer: completer));
          futures.add(completer.future);
        }
        await Future.wait(futures);
        return;
      }
      // If the subscription is closing or closed, fall back to a unary RPC so
      // already-delivered and in-flight messages can be cleanly acknowledged.
      await pubsub.acknowledge(name, ackIds);
    }

    Future<void> handleModifyDeadline(
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
      if (ackIds.isEmpty) return;
      if (!_isClosed && !_modifyAckBatcher.isClosed) {
        final futures = <Future<void>>[];
        for (final ackId in ackIds) {
          final completer = Completer<void>();
          _modifyAckBatcher.add(
            _ModifyAckDeadlineRequest(
              ackId,
              ackDeadlineSeconds,
              completer: completer,
            ),
          );
          futures.add(completer.future);
        }
        await Future.wait(futures);
        return;
      }
      // If the subscription is closing or closed, fall back to a unary RPC.
      await pubsub.modifyAckDeadline(name, ackIds, ackDeadlineSeconds);
    }

    void connect([Iterator<Duration>? delays]) {
      if (_isClosed || isCancelled || controller.isClosed) return;

      late final StreamController<grpc.StreamingPullRequest> requestController;
      requestController =
          StreamController<grpc.StreamingPullRequest>(
            onListen: () {
              if (!_isClosed && !isCancelled && !controller.isClosed) {
                _activeStreams.add(requestController);
              }
            },
            onCancel: () {
              _activeStreams.remove(requestController);
            },
          )..add(
            grpc.StreamingPullRequest()
              ..subscription = name
              ..streamAckDeadlineSeconds = streamAckDeadlineSeconds,
          );
      requestControllers.add(requestController);

      Stopwatch? connectionStopwatch;
      void markConnected() {
        connectionStopwatch ??= (Stopwatch()..start());
      }

      var hasReceivedItem = false;
      StreamSubscription<ReceivedMessage>? currentSubscription;

      void cleanupCurrentConnection() {
        _activeStreams.remove(requestController);
        requestControllers.remove(requestController);
        if (currentSubscription != null) {
          currentSubscriptions.remove(currentSubscription);
          unawaited(currentSubscription.cancel().catchError((_) {}));
        }
        unawaited(requestController.close());
      }

      Future<void> scheduleReconnect({
        Object? error,
        StackTrace? stackTrace,
      }) async {
        cleanupCurrentConnection();
        if (_isClosed || isCancelled || controller.isClosed) return;

        if (error != null && !effectiveRetry.isRetryable(error)) {
          activeOrReconnectingStreams = 0;
          await cancelSession();
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
            unawaited(controller.close());
          }
          return;
        }

        final uptime = connectionStopwatch?.elapsed ?? Duration.zero;
        // A quiet subscription can stay connected for long periods without
        // receiving messages. Treating a connection that stayed open for at
        // least 15 seconds as healthy prevents periodic server-side idle
        // disconnects from accumulating backoff up to `maxDelay`.
        final wasHealthy =
            hasReceivedItem || (uptime >= const Duration(seconds: 15));
        final nextDelays = (wasHealthy || delays == null)
            ? effectiveRetry.delays().iterator
            : delays;
        if (nextDelays.moveNext()) {
          late Timer timer;
          timer = Timer(nextDelays.current, () {
            reconnectTimers.remove(timer);
            if (_isClosed || isCancelled || controller.isClosed) return;
            connect(nextDelays);
          });
          reconnectTimers.add(timer);
        } else {
          activeOrReconnectingStreams--;
          if (error != null) {
            lastError = error;
            lastStackTrace = stackTrace;
          }
          if (activeOrReconnectingStreams == 0) {
            await cancelSession();
            if (!controller.isClosed) {
              if (lastError != null) {
                controller.addError(lastError!, lastStackTrace);
              }
              unawaited(controller.close());
            }
          }
        }
      }

      final subscription = pubsub
          .streamingPullWithStream(
            requestController.stream,
            onConnected: markConnected,
            ackHandler: handleAck,
            modifyDeadlineHandler: handleModifyDeadline,
          )
          .listen(
            (message) {
              if (_isClosed || isCancelled || controller.isClosed) return;
              markConnected();
              hasReceivedItem = true;
              controller.add(message);
            },
            onError: (Object error, StackTrace stackTrace) =>
                scheduleReconnect(error: error, stackTrace: stackTrace),
            onDone: scheduleReconnect,
            cancelOnError: true,
          );
      currentSubscription = subscription;

      if (isPaused) {
        subscription.pause();
      }
      currentSubscriptions.add(subscription);
    }

    controller = StreamController<ReceivedMessage>(
      onListen: () {
        if (_isClosed) {
          unawaited(controller.close());
          return;
        }
        _activeStreamingPulls.add(session);
        for (var i = 0; i < maxConcurrentStreams; i++) {
          connect();
        }
      },

      onPause: () {
        isPaused = true;
        for (final subscription in currentSubscriptions.toList()) {
          subscription.pause();
        }
      },
      onResume: () {
        isPaused = false;
        for (final subscription in currentSubscriptions.toList()) {
          subscription.resume();
        }
      },
      onCancel: cancelSession,
    );

    session = _ActiveStreamingPull(
      controller: controller,
      cancel: cancelSession,
    );
    return controller.stream;
  }

  /// Acknowledges the [messages] immediately in a single unary RPC without
  /// batching or retry.
  ///
  /// It is an error if called on a closed [Subscription].
  /// Throws a [NotFoundException] if the subscription does not exist.
  /// Throws a [ServiceException] if the RPC fails.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.Acknowledge).
  Future<void> acknowledgeNow(List<ReceivedMessage> messages) {
    if (_isClosed) {
      throw StateError('Cannot acknowledge messages on a closed Subscription.');
    }
    if (messages.isEmpty) return Future.value();
    return pubsub.acknowledge(
      name,
      messages.map((message) => message.ackId).toList(),
    );
  }

  /// Acknowledges [message] in the background.
  ///
  /// The acknowledgment is buffered and sent in a batch according to
  /// [AckSettings.batching]. If active [streamingPull] connections exist for
  /// this subscription, batches are written to an active request stream.
  /// Otherwise, they are sent via a unary RPC with retries configured by
  /// [AckSettings.retry].
  ///
  /// Call and await [close] before shutdown to flush any buffered
  /// acknowledgments.
  ///
  /// It is an error if called on a closed [Subscription].
  ///
  /// This is a non-blocking, fire-and-forget operation. If a background
  /// acknowledgment fails permanently, the message will eventually be
  /// redelivered by the server after its ack deadline expires.
  ///
  /// See [acknowledgeNow] for an immediate, awaitable alternative.
  void acknowledge(ReceivedMessage message) {
    if (_isClosed) {
      throw StateError('Cannot acknowledge messages on a closed Subscription.');
    }
    _ackBatcher.add(_AckRequest(message.ackId));
  }

  /// Modifies the ack deadline for [messages] immediately in a single unary
  /// RPC without batching or retry.
  ///
  /// [ackDeadlineSeconds] must be the new ack deadline in seconds, relative to
  /// the time the request is received. For example, if [ackDeadlineSeconds] is
  /// 10, the new ack deadline is 10 seconds from now. Specifying 0 makes the
  /// message immediately available for redelivery.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [ackDeadlineSeconds] is not between 0 and 600 seconds.
  /// Throws a [NotFoundException] if the subscription does not exist.
  /// Throws a [ServiceException] if the RPC fails.
  ///
  /// See the [official documentation](https://cloud.google.com/pubsub/docs/reference/rpc/google.pubsub.v1#google.pubsub.v1.Subscriber.ModifyAckDeadline).
  Future<void> modifyAckDeadlineNow(
    List<ReceivedMessage> messages,
    int ackDeadlineSeconds,
  ) {
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be between 0 and 600 seconds',
      );
    }
    if (messages.isEmpty) return Future.value();
    return pubsub.modifyAckDeadline(
      name,
      messages.map((message) => message.ackId).toList(),
      ackDeadlineSeconds,
    );
  }

  /// Modifies the ack deadline for [message] in the background.
  ///
  /// The request is buffered and sent in a batch according to
  /// [AckSettings.batching]. If active [streamingPull] connections exist for
  /// this subscription, batches are written to an active request stream.
  /// Otherwise, they are sent via a unary RPC with retries configured by
  /// [AckSettings.retry].
  ///
  /// [ackDeadlineSeconds] must be the new ack deadline in seconds, relative to
  /// the time the request is received. For example, if [ackDeadlineSeconds] is
  /// 10, the new ack deadline is 10 seconds from now. Specifying 0 makes the
  /// message immediately available for redelivery.
  ///
  /// Call and await [close] before shutdown to flush any buffered deadline
  /// modifications.
  ///
  /// It is an error if called on a closed [Subscription].
  /// It is an error if [ackDeadlineSeconds] is not between 0 and 600 seconds.
  ///
  /// This is a non-blocking, fire-and-forget operation. See
  /// [modifyAckDeadlineNow] for an immediate, awaitable alternative.
  void modifyAckDeadline(ReceivedMessage message, int ackDeadlineSeconds) {
    if (_isClosed) {
      throw StateError('Cannot modify ack deadline on a closed Subscription.');
    }
    if (ackDeadlineSeconds < 0 || ackDeadlineSeconds > 600) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be between 0 and 600 seconds',
      );
    }
    _modifyAckBatcher.add(
      _ModifyAckDeadlineRequest(message.ackId, ackDeadlineSeconds),
    );
  }

  /// Closes the subscription, cancelling any active streaming pulls,
  /// flushing any buffered acknowledgments and deadline modifications via
  /// unary RPCs, and waiting for in-flight batches to complete.
  ///
  /// Once closed, it is an error to call [acknowledge], [acknowledgeNow],
  /// [modifyAckDeadline], [modifyAckDeadlineNow], [pull], or [streamingPull].
  Future<void> close() {
    _isClosed = true;
    return _closeFuture ??= _doClose();
  }

  Future<void> _doClose() async {
    final pulls = _activeStreamingPulls.toList();
    _activeStreamingPulls.clear();
    // Cancel active streaming pulls first so the final flush of `_ackBatcher`
    // and `_modifyAckBatcher` below falls back to unary RPCs (which await
    // server confirmation and retry on transient failures) rather than writing
    // fire-and-forget frames onto streams that are being torn down.
    await Future.wait(pulls.map((pull) => pull.cancel()));
    await Future.wait([_ackBatcher.close(), _modifyAckBatcher.close()]);
    for (final pull in pulls) {
      if (!pull.controller.isClosed) {
        unawaited(pull.controller.close());
      }
    }
  }
}
