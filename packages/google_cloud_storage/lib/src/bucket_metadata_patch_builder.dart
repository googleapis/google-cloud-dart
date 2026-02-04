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
import 'package:meta/meta.dart';

import '../google_cloud_storage.dart';
import 'bucket_metadata_json.dart';

@internal
class BucketMetadataPatchBuilderJsonEncodable implements JsonEncodable {
  final BucketMetadataPatchBuilder _builder;

  BucketMetadataPatchBuilderJsonEncodable(this._builder);

  @override
  Object? toJson() => _builder._json;
}

/// A set of fields to update on a [Cloud Storage bucket].
///
/// Fields explicitly set to `null` are cleared.
///
/// For detailed information on the meaning of each field, see
/// [Bucket resource](https://docs.cloud.google.com/storage/docs/json_api/v1/buckets#resource).
///
/// [Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
final class BucketMetadataPatchBuilder {
  // Keep field documentation in sync with [BucketMetadata].
  final _json = <String, Object?>{};

  /// Access controls on the bucket.
  set acl(List<BucketAccessControl>? value) {
    _json['acl'] = value?.map(bucketAccessControlToJson).toList();
  }

  /// The bucket's [Autoclass][] configuration.
  ///
  /// [Autoclass]: https://docs.cloud.google.com/storage/docs/autoclass
  set autoclass(BucketAutoclass? value) {
    _json['autoclass'] = bucketAutoclassToJson(value);
  }

  /// The bucket's [Cross-Origin Resource Sharing (CORS)][] configuration.
  ///
  /// [Cross-Origin Resource Sharing (CORS)]: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
  set cors(List<BucketCorsConfiguration>? value) {
    _json['cors'] = value?.map(bucketCorsConfigurationToJson).toList();
  }

  /// The bucket's [hierarchical namespace][] configuration.
  ///
  /// [hierarchical namespace]: https://docs.cloud.google.com/storage/docs/hns-overview
  set hierarchicalNamespace(BucketHierarchicalNamespace? value) {
    _json['hierarchicalNamespace'] = bucketHierarchicalNamespaceToJson(value);
  }

  /// The bucket's [IP filter][] configuration.
  ///
  /// [IP filter]: https://docs.cloud.google.com/storage/docs/ip-filtering-overview
  set ipFilter(BucketIpFilter? value) {
    _json['ipFilter'] = bucketIpFilterToJson(value);
  }

  /// User-provided labels, in key/value pairs.
  set labels(Map<String, String>? value) {
    _json['labels'] = value;
  }

  /// The bucket's [lifecycle][] configuration.
  ///
  /// [lifecycle]: https://docs.cloud.google.com/storage/docs/lifecycle
  set lifecycle(Lifecycle? value) {
    _json['lifecycle'] = lifecycleToJson(value);
  }

  /// The bucket's logging configuration.
  set logging(BucketLoggingConfiguration? value) {
    _json['logging'] = bucketLoggingConfigurationToJson(value);
  }

  /// The bucket's [object retention configuration][].
  ///
  /// [object retention configuration]: https://docs.cloud.google.com/storage/docs/object-lock
  set retentionPolicy(BucketRetentionPolicy? value) {
    _json['retentionPolicy'] = bucketRetentionPolicyToJson(value);
  }

  /// The bucket's [soft delete policy][].
  ///
  /// You can [disable soft delete][] by setting
  /// [BucketSoftDeletePolicy.retentionDurationSeconds] to `0`.
  ///
  /// [soft delete policy]: https://docs.cloud.google.com/storage/docs/soft-delete
  /// [disable soft delete]: https://docs.cloud.google.com/storage/docs/disable-soft-delete#disable-soft-delete-on-specific-bucket
  set softDeletePolicy(BucketSoftDeletePolicy value) {
    _json['softDeletePolicy'] = bucketSoftDeletePolicyToJson(value);
  }

  /// The bucket's versioning configuration.
  set versioning(BucketVersioning? value) {
    _json['versioning'] = bucketVersioningToJson(value);
  }

  /// The bucket's website configuration.
  set website(BucketWebsiteConfiguration? value) {
    _json['website'] = bucketWebsiteConfigurationToJson(value);
  }
}
