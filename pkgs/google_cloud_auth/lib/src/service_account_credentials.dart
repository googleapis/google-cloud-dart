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

/// Design based on:
/// - https://github.com/googleapis/google-cloud-java/blob/main/google-auth-library-java/oauth2_http/java/com/google/auth/oauth2/ServiceAccountCredentials.java
/// - https://github.com/googleapis/google-cloud-python/blob/main/packages/google-auth/google/oauth2/service_account.py
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:webcrypto/webcrypto.dart';

import 'access_token.dart';
import 'credential_exception.dart';
import 'google_credentials.dart';
import 'json_utils.dart';
import 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
import 'service_account_signer.dart';

const _infoDescription = 'service account info';

/// The OAuth 2.0 scopes requested when none are specified.
const _defaultScopes = ['https://www.googleapis.com/auth/cloud-platform'];

/// The `grant_type` used to exchange a signed JWT for an access token.
///
/// See [RFC 7523 §2.1](https://datatracker.ietf.org/doc/html/rfc7523#section-2.1).
const _jwtBearerGrantType = 'urn:ietf:params:oauth:grant-type:jwt-bearer';

/// The `aud` claim of JWTs exchanged for access tokens.
///
/// Like the Java and Python libraries, this is used even when
/// [ServiceAccountCredentials.tokenUri] is customized.
const _oauth2TokenAudience = 'https://oauth2.googleapis.com/token';

/// The lifetime of the JWTs signed by [ServiceAccountCredentials].
///
/// [AIP-4111](https://google.aip.dev/auth/4111) requires that self-signed JWTs
/// expire exactly one hour after they are issued.
const _jwtLifetime = Duration(hours: 1);

Uint8List _parsePemPkcs8Key(String pemString) {
  final lines = LineSplitter.split(pemString)
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('-----'))
      .join();
  try {
    return Uint8List.fromList(base64.decode(lines));
  } on FormatException catch (e) {
    throw FormatException('Invalid PEM encoding in private key: $e');
  }
}

/// Encodes [bytes] as unpadded base64url, as used in JWS segments.
///
/// See [RFC 7515 §2](https://datatracker.ietf.org/doc/html/rfc7515#section-2).
String _base64UrlUnpadded(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

/// Credentials for a Google Cloud service account.
///
/// Service accounts are used for server-to-server communication, such as
/// interactions between a web application server and a Google service.
final class ServiceAccountCredentials extends GoogleCredentials
    implements ServiceAccountSigner {
  /// The email address of the service account.
  @override
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

  /// The OAuth 2.0 scopes requested by [accessToken].
  ///
  /// See [OAuth 2.0 Scopes for Google APIs](https://developers.google.com/identity/protocols/oauth2/scopes).
  final List<String> scopes;

  final RsassaPkcs1V15PrivateKey _privateKey;
  final FutureOr<http.Client> Function() _clientFactory;

  late final _accessTokenCache = AccessTokenCache(_fetchAccessToken);

  ServiceAccountCredentials._({
    required this.clientEmail,
    required RsassaPkcs1V15PrivateKey privateKey,
    this.clientId,
    this.privateKeyId,
    this.projectId,
    this.quotaProjectId,
    Uri? tokenUri,
    List<String>? scopes,
    FutureOr<http.Client> Function()? clientFactory,
    super.universeDomain = GoogleCredentials.defaultUniverseDomain,
  }) : _privateKey = privateKey,
       tokenUri = tokenUri ?? Uri.https('oauth2.$universeDomain', '/token'),
       scopes = List.unmodifiable(scopes ?? _defaultScopes),
       _clientFactory = clientFactory ?? http.Client.new;

  /// Creates a [ServiceAccountCredentials] instance from a service account
  /// JSON file at [path].
  ///
  /// [scopes] are the OAuth 2.0 scopes requested by [accessToken]. If omitted,
  /// `https://www.googleapis.com/auth/cloud-platform` is requested.
  ///
  /// If provided, [clientFactory] is called to create the [http.Client]s used
  /// to make requests. Each client it returns is closed after use, so it must
  /// return a new client on every call.
  ///
  /// Throws a [CredentialException] if reading [path] fails or when running on
  /// the web.
  static Future<ServiceAccountCredentials> fromServiceAccountFile(
    String path, {
    List<String>? scopes,
    FutureOr<http.Client> Function()? clientFactory,
  }) async {
    final contents = await readCredentialFileAsString(path);
    return fromServiceAccountString(
      contents,
      scopes: scopes,
      clientFactory: clientFactory,
    );
  }

  /// Creates a [ServiceAccountCredentials] instance from parsed service
  /// account JSON [info].
  ///
  /// [scopes] are the OAuth 2.0 scopes requested by [accessToken]. If omitted,
  /// `https://www.googleapis.com/auth/cloud-platform` is requested.
  ///
  /// If provided, [clientFactory] is called to create the [http.Client]s used
  /// to make requests. Each client it returns is closed after use, so it must
  /// return a new client on every call.
  static Future<ServiceAccountCredentials> fromServiceAccountInfo(
    Map<String, dynamic> info, {
    List<String>? scopes,
    FutureOr<http.Client> Function()? clientFactory,
  }) async {
    final type = info['type'];
    if (type != 'service_account') {
      throw const FormatException(
        "The value of 'type' must be 'service_account'.",
      );
    }

    final clientEmail = requiredString(info, 'client_email', _infoDescription);
    final privateKeyPem = requiredString(info, 'private_key', _infoDescription);
    final privateKeyId = optionalString(info, 'private_key_id');
    final clientId = optionalString(info, 'client_id');
    final projectId = optionalString(info, 'project_id');
    final quotaProjectId = optionalString(info, 'quota_project_id');
    final universeDomain =
        optionalString(info, 'universe_domain') ??
        GoogleCredentials.defaultUniverseDomain;

    final tokenUriStr = optionalString(info, 'token_uri');
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
      scopes: scopes,
      clientFactory: clientFactory,
      universeDomain: universeDomain,
    );
  }

  /// Creates a [ServiceAccountCredentials] instance from a service account
  /// JSON string [jsonString].
  ///
  /// [scopes] are the OAuth 2.0 scopes requested by [accessToken]. If omitted,
  /// `https://www.googleapis.com/auth/cloud-platform` is requested.
  ///
  /// If provided, [clientFactory] is called to create the [http.Client]s used
  /// to make requests. Each client it returns is closed after use, so it must
  /// return a new client on every call.
  static Future<ServiceAccountCredentials> fromServiceAccountString(
    String jsonString, {
    List<String>? scopes,
    FutureOr<http.Client> Function()? clientFactory,
  }) => fromServiceAccountInfo(
    decodeJsonObject(jsonString),
    scopes: scopes,
    clientFactory: clientFactory,
  );

  /// Creates a [ServiceAccountCredentials] instance from a PKCS#8 private key
  /// PEM string.
  ///
  /// [scopes] are the OAuth 2.0 scopes requested by [accessToken]. If omitted,
  /// `https://www.googleapis.com/auth/cloud-platform` is requested.
  ///
  /// If provided, [clientFactory] is called to create the [http.Client]s used
  /// to make requests. Each client it returns is closed after use, so it must
  /// return a new client on every call.
  static Future<ServiceAccountCredentials> fromPkcs8({
    required String clientEmail,
    required String privateKeyPkcs8,
    String? privateKeyId,
    String? clientId,
    String? projectId,
    String? quotaProjectId,
    Uri? tokenUri,
    String universeDomain = GoogleCredentials.defaultUniverseDomain,
    List<String>? scopes,
    FutureOr<http.Client> Function()? clientFactory,
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
      scopes: scopes,
      clientFactory: clientFactory,
      universeDomain: universeDomain,
    );
  }

  /// A non-expired current OAuth2 access token for the service account, with
  /// the requested [scopes].
  ///
  /// In the default universe domain, the token is obtained from [tokenUri] in
  /// exchange for a JWT signed with the private key
  /// ([RFC 7523](https://datatracker.ietf.org/doc/html/rfc7523)). That
  /// exchange is not available in other universe domains, so the token is a
  /// self-signed JWT ([AIP-4111](https://google.aip.dev/auth/4111)) instead.
  ///
  /// If the cached token is expired or if [forceRefresh] is `true`, then a new
  /// token is obtained.
  ///
  /// It is safe to call this method concurrently.
  ///
  /// Throws [CredentialException] on failure.
  Future<String> accessToken({bool forceRefresh = false}) =>
      _accessTokenCache.accessToken(forceRefresh: forceRefresh);

  Future<TokenResponse> _fetchAccessToken() async {
    final issuedAt = DateTime.timestamp().millisecondsSinceEpoch ~/ 1000;
    final claims = {
      'iss': clientEmail,
      'scope': scopes.join(' '),
      // Go's `x/oauth2` and `package:googleapis_path` backdate 'iat' to
      // handle the case where the local clock is ahead of the endpoint's clock.
      // Since Java and Python do not do this, it is likely that endpoint's are
      // tolerant of clock skew.
      'iat': issuedAt,
      'exp': issuedAt + _jwtLifetime.inSeconds,
    };

    if (universeDomain != GoogleCredentials.defaultUniverseDomain) {
      // Token exchange is not available outside of the default universe
      // domain, so APIs there accept self-signed JWTs as access tokens.
      return (
        accessToken: await _signJwt({...claims, 'sub': clientEmail}),
        expiresIn: _jwtLifetime,
      );
    }

    final assertion = await _signJwt({...claims, 'aud': _oauth2TokenAudience});
    return fetchAccessToken(
      clientFactory: _clientFactory,
      source: tokenUri.toString(),
      send: (client) => client.post(
        tokenUri,
        body: {'grant_type': _jwtBearerGrantType, 'assertion': assertion},
      ),
    );
  }

  /// Creates a JWT with [claims], signed using RS256 and the private key.
  ///
  /// See [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519).
  ///
  /// Throws [SigningException] on failure.
  Future<String> _signJwt(Map<String, Object> claims) async {
    final header = {'alg': 'RS256', 'typ': 'JWT', 'kid': ?privateKeyId};
    final signingInput = [header, claims]
        .map((part) => _base64UrlUnpadded(utf8.encode(jsonEncode(part))))
        .join('.');
    final signature = await sign(ascii.encode(signingInput));
    return '$signingInput.${_base64UrlUnpadded(signature)}';
  }

  /// Signs [message] using RSASSA-PKCS1-v1_5 with SHA-256 and the private key.
  ///
  /// Throws [SigningException] on failure.
  @override
  Future<Uint8List> sign(List<int> message) async {
    try {
      return await _privateKey.signBytes(message);
    } on Exception catch (e, stackTrace) {
      throw SigningException(
        'Failed to sign message: $e',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }
  }
}
