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

/// @docImport 'subscription.dart';
library;

import 'dart:async';
import 'dart:typed_data';

/// A Pub/Sub message.
final class Message {
  /// The payload of this message.
  final Uint8List data;

  /// Optional attributes for this message.
  final Map<String, String> attributes;

  /// Creates a new [Message] with the given [data] and optional [attributes].
  Message({required List<int> data, Map<String, String>? attributes})
    : data = Uint8List.fromList(data),
      attributes = attributes == null ? const {} : Map.unmodifiable(attributes);

  @override
  String toString() =>
      'Message('
      'data: ${data.length} bytes, '
      'attributes: $attributes)';
}

/// A message received from a subscription.
final class ReceivedMessage {
  /// The message details.
  final Message message;

  /// The acknowledgment ID for this message.
  final String ackId;

  /// The server-assigned ID of this message.
  final String messageId;

  /// The time at which the message was published.
  final DateTime publishTime;

  /// The delivery attempt count for this message.
  ///
  /// This value is greater than 0 only if the subscription has a dead-letter
  /// policy configured. Otherwise, it is 0.
  final int deliveryAttempt;

  final FutureOr<void> Function(List<String> ackIds)? _ackHandler;
  final FutureOr<void> Function(List<String> ackIds, int ackDeadlineSeconds)?
  _modifyDeadlineHandler;

  /// Creates a new [ReceivedMessage].
  ReceivedMessage({
    required this.message,
    required this.ackId,
    required this.messageId,
    required this.publishTime,
    this.deliveryAttempt = 0,
    FutureOr<void> Function(List<String> ackIds)? ackHandler,
    FutureOr<void> Function(List<String> ackIds, int ackDeadlineSeconds)?
    modifyDeadlineHandler,
  }) : _ackHandler = ackHandler,
       _modifyDeadlineHandler = modifyDeadlineHandler;

  /// The message data.
  Uint8List get data => message.data;

  /// Optional attributes for this message.
  Map<String, String> get attributes => message.attributes;

  /// Acknowledges the message.
  ///
  /// Returns a [Future] that completes when the acknowledgment has been
  /// processed.
  ///
  /// For background batched acknowledgment with retries, use
  /// [Subscription.acknowledge].
  ///
  /// It is an error if no acknowledge handler is configured for this message
  /// (e.g. if the message was constructed manually without a handler).
  Future<void> acknowledge() async {
    final handler = _ackHandler;
    if (handler == null) {
      throw StateError('No acknowledge handler configured for this message.');
    }
    await handler([ackId]);
  }

  /// Modifies the ack deadline for this message.
  ///
  /// Returns a [Future] that completes when the deadline modification has been
  /// processed.
  ///
  /// [ackDeadlineSeconds] must be the new ack deadline in seconds, relative to
  /// the time this method is called. For example, if [ackDeadlineSeconds] is
  /// 10, the new ack deadline is 10 seconds from now. Specifying 0 makes the
  /// message immediately available for redelivery.
  ///
  /// For background batched deadline modifications with retries, use
  /// [Subscription.modifyAckDeadline].
  ///
  /// It is an error if [ackDeadlineSeconds] is negative.
  /// It is an error if no modify-ack-deadline handler is configured for this
  /// message (e.g. if the message was constructed manually without a handler).
  Future<void> modifyAckDeadline(int ackDeadlineSeconds) async {
    if (ackDeadlineSeconds < 0) {
      throw ArgumentError.value(
        ackDeadlineSeconds,
        'ackDeadlineSeconds',
        'Must be non-negative',
      );
    }
    final handler = _modifyDeadlineHandler;
    if (handler == null) {
      throw StateError(
        'No modify-ack-deadline handler configured for this message.',
      );
    }
    await handler([ackId], ackDeadlineSeconds);
  }

  @override
  String toString() =>
      'ReceivedMessage('
      'messageId: $messageId, '
      'ackId: $ackId, '
      'publishTime: $publishTime, '
      'deliveryAttempt: $deliveryAttempt, '
      'message: $message)';
}
