import '../google_cloud_storage.dart';

import 'googleapis_converters.dart';

final class BucketMetadataPatchBuilder {
  final _json = <String, Object?>{};

  set acl(List<BucketAccessControl>? value) {
    _json['acl'] = value
        ?.map((acl) => toBucketAccessControl(acl).toJson())
        .toList();
  }

  set autoclass(BucketAutoclass? value) {
    _json['autoclass'] = value == null ? null : toAutoclass(value).toJson();
  }

  set cors(List<BucketCorsConfiguration>? value) {
    _json['cors'] = value?.map(toCors).toList();
  }
}
