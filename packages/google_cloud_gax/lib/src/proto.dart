// Copyright 2025 Google LLC
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

/// An abstract class that can return a JSON representation of itself.
///
/// Classes that implement [JsonEncodable] will often have a `fromJson()`
/// constructor.
abstract class JsonEncodable {
  Object? toJson();
}

/// The abstract common superclass of all messages.
abstract class ProtoMessage implements JsonEncodable {
  /// The fully qualified name of this message, i.e., `google.protobuf.Duration`
  /// or `google.rpc.ErrorInfo`.
  final String qualifiedName;

  ProtoMessage(this.qualifiedName);
}

/// The abstract common superclass of all enum values.
abstract class ProtoEnum implements JsonEncodable {
  final String value;

  const ProtoEnum(this.value);

  @override
  String toJson() => value;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        value == (other as ProtoEnum).value;
  }

  @override
  int get hashCode => value.hashCode;
}
