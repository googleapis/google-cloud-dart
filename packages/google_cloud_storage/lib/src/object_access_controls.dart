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

import 'package:google_cloud_rpc/exceptions.dart';

/// The viewers, editors, or owners of a given project.
///
/// See [Cloud Storage &gt; Guides &gt; Projects](https://docs.cloud.google.com/storage/docs/projects)
final class ProjectTeam {
  /// The automatically generated unique identifier for the project.
  final String? projectNumber;

  /// The team.
  ///
  /// The value *must* be one of `"editors"`, `"owners"`, or `"viewers"`.
  final String? team;

  ProjectTeam({this.projectNumber, this.team});

  @override
  String toString() =>
      'ProjectTeam(projectNumber: $projectNumber, team: $team)';

  /// Creates a new [ProjectTeam] with the given property values.
  ///
  /// If an argument is omitted or `null`, the value of the property in this
  /// team is used.
  ProjectTeam copyWith({String? projectNumber, String? team}) => ProjectTeam(
    projectNumber: projectNumber ?? this.projectNumber,
    team: team ?? this.team,
  );

  /// Creates a new [ProjectTeam] with the given fields set to `null`.
  ProjectTeam copyWithout({bool projectNumber = false, bool team = false}) =>
      ProjectTeam(
        projectNumber: projectNumber ? null : this.projectNumber,
        team: team ? null : this.team,
      );
}

/// An Access Control List (ACL) for objects within Cloud Storage.
///
/// ACLs let you specify who has access to your data and to what extent.
///
/// [!IMPORTANT]
/// The methods that modify ACLs for this object will fail with
/// [BadRequestException] for buckets with uniform bucket-level access enabled.
/// Use `storage.buckets.getIamPolicy` and `storage.buckets.setIamPolicy` to
/// control access instead.
///
/// There are two roles that can be assigned to an object:
/// 1. `READER` can get an object, though the `acl` property will not be
///    revealed.
/// 2. `OWNER` are `READER`s, and they can get the `acl` property, update the
///    object's metadata, and call all [ObjectAccessControl]-related methods on
///    the object. The owner of an object is always an `OWNER`.
///
/// For more information, see
/// [Access Control](https://docs.cloud.google.com/storage/docs/access-control),
/// with the caveat that this API uses `READER` and `OWNER` instead of `READ`
/// and `FULL_CONTROL`.
///
/// See [ObjectAccessControls](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls).
final class ObjectAccessControl {
  /// The name of the bucket that the access control applies to.
  final String? bucket;

  /// The domain associated with the entity, if any.
  final String? domain;

  /// The email address associated with the entity, if any.
  final String? email;

  /// The entity holding the permission.
  ///
  /// Must be either a tag followed by a dash and a value, or one of the
  /// non-parameterized tag.
  ///
  /// - `user-<email address>`
  /// - `group-<group id>`
  /// - `group-<email address>`
  /// - `domain-<domain>`
  /// - `project-team-<project id>`
  /// - `allUsers`
  /// - `allAuthenticatedUsers`
  ///
  /// For example:
  /// - The user `liz@example.com` would be `"user-liz@example.com"`.
  /// - The group `example@googlegroups.com` would be
  ///   `"group-example@googlegroups.com"`.
  /// - To refer to all members of the domain `example.com`, the entity would
  ///   be `"domain-example.com"`.
  final String? entity;

  /// The ID for the entity, if any.
  final String? entityId;

  /// [HTTP 1.1 Entity tag](https://tools.ietf.org/html/rfc7232#section-2.3)
  /// for the access-control entry.
  final String? etag;

  /// The content generation of the object.
  ///
  /// Used for
  /// [object versioning](https://docs.cloud.google.com/storage/docs/object-versioning)
  /// and [soft delete](https://cloud.google.com/storage/docs/soft-delete).
  final String? generation;

  /// The ID of this access-control entry.
  final String? id;

  /// The kind of item this is. For object access control entries, this is
  /// always `"storage#objectAccessControl"`.
  final String? kind;

  /// The name of the object, if applied to an object.
  final String? object;

  /// The project team associated with the entity, if any.
  final ProjectTeam? projectTeam;

  /// The access permission for the entity.
  ///
  /// Acceptable values are `"OWNER"` and `"READER"`.
  final String? role;

  /// The link to this access-control resource.
  final Uri? selfLink;

  ObjectAccessControl({
    this.bucket,
    this.domain,
    this.email,
    this.entity,
    this.entityId,
    this.etag,
    this.generation,
    this.id,
    this.kind,
    this.object,
    this.projectTeam,
    this.role,
    this.selfLink,
  });

  @override
  String toString() =>
      'ObjectAccessControl(bucket: $bucket, domain: $domain, email: $email, '
      'entity: $entity, entityId: $entityId, etag: $etag, '
      'generation: $generation, id: $id, kind: $kind, object: $object, '
      'projectTeam: $projectTeam, role: $role, selfLink: $selfLink)';

  /// Creates a new [ObjectAccessControl] with the given non-`null` fields
  /// replaced.
  ObjectAccessControl copyWith({
    String? bucket,
    String? domain,
    String? email,
    String? entity,
    String? entityId,
    String? etag,
    String? generation,
    String? id,
    String? kind,
    String? object,
    ProjectTeam? projectTeam,
    String? role,
    Uri? selfLink,
  }) => ObjectAccessControl(
    bucket: bucket ?? this.bucket,
    domain: domain ?? this.domain,
    email: email ?? this.email,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    etag: etag ?? this.etag,
    generation: generation ?? this.generation,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    object: object ?? this.object,
    projectTeam: projectTeam ?? this.projectTeam,
    role: role ?? this.role,
    selfLink: selfLink ?? this.selfLink,
  );

  /// Creates a new [ObjectAccessControl] with the given fields set to `null`.
  ObjectAccessControl copyWithout({
    bool bucket = false,
    bool domain = false,
    bool email = false,
    bool entity = false,
    bool entityId = false,
    bool etag = false,
    bool generation = false,
    bool id = false,
    bool kind = false,
    bool object = false,
    bool projectTeam = false,
    bool role = false,
    bool selfLink = false,
  }) => ObjectAccessControl(
    bucket: bucket ? null : this.bucket,
    domain: domain ? null : this.domain,
    email: email ? null : this.email,
    entity: entity ? null : this.entity,
    entityId: entityId ? null : this.entityId,
    etag: etag ? null : this.etag,
    generation: generation ? null : this.generation,
    id: id ? null : this.id,
    kind: kind ? null : this.kind,
    object: object ? null : this.object,
    projectTeam: projectTeam ? null : this.projectTeam,
    role: role ? null : this.role,
    selfLink: selfLink ? null : this.selfLink,
  );
}
