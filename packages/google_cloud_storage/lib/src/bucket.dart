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
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'retry.dart';

Bucket create({
  required String name,
  required StorageService storageService,
  Uri? selfLink,
  int? metaGeneration,
  String? location,
  String? locationType,
  DateTime? timeCreated,
}) => Bucket._(
  name: name,
  storageService: storageService,
  selfLink: selfLink,
  metaGeneration: metaGeneration,
  location: location,
  locationType: locationType,
  timeCreated: timeCreated,
);

Bucket fromJson(Map<String, dynamic> json, StorageService storageService) =>
    Bucket._(
      name: json['name'] as String,
      storageService: storageService,
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

final class Bucket {
  final String name;
  final StorageService storageService;
  final Uri? selfLink;
  final int? metaGeneration;
  final String? location;
  final String? locationType;
  final DateTime? timeCreated;

  Bucket._({
    required this.name,
    required this.storageService,
    this.selfLink,
    this.metaGeneration,
    this.location,
    this.locationType,
    this.timeCreated,
  });

  Future<void> delete() async {
    await storageService.deleteBucket(bucketName: name);
  }

  @override
  String toString() => 'Bucket(name: $name)';
}
