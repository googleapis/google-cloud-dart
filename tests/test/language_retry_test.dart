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

/// Tests the retry behavior of the generated clients, using
/// package:google_cloud_language_v2.
library;

import 'package:google_cloud_language_v2/language.dart';
import 'package:google_cloud_language_v2/testing.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _noDelayRetry = ExponentialRetry.onCodes(
  [Code.unavailable],
  initialDelay: Duration.zero,
  maxDelay: Duration.zero,
  maxRetries: 3,
);

bool _isInternalServerError(Object error) =>
    error is InternalServerErrorException;

void main() {
  final request = AnalyzeSentimentRequest(
    document: Document(type: Document_Type.plainText, content: 'Hello, world!'),
  );

  late List<http.Request> requests;
  late List<int> statusCodes;

  /// A client whose responses have the given status codes, in order.
  ///
  /// A `200` response returns an `AnalyzeSentimentResponse`.
  http.Client mockClient(List<int> codes) {
    statusCodes = codes;
    return MockClient((request) async {
      requests.add(request);
      final statusCode = statusCodes[requests.length - 1];
      return statusCode == 200
          ? http.Response('{"languageCode":"en"}', 200)
          : http.Response('', statusCode);
    });
  }

  setUp(() => requests = []);

  group('default retry policy', () {
    test('retries UNAVAILABLE', () async {
      final service = LanguageService(client: mockClient([503, 503, 200]));

      final response = await service.analyzeSentiment(request);

      expect(response.languageCode, 'en');
      expect(requests, hasLength(3));
      for (final r in requests) {
        expect(r.url, requests.first.url);
        expect(r.body, requests.first.body);
      }
    });

    test('retries DEADLINE_EXCEEDED', () async {
      final service = LanguageService(client: mockClient([504, 200]));

      final response = await service.analyzeSentiment(request);

      expect(response.languageCode, 'en');
      expect(requests, hasLength(2));
    });

    test('does not retry other errors', () async {
      final service = LanguageService(client: mockClient([500, 200]));

      await expectLater(
        service.analyzeSentiment(request),
        throwsA(isA<InternalServerErrorException>()),
      );
      expect(requests, hasLength(1));
    });

    test('is used by every method', () async {
      final service = LanguageService(
        client: MockClient((request) async {
          requests.add(request);
          return requests.length.isOdd
              ? http.Response('', 503)
              : http.Response('{}', 200);
        }),
      );
      final document = Document(
        type: Document_Type.plainText,
        content: 'Hello, world!',
      );

      await service.analyzeSentiment(
        AnalyzeSentimentRequest(document: document),
      );
      await service.analyzeEntities(AnalyzeEntitiesRequest(document: document));
      await service.classifyText(ClassifyTextRequest(document: document));
      await service.moderateText(ModerateTextRequest(document: document));
      await service.annotateText(
        AnnotateTextRequest(
          document: document,
          features: AnnotateTextRequest_Features(extractEntities: true),
        ),
      );

      expect(requests, hasLength(10));
    });
  });

  group('client retry', () {
    test('noRetry disables retries', () async {
      final service = LanguageService(
        client: mockClient([503, 200]),
        retry: noRetry,
      );

      await expectLater(
        service.analyzeSentiment(request),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });

    test('replaces the default retry policy', () async {
      final service = LanguageService(
        client: mockClient([500, 200]),
        retry: const ExponentialRetry(
          retryIf: _isInternalServerError,
          initialDelay: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );

      final response = await service.analyzeSentiment(request);

      expect(response.languageCode, 'en');
      expect(requests, hasLength(2));
    });
  });

  group('call retry', () {
    test('overrides the default retry policy', () async {
      final service = LanguageService(client: mockClient([503, 200]));

      await expectLater(
        service.analyzeSentiment(request, retry: noRetry),
        throwsA(isA<ServiceUnavailableException>()),
      );
      expect(requests, hasLength(1));
    });

    test('overrides the client retry', () async {
      final service = LanguageService(
        client: mockClient([503, 200]),
        retry: noRetry,
      );

      final response = await service.analyzeSentiment(
        request,
        retry: _noDelayRetry,
      );

      expect(response.languageCode, 'en');
      expect(requests, hasLength(2));
    });

    test('can use status codes', () async {
      final service = LanguageService(client: mockClient([429, 200]));

      final response = await service.analyzeSentiment(
        request,
        retry: const ExponentialRetry.onCodes(
          [Code.resourceExhausted],
          initialDelay: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );

      expect(response.languageCode, 'en');
      expect(requests, hasLength(2));
    });

    test('can use a predicate', () async {
      final service = LanguageService(client: mockClient([429, 500, 200]));

      final response = await service.analyzeSentiment(
        request,
        retry: ExponentialRetry(
          retryIf: (e) =>
              hasStatusCode(e, const [Code.resourceExhausted]) ||
              _isInternalServerError(e),
          initialDelay: Duration.zero,
          maxDelay: Duration.zero,
        ),
      );

      expect(response.languageCode, 'en');
      expect(requests, hasLength(3));
    });
  });

  test('the fake accepts and ignores retry', () async {
    final service = FakeLanguageService(
      analyzeSentiment: (request) async =>
          AnalyzeSentimentResponse(languageCode: 'en'),
    );

    final response = await service.analyzeSentiment(request, retry: noRetry);

    expect(response.languageCode, 'en');
  });
}
