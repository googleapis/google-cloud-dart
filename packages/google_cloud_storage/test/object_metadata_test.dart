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
import 'package:google_cloud_storage/src/object_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('ObjectMetadata', () {
    test('copyWith', () {
      final original = ObjectMetadata(
        bucket: 'test-bucket',
        name: 'test-object',
        contentType: 'text/plain',
        size: 1024,
      );

      final copy = original.copyWith(
        contentType: 'application/json',
        size: 2048,
      );

      expect(copy.bucket, 'test-bucket');
      expect(copy.name, 'test-object');
      expect(copy.contentType, 'application/json');
      expect(copy.size, 2048);

      // Original should remain unchanged
      expect(original.contentType, 'text/plain');
      expect(original.size, 1024);
    });

    test('copyWithout', () {
      final original = ObjectMetadata(
        bucket: 'test-bucket',
        name: 'test-object',
        contentType: 'text/plain',
      );

      final copy = original.copyWithout(contentType: true);

      expect(copy.bucket, 'test-bucket');
      expect(copy.name, 'test-object');
      expect(copy.contentType, isNull);
    });
  });

  group('CustomerEncryption', () {
    test('copyWith', () {
      final original = CustomerEncryption(
        encryptionAlgorithm: 'AES256',
        keySha256: 'hash123',
      );
      final copy = original.copyWith(encryptionAlgorithm: 'DES512');

      expect(copy.encryptionAlgorithm, 'DES512');
      expect(copy.keySha256, 'hash123');

      // Original should remain unchanged
      expect(original.encryptionAlgorithm, 'AES256');
      expect(original.keySha256, 'hash123');
    });

    test('copyWithout', () {
      final original = CustomerEncryption(
        encryptionAlgorithm: 'AES256',
        keySha256: 'hash123',
      );
      final copy = original.copyWithout(encryptionAlgorithm: true);

      expect(copy.encryptionAlgorithm, isNull);
      expect(copy.keySha256, 'hash123');

      // Original should remain unchanged
      expect(original.encryptionAlgorithm, 'AES256');
      expect(original.keySha256, 'hash123');
    });
  });

  group('Owner', () {
    test('copyWith', () {
      final original = Owner(entity: 'user-1', entityId: 'id-1');
      final copy = original.copyWith(entity: 'user-2');

      expect(copy.entity, 'user-2');
      expect(copy.entityId, 'id-1');

      // Original should remain unchanged
      expect(original.entity, 'user-1');
      expect(original.entityId, 'id-1');
    });
    test('copyWithout', () {
      final original = Owner(entity: 'user-1', entityId: 'id-1');
      final copy = original.copyWithout(entity: true);

      expect(copy.entity, isNull);
      expect(copy.entityId, 'id-1');

      // Original should remain unchanged
      expect(original.entity, 'user-1');
      expect(original.entityId, 'id-1');
    });
  });

  group('ObjectRetention', () {
    test('copyWith', () {
      final original = ObjectRetention(
        mode: 'Locked',
        retainUntilTime: Timestamp(seconds: 1000, nanos: 0),
      );
      final copy = original.copyWith(mode: 'Unlocked');

      expect(copy.mode, 'Unlocked');
      expect(copy.retainUntilTime!.seconds, 1000);
      expect(copy.retainUntilTime!.nanos, 0);

      // Original should remain unchanged
      expect(original.mode, 'Locked');
      expect(original.retainUntilTime!.seconds, 1000);
      expect(original.retainUntilTime!.nanos, 0);
    });

    test('copyWithout', () {
      final original = ObjectRetention(
        mode: 'Locked',
        retainUntilTime: Timestamp(seconds: 1000, nanos: 0),
      );
      final copy = original.copyWithout(mode: true);

      expect(copy.mode, isNull);
      // TODO(https://github.com/googleapis/google-cloud-dart/issues/81):
      // Replace with direct comparison.
      expect(copy.retainUntilTime!.seconds, 1000);
      expect(copy.retainUntilTime!.nanos, 0);

      // Original should remain unchanged
      expect(original.mode, 'Locked');
      // TODO(https://github.com/googleapis/google-cloud-dart/issues/81):
      // Replace with direct comparison.
      expect(original.retainUntilTime!.seconds, 1000);
      expect(original.retainUntilTime!.nanos, 0);
    });
  });
}
