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

/// A Pub/Sub message.
final class Message {
  /// The message data.
  final List<int> data;

  /// Optional attributes for this message.
  final Map<String, String>? attributes;

  /// The ID of this message, assigned by the server.
  final String? messageId;

  /// The time at which the message was published.
  final DateTime? publishTime;

  Message({
    required this.data,
    this.attributes,
    this.messageId,
    this.publishTime,
  });
}

/// A message received from a subscription.
final class ReceivedMessage {
  /// The ack ID for this message.
  final String ackId;

  /// The received message.
  final Message message;

  ReceivedMessage({required this.ackId, required this.message});
}
