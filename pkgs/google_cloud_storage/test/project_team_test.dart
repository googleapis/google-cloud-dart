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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectTeam', () {
    test('copyWith', () {
      final original = ProjectTeam(projectNumber: '123456', team: 'editors');
      final copy = original.copyWith(projectNumber: '654321');

      expect(copy.projectNumber, '654321');
      expect(copy.team, 'editors');

      // Original should remain unchanged
      expect(original.projectNumber, '123456');
      expect(original.team, 'editors');
    });

    test('copyWithout', () {
      final original = ProjectTeam(projectNumber: '123456', team: 'editors');
      final copy = original.copyWithout(projectNumber: true);

      expect(copy.projectNumber, isNull);
      expect(copy.team, 'editors');

      // Original should remain unchanged
      expect(original.projectNumber, '123456');
      expect(original.team, 'editors');
    });
  });
}
