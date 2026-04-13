//
//  Generated code. Do not modify.
//  source: google/pubsub/v1/pubsub.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../protobuf/empty.pb.dart' as $1;
import 'pubsub.pb.dart' as $0;

export 'pubsub.pb.dart';

/// The service that an application uses to manipulate topics, and to send
/// messages to a topic.
@$pb.GrpcServiceName('google.pubsub.v1.Publisher')
class PublisherClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = 'pubsub.googleapis.com';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/pubsub',
  ];

  static final _$createTopic = $grpc.ClientMethod<$0.Topic, $0.Topic>(
      '/google.pubsub.v1.Publisher/CreateTopic',
      ($0.Topic value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Topic.fromBuffer(value));
  static final _$updateTopic =
      $grpc.ClientMethod<$0.UpdateTopicRequest, $0.Topic>(
          '/google.pubsub.v1.Publisher/UpdateTopic',
          ($0.UpdateTopicRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Topic.fromBuffer(value));
  static final _$publish =
      $grpc.ClientMethod<$0.PublishRequest, $0.PublishResponse>(
          '/google.pubsub.v1.Publisher/Publish',
          ($0.PublishRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.PublishResponse.fromBuffer(value));
  static final _$getTopic = $grpc.ClientMethod<$0.GetTopicRequest, $0.Topic>(
      '/google.pubsub.v1.Publisher/GetTopic',
      ($0.GetTopicRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Topic.fromBuffer(value));
  static final _$listTopics =
      $grpc.ClientMethod<$0.ListTopicsRequest, $0.ListTopicsResponse>(
          '/google.pubsub.v1.Publisher/ListTopics',
          ($0.ListTopicsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.ListTopicsResponse.fromBuffer(value));
  static final _$listTopicSubscriptions = $grpc.ClientMethod<
          $0.ListTopicSubscriptionsRequest, $0.ListTopicSubscriptionsResponse>(
      '/google.pubsub.v1.Publisher/ListTopicSubscriptions',
      ($0.ListTopicSubscriptionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ListTopicSubscriptionsResponse.fromBuffer(value));
  static final _$listTopicSnapshots = $grpc.ClientMethod<
          $0.ListTopicSnapshotsRequest, $0.ListTopicSnapshotsResponse>(
      '/google.pubsub.v1.Publisher/ListTopicSnapshots',
      ($0.ListTopicSnapshotsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ListTopicSnapshotsResponse.fromBuffer(value));
  static final _$deleteTopic =
      $grpc.ClientMethod<$0.DeleteTopicRequest, $1.Empty>(
          '/google.pubsub.v1.Publisher/DeleteTopic',
          ($0.DeleteTopicRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$detachSubscription = $grpc.ClientMethod<
          $0.DetachSubscriptionRequest, $0.DetachSubscriptionResponse>(
      '/google.pubsub.v1.Publisher/DetachSubscription',
      ($0.DetachSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.DetachSubscriptionResponse.fromBuffer(value));

  PublisherClient(super.channel, {super.options, super.interceptors});

  /// Creates the given topic with the given name. See the [resource name rules]
  /// (https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names).
  $grpc.ResponseFuture<$0.Topic> createTopic($0.Topic request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createTopic, request, options: options);
  }

  /// Updates an existing topic by updating the fields specified in the update
  /// mask. Note that certain properties of a topic are not modifiable.
  $grpc.ResponseFuture<$0.Topic> updateTopic($0.UpdateTopicRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateTopic, request, options: options);
  }

  /// Adds one or more messages to the topic. Returns `NOT_FOUND` if the topic
  /// does not exist.
  $grpc.ResponseFuture<$0.PublishResponse> publish($0.PublishRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$publish, request, options: options);
  }

  /// Gets the configuration of a topic.
  $grpc.ResponseFuture<$0.Topic> getTopic($0.GetTopicRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getTopic, request, options: options);
  }

  /// Lists matching topics.
  $grpc.ResponseFuture<$0.ListTopicsResponse> listTopics(
      $0.ListTopicsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listTopics, request, options: options);
  }

  /// Lists the names of the attached subscriptions on this topic.
  $grpc.ResponseFuture<$0.ListTopicSubscriptionsResponse>
      listTopicSubscriptions($0.ListTopicSubscriptionsRequest request,
          {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listTopicSubscriptions, request,
        options: options);
  }

  /// Lists the names of the snapshots on this topic. Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you can
  /// set the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  $grpc.ResponseFuture<$0.ListTopicSnapshotsResponse> listTopicSnapshots(
      $0.ListTopicSnapshotsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listTopicSnapshots, request, options: options);
  }

  /// Deletes the topic with the given name. Returns `NOT_FOUND` if the topic
  /// does not exist. After a topic is deleted, a new topic may be created with
  /// the same name; this is an entirely new topic with none of the old
  /// configuration or subscriptions. Existing subscriptions to this topic are
  /// not deleted, but their `topic` field is set to `_deleted-topic_`.
  $grpc.ResponseFuture<$1.Empty> deleteTopic($0.DeleteTopicRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteTopic, request, options: options);
  }

  /// Detaches a subscription from this topic. All messages retained in the
  /// subscription are dropped. Subsequent `Pull` and `StreamingPull` requests
  /// will return FAILED_PRECONDITION. If the subscription is a push
  /// subscription, pushes to the endpoint will stop.
  $grpc.ResponseFuture<$0.DetachSubscriptionResponse> detachSubscription(
      $0.DetachSubscriptionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$detachSubscription, request, options: options);
  }
}

@$pb.GrpcServiceName('google.pubsub.v1.Publisher')
abstract class PublisherServiceBase extends $grpc.Service {
  $core.String get $name => 'google.pubsub.v1.Publisher';

  PublisherServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Topic, $0.Topic>(
        'CreateTopic',
        createTopic_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Topic.fromBuffer(value),
        ($0.Topic value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateTopicRequest, $0.Topic>(
        'UpdateTopic',
        updateTopic_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateTopicRequest.fromBuffer(value),
        ($0.Topic value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PublishRequest, $0.PublishResponse>(
        'Publish',
        publish_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PublishRequest.fromBuffer(value),
        ($0.PublishResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetTopicRequest, $0.Topic>(
        'GetTopic',
        getTopic_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetTopicRequest.fromBuffer(value),
        ($0.Topic value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTopicsRequest, $0.ListTopicsResponse>(
        'ListTopics',
        listTopics_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListTopicsRequest.fromBuffer(value),
        ($0.ListTopicsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTopicSubscriptionsRequest,
            $0.ListTopicSubscriptionsResponse>(
        'ListTopicSubscriptions',
        listTopicSubscriptions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListTopicSubscriptionsRequest.fromBuffer(value),
        ($0.ListTopicSubscriptionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListTopicSnapshotsRequest,
            $0.ListTopicSnapshotsResponse>(
        'ListTopicSnapshots',
        listTopicSnapshots_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListTopicSnapshotsRequest.fromBuffer(value),
        ($0.ListTopicSnapshotsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteTopicRequest, $1.Empty>(
        'DeleteTopic',
        deleteTopic_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteTopicRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DetachSubscriptionRequest,
            $0.DetachSubscriptionResponse>(
        'DetachSubscription',
        detachSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DetachSubscriptionRequest.fromBuffer(value),
        ($0.DetachSubscriptionResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.Topic> createTopic_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Topic> $request) async {
    return createTopic($call, await $request);
  }

  $async.Future<$0.Topic> updateTopic_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateTopicRequest> $request) async {
    return updateTopic($call, await $request);
  }

  $async.Future<$0.PublishResponse> publish_Pre($grpc.ServiceCall $call,
      $async.Future<$0.PublishRequest> $request) async {
    return publish($call, await $request);
  }

  $async.Future<$0.Topic> getTopic_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetTopicRequest> $request) async {
    return getTopic($call, await $request);
  }

  $async.Future<$0.ListTopicsResponse> listTopics_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListTopicsRequest> $request) async {
    return listTopics($call, await $request);
  }

  $async.Future<$0.ListTopicSubscriptionsResponse> listTopicSubscriptions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListTopicSubscriptionsRequest> $request) async {
    return listTopicSubscriptions($call, await $request);
  }

  $async.Future<$0.ListTopicSnapshotsResponse> listTopicSnapshots_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListTopicSnapshotsRequest> $request) async {
    return listTopicSnapshots($call, await $request);
  }

  $async.Future<$1.Empty> deleteTopic_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteTopicRequest> $request) async {
    return deleteTopic($call, await $request);
  }

  $async.Future<$0.DetachSubscriptionResponse> detachSubscription_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DetachSubscriptionRequest> $request) async {
    return detachSubscription($call, await $request);
  }

  $async.Future<$0.Topic> createTopic($grpc.ServiceCall call, $0.Topic request);
  $async.Future<$0.Topic> updateTopic(
      $grpc.ServiceCall call, $0.UpdateTopicRequest request);
  $async.Future<$0.PublishResponse> publish(
      $grpc.ServiceCall call, $0.PublishRequest request);
  $async.Future<$0.Topic> getTopic(
      $grpc.ServiceCall call, $0.GetTopicRequest request);
  $async.Future<$0.ListTopicsResponse> listTopics(
      $grpc.ServiceCall call, $0.ListTopicsRequest request);
  $async.Future<$0.ListTopicSubscriptionsResponse> listTopicSubscriptions(
      $grpc.ServiceCall call, $0.ListTopicSubscriptionsRequest request);
  $async.Future<$0.ListTopicSnapshotsResponse> listTopicSnapshots(
      $grpc.ServiceCall call, $0.ListTopicSnapshotsRequest request);
  $async.Future<$1.Empty> deleteTopic(
      $grpc.ServiceCall call, $0.DeleteTopicRequest request);
  $async.Future<$0.DetachSubscriptionResponse> detachSubscription(
      $grpc.ServiceCall call, $0.DetachSubscriptionRequest request);
}

/// The service that an application uses to manipulate subscriptions and to
/// consume messages from a subscription via the `Pull` method or by
/// establishing a bi-directional stream using the `StreamingPull` method.
@$pb.GrpcServiceName('google.pubsub.v1.Subscriber')
class SubscriberClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = 'pubsub.googleapis.com';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/pubsub',
  ];

  static final _$createSubscription =
      $grpc.ClientMethod<$0.Subscription, $0.Subscription>(
          '/google.pubsub.v1.Subscriber/CreateSubscription',
          ($0.Subscription value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Subscription.fromBuffer(value));
  static final _$getSubscription =
      $grpc.ClientMethod<$0.GetSubscriptionRequest, $0.Subscription>(
          '/google.pubsub.v1.Subscriber/GetSubscription',
          ($0.GetSubscriptionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Subscription.fromBuffer(value));
  static final _$updateSubscription =
      $grpc.ClientMethod<$0.UpdateSubscriptionRequest, $0.Subscription>(
          '/google.pubsub.v1.Subscriber/UpdateSubscription',
          ($0.UpdateSubscriptionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Subscription.fromBuffer(value));
  static final _$listSubscriptions = $grpc.ClientMethod<
          $0.ListSubscriptionsRequest, $0.ListSubscriptionsResponse>(
      '/google.pubsub.v1.Subscriber/ListSubscriptions',
      ($0.ListSubscriptionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $0.ListSubscriptionsResponse.fromBuffer(value));
  static final _$deleteSubscription =
      $grpc.ClientMethod<$0.DeleteSubscriptionRequest, $1.Empty>(
          '/google.pubsub.v1.Subscriber/DeleteSubscription',
          ($0.DeleteSubscriptionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$modifyAckDeadline =
      $grpc.ClientMethod<$0.ModifyAckDeadlineRequest, $1.Empty>(
          '/google.pubsub.v1.Subscriber/ModifyAckDeadline',
          ($0.ModifyAckDeadlineRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$acknowledge =
      $grpc.ClientMethod<$0.AcknowledgeRequest, $1.Empty>(
          '/google.pubsub.v1.Subscriber/Acknowledge',
          ($0.AcknowledgeRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$pull = $grpc.ClientMethod<$0.PullRequest, $0.PullResponse>(
      '/google.pubsub.v1.Subscriber/Pull',
      ($0.PullRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PullResponse.fromBuffer(value));
  static final _$streamingPull =
      $grpc.ClientMethod<$0.StreamingPullRequest, $0.StreamingPullResponse>(
          '/google.pubsub.v1.Subscriber/StreamingPull',
          ($0.StreamingPullRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.StreamingPullResponse.fromBuffer(value));
  static final _$modifyPushConfig =
      $grpc.ClientMethod<$0.ModifyPushConfigRequest, $1.Empty>(
          '/google.pubsub.v1.Subscriber/ModifyPushConfig',
          ($0.ModifyPushConfigRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$getSnapshot =
      $grpc.ClientMethod<$0.GetSnapshotRequest, $0.Snapshot>(
          '/google.pubsub.v1.Subscriber/GetSnapshot',
          ($0.GetSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Snapshot.fromBuffer(value));
  static final _$listSnapshots =
      $grpc.ClientMethod<$0.ListSnapshotsRequest, $0.ListSnapshotsResponse>(
          '/google.pubsub.v1.Subscriber/ListSnapshots',
          ($0.ListSnapshotsRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.ListSnapshotsResponse.fromBuffer(value));
  static final _$createSnapshot =
      $grpc.ClientMethod<$0.CreateSnapshotRequest, $0.Snapshot>(
          '/google.pubsub.v1.Subscriber/CreateSnapshot',
          ($0.CreateSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Snapshot.fromBuffer(value));
  static final _$updateSnapshot =
      $grpc.ClientMethod<$0.UpdateSnapshotRequest, $0.Snapshot>(
          '/google.pubsub.v1.Subscriber/UpdateSnapshot',
          ($0.UpdateSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.Snapshot.fromBuffer(value));
  static final _$deleteSnapshot =
      $grpc.ClientMethod<$0.DeleteSnapshotRequest, $1.Empty>(
          '/google.pubsub.v1.Subscriber/DeleteSnapshot',
          ($0.DeleteSnapshotRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$seek = $grpc.ClientMethod<$0.SeekRequest, $0.SeekResponse>(
      '/google.pubsub.v1.Subscriber/Seek',
      ($0.SeekRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SeekResponse.fromBuffer(value));

  SubscriberClient(super.channel, {super.options, super.interceptors});

  /// Creates a subscription to a given topic. See the [resource name rules]
  /// (https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names).
  /// If the subscription already exists, returns `ALREADY_EXISTS`.
  /// If the corresponding topic doesn't exist, returns `NOT_FOUND`.
  ///
  /// If the name is not provided in the request, the server will assign a random
  /// name for this subscription on the same project as the topic, conforming
  /// to the [resource name format]
  /// (https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names). The
  /// generated name is populated in the returned Subscription object. Note that
  /// for REST API requests, you must specify a name in the request.
  $grpc.ResponseFuture<$0.Subscription> createSubscription(
      $0.Subscription request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createSubscription, request, options: options);
  }

  /// Gets the configuration details of a subscription.
  $grpc.ResponseFuture<$0.Subscription> getSubscription(
      $0.GetSubscriptionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSubscription, request, options: options);
  }

  /// Updates an existing subscription by updating the fields specified in the
  /// update mask. Note that certain properties of a subscription, such as its
  /// topic, are not modifiable.
  $grpc.ResponseFuture<$0.Subscription> updateSubscription(
      $0.UpdateSubscriptionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateSubscription, request, options: options);
  }

  /// Lists matching subscriptions.
  $grpc.ResponseFuture<$0.ListSubscriptionsResponse> listSubscriptions(
      $0.ListSubscriptionsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listSubscriptions, request, options: options);
  }

  /// Deletes an existing subscription. All messages retained in the subscription
  /// are immediately dropped. Calls to `Pull` after deletion will return
  /// `NOT_FOUND`. After a subscription is deleted, a new one may be created with
  /// the same name, but the new one has no association with the old
  /// subscription or its topic unless the same topic is specified.
  $grpc.ResponseFuture<$1.Empty> deleteSubscription(
      $0.DeleteSubscriptionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSubscription, request, options: options);
  }

  /// Modifies the ack deadline for a specific message. This method is useful
  /// to indicate that more time is needed to process a message by the
  /// subscriber, or to make the message available for redelivery if the
  /// processing was interrupted. Note that this does not modify the
  /// subscription-level `ackDeadlineSeconds` used for subsequent messages.
  $grpc.ResponseFuture<$1.Empty> modifyAckDeadline(
      $0.ModifyAckDeadlineRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$modifyAckDeadline, request, options: options);
  }

  /// Acknowledges the messages associated with the `ack_ids` in the
  /// `AcknowledgeRequest`. The Pub/Sub system can remove the relevant messages
  /// from the subscription.
  ///
  /// Acknowledging a message whose ack deadline has expired may succeed,
  /// but such a message may be redelivered later. Acknowledging a message more
  /// than once will not result in an error.
  $grpc.ResponseFuture<$1.Empty> acknowledge($0.AcknowledgeRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$acknowledge, request, options: options);
  }

  /// Pulls messages from the server.
  $grpc.ResponseFuture<$0.PullResponse> pull($0.PullRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$pull, request, options: options);
  }

  /// Establishes a stream with the server, which sends messages down to the
  /// client. The client streams acknowledgments and ack deadline modifications
  /// back to the server. The server will close the stream and return the status
  /// on any error. The server may close the stream with status `UNAVAILABLE` to
  /// reassign server-side resources, in which case, the client should
  /// re-establish the stream. Flow control can be achieved by configuring the
  /// underlying RPC channel.
  $grpc.ResponseStream<$0.StreamingPullResponse> streamingPull(
      $async.Stream<$0.StreamingPullRequest> request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$streamingPull, request, options: options);
  }

  /// Modifies the `PushConfig` for a specified subscription.
  ///
  /// This may be used to change a push subscription to a pull one (signified by
  /// an empty `PushConfig`) or vice versa, or change the endpoint URL and other
  /// attributes of a push subscription. Messages will accumulate for delivery
  /// continuously through the call regardless of changes to the `PushConfig`.
  $grpc.ResponseFuture<$1.Empty> modifyPushConfig(
      $0.ModifyPushConfigRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$modifyPushConfig, request, options: options);
  }

  /// Gets the configuration details of a snapshot. Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you can
  /// set the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  $grpc.ResponseFuture<$0.Snapshot> getSnapshot($0.GetSnapshotRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSnapshot, request, options: options);
  }

  /// Lists the existing snapshots. Snapshots are used in [Seek](
  /// https://cloud.google.com/pubsub/docs/replay-overview) operations, which
  /// allow you to manage message acknowledgments in bulk. That is, you can set
  /// the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  $grpc.ResponseFuture<$0.ListSnapshotsResponse> listSnapshots(
      $0.ListSnapshotsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listSnapshots, request, options: options);
  }

  /// Creates a snapshot from the requested subscription. Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you can
  /// set the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  /// If the snapshot already exists, returns `ALREADY_EXISTS`.
  /// If the requested subscription doesn't exist, returns `NOT_FOUND`.
  /// If the backlog in the subscription is too old -- and the resulting snapshot
  /// would expire in less than 1 hour -- then `FAILED_PRECONDITION` is returned.
  /// See also the `Snapshot.expire_time` field. If the name is not provided in
  /// the request, the server will assign a random
  /// name for this snapshot on the same project as the subscription, conforming
  /// to the [resource name format]
  /// (https://cloud.google.com/pubsub/docs/pubsub-basics#resource_names). The
  /// generated name is populated in the returned Snapshot object. Note that for
  /// REST API requests, you must specify a name in the request.
  $grpc.ResponseFuture<$0.Snapshot> createSnapshot(
      $0.CreateSnapshotRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createSnapshot, request, options: options);
  }

  /// Updates an existing snapshot by updating the fields specified in the update
  /// mask. Snapshots are used in
  /// [Seek](https://cloud.google.com/pubsub/docs/replay-overview) operations,
  /// which allow you to manage message acknowledgments in bulk. That is, you can
  /// set the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  $grpc.ResponseFuture<$0.Snapshot> updateSnapshot(
      $0.UpdateSnapshotRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$updateSnapshot, request, options: options);
  }

  /// Removes an existing snapshot. Snapshots are used in [Seek]
  /// (https://cloud.google.com/pubsub/docs/replay-overview) operations, which
  /// allow you to manage message acknowledgments in bulk. That is, you can set
  /// the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot.
  /// When the snapshot is deleted, all messages retained in the snapshot
  /// are immediately dropped. After a snapshot is deleted, a new one may be
  /// created with the same name, but the new one has no association with the old
  /// snapshot or its subscription, unless the same subscription is specified.
  $grpc.ResponseFuture<$1.Empty> deleteSnapshot(
      $0.DeleteSnapshotRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSnapshot, request, options: options);
  }

  /// Seeks an existing subscription to a point in time or to a given snapshot,
  /// whichever is provided in the request. Snapshots are used in [Seek]
  /// (https://cloud.google.com/pubsub/docs/replay-overview) operations, which
  /// allow you to manage message acknowledgments in bulk. That is, you can set
  /// the acknowledgment state of messages in an existing subscription to the
  /// state captured by a snapshot. Note that both the subscription and the
  /// snapshot must be on the same topic.
  $grpc.ResponseFuture<$0.SeekResponse> seek($0.SeekRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$seek, request, options: options);
  }
}

@$pb.GrpcServiceName('google.pubsub.v1.Subscriber')
abstract class SubscriberServiceBase extends $grpc.Service {
  $core.String get $name => 'google.pubsub.v1.Subscriber';

  SubscriberServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Subscription, $0.Subscription>(
        'CreateSubscription',
        createSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Subscription.fromBuffer(value),
        ($0.Subscription value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetSubscriptionRequest, $0.Subscription>(
        'GetSubscription',
        getSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSubscriptionRequest.fromBuffer(value),
        ($0.Subscription value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.UpdateSubscriptionRequest, $0.Subscription>(
            'UpdateSubscription',
            updateSubscription_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.UpdateSubscriptionRequest.fromBuffer(value),
            ($0.Subscription value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListSubscriptionsRequest,
            $0.ListSubscriptionsResponse>(
        'ListSubscriptions',
        listSubscriptions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ListSubscriptionsRequest.fromBuffer(value),
        ($0.ListSubscriptionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSubscriptionRequest, $1.Empty>(
        'DeleteSubscription',
        deleteSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteSubscriptionRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModifyAckDeadlineRequest, $1.Empty>(
        'ModifyAckDeadline',
        modifyAckDeadline_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ModifyAckDeadlineRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AcknowledgeRequest, $1.Empty>(
        'Acknowledge',
        acknowledge_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.AcknowledgeRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PullRequest, $0.PullResponse>(
        'Pull',
        pull_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PullRequest.fromBuffer(value),
        ($0.PullResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.StreamingPullRequest, $0.StreamingPullResponse>(
            'StreamingPull',
            streamingPull,
            true,
            true,
            ($core.List<$core.int> value) =>
                $0.StreamingPullRequest.fromBuffer(value),
            ($0.StreamingPullResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ModifyPushConfigRequest, $1.Empty>(
        'ModifyPushConfig',
        modifyPushConfig_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ModifyPushConfigRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetSnapshotRequest, $0.Snapshot>(
        'GetSnapshot',
        getSnapshot_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetSnapshotRequest.fromBuffer(value),
        ($0.Snapshot value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListSnapshotsRequest, $0.ListSnapshotsResponse>(
            'ListSnapshots',
            listSnapshots_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListSnapshotsRequest.fromBuffer(value),
            ($0.ListSnapshotsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateSnapshotRequest, $0.Snapshot>(
        'CreateSnapshot',
        createSnapshot_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSnapshotRequest.fromBuffer(value),
        ($0.Snapshot value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdateSnapshotRequest, $0.Snapshot>(
        'UpdateSnapshot',
        updateSnapshot_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdateSnapshotRequest.fromBuffer(value),
        ($0.Snapshot value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSnapshotRequest, $1.Empty>(
        'DeleteSnapshot',
        deleteSnapshot_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeleteSnapshotRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SeekRequest, $0.SeekResponse>(
        'Seek',
        seek_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SeekRequest.fromBuffer(value),
        ($0.SeekResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.Subscription> createSubscription_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.Subscription> $request) async {
    return createSubscription($call, await $request);
  }

  $async.Future<$0.Subscription> getSubscription_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetSubscriptionRequest> $request) async {
    return getSubscription($call, await $request);
  }

  $async.Future<$0.Subscription> updateSubscription_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSubscriptionRequest> $request) async {
    return updateSubscription($call, await $request);
  }

  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSubscriptionsRequest> $request) async {
    return listSubscriptions($call, await $request);
  }

  $async.Future<$1.Empty> deleteSubscription_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteSubscriptionRequest> $request) async {
    return deleteSubscription($call, await $request);
  }

  $async.Future<$1.Empty> modifyAckDeadline_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ModifyAckDeadlineRequest> $request) async {
    return modifyAckDeadline($call, await $request);
  }

  $async.Future<$1.Empty> acknowledge_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AcknowledgeRequest> $request) async {
    return acknowledge($call, await $request);
  }

  $async.Future<$0.PullResponse> pull_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PullRequest> $request) async {
    return pull($call, await $request);
  }

  $async.Future<$1.Empty> modifyPushConfig_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ModifyPushConfigRequest> $request) async {
    return modifyPushConfig($call, await $request);
  }

  $async.Future<$0.Snapshot> getSnapshot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetSnapshotRequest> $request) async {
    return getSnapshot($call, await $request);
  }

  $async.Future<$0.ListSnapshotsResponse> listSnapshots_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListSnapshotsRequest> $request) async {
    return listSnapshots($call, await $request);
  }

  $async.Future<$0.Snapshot> createSnapshot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateSnapshotRequest> $request) async {
    return createSnapshot($call, await $request);
  }

  $async.Future<$0.Snapshot> updateSnapshot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdateSnapshotRequest> $request) async {
    return updateSnapshot($call, await $request);
  }

  $async.Future<$1.Empty> deleteSnapshot_Pre($grpc.ServiceCall $call,
      $async.Future<$0.DeleteSnapshotRequest> $request) async {
    return deleteSnapshot($call, await $request);
  }

  $async.Future<$0.SeekResponse> seek_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SeekRequest> $request) async {
    return seek($call, await $request);
  }

  $async.Future<$0.Subscription> createSubscription(
      $grpc.ServiceCall call, $0.Subscription request);
  $async.Future<$0.Subscription> getSubscription(
      $grpc.ServiceCall call, $0.GetSubscriptionRequest request);
  $async.Future<$0.Subscription> updateSubscription(
      $grpc.ServiceCall call, $0.UpdateSubscriptionRequest request);
  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions(
      $grpc.ServiceCall call, $0.ListSubscriptionsRequest request);
  $async.Future<$1.Empty> deleteSubscription(
      $grpc.ServiceCall call, $0.DeleteSubscriptionRequest request);
  $async.Future<$1.Empty> modifyAckDeadline(
      $grpc.ServiceCall call, $0.ModifyAckDeadlineRequest request);
  $async.Future<$1.Empty> acknowledge(
      $grpc.ServiceCall call, $0.AcknowledgeRequest request);
  $async.Future<$0.PullResponse> pull(
      $grpc.ServiceCall call, $0.PullRequest request);
  $async.Stream<$0.StreamingPullResponse> streamingPull(
      $grpc.ServiceCall call, $async.Stream<$0.StreamingPullRequest> request);
  $async.Future<$1.Empty> modifyPushConfig(
      $grpc.ServiceCall call, $0.ModifyPushConfigRequest request);
  $async.Future<$0.Snapshot> getSnapshot(
      $grpc.ServiceCall call, $0.GetSnapshotRequest request);
  $async.Future<$0.ListSnapshotsResponse> listSnapshots(
      $grpc.ServiceCall call, $0.ListSnapshotsRequest request);
  $async.Future<$0.Snapshot> createSnapshot(
      $grpc.ServiceCall call, $0.CreateSnapshotRequest request);
  $async.Future<$0.Snapshot> updateSnapshot(
      $grpc.ServiceCall call, $0.UpdateSnapshotRequest request);
  $async.Future<$1.Empty> deleteSnapshot(
      $grpc.ServiceCall call, $0.DeleteSnapshotRequest request);
  $async.Future<$0.SeekResponse> seek(
      $grpc.ServiceCall call, $0.SeekRequest request);
}
