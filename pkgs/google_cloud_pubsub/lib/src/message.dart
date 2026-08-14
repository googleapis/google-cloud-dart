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

/// A Pub/Sub message.
final class Message {
  /// The payload of this message.
  final Uint8List data;

  /// Optional attributes for this message.
  final Map<String, String> attributes;

  Message({required List<int> data, Map<String, String>? attributes})
    : data = data is Uint8List ? data : Uint8List.fromList(data),
      attributes = attributes ?? const {};
}

/// A message received from a subscription.
final class ReceivedMessage {
  /// The acknowledgment ID, used to identify this message when acknowledging
  /// it or modifying its acknowledgment deadline.
  final String ackId;

  /// The message payload and attributes.
  final Message message;

  /// The ID of this message, assigned by the server.
  final String messageId;

  /// The time at which the message was published.
  final DateTime publishTime;

  final FutureOr<void> Function(List<String>)? _ackHandler;
  final FutureOr<void> Function(List<String>, int)? _modifyDeadlineHandler;

  ReceivedMessage({
    required this.ackId,
    required this.messageId,
    required this.publishTime,
    required this.message,
    FutureOr<void> Function(List<String>)? ackHandler,
    FutureOr<void> Function(List<String>, int)? modifyDeadlineHandler,
  }) : _ackHandler = ackHandler,
       _modifyDeadlineHandler = modifyDeadlineHandler;

  /// The message data.
  Uint8List get data => message.data;

  /// Optional attributes for this message.
  Map<String, String> get attributes => message.attributes;

  /// Acknowledges the message.
  ///
  /// If this message was received via `pull`, it will call the unary
  /// acknowledge endpoint.
  /// If it was received via `streamingPull`, it will send an acknowledgment
  /// request over the existing stream.
  Future<void> acknowledge() async {
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
  Future<void> modifyAckDeadline(int seconds) async {
    final handler = _modifyDeadlineHandler;
    if (handler != null) {
      await handler([ackId], seconds);
    }
  }
}
