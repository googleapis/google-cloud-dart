// Copyright 2021 Google LLC
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

import 'package:shelf/shelf.dart';

import 'http_logging.dart';

/// When thrown in a [Handler], configured with [badRequestMiddleware] or
/// similar, causes a response with [statusCode] to be returned.
///
/// [statusCode] must be >= `400` and <= `499`.
///
/// [message] is used as the body of the response send to the requester.
///
/// If provided, [innerError] and [innerStack] can be used to provide additional
/// debugging information which is included in logs, but not sent to the
/// requester.
class BadRequestException implements Exception {
  /// The HTTP status code for the response.
  ///
  /// Must be between 400 and 499.
  final int statusCode;

  /// The message sent to the requester.
  final String message;

  /// The error that caused this exception.
  final Object? innerError;

  /// The stack trace of the error that caused this exception.
  final StackTrace? innerStack;

  /// An explicit error status string (e.g., `INVALID_ARGUMENT`).
  ///
  /// See https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto
  final String? status;

  /// Structured error details.
  ///
  /// See https://google.aip.dev/193#statusdetails
  final List<Map<String, Object?>>? details;

  BadRequestException(
    this.statusCode,
    this.message, {
    this.innerError,
    this.innerStack,
    this.status,
    this.details,
  }) : assert(message.isNotEmpty) {
    if (statusCode < 400 || statusCode > 499) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Must be between 400 and 499',
      );
    }
  }

  /// Creates a new [BadRequestException] with status code 400.
  factory BadRequestException.badRequest(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status,
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    400,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [BadRequestException] with status code 401.
  ///
  /// The request does not have valid authentication credentials for the
  /// operation.
  factory BadRequestException.unauthorized(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'UNAUTHENTICATED',
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    401,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [BadRequestException] with status code 403.
  ///
  /// The caller does not have permission to execute the specified
  /// operation. `PERMISSION_DENIED` must not be used for rejections
  /// caused by exhausting some resource (use `RESOURCE_EXHAUSTED`
  /// instead for those errors). `PERMISSION_DENIED` must not be
  /// used if the caller can not be identified (use `UNAUTHENTICATED`
  /// instead for those errors). This error code does not imply the
  /// request is valid or the requested entity exists or satisfies
  /// other pre-conditions.
  factory BadRequestException.forbidden(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'PERMISSION_DENIED',
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    403,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [BadRequestException] with status code 404.
  ///
  /// Some requested entity (e.g., file or directory) was not found.
  ///
  /// Note to server developers: if a request is denied for an entire class
  /// of users, such as gradual feature rollout or undocumented allowlist,
  /// `NOT_FOUND` may be used. If a request is denied for some users within
  /// a class of users, such as user-based access control, `PERMISSION_DENIED`
  /// must be used.
  factory BadRequestException.notFound(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'NOT_FOUND',
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    404,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [BadRequestException] with status code 409.
  factory BadRequestException.conflict(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status,
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    409,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [BadRequestException] with status code 429.
  ///
  /// Some resource has been exhausted, perhaps a per-user quota, or
  /// perhaps the entire file system is out of space.
  factory BadRequestException.tooManyRequests(
    String message, {
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'RESOURCE_EXHAUSTED',
    List<Map<String, Object?>>? details,
  }) => BadRequestException(
    429,
    message,
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  @override
  String toString() {
    final buffer = StringBuffer('$message ($statusCode)');
    if (status != null && status!.isNotEmpty) buffer.write(' [$status]');
    if (details != null && details!.isNotEmpty) {
      buffer.write(' Details: $details');
    }
    return buffer.toString();
  }

  /// Returns a JSON representation of the error, suitable for including in a
  /// response body.
  Map<String, Object?> toJson() => {
    'error': {
      'code': statusCode,
      'message': message,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (details != null && details!.isNotEmpty) 'details': details,
    },
  };
}
