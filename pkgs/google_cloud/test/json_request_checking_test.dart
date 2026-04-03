// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'package:google_cloud/src/serving/json_request_checking.dart';
import 'package:test/test.dart';

void main() {
  group('shouldSendJsonResponse', () {
    test('empty headers returns false', () {
      expect(shouldSendJsonResponse({}), isFalse);
    });

    test('Accept: application/json returns true', () {
      expect(
        shouldSendJsonResponse({HttpHeaders.acceptHeader: 'application/json'}),
        isTrue,
      );
    });

    test('Accept: text/plain returns false', () {
      expect(
        shouldSendJsonResponse({HttpHeaders.acceptHeader: 'text/plain'}),
        isFalse,
      );
    });

    test('Accept: application/json;q=0.5, text/plain;q=0.8 returns true '
        '(prefers JSON if allowed)', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader: 'application/json;q=0.5, text/plain;q=0.8',
        }),
        isTrue,
      );
    });

    test('Accept: application/json;q=0.8, text/plain;q=0.5 returns true', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader: 'application/json;q=0.8, text/plain;q=0.5',
        }),
        isTrue,
      );
    });

    test('Accept: application/json;q=0 returns false (explicitly forbids)', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader: 'application/json;q=0',
        }),
        isFalse,
      );
    });

    test('Content-Type: application/json returns true', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.contentTypeHeader: 'application/json',
        }),
        isTrue,
      );
    });

    test('Content-Type: application/problem+json returns true', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.contentTypeHeader: 'application/problem+json',
        }),
        isTrue,
      );
    });

    test('Conflict: Content-Type JSON but Accept forbids returns false', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json;q=0',
        }),
        isFalse,
      );
    });

    test('Accept with invalid media type is ignored', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader: 'invalid-mime, application/json',
        }),
        isTrue,
      );
    });

    test('Accept with JSON and text equal priority returns true '
        '(prefers JSON)', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader: 'application/json, text/plain',
        }),
        isTrue,
      );
    });

    test('Accept: */* returns false (defaults to text)', () {
      expect(
        shouldSendJsonResponse({HttpHeaders.acceptHeader: '*/*'}),
        isFalse,
      );
    });

    test('Accept with multiple JSON specs (one allowed, one forbidden) '
        'returns true', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader:
              'application/json, application/manifest+json;q=0',
        }),
        isTrue,
      );
    });

    test('Accept with multiple JSON specs (forbidden first) returns true', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader:
              'application/manifest+json;q=0, application/json',
        }),
        isTrue,
      );
    });

    test('testing mixed json bits', () {
      expect(
        shouldSendJsonResponse({
          HttpHeaders.acceptHeader:
              'application/json; q=1, application/ld+json; q=0',
        }),
        isTrue,
      );
    });
  });
}
