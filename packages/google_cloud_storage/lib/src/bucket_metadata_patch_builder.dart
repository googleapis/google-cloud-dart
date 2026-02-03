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
    _json['autoclass'] = value == null ? null : bucketAutoclassToJson(value);
  }

  set cors(List<BucketCorsConfiguration>? value) {
    _json['cors'] = value?.map(bucketCorsConfigurationToJson).toList();
  }
}
