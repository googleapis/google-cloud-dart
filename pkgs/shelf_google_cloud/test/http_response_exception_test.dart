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

import 'package:shelf_google_cloud/shelf_google_cloud.dart';
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
      expect(ex.toString(), 'Bad (400)');
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
  });
}
