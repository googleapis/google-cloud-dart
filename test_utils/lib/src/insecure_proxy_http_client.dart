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

import 'package:http/http.dart';

/// An HTTP client that proxies requests to another client but converts "https"
/// schemes to "http".
class InsecureProxyHttpClient extends BaseClient {
  final Client _client;

  InsecureProxyHttpClient(this._client);

  @override
  Future<StreamedResponse> send(BaseRequest originalRequest) =>
      _client.send(_copyRequest(originalRequest));

  StreamedRequest _copyRequest(BaseRequest original) {
    final body = original.finalize();
    final request =
        StreamedRequest(
            original.method,
            original.url.scheme == 'https'
                ? original.url.replace(scheme: 'http')
                : original.url,
          )
          ..contentLength = original.contentLength
          ..followRedirects = original.followRedirects
          ..headers.addAll(original.headers)
          ..maxRedirects = original.maxRedirects
          ..persistentConnection = original.persistentConnection;

    body.listen(
      request.sink.add,
      onError: request.sink.addError,
      onDone: request.sink.close,
      cancelOnError: true,
    );

    return request;
  }

  @override
  void close() => _client.close();
}
