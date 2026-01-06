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

import 'package:google_cloud_protobuf/src/encoding.dart';
import 'package:test/test.dart';

void main() {
  group('decodeBool', () {
    test('true', () {
      expect(decodeBool(true), true);
    });
    test('false', () {
      expect(decodeBool(false), false);
    });
  });

  group('decodeBytes', () {
    test('empty', () {
      final actual = decodeBytes('');
      expect(actual, isEmpty);
    });

    test('simple', () {
      final actual = decodeBytes('bG9yZW0gaXBzdW0=');
      final expected = [108, 111, 114, 101, 109, 32, 105, 112, 115, 117, 109];
      expect(actual, expected);
    });
  });

  group('decodeDouble', () {
    test('double', () {
      expect(decodeDouble(1.1), 1.1);
    });

    test('int', () {
      expect(decodeDouble(1), 1);
    });

    test('NaN', () {
      expect(decodeDouble('NaN'), isNaN);
    });

    test('Infinity', () {
      expect(decodeDouble('Infinity'), double.infinity);
    });

    test('-Infinity', () {
      expect(decodeDouble('-Infinity'), double.negativeInfinity);
    });

    test('string', () {
      expect(() => decodeDouble('1.0'), throwsFormatException);
    });
  });

  group('decodeInt', () {
    test('int', () {
      expect(decodeInt(1), 1);
    });

    test('string', () {
      expect(() => decodeInt('1'), throwsA(isA<TypeError>()));
    });
  });

  group('decodeInt64', () {
    test('int', () {
      expect(decodeInt64(1), 1);
    });

    test('string', () {
      expect(decodeInt64('1'), 1);
    });
  });

  group('decodeUint64', () {
    test('int', () {
      expect(decodeUint64(1), BigInt.from(1));
    });

    test('string', () {
      expect(decodeUint64('1'), BigInt.from(1));
    });
  });

  group('decodeBoolKey', () {
    test('true', () {
      expect(decodeBoolKey('true'), true);
    });

    test('false', () {
      expect(decodeBoolKey('false'), false);
    });

    test('invalid', () {
      expect(() => decodeBoolKey('xxx'), throwsFormatException);
    });
  });

  group('decodeIntKey', () {
    test('int', () {
      expect(decodeIntKey('1'), 1);
    });

    test('invalid', () {
      expect(() => decodeIntKey('xxx'), throwsFormatException);
    });
  });

  group('decodeUint64Key', () {
    test('int', () {
      expect(decodeUint64Key('1'), BigInt.one);
    });

    test('invalid', () {
      expect(() => decodeUint64Key('xxx'), throwsFormatException);
    });
  });

  group('encodeBytes', () {
    test('encode empty', () {
      final bytes = Uint8List.fromList([]);
      expect(encodeBytes(bytes), '');
    });

    test('encode simple', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(encodeBytes(bytes), 'AQID');
    });
  });

  group('encodeDouble', () {
    test('double', () {
      expect(encodeDouble(1.1), 1.1);
    });

    test('NaN', () {
      expect(encodeDouble(double.nan), 'NaN');
    });

    test('Infinity', () {
      expect(encodeDouble(double.infinity), 'Infinity');
    });

    test('-Infinity', () {
      expect(encodeDouble(double.negativeInfinity), '-Infinity');
    });
  });
}
