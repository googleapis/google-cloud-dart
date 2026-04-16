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

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const _bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String randomBucketCharacters(int length) => [
  for (int i = 0; i < length; i++)
    _bucketChars[_random.nextInt(_bucketChars.length)],
].join();

String testBucketName(String name) {
  assert(name.length < 40, '"$name" is too long to append a random suffix.');
  return '$name-${randomBucketCharacters(45 - name.length)}';
}

String bucketNameWithTearDown(Storage storage, String name) {
  final generatedName = testBucketName(name);
  addTearDown(() async {
    try {
      // Use `versions: true` to get all versions of all objects.
      await for (final object in storage.listObjects(
        generatedName,
        versions: true,
      )) {
        if (object.eventBasedHold == true || object.temporaryHold == true) {
          await storage.patchObject(
            generatedName,
            object.name!,
            ObjectMetadataPatchBuilder()
              ..eventBasedHold = false
              ..temporaryHold = false,
            generation: object.generation,
          );
        }
        await storage.deleteObject(
          generatedName,
          object.name!,
          generation: object.generation,
        );
      }
      await storage.deleteBucket(generatedName);
    } on NotFoundException {
      // Ignore.
    }
  });
  return generatedName;
}

Future<String> createBucketWithTearDown(
  Storage storage,
  String name, {
  BucketMetadata? metadata,
  bool enableObjectRetention = false,
}) async {
  final bucketName = bucketNameWithTearDown(storage, name);
  final meta = (metadata == null)
      ? BucketMetadata(name: bucketName)
      : metadata.copyWith(name: bucketName);
  await storage.createBucket(
    meta,
    enableObjectRetention: enableObjectRetention,
  );
  return bucketName;
}

/// An HTTP client that can add a `x-retry-test-id` header to requests for
/// testing with Storage Testbench.
///
/// See https://github.com/googleapis/storage-testbench.
final class RetryTestHttpClient extends http.BaseClient {
  final http.Client _client;
  String? retryTestId;

  String? instructions;

  RetryTestHttpClient(this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest originalRequest) {
    if (retryTestId case final id?) {
      originalRequest.headers['x-retry-test-id'] = id;
    }
    if (instructions case final i?) {
      originalRequest.headers['x-goog-emulator-instructions'] = i;
      if (originalRequest.method == 'PUT') {
        instructions = null;
      }
    }
    return _client.send(originalRequest);
  }

  @override
  void close() => _client.close();
}

/// A client that can create Storage Testbench Retry Tests.
///
/// See https://github.com/googleapis/storage-testbench?tab=readme-ov-file#creating-a-new-retry-test
final class RetryTestCreator {
  final http.Client _client;
  final List<String> _retryTests = [];

  RetryTestCreator(this._client);

  /// Creates a new retry test and returns the test id that can be used in the
  /// `x-retry-test-id` header.
  ///
  /// The [test] object is a JSON-serializable object that describes the retry
  /// test. See
  /// https://github.com/googleapis/storage-testbench?tab=readme-ov-file#creating-a-new-retry-test
  Future<String> createRetryTest(Object test) async {
    final responseBody = (await _client.post(
      Uri.http('localhost:9000', '/retry_test'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(test),
    )).body;
    final id =
        (jsonDecode(responseBody) as Map<String, dynamic>)['id'] as String;
    _retryTests.add(id);
    return id;
  }

  Future<void> close() async {
    for (var id in _retryTests) {
      await _client.delete(Uri.http('localhost:9000', '/retry_test/$id'));
    }
    _client.close();
  }
}
