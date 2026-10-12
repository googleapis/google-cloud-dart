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

import 'dart:convert';

import 'package:google_cloud_auth/src/verifier/jws_parser.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

String _segment(Object? json) =>
    base64UrlUnpadded(utf8.encode(jsonEncode(json)));

void main() {
  group('JwsParts.parse', () {
    test('success', () {
      final token =
          '${_segment({'alg': 'RS256', 'kid': 'abc'})}'
          '.${_segment({'sub': 'user-1', 'exp': 123})}'
          '.${base64UrlUnpadded(const [1, 2, 3])}';

      final parts = JwsParts.parse(token);

      expect(parts.header, {'alg': 'RS256', 'kid': 'abc'});
      expect(parts.payload, {'sub': 'user-1', 'exp': 123});
      expect(parts.signature, [1, 2, 3]);
      expect(parts.algorithm, 'RS256');
      expect(parts.keyId, 'abc');
    });

    test('signedContent covers exactly the header and payload segments', () {
      final header = _segment({'alg': 'RS256'});
      final payload = _segment({'sub': 'user-1'});
      final token = '$header.$payload.${base64UrlUnpadded(const [9])}';

      final parts = JwsParts.parse(token);

      expect(ascii.decode(parts.signedContent), '$header.$payload');
    });

    test('empty signature, as emulators produce', () {
      final token =
          '${_segment({'alg': 'none'})}.${_segment({'sub': 'user-1'})}.';

      final parts = JwsParts.parse(token);

      expect(parts.signature, isEmpty);
      expect(parts.algorithm, 'none');
    });

    test('decodes base64url without padding and with - and _ characters', () {
      // Chosen so the base64url encoding contains both '-' and '_'.
      final payload = {'data': '≥?~ÿ<>'};
      final encoded = _segment(payload);
      expect(encoded, anyOf(contains('-'), contains('_')));

      final token = '${_segment({'alg': 'RS256'})}.$encoded.';

      expect(JwsParts.parse(token).payload, payload);
    });

    test('missing algorithm', () {
      final token =
          '${_segment({'kid': 'abc'})}.${_segment({'sub': 'user-1'})}.';

      expect(JwsParts.parse(token).algorithm, isNull);
    });

    test('missing keyId', () {
      final token =
          '${_segment({'alg': 'RS256'})}.${_segment({'sub': 'user-1'})}.';

      expect(JwsParts.parse(token).keyId, isNull);
    });

    test('int algorithm', () {
      final token = '${_segment({'alg': 123})}.${_segment({'sub': 'user-1'})}.';

      expect(JwsParts.parse(token).algorithm, isNull);
    });

    test('int keyId', () {
      final token = '${_segment({'kid': 123})}.${_segment({'sub': 'user-1'})}.';

      expect(JwsParts.parse(token).keyId, isNull);
    });

    test('a token with too few segments', () {
      expect(
        () => JwsParts.parse('only-one'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('found 1'),
          ),
        ),
      );
      expect(
        () => JwsParts.parse('one.two'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('found 2'),
          ),
        ),
      );
    });

    test('a token with too many segments', () {
      expect(() => JwsParts.parse('a.b.c.d'), throwsA(isA<FormatException>()));
    });

    test('an empty string', () {
      expect(() => JwsParts.parse(''), throwsA(isA<FormatException>()));
    });

    test('a segment that is not base64url', () {
      expect(
        () => JwsParts.parse('!!!.${_segment({'a': 1})}.'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('base64url'),
          ),
        ),
      );
    });

    test('a segment with non-ASCII characters', () {
      // `signedContent` is ASCII-encoded, so non-ASCII input must be rejected
      // as a FormatException while decoding, before that encoding happens.
      final header = _segment({'alg': 'RS256'});
      final payload = _segment({'sub': 'user-1'});
      for (final token in ['$headeré.$payload.', '$header.$payloadé.']) {
        expect(
          () => JwsParts.parse(token),
          throwsA(isA<FormatException>()),
          reason: token,
        );
      }
    });

    test('a segment that is not JSON', () {
      final notJson = base64UrlUnpadded(utf8.encode('not json'));
      expect(
        () => JwsParts.parse('$notJson.${_segment({'a': 1})}.'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('valid JSON'),
          ),
        ),
      );
    });

    test('a segment that is JSON but not an object', () {
      expect(
        () => JwsParts.parse(
          '${_segment([1, 2])}.'
          '${_segment({'a': 1})}.',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('must be a JSON object'),
          ),
        ),
      );
    });
  });
}
