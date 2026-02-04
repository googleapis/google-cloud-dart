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

import 'object_metadata.dart';
import 'project_team.dart';

ProjectTeam? projectTeamFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return ProjectTeam(
    projectNumber: json['projectNumber'] as String?,
    team: json['team'] as String?,
  );
}

Map<String, Object?>? projectTeamToJson(ProjectTeam? instance) {
  if (instance == null) return null;
  return {'projectNumber': ?instance.projectNumber, 'team': ?instance.team};
}

ObjectAccessControl? objectAccessControlFromJson(Map<String, Object?>? json) {
  if (json == null) return null;
  return ObjectAccessControl(
    bucket: json['bucket'] as String?,
    domain: json['domain'] as String?,
    email: json['email'] as String?,
    entity: json['entity'] as String?,
    entityId: json['entityId'] as String?,
    etag: json['etag'] as String?,
    generation:
        json['generation']
            as String?, // ObjectAccessControl.generation is String?
    id: json['id'] as String?,
    kind: json['kind'] as String?,
    object: json['object'] as String?,
    projectTeam: projectTeamFromJson(
      json['projectTeam'] as Map<String, Object?>?,
    ),
    role: json['role'] as String?,
    selfLink: json['selfLink'] == null
        ? null
        : Uri.parse(json['selfLink'] as String),
  );
}

Map<String, Object?>? objectAccessControlToJson(ObjectAccessControl? instance) {
  if (instance == null) return null;
  return {
    'bucket': ?instance.bucket,
    'domain': ?instance.domain,
    'email': ?instance.email,
    'entity': ?instance.entity,
    'entityId': ?instance.entityId,
    'etag': ?instance.etag,
    'generation': ?instance.generation,
    'id': ?instance.id,
    'kind': ?instance.kind,
    'object': ?instance.object,
    'projectTeam': ?projectTeamToJson(instance.projectTeam),
    'role': ?instance.role,
    'selfLink': ?instance.selfLink?.toString(),
  };
}

Timestamp? timestampFromJson(Object? json) {
  if (json == null) return null;
  return Timestamp.fromJson(json);
}

Object? timestampToJson(Timestamp? instance) {
  if (instance == null) return null;
  return instance.toJson();
}

int? int64FromJson(Object? json) {
  if (json == null) return null;
  if (json is String) {
    return int.parse(json);
  }
  if (json is int) {
    return json;
  }
  throw ArgumentError.value(json, 'json', 'Expected String or int for int64');
}

Object? int64ToJson(int? instance) {
  if (instance == null) return null;
  return instance.toString();
}

DateTime? dateFromJson(Object? json) {
  if (json == null) return null;
  if (json is String) {
    return DateTime.parse(json);
  }
  throw ArgumentError.value(json, 'json', 'Expected String for DateTime');
}

String? dateToJson(DateTime? instance) {
  if (instance == null) return null;
  return '${instance.year.toString().padLeft(4, '0')}-'
      '${instance.month.toString().padLeft(2, '0')}-'
      '${instance.day.toString().padLeft(2, '0')}';
}
