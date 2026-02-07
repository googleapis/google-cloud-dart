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

import 'package:google_cloud_storage/src/crc32c.dart';
import 'package:test/test.dart';

void main() {
  group('Crc32c', () {
    test('initial value is 0', () {
      expect(Crc32c().toBase64(), 'AAAAAA==');
    });

    test('empty input', () {
      final crc = Crc32c()..update([]);
      expect(crc.toBase64(), 'AAAAAA==');
    });

    test('calculates correct CRC32C for "123456789"', () {
      final crc = Crc32c()..update(utf8.encode('123456789'));
      // 0xe3069283 -> 4waSgw==
      expect(crc.toBase64(), '4waSgw==');
    });

    test('updates incrementally', () {
      final crc = Crc32c()
        ..update(utf8.encode('12345'))
        ..update(utf8.encode('6789'));
      // 0xe3069283 -> 4waSgw==
      expect(crc.toBase64(), '4waSgw==');
    });
  });
}
