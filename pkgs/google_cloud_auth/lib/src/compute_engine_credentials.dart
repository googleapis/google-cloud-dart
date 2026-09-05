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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'credential_exception.dart';
import 'service_account_signer.dart';

// Design based on:
// - https://github.com/googleapis/google-auth-library-java/blob/main/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java
// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/compute_engine/credentials.py
// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/iam.py

/// Credentials for Google Compute Engine, Cloud Run, Cloud Functions, and
/// other environments providing a Google Cloud metadata server.
final class ComputeEngineCredentials implements ServiceAccountSigner {
  static const _defaultMetadataHost = 'metadata.google.internal';
  static const _metadataFlavorHeader = {'Metadata-Flavor': 'Google'};
  static const _retryableStatusCodes = {500, 502, 503, 504};

  /// The email address of the service account.
  @override
  final String clientEmail;

  /// The universe domain for the service account.
  final String universeDomain;

  /// The metadata server host.
  final String metadataHost;

  final http.Client _client;
  final bool _ownsClient;

  String? _cachedAccessToken;
  DateTime? _accessTokenExpiry;

  /// The active request to fetch a new token.
  ///
  /// This is used to prevent multiple concurrent requests from fetching new
  /// tokens at the same time.
  Future<String>? _activeTokenRequest;

  ComputeEngineCredentials._({
    required this.clientEmail,
    required this.universeDomain,
    required this.metadataHost,
    required http.Client client,
    required bool ownsClient,
  }) : _client = client,
       _ownsClient = ownsClient;

  /// A non-expired current OAuth2 access token for the service account.
  ///
  /// If the cached token is expired or if [forceRefresh] is `true`, then a new
  /// token is fetched.
  ///
  /// It is safe to call this method concurrently.
  ///
  /// Throws [CredentialException] on failure.
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedAccessToken != null &&
        _accessTokenExpiry != null) {
      if (DateTime.now().isBefore(
        _accessTokenExpiry!.subtract(const Duration(minutes: 1)),
      )) {
        return _cachedAccessToken!;
      }
    }

    return await (_activeTokenRequest ??= _fetchAccessToken().whenComplete(() {
      _activeTokenRequest = null;
    }));
  }

  Future<String> _fetchAccessToken() async {
    final tokenUri = Uri.http(
      metadataHost,
      '/computeMetadata/v1/instance/service-accounts/default/token',
    );
    final http.Response response;
    try {
      response = await _client.get(tokenUri, headers: _metadataFlavorHeader);
    } on Exception catch (e, stackTrace) {
      throw CredentialException(
        'Failed to get access token from Compute Engine metadata server: $e',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }

    if (response.statusCode != 200) {
      throw CredentialException(
        'Failed to get access token from Compute Engine metadata server: '
        'HTTP ${response.statusCode} ${response.body}',
      );
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = json['access_token'];
      final expiresIn = json['expires_in'];
      if (accessToken is! String || expiresIn is! int) {
        throw const FormatException('Missing access_token or expires_in');
      }
      _cachedAccessToken = accessToken;
      _accessTokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
      return accessToken;
    } on FormatException catch (e, stackTrace) {
      throw CredentialException(
        'Failed to parse token response from metadata server: $e',
        innerException: e,
        innerStackTrace: stackTrace,
      );
    }
  }

  /// Creates a [ComputeEngineCredentials] instance, discovering configuration
  /// from the Compute Engine metadata server.
  ///
  /// Throws [CredentialException] on failure.
  static Future<ComputeEngineCredentials> create({
    http.Client? client,
    String? clientEmail,
    String? universeDomain,
    String? metadataHost,
  }) async {
    final host =
        metadataHost ??
        Platform.environment['GCE_METADATA_HOST'] ??
        _defaultMetadataHost;
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      var resolvedEmail = clientEmail;
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        final emailUri = Uri.http(
          host,
          '/computeMetadata/v1/instance/service-accounts/default/email',
        );
        final http.Response response;
        try {
          response = await httpClient.get(
            emailUri,
            headers: _metadataFlavorHeader,
          );
        } on Exception catch (e, stackTrace) {
          throw CredentialException(
            'Failed to get default service account email from metadata server: '
            '$e',
            innerException: e,
            innerStackTrace: stackTrace,
          );
        }
        if (response.statusCode != 200) {
          throw CredentialException(
            'Failed to get default service account email from metadata server: '
            'HTTP ${response.statusCode} ${response.body}',
          );
        }
        resolvedEmail = response.body.trim();
        if (resolvedEmail.isEmpty) {
          throw CredentialException(
            'Empty service account email received from metadata server.',
          );
        }
      }

      var resolvedUniverseDomain = universeDomain;
      if (resolvedUniverseDomain == null || resolvedUniverseDomain.isEmpty) {
        final universeUri = Uri.http(
          host,
          '/computeMetadata/v1/universe/universe-domain',
        );
        final http.Response response;
        try {
          response = await httpClient.get(
            universeUri,
            headers: _metadataFlavorHeader,
          );
        } on Exception catch (e, stackTrace) {
          throw CredentialException(
            'Failed to get universe domain from metadata server: $e',
            innerException: e,
            innerStackTrace: stackTrace,
          );
        }
        // 404 indicates an older metadata server without universe-domain
        // support, and early versions returned an empty string for the default
        // universe; both default to 'googleapis.com'.
        // See:
        // https://github.com/googleapis/google-auth-library-java/blob/9ac2d4340ebc6a8582b898e97f65aeed3c1776d6/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java#L282
        if (response.statusCode == 200) {
          final trimmed = response.body.trim();
          resolvedUniverseDomain = trimmed.isNotEmpty
              ? trimmed
              : 'googleapis.com';
        } else if (response.statusCode == 404) {
          resolvedUniverseDomain = 'googleapis.com';
        } else {
          throw CredentialException(
            'Failed to get universe domain from metadata server: '
            'HTTP ${response.statusCode} ${response.body}',
          );
        }
      }

      return ComputeEngineCredentials._(
        clientEmail: resolvedEmail,
        universeDomain: resolvedUniverseDomain,
        metadataHost: host,
        client: httpClient,
        ownsClient: ownsClient,
      );
    } catch (e) {
      if (ownsClient) {
        httpClient.close();
      }
      rethrow;
    }
  }

  // Equivalent of:
  // - https://github.com/googleapis/google-auth-library-java/blob/9ac2d4340ebc6a8582b898e97f65aeed3c1776d6/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java#L595-L613
  // - https://github.com/googleapis/google-auth-library-python/blob/2ea24b03436765fa3cf279ce148482ff6332136b/google/auth/compute_engine/_metadata.py#L122-L144
  /// Checks if the application is running in an environment with an accessible
  /// Compute Engine metadata server.
  static Future<bool> isOnComputeEngine({
    http.Client? client,
    String? metadataHost,
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    if (Platform.environment['NO_GCE_CHECK']?.toLowerCase() == 'true') {
      return false;
    }

    final host =
        metadataHost ??
        Platform.environment['GCE_METADATA_HOST'] ??
        _defaultMetadataHost;
    final httpClient = client ?? http.Client();
    final closeClient = client == null;

    try {
      final response = await httpClient
          .get(
            Uri.http(host, '/computeMetadata/v1/'),
            headers: _metadataFlavorHeader,
          )
          .timeout(timeout);
      final flavorHeader = response.headers['metadata-flavor'];
      return response.statusCode == 200 &&
          flavorHeader != null &&
          flavorHeader.toLowerCase() == 'google';
    } catch (_) {
      return false;
    } finally {
      if (closeClient) {
        httpClient.close();
      }
    }
  }

  /// Signs [message] using the Identity and Access Management (IAM)
  /// `signBlob` API.
  ///
  /// Throws [CredentialException] on failure.
  @override
  Future<Uint8List> sign(List<int> message) async {
    final signBlobUrl = Uri(
      scheme: 'https',
      host: 'iamcredentials.$universeDomain',
      pathSegments: [
        'v1',
        'projects',
        '-',
        'serviceAccounts',
        '$clientEmail:signBlob',
      ],
    );
    final requestBody = jsonEncode({'payload': base64.encode(message)});

    var token = await accessToken();
    var attempts = 0;
    var refreshedToken = false;

    while (true) {
      attempts++;
      final http.Response response;
      try {
        response = await _client.post(
          signBlobUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: requestBody,
        );
      } on Exception catch (e, stackTrace) {
        throw SigningException(
          'Failed to sign message via IAM signBlob API: $e',
          innerException: e,
          innerStackTrace: stackTrace,
        );
      }

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final signedBlob = json['signedBlob'];
          if (signedBlob is! String) {
            throw const FormatException("Missing 'signedBlob' in response");
          }
          return Uint8List.fromList(base64.decode(signedBlob));
        } on FormatException catch (e, stackTrace) {
          throw SigningException(
            'Failed to parse signBlob response: ${e.message}',
            innerException: e,
            innerStackTrace: stackTrace,
          );
        }
      }

      // If token expired (401), retry once with a freshly requested token.
      if (response.statusCode == 401 && !refreshedToken) {
        refreshedToken = true;
        token = await accessToken(forceRefresh: true);
        continue;
      }

      // If retryable status code (5xx), back off and retry up to 3 times.
      if (_retryableStatusCodes.contains(response.statusCode) &&
          attempts <= 3) {
        final delayMs = (pow(2, attempts) * 100).toInt();
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        continue;
      }

      throw SigningException(
        'Failed to sign message via IAM signBlob API: '
        'HTTP ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Closes the underlying HTTP client if this instance created it.
  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
