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
import 'common_json.dart';
import 'object_metadata_json.dart';

@internal
class ObjectMetadataPatchBuilderJsonEncodable implements JsonEncodable {
  final ObjectMetadataPatchBuilder _builder;

  ObjectMetadataPatchBuilderJsonEncodable(this._builder);

  @override
  Object? toJson() => _builder._json;
}

/// A set of fields to update on a [Cloud Storage object].
///
/// Fields explicitly set to `null` are cleared.
///
/// For detailed information on the meaning of each field, see
/// [Object resource](https://docs.cloud.google.com/storage/docs/json_api/v1/objects#resource).
///
/// [Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
final class ObjectMetadataPatchBuilder {
  // Keep field documentation in sync with [ObjectMetadata].
  final _json = <String, Object?>{};

  /// Access controls on the object.
  set acl(List<ObjectAccessControl>? value) {
    _json['acl'] = value?.map(objectAccessControlToJson).toList();
  }

  /// Cache-Control directive for the object data.
  ///
  /// If omitted, and the object is accessible to all anonymous users, the
  /// default will be `"public, max-age=3600"`.
  set cacheControl(String? value) {
    _json['cacheControl'] = value;
  }

  /// Content-Disposition of the object data.
  set contentDisposition(String? value) {
    _json['contentDisposition'] = value;
  }

  /// Content-Encoding of the object data.
  set contentEncoding(String? value) {
    _json['contentEncoding'] = value;
  }

  /// Content-Language of the object data.
  set contentLanguage(String? value) {
    _json['contentLanguage'] = value;
  }

  /// Content-Type of the object data. If an object is stored without a
  /// Content-Type, it is served as `application/octet-stream`.
  set contentType(String? value) {
    _json['contentType'] = value;
  }

  /// A timestamp specified by the user for an object.
  set customTime(Timestamp? value) {
    _json['customTime'] = timestampToJson(value);
  }

  /// Whether an object is under event-based hold.
  ///
  /// Event-based hold is a way to retain objects until an event occurs, which
  /// is signified by the hold's release (i.e. this value is set to false).
  ///
  /// After being released (set to false), such objects will be subject to
  /// bucket-level retention (if any).
  ///
  /// One sample use case of this flag is for banks to hold loan documents for
  /// at least 3 years after loan is paid in full. Here, bucket-level retention
  /// is 3 years and the event is the loan being paid in full. In this example,
  /// these objects will be held intact for any number of years until the event
  /// has occurred (event-based hold on the object is released) and then 3 more
  /// years after that. That means retention duration of the objects begins from
  /// the moment event-based hold transitioned from true to false.
  set eventBasedHold(bool? value) {
    _json['eventBasedHold'] = value;
  }

  /// User-provided metadata, in key/value pairs.
  set metadata(Map<String, String>? value) {
    _json['metadata'] = value;
  }

  /// The object's [retention configuration][].
  ///
  /// This defines the earliest datetime that the object can be deleted or
  /// replaced.
  ///
  /// [retention configuration]: https://docs.cloud.google.com/storage/docs/object-lock
  set retention(ObjectRetention? value) {
    _json['retention'] = objectRetentionToJson(value);
  }

  /// Storage class of the object.
  set storageClass(String? value) {
    _json['storageClass'] = value;
  }

  /// Whether an object is under temporary hold.
  set temporaryHold(bool? value) {
    _json['temporaryHold'] = value;
  }
}
