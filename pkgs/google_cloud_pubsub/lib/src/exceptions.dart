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

import 'package:grpc/grpc.dart';

/// Thrown when a topic is not found.
class TopicNotFoundException implements Exception {
  /// The name of the topic that was not found.
  final String name;

  TopicNotFoundException(this.name);

  @override
  String toString() => 'TopicNotFoundException: Topic "$name" not found.';
}

/// Thrown when a topic already exists.
class TopicAlreadyExistsException implements Exception {
  /// The name of the topic that already exists.
  final String name;

  TopicAlreadyExistsException(this.name);

  @override
  String toString() =>
      'TopicAlreadyExistsException: Topic "$name" already exists.';
}

/// Thrown when a subscription already exists.
class SubscriptionAlreadyExistsException implements Exception {
  /// The name of the subscription that already exists.
  final String name;

  SubscriptionAlreadyExistsException(this.name);

  @override
  String toString() =>
      'SubscriptionAlreadyExistsException: Subscription "$name" '
      'already exists.';
}

/// Thrown when a subscription is not found.
class SubscriptionNotFoundException implements Exception {
  /// The name of the subscription that was not found.
  final String name;

  SubscriptionNotFoundException(this.name);

  @override
  String toString() =>
      'SubscriptionNotFoundException: Subscription "$name" not found.';
}

/// Thrown when a streaming pull connection is broken.
class StreamBrokenException implements Exception {
  /// The underlying gRPC error that caused the stream to break.
  final GrpcError error;

  StreamBrokenException(this.error);

  @override
  String toString() => 'StreamBrokenException: ${error.message}';
}
