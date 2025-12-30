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

import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('fromHttpResponse', () {
    test('empty body', () {
      final response = http.Response.bytes([0xff], 400);
      final e = ServiceException.fromHttpResponse(response, null);
      expect(e, isA<BadRequestException>());
      expect(e.message, 'unknown error');
      expect(e.statusCode, 400);
      expect(e.response, response);
      expect(e.responseBody, null);
      expect(e.status, isNull);
      expect(e.toString(), 'BadRequestException: unknown error');
    });

    test('empty body', () {
      final response = http.Response('', 400);
      final e = ServiceException.fromHttpResponse(response, '');
      expect(e, isA<BadRequestException>());
      expect(e.message, 'unknown error');
      expect(e.statusCode, 400);
      expect(e.response, response);
      expect(e.responseBody, '');
      expect(e.status, isNull);
      expect(e.toString(), 'BadRequestException: unknown error');
    });

    test('invalid json body', () {
      final response = http.Response('not json', 400);
      final e = ServiceException.fromHttpResponse(response, 'not json');
      expect(e, isA<BadRequestException>());
      expect(e.message, 'not json');
      expect(e.statusCode, 400);
      expect(e.response, response);
      expect(e.responseBody, 'not json');
      expect(e.status, isNull);
      expect(e.toString(), 'BadRequestException: not json');
    });

    test('valid json but missing error field', () {
      final response = http.Response('{}', 400);
      final e = ServiceException.fromHttpResponse(response, '{}');
      expect(e, isA<BadRequestException>());
      expect(e.message, '{}');
      expect(e.statusCode, 400);
      expect(e.response, response);
      expect(e.responseBody, '{}');
      expect(e.status, isNull);
      expect(e.toString(), 'BadRequestException: {}');
    });

    test('valid json but error field is not a map', () {
      final response = http.Response('{"error": "string error"}', 400);
      final e = ServiceException.fromHttpResponse(
        response,
        '{"error": "string error"}',
      );
      expect(e, isA<BadRequestException>());
      expect(e.message, '{"error": "string error"}');
      expect(e.statusCode, 400);
      expect(e.responseBody, '{"error": "string error"}');
      expect(e.status, isNull);
      expect(e.toString(), 'BadRequestException: {"error": "string error"}');
    });

    test('valid error 400', () {
      const responseBody = '''
{
  "error": {
    "code": 400,
    "message": "bad request",
    "status": "INVALID_ARGUMENT",
    "details": []
  }
}
''';
      final response = http.Response(responseBody, 400);
      final e = ServiceException.fromHttpResponse(response, responseBody);
      expect(e, isA<BadRequestException>());
      expect(e.message, 'bad request');
      expect(e.statusCode, 400);
      expect(e.responseBody, responseBody);
      expect(e.status, isNotNull);
      expect(e.status!.code, 400);
      expect(e.status!.message, 'bad request');
      expect(e.toString(), 'BadRequestException: bad request');
    });

    test('valid error 409', () {
      const responseBody = '''
{
  "error": {
    "code": 409,
    "message": "conflict",
    "status": "ALREADY_EXISTS",
    "details": []
  }
}
''';
      final response = http.Response(responseBody, 409);
      final e = ServiceException.fromHttpResponse(response, responseBody);
      expect(e, isA<ConflictException>());
      expect(e.message, 'conflict');
      expect(e.statusCode, 409);
      expect(e.responseBody, responseBody);
      expect(e.status, isNotNull);
      expect(e.toString(), 'ConflictException: conflict');
    });

    test('valid error other', () {
      const responseBody = '''
{
  "error": {
    "code": 418,
    "message": "internal error",
    "status": "INTERNAL",
    "details": []
  }
}
''';
      final response = http.Response(responseBody, 418);
      final e = ServiceException.fromHttpResponse(response, responseBody);
      expect(e, isA<ServiceException>());
      expect(e, isNot(isA<BadRequestException>()));
      expect(e, isNot(isA<ConflictException>()));
      expect(e.message, 'internal error');
      expect(e.statusCode, 418);
      expect(e.responseBody, responseBody);
      expect(e.status, isNotNull);
      expect(e.toString(), 'ServiceException: internal error');
    });

    test('valid error 401', () {
      final response = http.Response(
        '{"error": {"message": "unauthorized"}}',
        401,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<UnauthorizedException>());
      expect(e.message, 'unauthorized');
      expect(e.statusCode, 401);
      expect(e.toString(), 'UnauthorizedException: unauthorized');
    });

    test('valid error 403', () {
      final response = http.Response(
        '{"error": {"message": "forbidden"}}',
        403,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<ForbiddenException>());
      expect(e.message, 'forbidden');
      expect(e.statusCode, 403);
      expect(e.toString(), 'ForbiddenException: forbidden');
    });

    test('valid error 404', () {
      final response = http.Response(
        '{"error": {"message": "not found"}}',
        404,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<NotFoundException>());
      expect(e.message, 'not found');
      expect(e.statusCode, 404);
      expect(e.toString(), 'NotFoundException: not found');
    });

    test('valid error 405', () {
      final response = http.Response(
        '{"error": {"message": "method not allowed"}}',
        405,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<MethodNotAllowedException>());
      expect(e.message, 'method not allowed');
      expect(e.statusCode, 405);
      expect(e.toString(), 'MethodNotAllowedException: method not allowed');
    });

    test('valid error 411', () {
      final response = http.Response(
        '{"error": {"message": "length required"}}',
        411,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<LengthRequiredException>());
      expect(e.message, 'length required');
      expect(e.statusCode, 411);
      expect(e.toString(), 'LengthRequiredException: length required');
    });

    test('valid error 412', () {
      final response = http.Response(
        '{"error": {"message": "precondition failed"}}',
        412,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<PreconditionFailedException>());
      expect(e.message, 'precondition failed');
      expect(e.statusCode, 412);
      expect(e.toString(), 'PreconditionFailedException: precondition failed');
    });

    test('valid error 416', () {
      final response = http.Response(
        '{"error": {"message": "range not satisfiable"}}',
        416,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<RequestRangeNotSatisfiableException>());
      expect(e.message, 'range not satisfiable');
      expect(e.statusCode, 416);
      expect(
        e.toString(),
        'RequestRangeNotSatisfiableException: range not satisfiable',
      );
    });

    test('valid error 429', () {
      final response = http.Response(
        '{"error": {"message": "too many requests"}}',
        429,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<TooManyRequestsException>());
      expect(e.message, 'too many requests');
      expect(e.statusCode, 429);
      expect(e.toString(), 'TooManyRequestsException: too many requests');
    });

    test('valid error 499', () {
      final response = http.Response(
        '{"error": {"message": "cancelled"}}',
        499,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<CancelledException>());
      expect(e.message, 'cancelled');
      expect(e.statusCode, 499);
      expect(e.toString(), 'CancelledException: cancelled');
    });

    test('valid error 500', () {
      final response = http.Response(
        '{"error": {"message": "internal server error"}}',
        500,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<InternalServerErrorException>());
      expect(e.message, 'internal server error');
      expect(e.statusCode, 500);
      expect(
        e.toString(),
        'InternalServerErrorException: internal server error',
      );
    });

    test('valid error 501', () {
      final response = http.Response(
        '{"error": {"message": "not implemented"}}',
        501,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<NotImplementedException>());
      expect(e.message, 'not implemented');
      expect(e.statusCode, 501);
      expect(e.toString(), 'NotImplementedException: not implemented');
    });

    test('valid error 502', () {
      final response = http.Response(
        '{"error": {"message": "bad gateway"}}',
        502,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<BadGatewayException>());
      expect(e.message, 'bad gateway');
      expect(e.statusCode, 502);
      expect(e.toString(), 'BadGatewayException: bad gateway');
    });

    test('valid error 503', () {
      final response = http.Response(
        '{"error": {"message": "service unavailable"}}',
        503,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<ServiceUnavailableException>());
      expect(e.message, 'service unavailable');
      expect(e.statusCode, 503);
      expect(e.toString(), 'ServiceUnavailableException: service unavailable');
    });

    test('valid error 504', () {
      final response = http.Response(
        '{"error": {"message": "gateway timeout"}}',
        504,
      );
      final e = ServiceException.fromHttpResponse(response, response.body);
      expect(e, isA<GatewayTimeoutException>());
      expect(e.message, 'gateway timeout');
      expect(e.statusCode, 504);
      expect(e.toString(), 'GatewayTimeoutException: gateway timeout');
    });
  });
}
