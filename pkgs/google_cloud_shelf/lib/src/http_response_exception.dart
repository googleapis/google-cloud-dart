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

/// @docImport 'http_logging.dart';
library;

import 'package:shelf/shelf.dart';

/// When thrown in a [Handler], configured with
/// [createLoggingMiddleware] or similar, causes a response with
/// [statusCode] to be returned.
///
/// [statusCode] must be >= `400` and <= `599`.
///
/// [message] is used as the body of the response send to the requester.
///
/// [details] can be used to provide additional error information which is
/// included in the JSON response body sent to the requester.
///
/// If provided, [innerError] and [innerStack] can be used to provide additional
/// debugging information which is included in logs, but not sent to the
/// requester.
///
/// NOTE: [toString] and [toJson] are carefully written not to leak internal
/// details. Implementors of [HttpResponseException] should be careful to
/// ensure their [toString] and [toJson] implementations are similarly safe.
class HttpResponseException implements Exception {
  /// The HTTP status code for the response.
  ///
  /// Must be between 400 and 599.
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

  HttpResponseException(
    this.statusCode,
    this.message, {
    this.innerError,
    this.innerStack,
    this.status,
    this.details,
  }) : assert(message.isNotEmpty),
       assert(
         statusCode >= 400 && statusCode <= 599,
         'Must be between 400 and 599',
       );

  /// Creates a new [HttpResponseException] with status code 400.
  ///
  /// [message] defaults to `'Bad Request'`.
  factory HttpResponseException.badRequest({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'INVALID_ARGUMENT',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    400,
    message ?? 'Bad Request',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 401.
  ///
  /// The request does not have valid authentication credentials for the
  /// operation.
  ///
  /// [message] defaults to `'Unauthorized'`.
  factory HttpResponseException.unauthorized({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'UNAUTHENTICATED',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    401,
    message ?? 'Unauthorized',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 403.
  ///
  /// The caller does not have permission to execute the specified
  /// operation. `PERMISSION_DENIED` must not be used for rejections
  /// caused by exhausting some resource (use `RESOURCE_EXHAUSTED`
  /// instead for those errors). `PERMISSION_DENIED` must not be
  /// used if the caller can not be identified (use `UNAUTHENTICATED`
  /// instead for those errors). This error code does not imply the
  /// request is valid or the requested entity exists or satisfies
  /// other pre-conditions.
  ///
  /// [message] defaults to `'Forbidden'`.
  factory HttpResponseException.forbidden({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'PERMISSION_DENIED',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    403,
    message ?? 'Forbidden',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 404.
  ///
  /// Some requested entity (e.g., file or directory) was not found.
  ///
  /// Note to server developers: if a request is denied for an entire class
  /// of users, such as gradual feature rollout or undocumented allowlist,
  /// `NOT_FOUND` may be used. If a request is denied for some users within
  /// a class of users, such as user-based access control, `PERMISSION_DENIED`
  /// must be used.
  ///
  /// [message] defaults to `'Not Found'`.
  factory HttpResponseException.notFound({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'NOT_FOUND',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    404,
    message ?? 'Not Found',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 409.
  ///
  /// [message] defaults to `'Conflict'`.
  factory HttpResponseException.conflict({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'ALREADY_EXISTS',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    409,
    message ?? 'Conflict',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 429.
  ///
  /// Some resource has been exhausted, perhaps a per-user quota, or
  /// perhaps the entire file system is out of space.
  ///
  /// [message] defaults to `'Too Many Requests'`.
  factory HttpResponseException.tooManyRequests({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'RESOURCE_EXHAUSTED',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    429,
    message ?? 'Too Many Requests',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 500.
  ///
  /// [message] defaults to `'Internal Server Error'`.
  factory HttpResponseException.internalServerError({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'INTERNAL',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    500,
    message ?? 'Internal Server Error',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 501.
  ///
  /// [message] defaults to `'Not Implemented'`.
  factory HttpResponseException.notImplemented({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'UNIMPLEMENTED',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    501,
    message ?? 'Not Implemented',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 503.
  ///
  /// [message] defaults to `'Service Unavailable'`.
  factory HttpResponseException.serviceUnavailable({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'UNAVAILABLE',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    503,
    message ?? 'Service Unavailable',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  /// Creates a new [HttpResponseException] with status code 504.
  ///
  /// [message] defaults to `'Gateway Timeout'`.
  factory HttpResponseException.gatewayTimeout({
    String? message,
    Object? innerError,
    StackTrace? innerStack,
    String? status = 'DEADLINE_EXCEEDED',
    List<Map<String, Object?>>? details,
  }) => HttpResponseException(
    504,
    message ?? 'Gateway Timeout',
    innerError: innerError,
    innerStack: innerStack,
    status: status,
    details: details,
  );

  // ‼️ DO NOT INCLUDE innerError or innerStack in toString().
  //
  // This data is presented to the end user and may contain sensitive
  // information.
  @override
  String toString() {
    final buffer = StringBuffer(
      'HttpResponseException: $message ($statusCode)',
    );
    if (status != null && status!.isNotEmpty) buffer.write(' [$status]');
    return buffer.toString();
  }

  // ‼️ DO NOT INCLUDE innerError or innerStack in toJson().
  //
  // This data is presented to the end user and may contain sensitive
  // information.
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
