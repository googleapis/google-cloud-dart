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

import 'package:google_cloud/google_cloud.dart';
import 'package:test/test.dart';

void main() {
  group('HttpResponseException', () {
    test('skips empty details in toJson', () {
      final e1 = HttpResponseException(400, 'Custom bad request');
      expect(e1.toJson()['error'], {
        'code': 400,
        'message': 'Custom bad request',
      });

      final e2 = HttpResponseException(400, 'Custom bad request', details: []);
      expect(e2.toJson()['error'], {
        'code': 400,
        'message': 'Custom bad request',
      });
    });

    test('valid status code', () {
      final ex = HttpResponseException(400, 'Bad');
      expect(ex.statusCode, 400);
      expect(ex.message, 'Bad');
      expect(ex.toString(), 'HttpResponseException: Bad (400)');
    });

    test('toString includes status', () {
      final ex = HttpResponseException(400, 'Bad', status: 'INVALID_ARGUMENT');
      expect(
        ex.toString(),
        'HttpResponseException: Bad (400) [INVALID_ARGUMENT]',
      );
    });

    test('invalid status code low', () {
      expect(
        () => HttpResponseException(399, 'Bad'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('invalid status code high', () {
      expect(
        () => HttpResponseException(600, 'Bad'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('empty message', () {
      expect(
        () => HttpResponseException(400, ''),
        throwsA(isA<AssertionError>()),
      );
    });
    group('factories', () {
      test('badRequest', () {
        final ex = HttpResponseException.badRequest();
        expect(ex.statusCode, 400);
        expect(ex.message, 'Bad Request');
        expect(ex.status, 'INVALID_ARGUMENT');
      });

      test('unauthorized', () {
        final ex = HttpResponseException.unauthorized();
        expect(ex.statusCode, 401);
        expect(ex.message, 'Unauthorized');
        expect(ex.status, 'UNAUTHENTICATED');
      });

      test('forbidden', () {
        final ex = HttpResponseException.forbidden();
        expect(ex.statusCode, 403);
        expect(ex.message, 'Forbidden');
        expect(ex.status, 'PERMISSION_DENIED');
      });

      test('notFound', () {
        final ex = HttpResponseException.notFound();
        expect(ex.statusCode, 404);
        expect(ex.message, 'Not Found');
        expect(ex.status, 'NOT_FOUND');
      });

      test('conflict', () {
        final ex = HttpResponseException.conflict();
        expect(ex.statusCode, 409);
        expect(ex.message, 'Conflict');
        expect(ex.status, 'ALREADY_EXISTS');
      });

      test('tooManyRequests', () {
        final ex = HttpResponseException.tooManyRequests();
        expect(ex.statusCode, 429);
        expect(ex.message, 'Too Many Requests');
        expect(ex.status, 'RESOURCE_EXHAUSTED');
      });

      test('internalServerError', () {
        final ex = HttpResponseException.internalServerError();
        expect(ex.statusCode, 500);
        expect(ex.message, 'Internal Server Error');
        expect(ex.status, 'INTERNAL');
      });

      test('notImplemented', () {
        final ex = HttpResponseException.notImplemented();
        expect(ex.statusCode, 501);
        expect(ex.message, 'Not Implemented');
        expect(ex.status, 'UNIMPLEMENTED');
      });

      test('serviceUnavailable', () {
        final ex = HttpResponseException.serviceUnavailable();
        expect(ex.statusCode, 503);
        expect(ex.message, 'Service Unavailable');
        expect(ex.status, 'UNAVAILABLE');
      });

      test('gatewayTimeout', () {
        final ex = HttpResponseException.gatewayTimeout();
        expect(ex.statusCode, 504);
        expect(ex.message, 'Gateway Timeout');
        expect(ex.status, 'DEADLINE_EXCEEDED');
      });

      test('custom values', () {
        final ex = HttpResponseException.badRequest(
          message: 'Custom message',
          status: 'CUSTOM_STATUS',
          details: [
            {'key': 'value'},
          ],
        );
        expect(ex.statusCode, 400);
        expect(ex.message, 'Custom message');
        expect(ex.status, 'CUSTOM_STATUS');
        expect(ex.details, [
          {'key': 'value'},
        ]);

        final json = ex.toJson();
        expect(json['error'], {
          'code': 400,
          'message': 'Custom message',
          'status': 'CUSTOM_STATUS',
          'details': [
            {'key': 'value'},
          ],
        });
      });
    });
  });
}
