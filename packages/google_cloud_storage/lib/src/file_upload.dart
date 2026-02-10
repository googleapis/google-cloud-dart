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

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:google_cloud_rpc/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'bucket_metadata.dart';
import 'common_json.dart';
import 'crc32c.dart';
import 'object_metadata.dart';
import 'object_metadata_json.dart';

final _random = Random.secure();

/// A subset of the acceptable boundary characters as defined in Appendix A of
/// RFC 2046.
///
/// See https://datatracker.ietf.org/doc/html/rfc2046
const _boundaryChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// The boundary string to use when seperating parts of a multipart request.
///
/// If `null` then the boundary string will be generated randomly. Setting this
/// to a fixed value is useful for testing because it results in a deterministic
/// request body.
@visibleForTesting
String? fixedBoundaryString;

String _boundaryString() {
  if (fixedBoundaryString case final boundary?) return boundary;

  // A boundary string has a maximum length of 70 characters.
  // See https://datatracker.ietf.org/doc/html/rfc2046#section-5.1
  var prefix = 'http-boundary-';
  var list = List<String>.generate(
    70 - prefix.length,
    (index) => _boundaryChars[_random.nextInt(_boundaryChars.length)],
    growable: false,
  );
  return '$prefix${list.join()}';
}

/// Upload the given content as a Google Cloud Storage object using the
/// non-streaming, non-resumeable upload approach.
///
/// See [Upload an object to a bucket](https://docs.cloud.google.com/storage/docs/uploading-objects#uploading-an-object)
Future<ObjectMetadata> uploadFile(
  http.Client client,
  String projectId,
  String bucket,
  String object,
  List<int> data, {
  ObjectMetadata? metadata,
  int? ifGenerationMatch,
  String? predefinedAcl,
  String? projection,
  String? userProject,
}) async {
  final url =
      Uri.https('storage.googleapis.com', '/upload/storage/v1/b/$bucket/o', {
        'uploadType': 'multipart',
        'name': object,
        'project': projectId,
        'ifGenerationMatch': ?ifGenerationMatch?.toString(),
        'predefinedAcl': ?predefinedAcl,
        'projection': ?projection,
        'userProject': ?userProject,
      });

  final boundary = _boundaryString();

  final metadataJson = metadata == null
      ? <String, Object?>{}
      : objectMetadataToJson(metadata);

  if (metadata?.crc32c == null) {
    final crc32c = Crc32c()..update(data);
    metadataJson['crc32c'] = crc32c.toBase64();
  }
  if (metadata?.md5Hash == null) {
    metadataJson['md5Hash'] = base64Encode(crypto.md5.convert(data).bytes);
  }
  final contentType = metadata?.contentType ?? 'application/octet-stream';

  final multipartBody = BytesBuilder(copy: false);
  final metadataPart = utf8.encode(
    '--$boundary\r\n'
    'Content-Type: application/json; charset=UTF-8\r\n'
    '\r\n'
    '${jsonEncode(metadataJson)}\r\n'
    '--$boundary\r\n'
    'Content-Type: $contentType\r\n'
    '\r\n',
  );
  multipartBody
    ..add(metadataPart)
    ..add(data)
    ..add(utf8.encode('\r\n--$boundary--\r\n'));

  final bodyBytes = multipartBody.takeBytes();

  final request = http.Request('POST', url);
  request.headers['Content-Type'] = 'multipart/related; boundary=$boundary';
  request.headers['Content-Length'] = bodyBytes.length.toString();
  request.bodyBytes = bodyBytes;

  final response = await client.send(request);
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ServiceException.fromHttpResponse(response, responseBody);
  }

  return objectMetadataFromJson(
    jsonDecode(responseBody) as Map<String, Object?>,
  );
}
