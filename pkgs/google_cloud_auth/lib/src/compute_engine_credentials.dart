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
/// - https://github.com/googleapis/google-auth-library-java/blob/main/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java
/// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/compute_engine/credentials.py
/// - https://github.com/googleapis/google-auth-library-python/blob/main/google/auth/iam.py
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'access_token.dart';
import 'credential_exception.dart';
import 'credentials.dart';
import 'google_credentials.dart';
import 'json_utils.dart';
import 'platform_web.dart' if (dart.library.io) 'platform_io.dart';
import 'service_account_signer.dart';

const _defaultMetadataHost = 'metadata.google.internal';
const _linuxProductNamePath = '/sys/class/dmi/id/product_name';
const _metadataFlavorHeader = {'Metadata-Flavor': 'Google'};
const _retryableStatusCodes = {500, 502, 503, 504};
const _maxComputePingTries = 3;
const _computePingTimeout = Duration(milliseconds: 500);

// Equivalent of:
// - https://github.com/googleapis/google-auth-library-java/blob/9ac2d4340ebc6a8582b898e97f65aeed3c1776d6/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java#L621-L641
// - https://github.com/googleapis/google-auth-library-python/blob/2ea24b03436765fa3cf279ce148482ff6332136b/google/auth/compute_engine/_metadata.py#L146-L160
/// Detects whether the application is running on Google Compute Engine by
/// checking the DMI BIOS product name on Linux.
Future<bool> _checkStaticGceDetection(String path, bool isLinux) async {
  if (!isLinux) return false;
  try {
    final content = await readCredentialFileAsString(path);
    return content.trim().startsWith('Google');
  } catch (_) {
    return false;
  }
}

/// [ComputeEngineCredentials.isOnComputeEngine] with extra arguments for test
/// injection.
@internal
Future<bool> internalIsOnComputeEngine({
  http.Client? client,
  String? Function(String name)? readEnvironment,
  String? linuxProductNamePath,
  bool? isLinux,
}) async {
  // On the web, browser `fetch` cannot access `http://metadata.google.internal`
  // because the required `Metadata-Flavor: Google` header is not
  // CORS-safelisted and the GCE metadata server rejects CORS preflights to
  // prevent browser-based SSRF / DNS-rebinding attacks. Short-circuit unless a
  // custom `client` is injected so browser callers do not fire doomed retries.
  if (!isPlatformIo && client == null) {
    return false;
  }
  final readEnv = readEnvironment ?? readPlatformEnvironment;
  final noGceCheck = readEnv('NO_GCE_CHECK')?.toLowerCase();
  if (noGceCheck == 'true' || noGceCheck == '1') {
    return false;
  }

  final customHost = readEnv('GCE_METADATA_HOST');
  final host = customHost ?? _defaultMetadataHost;
  final ownedClient = client == null ? http.Client() : null;
  final httpClient = client ?? ownedClient!;
  final inFlightRequests = <Future<void>>[];

  try {
    final pingUri = Uri.http(host, '/computeMetadata/v1/');
    for (var attempt = 1; attempt <= _maxComputePingTries; attempt++) {
      try {
        final request = httpClient.get(pingUri, headers: _metadataFlavorHeader);
        inFlightRequests.add(request.catchError((_) => http.Response('', 500)));
        final response = await request.timeout(_computePingTimeout);
        final flavorHeader = response.headers['metadata-flavor'];
        if (response.statusCode == 200 &&
            flavorHeader != null &&
            flavorHeader.toLowerCase() == 'google') {
          return true;
        }
        if (!_retryableStatusCodes.contains(response.statusCode)) {
          break;
        }
      } on Exception catch (_) {
        // Ignore network/timeout exceptions and retry.
      }
    }
    if (customHost != null) {
      return false;
    }
    return await _checkStaticGceDetection(
      linuxProductNamePath ?? _linuxProductNamePath,
      isLinux ?? isPlatformLinux,
    );
  } finally {
    if (ownedClient != null) {
      unawaited(inFlightRequests.wait.whenComplete(ownedClient.close));
    }
  }
}

/// Credentials for Google Compute Engine, Cloud Run, Cloud Functions, and
/// other environments providing a Google Cloud metadata server.
final class ComputeEngineCredentials extends GoogleCredentials
    implements ServiceAccountSigner {
  /// The email address of the service account.
  @override
  final String clientEmail;

  /// The metadata server host.
  final String metadataHost;

  final _accessTokenCache = AccessTokenCache();

  ComputeEngineCredentials._({
    required this.clientEmail,
    required super.universeDomain,
    required this.metadataHost,
  });

  @override
  Future<String> accessToken({
    bool forceRefresh = false,
    http.Client? client,
  }) => _accessTokenCache.accessToken(
    () => fetchAccessToken(
      client: client,
      source: 'Compute Engine metadata server',
      send: (c) => c.get(
        Uri.http(
          metadataHost,
          '/computeMetadata/v1/instance/service-accounts/default/token',
        ),
        headers: _metadataFlavorHeader,
      ),
    ),
    forceRefresh: forceRefresh,
  );

  /// Creates a [ComputeEngineCredentials] instance, discovering configuration
  /// from the Compute Engine metadata server.
  ///
  /// If provided, [client] is used to make metadata requests. [client] must be
  /// unauthenticated and is not closed by this method. Otherwise, a temporary
  /// [http.Client] is created as needed and closed after use.
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
        readPlatformEnvironment('GCE_METADATA_HOST') ??
        _defaultMetadataHost;
    http.Client? ownedClient;

    try {
      var resolvedEmail = clientEmail;
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        final emailUri = Uri.http(
          host,
          '/computeMetadata/v1/instance/service-accounts/default/email',
        );
        final http.Response response;
        try {
          ownedClient ??= client == null ? http.Client() : null;
          client ??= ownedClient;

          response = await client!.get(
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
        ownedClient ??= client == null ? http.Client() : null;
        client ??= ownedClient;

        try {
          response = await client!.get(
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
              : Credentials.defaultUniverseDomain;
        } else if (response.statusCode == 404) {
          resolvedUniverseDomain = Credentials.defaultUniverseDomain;
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
      );
    } finally {
      ownedClient?.close();
    }
  }

  // Equivalent of:
  // - https://github.com/googleapis/google-auth-library-java/blob/9ac2d4340ebc6a8582b898e97f65aeed3c1776d6/oauth2_http/java/com/google/auth/oauth2/ComputeEngineCredentials.java#L595-L641
  // - https://github.com/googleapis/google-auth-library-python/blob/2ea24b03436765fa3cf279ce148482ff6332136b/google/auth/compute_engine/_metadata.py#L122-L160
  /// Checks if the application is running in an environment with an accessible
  /// Compute Engine metadata server.
  ///
  /// If provided, [client] is used to ping the metadata server. [client] must
  /// be unauthenticated and is not closed by this method. Otherwise, a
  /// temporary [http.Client] is created as needed and closed after use.
  static Future<bool> isOnComputeEngine({http.Client? client}) =>
      internalIsOnComputeEngine(client: client);

  /// Signs [message] using the Identity and Access Management (IAM)
  /// `signBlob` API.
  ///
  /// If provided, [client] is used to make HTTP requests. [client] must be
  /// unauthenticated and is not closed by this method. Otherwise, a temporary
  /// [http.Client] is created as needed and closed after use.
  ///
  /// Throws [SigningException] on failure.
  @override
  Future<Uint8List> sign(List<int> message, {http.Client? client}) async {
    final signBlobUrl = Uri.https(
      'iamcredentials.$universeDomain',
      '/v1/projects/-/serviceAccounts/$clientEmail:signBlob',
    );
    final requestBody = jsonEncode({'payload': base64.encode(message)});

    final ownedClient = client == null ? http.Client() : null;
    final httpClient = client ?? ownedClient!;
    try {
      String token;
      try {
        token = await accessToken(client: httpClient);
      } on Exception catch (e, stackTrace) {
        throw SigningException(
          'Failed to obtain access token for signing: $e',
          innerException: e,
          innerStackTrace: stackTrace,
        );
      }
      var attempts = 0;
      var refreshedToken = false;
      while (true) {
        attempts++;
        final http.Response response;
        try {
          response = await httpClient.post(
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
            final signedBlob = requiredString(
              decodeJsonObject(response.body),
              'signedBlob',
              'signBlob response',
            );
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
          try {
            token = await accessToken(forceRefresh: true, client: httpClient);
          } on Exception catch (e, stackTrace) {
            throw SigningException(
              'Failed to refresh access token for signing: $e',
              innerException: e,
              innerStackTrace: stackTrace,
            );
          }
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
    } finally {
      ownedClient?.close();
    }
  }
}
