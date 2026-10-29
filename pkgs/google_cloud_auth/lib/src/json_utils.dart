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

import 'package:meta/meta.dart';

/// Decodes [source] as a JSON object.
///
/// Throws a [FormatException] if [source] is not valid JSON or does not
/// contain a JSON object.
@internal
Map<String, dynamic> decodeJsonObject(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Expected a JSON object.');
  }
  return decoded;
}

/// Returns the value of [key] in [json], which must be a non-empty string.
///
/// Throws a [FormatException] if the value is missing, empty, or not a string.
/// [description] describes [json] in the exception message, for example
/// `'service account info'`.
@internal
String requiredString(
  Map<String, dynamic> json,
  String key,
  String description,
) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException("Missing required '$key' in $description.");
  }
  return value;
}

/// Returns the value of [key] in [json], or `null` if it is absent.
///
/// Throws a [FormatException] if the value is present but is not a string.
@internal
String? optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException("The value of '$key' must be a string.");
  }
  return value;
}
