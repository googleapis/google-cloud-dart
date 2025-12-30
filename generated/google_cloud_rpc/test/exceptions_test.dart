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

import 'package:google_cloud_rpc/rpc.dart';
import 'package:google_cloud_rpc/service_client.dart';
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
    "code": 500,
    "message": "internal error",
    "status": "INTERNAL",
    "details": []
  }
}
''';
      final response = http.Response(responseBody, 500);
      final e = ServiceException.fromHttpResponse(response, responseBody);
      expect(e, isA<ServiceException>());
      expect(e, isNot(isA<BadRequestException>()));
      expect(e, isNot(isA<ConflictException>()));
      expect(e.message, 'internal error');
      expect(e.statusCode, 500);
      expect(e.responseBody, responseBody);
      expect(e.status, isNotNull);
      expect(e.toString(), 'ServiceException: internal error');
    });
  });
}
