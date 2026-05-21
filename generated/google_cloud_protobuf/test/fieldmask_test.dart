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

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:test/test.dart';

void main() {
  test('encode empty', () {
    final fieldMask = FieldMask(paths: []);
    expect(fieldMask.toJson(), '');
  });

  test('encode single', () {
    final fieldMask = FieldMask(paths: ['one']);
    expect(fieldMask.toJson(), 'one');
  });

  test('encode multiple', () {
    final fieldMask = FieldMask(paths: ['one', '', 'two']);
    expect(fieldMask.toJson(), 'one,two');
  });

  test('encode uppercase', () {
    final fieldMask = FieldMask(paths: ['Bar.foBar', 'baQux']);
    expect(fieldMask.toJson(), 'bar.fobar,baqux');
  });

  test('encode snake_case to camelCase', () {
    final fieldMask = FieldMask(paths: ['foo_bar', 'baz_qux.foo_bar']);
    expect(fieldMask.toJson(), 'fooBar,bazQux.fooBar');
  });

  test('decode empty', () {
    final fieldMask = FieldMask.fromJson('');
    final actual = fieldMask.paths.join('|');
    expect(actual, '');
  });

  test('decode single', () {
    final fieldMask = FieldMask.fromJson('one');
    expect(fieldMask.paths, ['one']);
  });

  test('decode multiple', () {
    final fieldMask = FieldMask.fromJson('one,two');
    expect(fieldMask.paths, ['one', 'two']);
  });

  test('decode camelCase', () {
    final fieldMask = FieldMask.fromJson('fooBar,,bazQux.fooBar');
    expect(fieldMask.paths, ['foo_bar', 'baz_qux.foo_bar']);
  });
}
