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

import 'package:google_cloud_gax/gax.dart';
import 'package:google_cloud_rpc/rpc.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceException', () {
    test('no body', () {
      final e = ServiceException('test message');

      expect(e.message, 'test message');
      expect(e.toString(), 'ServiceException: test message');
    });
    test('with body', () {
      final e = ServiceException(
        'test message',
        responseBody: '<response body>',
      );

      expect(e.message, 'test message');
      expect(e.responseBody, '<response body>');
      expect(
        e.toString(),
        'ServiceException: test message, responseBody="<response body>"',
      );
    });
  });

  group('StatusException', () {
    test('no body, no message', () {
      final e = StatusException.fromStatus(Status(code: 123));

      expect(e.message, 'status returned without message');
      expect(e.status.code, 123);
      expect(e.toString(), 'StatusException: status returned without message');
    });
    test('no body, status message', () {
      final e = StatusException.fromStatus(
        Status(message: 'bad auth', code: 123),
      );

      expect(e.message, 'bad auth');
      expect(e.status.code, 123);
      expect(e.toString(), 'StatusException: bad auth');
    });

    test('with body, status message', () {
      final e = StatusException.fromStatus(
        Status(message: 'bad auth', code: 123),
        responseBody: '<response body>',
      );

      expect(e.message, 'bad auth');
      expect(e.responseBody, '<response body>');
      expect(e.status.code, 123);
      expect(e.toString(), 'StatusException: bad auth');
    });
  });
}
