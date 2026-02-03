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

import '../google_cloud_storage.dart';
import 'bucket_metadata_json.dart';

Map<String, Object?> getJson(BucketMetadataPatchBuilder builder) =>
    builder._json;

final class BucketMetadataPatchBuilder {
  final _json = <String, Object?>{};

  set acl(List<BucketAccessControl>? value) {
    _json['acl'] = value?.map(bucketAccessControlToJson).toList();
  }

  set autoclass(BucketAutoclass? value) {
    _json['autoclass'] = bucketAutoclassToJson(value);
  }

  set cors(List<BucketCorsConfiguration>? value) {
    _json['cors'] = value?.map(bucketCorsConfigurationToJson).toList();
  }

  set hierarchicalNamespace(BucketHierarchicalNamespace? value) {
    _json['hierarchicalNamespace'] = bucketHierarchicalNamespaceToJson(value);
  }

  set name(String? value) {
    _json['name'] = value;
  }
}
