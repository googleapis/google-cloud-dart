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
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'crc32c.dart';

Map<String, String> _parseHashes(List<String> hashes) {
  final result = <String, String>{};
  for (final hash in hashes) {
    final equalsIndex = hash.indexOf('=');
    if (equalsIndex == -1) {
      throw FormatException('Invalid hash format: $hash');
    }
    result[hash.substring(0, equalsIndex)] = hash.substring(equalsIndex + 1);
  }
  return result;
}

Future<Uint8List> downloadFile(
  http.Client client,
  String bucket,
  String object,
  BigInt? generation,
  BigInt? ifGenerationMatch,
  BigInt? ifMetagenerationMatch,
  String? userProject,
) async {
  final url = Uri(
    scheme: 'https',
    host: 'storage.googleapis.com',
    pathSegments: ['storage', 'v1', 'b', bucket, 'o', object],
    queryParameters: {
      'alt': 'media',
      'generation': ?generation?.toString(),
      'ifGenerationMatch': ?ifGenerationMatch?.toString(),
      'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
      'userProject': ?userProject,
    },
  );

  final response = await client.get(url, headers: {'Accept-Encoding': 'gzip'});
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ServiceException.fromHttpResponse(response, response.body);
  }

  final data = response.bodyBytes;

  // The computed content hashes (returned in the `x-goog-hash` header) are
  // based on the hash of the content at rest in storage (returned in the
  // `x-goog-stored-content-encoding` header).
  //
  // `http.Client` automatically decompresses gzip encoded responses and
  // doesn't provide any way to access to original response body.
  //
  // The "x-goog-hash" header is a comma separated list of hash values.
  // Example: "crc32c=/mzx3A==,md5=7Qdih1MuhjZehB6Sv8UNjA=="
  //
  // For now, checksum validation is only performed for content that is not
  // compressed in storage.
  final hashes = response.headersSplitValues['x-goog-hash'] ?? [];
  final parsedHashes = _parseHashes(hashes);

  final storedContentEncoding =
      response.headers['x-goog-stored-content-encoding'];

  if (storedContentEncoding == null || storedContentEncoding == 'identity') {
    final crc32c = parsedHashes['crc32c'];
    if (crc32c != null) {
      final calculatedCrc32c = Crc32c()..update(data);
      if (calculatedCrc32c.toBase64() != crc32c) {
        throw ChecksumValidationException(
          'header crc32c value "$crc32c" is different from calculated value '
          '"${calculatedCrc32c.toBase64()}"',
        );
      }
    }
    final md5 = parsedHashes['md5'];
    if (parsedHashes['md5'] case final md5?) {
      final calculatedMd5 = base64Encode(crypto.md5.convert(data).bytes);
      if (calculatedMd5 != md5) {
        throw ChecksumValidationException(
          'header md5 value "$md5" is different from calculated value '
          '"$calculatedMd5"',
        );
      }
    }
  }
  return data;
}
