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
import 'package:http_parser/http_parser.dart';
import 'package:meta/meta.dart';

/// Evaluates whether to send a JSON response based on request headers.
///
/// Rules:
/// 1. Return `true` if the `Accept` header explicitly asks for JSON and it is
///    a higher priority than `text/plain` (the default fallback). Wildcards
///    like `*/*` do not count as explicitly asking for JSON.
/// 2. Return `false` if the `Accept` header explicitly forbids JSON
///    (e.g., `q=0`).
/// 3. Return `true` if the `Content-Type` header is any valid flavor of JSON.
///
/// Conflict resolution: If `Accept` explicitly forbids JSON (Rule 2), it takes
/// precedence over `Content-Type` being JSON (Rule 3), and returns `false`.
@internal
bool shouldSendJsonResponse(Map<String, String> requestHeaders) {
  final accept = requestHeaders[HttpHeaders.acceptHeader];

  // TODO(kevmoo): leverage support in pkg:http_parser when it lands
  // https://github.com/dart-lang/http/issues/1904

  // Parse Accept header to find priorities
  var qJson = 0.0;
  var qText = 0.0;
  var forbidsJson = false;

  if (accept != null) {
    final values = accept.split(',');
    for (final value in values) {
      final trimmed = value.trim();
      try {
        final mediaType = MediaType.parse(trimmed);
        final q = double.tryParse(mediaType.parameters['q'] ?? '1.0') ?? 1.0;

        if (_isJson(mediaType)) {
          if (q == 0.0) {
            forbidsJson = true;
          }
          if (q > qJson) qJson = q;
        } else if (mediaType.mimeType == 'text/plain') {
          if (q > qText) qText = q;
        }
      } catch (_) {
        // Ignore invalid media types in Accept header
      }
    }
  }

  // Rule 2: Return false if the Accept header explicitly forbids JSON.
  if (forbidsJson) return false;

  final contentType = requestHeaders[HttpHeaders.contentTypeHeader];

  // Rule 3: Return true if the Content-Type header is any valid flavor of JSON.
  final contentTypeIsJson = contentType != null && _isAnyJson(contentType);

  // Conflict resolution: If Accept explicitly forbids JSON, it takes
  // precedence over Content-Type being JSON (handled by Rule 2 above).
  if (contentTypeIsJson) return true;

  // Rule 1: Return true if the Accept header explicitly asks for JSON and it is
  // a higher priority than text/plain.
  if (qJson > qText) {
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
