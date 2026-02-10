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
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/object_metadata_json.dart';
import 'package:test/test.dart';

void main() {
  group('customerEncryption', () {
    group('from json', () {
      test('null', () {
        expect(customerEncryptionFromJson(null), isNull);
      });
      test('empty', () {
        final encryption = customerEncryptionFromJson({});
        expect(encryption?.encryptionAlgorithm, isNull);
        expect(encryption?.keySha256, isNull);
      });
      test('encryptionAlgorithm', () {
        final encryption = customerEncryptionFromJson({
          'encryptionAlgorithm': 'AES256',
        });
        expect(encryption?.encryptionAlgorithm, 'AES256');
      });
      test('keySha256', () {
        final encryption = customerEncryptionFromJson({
          'keySha256': 'keySha256',
        });
        expect(encryption?.keySha256, 'keySha256');
      });
    });
    group('to json', () {
      test('empty', () {
        final json = customerEncryptionToJson(CustomerEncryption());
        expect(json, isEmpty);
      });
      test('encryptionAlgorithm', () {
        final json = customerEncryptionToJson(
          CustomerEncryption(encryptionAlgorithm: 'AES256'),
        );
        expect(json, {'encryptionAlgorithm': 'AES256'});
      });
      test('keySha256', () {
        final json = customerEncryptionToJson(
          CustomerEncryption(keySha256: 'keySha256'),
        );
        expect(json, {'keySha256': 'keySha256'});
      });
    });
  });

  group('objectMetadataToJson', () {
    group('acl', () {
      test('empty', () {
        final original = ObjectMetadata(acl: []);
        final json = objectMetadataToJson(original);
        expect(json['acl'], isEmpty);
      });
      test('one entry', () {
        final original = ObjectMetadata(
          acl: [ObjectAccessControl(entity: 'entity')],
        );
        final json = objectMetadataToJson(original);
        expect(json['acl'], [
          {'entity': 'entity'},
        ]);
      });
    });
    test('bucket', () {
      final original = ObjectMetadata(bucket: 'bucket');
      final json = objectMetadataToJson(original);
      expect(json['bucket'], 'bucket');
    });
    test('cacheControl', () {
      final original = ObjectMetadata(cacheControl: 'public, max-age=3600');
      final json = objectMetadataToJson(original);
      expect(json['cacheControl'], 'public, max-age=3600');
    });
    test('md5Hash', () {
      final original = ObjectMetadata(md5Hash: '7Qdih1MuhjZehB6Sv8UNjA==');
      final json = objectMetadataToJson(original);
      expect(json['md5Hash'], '7Qdih1MuhjZehB6Sv8UNjA==');
    });
  });
}
