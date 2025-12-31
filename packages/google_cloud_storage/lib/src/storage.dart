// Copyright 2025 Google LLC
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

import 'package:google_cloud_rpc/service_client.dart';
import 'package:http/http.dart' as http;

import 'bucket.dart';

final class Retry {
  Future<T> run<T extends http.BaseResponse>(Future<T> Function() body) =>
      body();

  const Retry();
}

final class DefaultRetry {
  Future<T> run<T extends http.BaseResponse>(Future<T> Function() body) {
    while (true) {
      try {
        return body();
      } on (TooManyRequestsException, 
      InternalServerErrorException,
      BadGatewayException,
      ServiceUnavailableException,
      GatewayTimeoutException,
//      RequestTimeoutException,
      http.ClientException) catch (e {
        return body();
      }
    }
  }
}

const defaultRetry = DefaultRetry();

/// API for storing and retrieving potentially large, immutable data objects.
class StorageService {
  final http.Client _client;
  static const _host = 'storage.googleapis.com';

  /// Creates a `StorageService` using [client] for transport.
  ///
  /// The provided [http.Client] must be configured to provide whatever
  /// authentication is required by `StorageService`. You can do that using
  /// [`package:googleapis_auth`](https://pub.dev/packages/googleapis_auth).
  StorageService({required http.Client client}) : _client = client;

  /// Creates a new bucket.
  ///
  /// See https://cloud.google.com/storage/docs/json_api/v1/buckets/insert
  Future<Bucket> createBucket({
    required String bucketName,
    String? project,
    Retry retry = defaultRetry,
  }) async {
    final query = {if (project != null) 'project': project};

    final body = Bucket(name: bucketName);

    final url = Uri.https(_host, 'storage/v1/b', query);
    final response = await retry.run(() => _client.post(url, body: body));

    return Bucket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void close() {
    _client.close();
  }
}
