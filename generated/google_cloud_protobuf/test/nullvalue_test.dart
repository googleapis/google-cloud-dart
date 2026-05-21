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
    expect(NullValue.nullValue.toJson(), null);
  });

  test('decode null', () {
    expect(NullValue.fromJson(null), NullValue.nullValue);
  });

  test('decode NULL_VALUE', () {
    expect(NullValue.fromJson('NULL_VALUE'), NullValue.nullValue);
  });

  test('decode invalid', () {
    expect(() => NullValue.fromJson(5), throwsFormatException);
  });
}
