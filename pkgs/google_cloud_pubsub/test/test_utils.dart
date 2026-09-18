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
import 'dart:io';
import 'dart:math';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pbgrpc.dart'
    as generated;
import 'package:grpc/grpc.dart' as grpc;
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart'
    as protobuf;
import 'package:test/fake.dart';
import 'package:test/test.dart';

final isEmulator = Platform.environment['PUBSUB_EMULATOR_HOST'] != null;

const _nameCharacters = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

/// Returns `prefix` followed by a random suffix.
///
/// The tests tagged `google-cloud` run against a real, shared Google Cloud
/// project, where several builds may be running at the same time. A random
/// suffix keeps concurrently running tests from picking the same topic or
/// subscription name, which would make one of them fail with a
/// [ConflictException] or observe the other's messages.
String testResourceName(String prefix) => [
  prefix,
  '-',
  for (var i = 0; i < 12; i++)
    _nameCharacters[_random.nextInt(_nameCharacters.length)],
].join();

/// Creates a [PubSub] client configured for either the emulator or production
/// based on environment variables.
Future<PubSub> createClient() async {
  final host = Platform.environment['PUBSUB_EMULATOR_HOST'];
  final project = Platform.environment['GOOGLE_CLOUD_PROJECT'];

  if (host != null) {
    return PubSub(projectId: 'test-project');
  } else if (project != null) {
    return PubSub(
      projectId: project,
      authenticator: await applicationDefaultCredentialsAuthenticator([
        'https://www.googleapis.com/auth/pubsub',
      ]),
    );
  } else {
    fail(
      'Neither PUBSUB_EMULATOR_HOST nor GOOGLE_CLOUD_PROJECT '
      'environment variable set',
    );
  }
}

/// Pulls up to [count] messages from the [subscription], retrying up to 10
/// times with a 1-second delay between attempts if the expected count is
/// not met.
Future<List<ReceivedMessage>> pullReliably(
  Subscription subscription, {
  required int count,
}) async {
  final messages = <ReceivedMessage>[];
  for (var i = 0; i < 10 && messages.length < count; i++) {
    if (i > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final pulled = await subscription.pull(
      maxMessages: count - messages.length,
    );
    messages.addAll(pulled);
  }
  return messages;
}

class FakeResponseFuture<T> extends Fake implements grpc.ResponseFuture<T> {
  final Future<T> _future;

  FakeResponseFuture(this._future);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class FakeResponseStream<T> extends StreamView<T>
    implements grpc.ResponseStream<T> {
  FakeResponseStream(super.stream);

  @override
  grpc.ResponseFuture<T> get single => FakeResponseFuture(super.single);

  @override
  Future<void> cancel() => Future<void>.value();

  @override
  Future<Map<String, String>> get headers => Future.value(const {});

  @override
  Future<Map<String, String>> get trailers => Future.value(const {});
}

class FakeClientChannel extends Fake implements grpc.ClientChannel {
  bool isShutdown = false;

  @override
  Future<void> shutdown() async {
    isShutdown = true;
  }
}

class FakePublisherClient extends Fake implements generated.PublisherClient {
  Future<generated.PublishResponse> Function(generated.PublishRequest request)?
  publishBehavior;
  int publishCallCount = 0;
  bool get publishCalled => publishCallCount > 0;
  final List<generated.PublishRequest> recordedRequests = [];

  @override
  grpc.ResponseFuture<generated.PublishResponse> publish(
    generated.PublishRequest request, {
    grpc.CallOptions? options,
  }) {
    publishCallCount++;
    recordedRequests.add(request);
    final completer = Completer<generated.PublishResponse>();
    if (publishBehavior case final behavior?) {
      behavior(
        request,
      ).then(completer.complete).catchError(completer.completeError);
    } else {
      final response = generated.PublishResponse()
        ..messageIds.addAll(
          List.generate(request.messages.length, (i) => 'msg-$i'),
        );
      completer.complete(response);
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<generated.Topic> createTopic(
    generated.Topic request, {
    grpc.CallOptions? options,
  }) => FakeResponseFuture(Future.value(request));

  @override
  grpc.ResponseFuture<protobuf.Empty> deleteTopic(
    generated.DeleteTopicRequest request, {
    grpc.CallOptions? options,
  }) => FakeResponseFuture(Future.value(protobuf.Empty()));
}

class FakeSubscriberClient extends Fake implements generated.SubscriberClient {
  Future<void> Function(List<String> ackIds)? acknowledgeBehavior;
  int acknowledgeCallCount = 0;
  bool get acknowledgeCalled => acknowledgeCallCount > 0;
  final List<generated.AcknowledgeRequest> recordedAckRequests = [];
  List<String>? get lastAckIds =>
      recordedAckRequests.isEmpty ? null : recordedAckRequests.last.ackIds;

  Future<void> Function(List<String> ackIds, int seconds)?
  modifyAckDeadlineBehavior;
  int modifyAckDeadlineCallCount = 0;
  bool get modifyAckDeadlineCalled => modifyAckDeadlineCallCount > 0;
  final List<generated.ModifyAckDeadlineRequest> recordedModifyAckRequests = [];
  List<String>? get lastModifyAckDeadlineIds =>
      recordedModifyAckRequests.isEmpty
      ? null
      : recordedModifyAckRequests.last.ackIds;
  int? get lastModifyAckDeadlineSeconds => recordedModifyAckRequests.isEmpty
      ? null
      : recordedModifyAckRequests.last.ackDeadlineSeconds;

  @override
  grpc.ResponseFuture<protobuf.Empty> acknowledge(
    generated.AcknowledgeRequest request, {
    grpc.CallOptions? options,
  }) {
    acknowledgeCallCount++;
    recordedAckRequests.add(request);
    final completer = Completer<protobuf.Empty>();
    if (acknowledgeBehavior case final behavior?) {
      behavior(request.ackIds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }

  @override
  grpc.ResponseFuture<protobuf.Empty> modifyAckDeadline(
    generated.ModifyAckDeadlineRequest request, {
    grpc.CallOptions? options,
  }) {
    modifyAckDeadlineCallCount++;
    recordedModifyAckRequests.add(request);
    final completer = Completer<protobuf.Empty>();
    if (modifyAckDeadlineBehavior case final behavior?) {
      behavior(request.ackIds, request.ackDeadlineSeconds)
          .then((_) => completer.complete(protobuf.Empty()))
          .catchError(completer.completeError);
    } else {
      completer.complete(protobuf.Empty());
    }
    return FakeResponseFuture(completer.future);
  }
}
