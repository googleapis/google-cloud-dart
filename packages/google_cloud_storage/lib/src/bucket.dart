// Copyright 2025 Google LLC
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

class Bucket implements JsonEncodable {
  final String name;
  final Uri? selfLink;
  final int? metaGeneration;
  final String? location;
  final String? locationType;
  final DateTime? timeCreated;

  Bucket({
    required this.name,
    this.selfLink,
    this.metaGeneration,
    this.location,
    this.locationType,
    this.timeCreated,
  });

  factory Bucket.fromJson(Map<String, dynamic> json) => Bucket(
    name: json['name'] as String,
    selfLink: Uri.parse(json['selfLink'] as String),
    metaGeneration: switch (json['metageneration']) {
      String s => int.parse(s),
      int i => i,
      _ => throw const FormatException('"metageneration" format incorrect'),
    },
    location: json['location'] as String,
    locationType: json['locationType'] as String,
    timeCreated: Timestamp.fromJson(json['timeCreated']).toDateTime(),
  );

  @override
  Map<String, dynamic> toJson() => {'name': name};

  @override
  String toString() => 'Bucket(name: $name)';
}
