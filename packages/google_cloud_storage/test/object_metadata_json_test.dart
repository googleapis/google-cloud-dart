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
  group('objectMetadataToJson', () {
    group('acl', () {
      group('from json', () {
        test('acl', () {
          final metadata = objectMetadataFromJson({
            'acl': [
              {
                'bucket': 'bucket',
                'domain': 'domain',
                'email': 'email',
                'entity': 'entity',
                'entityId': 'entityId',
                'etag': 'etag',
                'generation': 'generation',
                'id': 'id',
                'kind': 'kind',
                'object': 'object',
                'projectTeam': {
                  'projectNumber': 'projectNumber',
                  'team': 'team',
                },
                'role': 'role',
                'selfLink': 'http://example.com/selfLink',
              },
            ],
          });
          final acl = metadata.acl!.first;
          expect(acl.bucket, 'bucket');
          expect(acl.domain, 'domain');
          expect(acl.email, 'email');
          expect(acl.entity, 'entity');
          expect(acl.entityId, 'entityId');
          expect(acl.etag, 'etag');
          expect(acl.generation, 'generation');
          expect(acl.id, 'id');
          expect(acl.kind, 'kind');
          expect(acl.object, 'object');
          expect(acl.projectTeam?.projectNumber, 'projectNumber');
          expect(acl.projectTeam?.team, 'team');
          expect(acl.role, 'role');
          expect(acl.selfLink, Uri.parse('http://example.com/selfLink'));
        });
      });
      group('to json', () {
        test('acl', () {
          final json = objectMetadataToJson(
            ObjectMetadata(
              acl: [
                ObjectAccessControl(
                  bucket: 'bucket',
                  domain: 'domain',
                  email: 'email',
                  entity: 'entity',
                  entityId: 'entityId',
                  etag: 'etag',
                  generation: 'generation',
                  id: 'id',
                  kind: 'kind',
                  object: 'object',
                  projectTeam: ProjectTeam(
                    projectNumber: 'projectNumber',
                    team: 'team',
                  ),
                  role: 'role',
                  selfLink: Uri.parse('http://example.com/selfLink'),
                ),
              ],
            ),
          );
          expect(json['acl'], [
            {
              'bucket': 'bucket',
              'domain': 'domain',
              'email': 'email',
              'entity': 'entity',
              'entityId': 'entityId',
              'etag': 'etag',
              'generation': 'generation',
              'id': 'id',
              'kind': 'kind',
              'object': 'object',
              'projectTeam': {'projectNumber': 'projectNumber', 'team': 'team'},
              'role': 'role',
              'selfLink': 'http://example.com/selfLink',
            },
          ]);
        });
      });
    });

    group('bucket', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(bucket: 'bucket'));
        expect(json['bucket'], 'bucket');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'bucket': 'bucket'});
        expect(metadata.bucket, 'bucket');
      });
    });

    group('cacheControl', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(cacheControl: 'public, max-age=3600'),
        );
        expect(json['cacheControl'], 'public, max-age=3600');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'cacheControl': 'public, max-age=3600',
        });
        expect(metadata.cacheControl, 'public, max-age=3600');
      });
    });

    group('componentCount', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(componentCount: 5));
        expect(json['componentCount'], 5);
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'componentCount': 5});
        expect(metadata.componentCount, 5);
      });
    });

    group('contentDisposition', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(contentDisposition: 'attachment'),
        );
        expect(json['contentDisposition'], 'attachment');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'contentDisposition': 'attachment',
        });
        expect(metadata.contentDisposition, 'attachment');
      });
    });

    group('contentEncoding', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(contentEncoding: 'gzip'),
        );
        expect(json['contentEncoding'], 'gzip');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'contentEncoding': 'gzip'});
        expect(metadata.contentEncoding, 'gzip');
      });
    });

    group('contentLanguage', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(contentLanguage: 'en'),
        );
        expect(json['contentLanguage'], 'en');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'contentLanguage': 'en'});
        expect(metadata.contentLanguage, 'en');
      });
    });

    group('contentType', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(contentType: 'text/plain'),
        );
        expect(json['contentType'], 'text/plain');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'contentType': 'text/plain'});
        expect(metadata.contentType, 'text/plain');
      });
    });

    group('contexts', () {
      group('from json', () {
        test('custom', () {
          final metadata = objectMetadataFromJson({
            'contexts': {
              'custom': {
                'key1': {
                  'createTime': '1970-01-01T00:16:40Z',
                  'updateTime': '1970-01-01T00:16:40Z',
                  'value': 'val1',
                },
              },
            },
          });
          expect(metadata.contexts?.custom?['key1']?.value, 'val1');
          expect(metadata.contexts?.custom?['key1']?.createTime?.seconds, 1000);
        });
      });
      group('to json', () {
        test('custom', () {
          final json = objectMetadataToJson(
            ObjectMetadata(
              contexts: ObjectContexts(
                custom: {
                  'key1': ObjectCustomContextPayload(
                    createTime: Timestamp(seconds: 1000, nanos: 0),
                    updateTime: Timestamp(seconds: 1000, nanos: 0),
                    value: 'val1',
                  ),
                },
              ),
            ),
          );
          expect(json['contexts'], {
            'custom': {
              'key1': {
                'createTime': '1970-01-01T00:16:40Z',
                'updateTime': '1970-01-01T00:16:40Z',
                'value': 'val1',
              },
            },
          });
        });
      });
    });

    group('crc32c', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(crc32c: 'crc'));
        expect(json['crc32c'], 'crc');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'crc32c': 'crc'});
        expect(metadata.crc32c, 'crc');
      });
    });

    group('customTime', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(customTime: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['customTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'customTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.customTime?.seconds, 1000);
      });
    });

    group('customerEncryption', () {
      group('from json', () {
        test('encryptionAlgorithm', () {
          final metadata = objectMetadataFromJson({
            'customerEncryption': {'encryptionAlgorithm': 'AES256'},
          });
          expect(metadata.customerEncryption?.encryptionAlgorithm, 'AES256');
        });
        test('keySha256', () {
          final metadata = objectMetadataFromJson({
            'customerEncryption': {'keySha256': 'keySha256'},
          });
          expect(metadata.customerEncryption?.keySha256, 'keySha256');
        });
      });
      group('to json', () {
        test('encryptionAlgorithm', () {
          final json = objectMetadataToJson(
            ObjectMetadata(
              customerEncryption: CustomerEncryption(
                encryptionAlgorithm: 'AES256',
              ),
            ),
          );
          expect(json['customerEncryption'], {'encryptionAlgorithm': 'AES256'});
        });
        test('keySha256', () {
          final json = objectMetadataToJson(
            ObjectMetadata(
              customerEncryption: CustomerEncryption(keySha256: 'keySha256'),
            ),
          );
          expect(json['customerEncryption'], {'keySha256': 'keySha256'});
        });
      });
    });

    group('etag', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(etag: 'etag'));
        expect(json['etag'], 'etag');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'etag': 'etag'});
        expect(metadata.etag, 'etag');
      });
    });

    group('eventBasedHold', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(eventBasedHold: true));
        expect(json['eventBasedHold'], true);
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'eventBasedHold': true});
        expect(metadata.eventBasedHold, true);
      });
    });

    group('generation', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(generation: 123));
        expect(json['generation'], '123');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'generation': '123'});
        expect(metadata.generation, 123);
      });
    });

    group('hardDeleteTime', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(hardDeleteTime: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['hardDeleteTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'hardDeleteTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.hardDeleteTime?.seconds, 1000);
      });
    });

    group('id', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(id: 'id'));
        expect(json['id'], 'id');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'id': 'id'});
        expect(metadata.id, 'id');
      });
    });

    group('kind', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(kind: 'kind'));
        expect(json['kind'], 'kind');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'kind': 'kind'});
        expect(metadata.kind, 'kind');
      });
    });

    group('kmsKeyName', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(kmsKeyName: 'kms'));
        expect(json['kmsKeyName'], 'kms');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'kmsKeyName': 'kms'});
        expect(metadata.kmsKeyName, 'kms');
      });
    });

    group('md5Hash', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(md5Hash: 'md5'));
        expect(json['md5Hash'], 'md5');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'md5Hash': 'md5'});
        expect(metadata.md5Hash, 'md5');
      });
    });

    group('mediaLink', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(mediaLink: Uri.parse('http://example.com')),
        );
        expect(json['mediaLink'], 'http://example.com');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'mediaLink': 'http://example.com',
        });
        expect(metadata.mediaLink, Uri.parse('http://example.com'));
      });
    });

    group('metadata', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(metadata: {'key': 'value'}),
        );
        expect(json['metadata'], {'key': 'value'});
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'metadata': {'key': 'value'},
        });
        expect(metadata.metadata, {'key': 'value'});
      });
    });

    group('metageneration', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(metageneration: 456));
        expect(json['metageneration'], '456');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'metageneration': '456'});
        expect(metadata.metageneration, 456);
      });
    });

    group('name', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(name: 'name'));
        expect(json['name'], 'name');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'name': 'name'});
        expect(metadata.name, 'name');
      });
    });

    group('owner', () {
      group('from json', () {
        test('entity', () {
          final metadata = objectMetadataFromJson({
            'owner': {'entity': 'user-1'},
          });
          expect(metadata.owner?.entity, 'user-1');
        });
        test('entityId', () {
          final metadata = objectMetadataFromJson({
            'owner': {'entityId': 'id-1'},
          });
          expect(metadata.owner?.entityId, 'id-1');
        });
      });
      group('to json', () {
        test('entity', () {
          final json = objectMetadataToJson(
            ObjectMetadata(owner: Owner(entity: 'user-1')),
          );
          expect(json['owner'], {'entity': 'user-1'});
        });
        test('entityId', () {
          final json = objectMetadataToJson(
            ObjectMetadata(owner: Owner(entityId: 'id-1')),
          );
          expect(json['owner'], {'entityId': 'id-1'});
        });
      });
    });

    group('restoreToken', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(restoreToken: 'token'),
        );
        expect(json['restoreToken'], 'token');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'restoreToken': 'token'});
        expect(metadata.restoreToken, 'token');
      });
    });

    group('retention', () {
      group('from json', () {
        test('mode', () {
          final metadata = objectMetadataFromJson({
            'retention': {'mode': 'Locked'},
          });
          expect(metadata.retention?.mode, 'Locked');
        });
        test('retainUntilTime', () {
          final metadata = objectMetadataFromJson({
            'retention': {'retainUntilTime': '1970-01-01T00:16:40Z'},
          });
          expect(metadata.retention?.retainUntilTime?.seconds, 1000);
        });
      });
      group('to json', () {
        test('mode', () {
          final json = objectMetadataToJson(
            ObjectMetadata(retention: ObjectRetention(mode: 'Locked')),
          );
          expect(json['retention'], {'mode': 'Locked'});
        });
        test('retainUntilTime', () {
          final json = objectMetadataToJson(
            ObjectMetadata(
              retention: ObjectRetention(
                retainUntilTime: Timestamp(seconds: 1000, nanos: 0),
              ),
            ),
          );
          expect(json['retention'], {
            'retainUntilTime': '1970-01-01T00:16:40Z',
          });
        });
      });
    });

    group('retentionExpirationTime', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(
            retentionExpirationTime: Timestamp(seconds: 1000, nanos: 0),
          ),
        );
        expect(json['retentionExpirationTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'retentionExpirationTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.retentionExpirationTime?.seconds, 1000);
      });
    });

    group('selfLink', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(selfLink: Uri.parse('http://example.com')),
        );
        expect(json['selfLink'], 'http://example.com');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'selfLink': 'http://example.com',
        });
        expect(metadata.selfLink, Uri.parse('http://example.com'));
      });
    });

    group('size', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(size: 1024));
        expect(json['size'], '1024');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'size': '1024'});
        expect(metadata.size, 1024);
      });
    });

    group('softDeleteTime', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(softDeleteTime: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['softDeleteTime'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'softDeleteTime': '1970-01-01T00:16:40Z',
        });
        expect(metadata.softDeleteTime?.seconds, 1000);
      });
    });

    group('storageClass', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(storageClass: 'class'),
        );
        expect(json['storageClass'], 'class');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'storageClass': 'class'});
        expect(metadata.storageClass, 'class');
      });
    });

    group('temporaryHold', () {
      test('to json', () {
        final json = objectMetadataToJson(ObjectMetadata(temporaryHold: true));
        expect(json['temporaryHold'], true);
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({'temporaryHold': true});
        expect(metadata.temporaryHold, true);
      });
    });

    group('timeCreated', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(timeCreated: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['timeCreated'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'timeCreated': '1970-01-01T00:16:40Z',
        });
        expect(metadata.timeCreated?.seconds, 1000);
      });
    });

    group('timeDeleted', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(timeDeleted: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['timeDeleted'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'timeDeleted': '1970-01-01T00:16:40Z',
        });
        expect(metadata.timeDeleted?.seconds, 1000);
      });
    });

    group('timeStorageClassUpdated', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(
            timeStorageClassUpdated: Timestamp(seconds: 1000, nanos: 0),
          ),
        );
        expect(json['timeStorageClassUpdated'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'timeStorageClassUpdated': '1970-01-01T00:16:40Z',
        });
        expect(metadata.timeStorageClassUpdated?.seconds, 1000);
      });
    });

    group('updated', () {
      test('to json', () {
        final json = objectMetadataToJson(
          ObjectMetadata(updated: Timestamp(seconds: 1000, nanos: 0)),
        );
        expect(json['updated'], '1970-01-01T00:16:40Z');
      });
      test('from json', () {
        final metadata = objectMetadataFromJson({
          'updated': '1970-01-01T00:16:40Z',
        });
        expect(metadata.updated?.seconds, 1000);
      });
    });
  });
}
