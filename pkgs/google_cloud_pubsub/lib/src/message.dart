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

import 'dart:typed_data';

import 'exceptions.dart';
import 'subscription.dart';

/// A Pub/Sub message.
final class Message {
  /// The message data.
  final Uint8List data;

  /// Optional attributes for this message.
  final Map<String, String> attributes;

  Message({required List<int> data, Map<String, String>? attributes})
    : data = data is Uint8List ? data : Uint8List.fromList(data),
      attributes = attributes ?? const {};
}

/// A message received from a subscription.
final class ReceivedMessage {
  /// The ack ID for this message.
  final String ackId;

  /// The received message.
  final Message message;

  /// The ID of this message, assigned by the server.
  final String messageId;

  /// The time at which the message was published.
  final DateTime publishTime;

  final FutureOr<void> Function(List<String> ackIds)? _ackHandler;
  final FutureOr<void> Function(List<String> ackIds, int seconds)?
  _modifyDeadlineHandler;

  ReceivedMessage({
    required this.ackId,
    required this.messageId,
    required this.publishTime,
    required this.message,
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int seconds)?
    modifyDeadlineHandler,
  }) : _ackHandler = ackHandler,
       _modifyDeadlineHandler = modifyDeadlineHandler;

  /// The message data.
  Uint8List get data => message.data;

  /// Optional attributes for this message.
  Map<String, String> get attributes => message.attributes;

  /// Acknowledges the message.
  ///
  /// If this message was received via [Subscription.pull], it will call
  /// [Subscription.acknowledge].
  /// If it was received via [Subscription.streamingPull], it will send an
  /// acknowledgment request over the existing stream.
  ///
  /// Throws a [PubSubException] if the acknowledgment fails (for example, if
  /// the subscription does not exist or there is a network error).
  Future<void> ack() async {
    final handler = _ackHandler;
    if (handler != null) {
      await handler([ackId]);
    }
  }

  /// Modifies the ack deadline for this message.
  ///
  /// [seconds] must be the new ack deadline in seconds, relative to the
  /// time this method is called. For example, if [seconds] is 10, the new ack
  /// deadline is 10 seconds from now. Specifying 0 makes the message
  /// immediately available for redelivery.
  ///
  /// If this message was received via [Subscription.pull], it will call
  /// [Subscription.modifyAckDeadline].
  /// If it was received via [Subscription.streamingPull], it will send a
  /// modification request over the existing stream.
  ///
  /// Modifying the ack deadline for a message whose deadline has already
  /// expired may succeed, but the message may have already been redelivered
  /// or made available for redelivery.
  ///
  /// Throws a [PubSubException] if the modification fails (for example, if the
  /// subscription does not exist or there is a network error).
  Future<void> modifyAckDeadline(int seconds) async {
    final handler = _modifyDeadlineHandler;
    if (handler != null) {
      await handler([ackId], seconds);
    }
  }
}
