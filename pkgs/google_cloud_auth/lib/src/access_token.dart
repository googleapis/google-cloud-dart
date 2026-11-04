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

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'credential_exception.dart';
import 'json_utils.dart';

/// The maximum number of characters of an error response body to include in
/// exception messages.
const _maxErrorBodyLength = 500;

/// An access token and the duration for which it is valid, as returned by a
/// token endpoint.
@internal
typedef TokenResponse = ({String accessToken, Duration expiresIn});

/// Requests an access token from a token endpoint.
///
/// [clientFactory] is called to create the [http.Client] passed to [send],
/// which makes the token request. The client is closed afterwards.
///
/// The response body must be a JSON object with `access_token` and
/// `expires_in` fields, as returned by OAuth 2.0 token endpoints
/// ([RFC 6749 §5.1](https://datatracker.ietf.org/doc/html/rfc6749#section-5.1))
/// and by the Compute Engine metadata server.
///
/// [source] describes the token endpoint in exception messages.
///
/// Throws a [CredentialException] on failure.
@internal
Future<TokenResponse> fetchAccessToken({
  required FutureOr<http.Client> Function() clientFactory,
  required Future<http.Response> Function(http.Client client) send,
  required String source,
}) async {
  final http.Response response;
  try {
    final client = await clientFactory();
    try {
      response = await send(client);
    } finally {
      client.close();
    }
  } on Exception catch (e, stackTrace) {
    throw CredentialException(
      'Failed to get access token from $source: $e',
      innerException: e,
      innerStackTrace: stackTrace,
    );
  }

  if (response.statusCode != 200) {
    final body = response.body;
    final truncatedBody = body.length > _maxErrorBodyLength
        ? '${body.substring(0, _maxErrorBodyLength)}...'
        : body;
    throw CredentialException(
      'Bad HTTP status response when fetching access token from $source: '
      '${response.statusCode} $truncatedBody',
    );
  }

  try {
    final json = decodeJsonObject(response.body);
    final accessToken = requiredString(json, 'access_token', 'token response');
    final expiresIn = switch (json['expires_in']) {
      null => throw const FormatException(
        "Missing required 'expires_in' in token response.",
      ),
      num n when n.isFinite => n,
      _ => throw const FormatException(
        "Invalid 'expires_in' in token response.",
      ),
    };
    return (
      accessToken: accessToken,
      expiresIn: Duration(seconds: expiresIn.truncate()),
    );
  } on FormatException catch (e, stackTrace) {
    throw CredentialException(
      'Failed to parse token response from $source: $e',
      innerException: e,
      innerStackTrace: stackTrace,
    );
  }
}

/// Caches an access token, fetching a new one when the cached token is about
/// to expire.
@internal
final class AccessTokenCache {
  /// Cached tokens that expire within this margin are not used.
  static const _expiryMargin = Duration(minutes: 1);

  final Future<TokenResponse> Function() _fetch;
  final DateTime Function() _clock;

  ({String accessToken, DateTime expiry})? _cached;

  /// The in-flight fetch, so that concurrent callers share one request.
  Future<String>? _activeFetch;

  /// Creates an [AccessTokenCache] that calls [_fetch] to obtain new tokens.
  ///
  /// If provided, [clock] is used to determine the current time.
  AccessTokenCache(this._fetch, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.timestamp;

  /// A non-expired access token.
  ///
  /// If the cached token expires within `_expiryMargin`, or if [forceRefresh]
  /// is `true`, then a new token is fetched.
  ///
  /// It is safe to call this method concurrently: concurrent callers share a
  /// single fetch.
  ///
  /// Throws any exception thrown while fetching a new token, in which case
  /// the cached token, if any, is unchanged.
  Future<String> accessToken({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      if (_freshToken() case final token?) return token;
    }

    return await (_activeFetch ??= _refresh().whenComplete(() {
      _activeFetch = null;
    }));
  }

  /// The cached token, or `null` if there is none or it expires soon.
  String? _freshToken() {
    final cached = _cached;
    if (cached == null) return null;
    return _clock().isBefore(cached.expiry.subtract(_expiryMargin))
        ? cached.accessToken
        : null;
  }

  Future<String> _refresh() async {
    final response = await _fetch();
    _cached = (
      accessToken: response.accessToken,
      expiry: _clock().add(response.expiresIn),
    );
    return response.accessToken;
  }
}
