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

import 'dart:typed_data';

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

  ReceivedMessage({
    required this.ackId,
    required this.messageId,
    required this.publishTime,
    required this.message,
  });

  /// The message data.
  Uint8List get data => message.data;

  /// Optional attributes for this message.
  Map<String, String> get attributes => message.attributes;
}
