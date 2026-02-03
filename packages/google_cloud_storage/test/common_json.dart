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

import 'package:google_cloud_protobuf/protobuf.dart' show Timestamp;
import 'package:google_cloud_storage/src/common_json.dart';
import 'package:test/test.dart';

void main() {
  group('common json', () {
    test('dateFromJson', () {
      expect(dateFromJson(null), isNull);
      expect(dateFromJson('2026-02-03'), DateTime.parse('2026-02-03'));
      expect(() => dateFromJson(123), throwsArgumentError);
    });

    test('dateToJson', () {
      expect(dateToJson(null), isNull);
      expect(dateToJson(DateTime.utc(2026, 2, 3)), '2026-02-03');
    });

    test('int64FromJson', () {
      expect(int64FromJson(null), isNull);
      expect(int64FromJson('123'), 123);
      expect(int64FromJson(456), 456);
      expect(() => int64FromJson(true), throwsArgumentError);
    });

    test('int64ToJson', () {
      expect(int64ToJson(null), isNull);
      expect(int64ToJson(123), '123');
    });

    test('timestampFromJson', () {
      expect(timestampFromJson(null), isNull);
      final timestamp = timestampFromJson('1970-01-01T00:16:40Z');
      expect(timestamp!.seconds.toInt(), 1000);
      expect(timestamp.nanos, 0);
    });

    test('timestampToJson', () {
      expect(timestampToJson(null), isNull);
      final timestamp = Timestamp(seconds: 1000, nanos: 0);
      final json = timestampToJson(timestamp);
      expect(json, '1970-01-01T00:16:40Z');
    });
  });
}
