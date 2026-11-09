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

import 'package:google_cloud_auth/src/json_utils.dart';
import 'package:test/test.dart';

void main() {
  group('decodeJsonObject', () {
    test('decodes a JSON object', () {
      expect(decodeJsonObject('{"a": 1, "b": "c"}'), {'a': 1, 'b': 'c'});
    });

    test('throws on invalid JSON', () {
      expect(() => decodeJsonObject('not valid json'), throwsFormatException);
    });

    for (final json in ['[1, 2, 3]', '"string"', '42', 'null']) {
      test('throws on non-object JSON: $json', () {
        expect(
          () => decodeJsonObject(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Expected a JSON object.',
            ),
          ),
        );
      });
    }
  });

  group('requiredString', () {
    test('returns the value', () {
      expect(requiredString({'key': 'value'}, 'key', 'test info'), 'value');
    });

    for (final MapEntry(key: description, value: json)
        in <String, Map<String, dynamic>>{
          'missing': {},
          'null': {'key': null},
          'empty': {'key': ''},
          'not a string': {'key': 42},
        }.entries) {
      test('throws when the value is $description', () {
        expect(
          () => requiredString(json, 'key', 'test info'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              "Missing required 'key' in test info.",
            ),
          ),
        );
      });
    }
  });

  group('optionalString', () {
    test('returns the value', () {
      expect(optionalString({'key': 'value'}, 'key'), 'value');
    });

    test('returns an empty value', () {
      expect(optionalString({'key': ''}, 'key'), '');
    });

    test('returns null when missing', () {
      expect(optionalString({}, 'key'), isNull);
    });

    test('returns null when null', () {
      expect(optionalString({'key': null}, 'key'), isNull);
    });

    test('throws when not a string', () {
      expect(
        () => optionalString({'key': 42}, 'key'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            "The value of 'key' must be a string.",
          ),
        ),
      );
    });
  });
}
