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
import 'dart:io';
import 'dart:typed_data';

import 'package:webcrypto/webcrypto.dart';

/// Credentials for a Google Cloud service account.
///
/// Service accounts are used for server-to-server communication, such as
/// interactions between a web application server and a Google service.
final class ServiceAccountCredentials {
  /// The email address of the service account.
  final String clientEmail;

  /// The unique identifier of the service account client, if available.
  final String? clientId;

  /// The identifier of the private key, if available.
  final String? privateKeyId;

  /// The Google Cloud project ID associated with the service account,
  /// if available.
  final String? projectId;

  /// The quota project ID associated with the service account, if available.
  final String? quotaProjectId;

  /// The OAuth2 token endpoint URI.
  final Uri tokenUri;

  /// The universe domain for the service account.
  final String universeDomain;

  final RsassaPkcs1V15PrivateKey _privateKey;

  ServiceAccountCredentials._({
    required this.clientEmail,
    required RsassaPkcs1V15PrivateKey privateKey,
    this.clientId,
    this.privateKeyId,
    this.projectId,
    this.quotaProjectId,
    Uri? tokenUri,
    this.universeDomain = 'googleapis.com',
  }) : _privateKey = privateKey,
       tokenUri = tokenUri ?? Uri.parse('https://oauth2.googleapis.com/token');

  /// Creates a [ServiceAccountCredentials] instance from a service account
  /// JSON file at [path].
  static Future<ServiceAccountCredentials> fromServiceAccountFile(
    String path,
  ) async {
    final file = File(path);
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    if (json is! Map<String, Object?> && json is! Map<String, dynamic>) {
      throw const FormatException(
        'Service account file does not contain a JSON object.',
      );
    }
    return fromServiceAccountInfo((json as Map).cast<String, Object?>());
  }

  /// Creates a [ServiceAccountCredentials] instance from parsed service
  /// account JSON [info].
  static Future<ServiceAccountCredentials> fromServiceAccountInfo(
    Map<String, Object?> info,
  ) async {
    final type = info['type'] as String?;
    if (type != 'service_account') {
      throw const FormatException(
        "The service account info does not have the 'service_account' type.",
      );
    }

    final clientEmail = info['client_email'] as String?;
    if (clientEmail == null || clientEmail.isEmpty) {
      throw const FormatException(
        "Missing required 'client_email' in service account info.",
      );
    }

    final privateKeyPem = info['private_key'] as String?;
    if (privateKeyPem == null || privateKeyPem.isEmpty) {
      throw const FormatException(
        "Missing required 'private_key' in service account info.",
      );
    }

    final privateKeyId = info['private_key_id'] as String?;
    final clientId = info['client_id'] as String?;
    final projectId = info['project_id'] as String?;
    final quotaProjectId = info['quota_project_id'] as String?;
    final universeDomain =
        info['universe_domain'] as String? ?? 'googleapis.com';

    final tokenUriStr = info['token_uri'] as String?;
    final tokenUri = tokenUriStr != null ? Uri.parse(tokenUriStr) : null;

    final pkcs8Bytes = _parsePemPkcs8Key(privateKeyPem);
    final privateKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
      pkcs8Bytes,
      Hash.sha256,
    );

    return ServiceAccountCredentials._(
      clientEmail: clientEmail,
      privateKey: privateKey,
      clientId: clientId,
      privateKeyId: privateKeyId,
      projectId: projectId,
      quotaProjectId: quotaProjectId,
      tokenUri: tokenUri,
      universeDomain: universeDomain,
    );
  }

  /// Creates a [ServiceAccountCredentials] instance from a service account
  /// JSON string [jsonString].
  static Future<ServiceAccountCredentials> fromServiceAccountString(
    String jsonString,
  ) async {
    final json = jsonDecode(jsonString);
    if (json is! Map<String, Object?> && json is! Map<String, dynamic>) {
      throw const FormatException(
        'Service account string does not contain a JSON object.',
      );
    }
    return fromServiceAccountInfo((json as Map).cast<String, Object?>());
  }

  /// Creates a [ServiceAccountCredentials] instance from PKCS#8 private key
  /// PEM string.
  static Future<ServiceAccountCredentials> fromPkcs8({
    required String clientEmail,
    required String privateKeyPkcs8,
    String? privateKeyId,
    String? clientId,
    String? projectId,
    String? quotaProjectId,
    Uri? tokenUri,
    String universeDomain = 'googleapis.com',
  }) async {
    final pkcs8Bytes = _parsePemPkcs8Key(privateKeyPkcs8);
    final privateKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
      pkcs8Bytes,
      Hash.sha256,
    );

    return ServiceAccountCredentials._(
      clientEmail: clientEmail,
      privateKey: privateKey,
      clientId: clientId,
      privateKeyId: privateKeyId,
      projectId: projectId,
      quotaProjectId: quotaProjectId,
      tokenUri: tokenUri,
      universeDomain: universeDomain,
    );
  }

  /// The email address of the service account used for signing.
  String get signerEmail => clientEmail;

  /// The email address of the service account.
  String get serviceAccountEmail => clientEmail;

  /// Signs [message] using RSASSA-PKCS1-v1_5 with SHA-256 and the private key.
  Future<Uint8List> sign(List<int> message) => _privateKey.signBytes(message);
}

Uint8List _parsePemPkcs8Key(String pemString) {
  final lines = pemString
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('-----'))
      .join();
  try {
    return Uint8List.fromList(base64.decode(lines));
  } on FormatException catch (e) {
    throw FormatException('Invalid PEM encoding in private key: $e');
  }
}
