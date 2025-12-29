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
  group('ServiceException', () {
    test('no body', () {
      final response = http.Response('test message', 404);
      final e = ServiceException(
        'test message',
        response: response,
        statusCode: 400,
      );

      expect(e.message, 'test message');
      expect(e.statusCode, 400);
      expect(e.responseBody, null);
      expect(e.response, response);

      expect(e.toString(), 'ServiceException: test message');
    });

    test('with body', () {
      final response = http.Response('test message', 400);

      final e = ServiceException(
        'test message',
        response: response,
        responseBody: '<response body>',
        statusCode: 400,
      );

      expect(e.message, 'test message');
      expect(e.statusCode, 400);
      expect(e.responseBody, '<response body>');
      expect(e.response, response);

      expect(e.toString(), 'ServiceException: test message');
    });

    test('with status', () {
      final response = http.Response('test message', 400);
      final status = Status(code: 400, message: 'failure', details: []);

      final e = ServiceException(
        'test message',
        response: response,
        responseBody: '<response body>',
        statusCode: 400,
        status: status,
      );

      expect(e.message, 'test message');
      expect(e.statusCode, 400);
      expect(e.responseBody, '<response body>');
      expect(e.response, response);
      expect(e.status?.toJson(), status.toJson());

      expect(e.toString(), 'ServiceException: test message');
    });
  });
}
