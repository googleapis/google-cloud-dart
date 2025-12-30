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

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../rpc.dart';

/// Exception thrown when a method is called without correct configuration.
final class ConfigurationException implements Exception {
  /// A message describing the cause of the exception.
  final String message;

  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Exception thrown when an API call fails.
final class ServiceException implements Exception {
  /// A message describing the cause of the exception.
  final String message;

  /// The HTTP status code that the server returned (e.g. 404).
  final int statusCode;

  /// The server response that caused the exception.
  final http.BaseResponse response;

  /// The response body that caused the exception. May be `null` if the response
  /// body could not be decoded.
  final String? responseBody;

  /// The status message returned by the server.
  ///
  /// You can find out more about this error model and how to work with it in
  /// the [API Design Guide](https://cloud.google.com/apis/design/errors).
  final Status? status;

  ServiceException(
    this.message, {
    required this.statusCode,
    required this.response,
    this.responseBody,
    this.status,
  });

  factory ServiceException._fromDecodedResponse(
    String message, {
    required http.BaseResponse response,
    String? responseBody,
    Status? status,
  }) => switch (response.statusCode) {
    400 => BadRequestException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    401 => UnauthorizedException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    403 => ForbiddenException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    404 => NotFoundException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    405 => MethodNotAllowedException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    409 => ConflictException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    411 => LengthRequiredException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    412 => PreconditionFailedException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    416 => RequestRangeNotSatisfiableException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    429 => TooManyRequestsException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    499 => CancelledException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    500 => InternalServerErrorException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    501 => NotImplementedException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    502 => BadGatewayException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    503 => ServiceUnavailableException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    504 => GatewayTimeoutException(
      message,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
    _ => ServiceException(
      message,
      statusCode: response.statusCode,
      response: response,
      responseBody: responseBody,
      status: status,
    ),
  };

  /// Create a [ServiceException] (or appropriate subclass) from an HTTP
  /// response.
  factory ServiceException.fromHttpResponse(
    http.BaseResponse response,
    String? responseBody,
  ) {
    if (responseBody == null || responseBody.isEmpty) {
      return ServiceException._fromDecodedResponse(
        'unknown error',
        response: response,
        responseBody: responseBody,
      );
    }

    final dynamic json;
    try {
      json = jsonDecode(responseBody);
    } on FormatException {
      return ServiceException._fromDecodedResponse(
        responseBody,
        response: response,
        responseBody: responseBody,
      );
    }

    final Status status;
    if (json is Map<String, dynamic> && json['error'] is Map<String, dynamic>) {
      status = Status.fromJson(json['error'] as Map<String, dynamic>);
    } else {
      return ServiceException._fromDecodedResponse(
        responseBody,
        response: response,
        responseBody: responseBody,
      );
    }

    return ServiceException._fromDecodedResponse(
      status.message,
      response: response,
      responseBody: responseBody,
      status: status,
    );
  }

  String get _name => 'ServiceException';

  @override
  String toString() => '$_name: $message';
}

/// Exception thrown when the server returns a "400 Bad Request" response.
final class BadRequestException extends ServiceException {
  BadRequestException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 400);

  @override
  String get _name => 'BadRequestException';
}

/// Exception thrown when the server returns a "401 Unauthorized" response.
final class UnauthorizedException extends ServiceException {
  UnauthorizedException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 401);

  @override
  String get _name => 'UnauthorizedException';
}

/// Exception thrown when the server returns a "403 Forbidden" response.
final class ForbiddenException extends ServiceException {
  ForbiddenException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 403);

  @override
  String get _name => 'ForbiddenException';
}

/// Exception thrown when the server returns a "404 Not Found" response.
final class NotFoundException extends ServiceException {
  NotFoundException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 404);

  @override
  String get _name => 'NotFoundException';
}

/// Exception thrown when the server returns a "405 Method Not Allowed"
/// response.
final class MethodNotAllowedException extends ServiceException {
  MethodNotAllowedException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 405);

  @override
  String get _name => 'MethodNotAllowedException';
}

/// Exception thrown when the server returns a "409 Conflict" response.
final class ConflictException extends ServiceException {
  ConflictException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 409);

  @override
  String get _name => 'ConflictException';
}

/// Exception thrown when the server returns a "411 Length Required" response.
final class LengthRequiredException extends ServiceException {
  LengthRequiredException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 411);

  @override
  String get _name => 'LengthRequiredException';
}

/// Exception thrown when the server returns a "412 Precondition Failed"
/// response.
final class PreconditionFailedException extends ServiceException {
  PreconditionFailedException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 412);

  @override
  String get _name => 'PreconditionFailedException';
}

/// Exception thrown when the server returns a
/// "416 Request Range Not Satisfiable" response.
final class RequestRangeNotSatisfiableException extends ServiceException {
  RequestRangeNotSatisfiableException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 416);

  @override
  String get _name => 'RequestRangeNotSatisfiableException';
}

/// Exception thrown when the server returns a "429 Too Many Requests" response.
final class TooManyRequestsException extends ServiceException {
  TooManyRequestsException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 429);

  @override
  String get _name => 'TooManyRequestsException';
}

/// Exception thrown when the server returns a "499 Cancelled" response.
final class CancelledException extends ServiceException {
  CancelledException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 499);

  @override
  String get _name => 'CancelledException';
}

/// Exception thrown when the server returns a "500 Internal Server Error"
/// response.
final class InternalServerErrorException extends ServiceException {
  InternalServerErrorException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 500);

  @override
  String get _name => 'InternalException';
}

/// Exception thrown when the server returns a "501 Not Implemented" response.
final class NotImplementedException extends ServiceException {
  NotImplementedException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 501);

  @override
  String get _name => 'NotImplementedException';
}

/// Exception thrown when the server returns a "502 Bad Gateway" response.
final class BadGatewayException extends ServiceException {
  BadGatewayException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 502);

  @override
  String get _name => 'BadGatewayException';
}

/// Exception thrown when the server returns a "503 Service Unavailable"
/// response.
final class ServiceUnavailableException extends ServiceException {
  ServiceUnavailableException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 503);

  @override
  String get _name => 'ServiceUnavailableException';
}

/// Exception thrown when the server returns a "504 Gateway Timeout" response.
final class GatewayTimeoutException extends ServiceException {
  GatewayTimeoutException(
    super.message, {
    required super.response,
    required super.responseBody,
    super.status,
  }) : super(statusCode: 504);

  @override
  String get _name => 'GatewayTimeoutException';
}
