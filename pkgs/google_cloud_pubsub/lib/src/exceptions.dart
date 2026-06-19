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

/// Base class for all exceptions thrown by the google_cloud_pubsub package.
abstract final class PubSubException implements Exception {}

/// Thrown when a topic is not found.
final class TopicNotFoundException implements PubSubException {
  /// The name of the topic that was not found.
  final String name;

  TopicNotFoundException(this.name);

  @override
  String toString() => 'TopicNotFoundException: Topic "$name" not found.';
}

/// Thrown when a topic already exists.
final class TopicAlreadyExistsException implements PubSubException {
  /// The name of the topic that already exists.
  final String name;

  TopicAlreadyExistsException(this.name);

  @override
  String toString() =>
      'TopicAlreadyExistsException: Topic "$name" already exists.';
}

/// Thrown when a subscription already exists.
final class SubscriptionAlreadyExistsException implements PubSubException {
  /// The name of the subscription that already exists.
  final String name;

  SubscriptionAlreadyExistsException(this.name);

  @override
  String toString() =>
      'SubscriptionAlreadyExistsException: Subscription "$name" '
      'already exists.';
}

/// Thrown when a subscription is not found.
final class SubscriptionNotFoundException implements PubSubException {
  /// The name of the subscription that was not found.
  final String name;

  SubscriptionNotFoundException(this.name);

  @override
  String toString() =>
      'SubscriptionNotFoundException: Subscription "$name" not found.';
}

/// Thrown when a streaming pull connection is broken.
final class StreamBrokenException implements PubSubException {
  final int code;
  final String message;
  final Map<String, String> trailers;

  StreamBrokenException(this.code, this.message, [this.trailers = const {}]);

  @override
  String toString() => 'StreamBrokenException: [$code] $message';
}

/// Thrown when a Pub/Sub operation fails due to a gRPC error.
final class PubSubOperationException implements PubSubException {
  /// The gRPC status code.
  final int code;

  /// The error message.
  final String message;

  /// The trailers from the gRPC error.
  final Map<String, String> trailers;

  PubSubOperationException(this.code, this.message, [this.trailers = const {}]);

  @override
  String toString() => 'PubSubOperationException: [$code] $message';
}
