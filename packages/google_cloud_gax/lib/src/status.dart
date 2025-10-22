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

import 'any.dart';
import 'encoding.dart';
import 'proto.dart';

// This class logically belongs in `package:google_cloud_rpc` but is here
// because it is used by the error handling in `ServiceClient` and we don't want
// to have circular dependencies between `package:google_cloud_gax` and
// `package:google_cloud_rpc`.
/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs. It is
/// used by [gRPC](https://github.com/grpc). Each `Status` message contains
/// three pieces of data: error code, error message, and error details.
///
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
final class Status extends ProtoMessage {
  static const String fullyQualifiedName = 'google.rpc.Status';

  /// The status code, which should be an enum value of
  /// `google.rpc.Code`.
  final int? code;

  /// A developer-facing error message, which should be in English. Any
  /// user-facing error message should be localized and sent in the
  /// `google.rpc.Status.details` field, or localized
  /// by the client.
  final String? message;

  /// A list of messages that carry the error details.  There is a common set of
  /// message types for APIs to use.
  final List<Any>? details;

  Status({this.code, this.message, this.details}) : super(fullyQualifiedName);

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    code: json['code'] as int?,
    message: json['message'] as String?,
    details: decodeListMessage(json['details'], Any.fromJson),
  );

  @override
  Object toJson() => {
    if (code != null) 'code': code,
    if (message != null) 'message': message,
    if (details != null) 'details': encodeList(details),
  };

  @override
  String toString() {
    final contents = [
      if (code != null) 'code=$code',
      if (message != null) 'message=$message',
    ].join(',');
    return 'Status($contents)';
  }
}
