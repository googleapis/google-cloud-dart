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

/// The viewers, editors, or owners of a given project.
///
/// See [Cloud Storage &gt; Guides &gt; Projects][].
///
/// [Cloud Storage &gt; Guides &gt; Projects]: https://docs.cloud.google.com/storage/docs/projects
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

  @override
  bool operator ==(Object other) =>
      other is ProjectTeam &&
      projectNumber == other.projectNumber &&
      team == other.team;

  @override
  int get hashCode => Object.hash(projectNumber, team);
}
