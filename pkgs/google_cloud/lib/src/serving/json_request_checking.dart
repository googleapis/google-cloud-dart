// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'package:http/http.dart' show MediaType;
import 'package:meta/meta.dart';

/// Evaluates whether to send a JSON response based on request headers.
///
/// Rules:
/// 1. Return `true` if the `Accept` header explicitly asks for JSON
///    (with q > 0).
/// 2. Return `false` if the `Accept` header explicitly forbids JSON (q = 0)
///    and does not allow it elsewhere.
/// 3. Fallback to return `true` if the `Content-Type` header is any
///    valid flavor of JSON when the `Accept` header does not specify
///    JSON preference.
///
/// This is a simplified content negotiation that prefers JSON if allowed,
/// or falls back to the request Content-Type.
@internal
bool shouldSendJsonResponse(Map<String, String> requestHeaders) {
  final accept = requestHeaders[HttpHeaders.acceptHeader];

  var jsonExplicitlyAllowed = false;
  var jsonExplicitlyForbidden = false;

  if (accept != null) {
    // TODO(kevmoo): leverage support in pkg:http_parser when it lands
    // https://github.com/dart-lang/http/issues/1904

    final values = accept.split(',');
    for (final value in values) {
      final trimmed = value.trim();
      final MediaType mediaType;
      try {
        mediaType = MediaType.parse(trimmed);
      } catch (_) {
        // Ignore invalid media types in Accept header
        continue;
      }

      final q = double.tryParse(mediaType.parameters['q'] ?? '1.0') ?? 1.0;

      if (_isJson(mediaType)) {
        if (q > 0.0) {
          jsonExplicitlyAllowed = true;
        } else {
          jsonExplicitlyForbidden = true;
        }
      }
    }
  }

  // If explicitly forbidden and not allowed by another spec, return false.
  final forbidsJson = jsonExplicitlyForbidden && !jsonExplicitlyAllowed;
  if (forbidsJson) return false;

  // If explicitly allowed, return true.
  if (jsonExplicitlyAllowed) return true;

  final contentType = requestHeaders[HttpHeaders.contentTypeHeader];

  // Fallback to Content-Type if it is any valid flavor of JSON.
  if (contentType != null && _isAnyJson(contentType)) {
    return true;
  }

  return false;
}

bool _isAnyJson(String contentTypeHeader) {
  try {
    final mediaType = MediaType.parse(contentTypeHeader);
    return _isJson(mediaType);
  } catch (e) {
    return false;
  }
}

bool _isJson(MediaType mediaType) =>
    mediaType.mimeType == 'application/json' ||
    mediaType.subtype.endsWith('+json');
