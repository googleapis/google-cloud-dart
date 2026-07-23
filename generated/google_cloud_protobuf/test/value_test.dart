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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  test('encode null', () {
    expect(Value(nullValue: NullValue.nullValue).toJson(), null);
  });

  test('decode null', () {
    expect(Value.fromJson(null).nullValue, NullValue.nullValue);
  });

  test('encode number', () {
    expect(Value(numberValue: 1.5).toJson(), 1.5);
  });

  test('decode number', () {
    expect(Value.fromJson(1.5).numberValue, 1.5);
  });

  test('decode int', () {
    expect(Value.fromJson(1).numberValue, 1.0);
  });

  test('encode string', () {
    expect(Value(stringValue: 'foo').toJson(), 'foo');
  });

  test('decode string', () {
    expect(Value.fromJson('foo').stringValue, 'foo');
  });

  test('encode bool', () {
    expect(Value(boolValue: true).toJson(), true);
  });

  test('decode bool', () {
    expect(Value.fromJson(true).boolValue, true);
  });

  test('encode list', () {
    expect(
      Value(
        listValue: ListValue(
          values: [
            Value(stringValue: 'foo'),
            Value(nullValue: NullValue.nullValue),
          ],
        ),
      ).toJson(),
      ['foo', null],
    );
  });

  test('decode list', () {
    expect(
      Value.fromJson(['foo', null]).listValue?.values,
      containsAllInOrder([
        isA<Value>().having((e) => e.stringValue, 'stringValue', 'foo'),
        isA<Value>().having(
          (e) => e.nullValue,
          'nullValue',
          NullValue.nullValue,
        ),
      ]),
    );
  });

  test('encode struct', () {
    expect(
      Value(
        structValue: Struct(fields: {'foo': Value(stringValue: 'bar')}),
      ).toJson(),
      {'foo': 'bar'},
    );
  });

  test('decode struct', () {
    expect(
      Value.fromJson({'foo': 'bar', 'baz': null}).structValue?.fields,
      equals({
        'foo': isA<Value>().having((e) => e.stringValue, 'stringValue', 'bar'),
        'baz': isA<Value>().having(
          (e) => e.nullValue,
          'nullValue',
          NullValue.nullValue,
        ),
      }),
    );
  });

  test('decode invalid', () {
    expect(() => Value.fromJson(DateTime.now()), throwsFormatException);
  });

  group('decode cyclic', () {
    test('map referencing itself', () {
      final map = <String, Object?>{};
      map['x'] = map;

      expect(() => Value.fromJson(map), throwsFormatException);
    });

    test('list containing itself', () {
      final list = <Object?>[];
      list.add(list);

      expect(() => Value.fromJson(list), throwsFormatException);
    });

    test('map and list referencing each other', () {
      final map = <String, Object?>{};
      final list = <Object?>[map];
      map['list'] = list;

      expect(() => Value.fromJson(map), throwsFormatException);
      expect(() => Value.fromJson(list), throwsFormatException);
    });

    test('map nested below the root', () {
      final inner = <String, Object?>{};
      inner['self'] = inner;

      expect(
        () => Value.fromJson({
          'a': [
            {'b': inner},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('decode repeated but acyclic', () {
    test('map referenced by two keys', () {
      final shared = <String, Object?>{'a': 1};

      final value = Value.fromJson({'x': shared, 'y': shared});

      expect(value.toJson(), {
        'x': {'a': 1.0},
        'y': {'a': 1.0},
      });
    });

    test('list referenced by two elements', () {
      final shared = <Object?>[1, 2];

      final value = Value.fromJson([shared, shared]);

      expect(value.toJson(), [
        [1.0, 2.0],
        [1.0, 2.0],
      ]);
    });
  });
}
