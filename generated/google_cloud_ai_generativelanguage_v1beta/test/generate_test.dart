import 'dart:convert';
import 'dart:io' as io;
import 'package:async/async.dart';

import 'package:http/http.dart';
import 'package:test/test.dart';

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:dartvcr/dartvcr.dart';

import 'replay_http_client.dart' as replay;

void main() async {
  late GenerativeService generativeService;
  late replay.ReplayHttpClient replayClient;

  group('model', () {
    setUp(() async {
      final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: [
          'https://www.googleapis.com/auth/cloud-platform',
          'https://www.googleapis.com/auth/generative-language.retriever',
        ],
      );

      replayClient = replay.ReplayHttpClient(client: client);
      generativeService = GenerativeService(client: replayClient);
    });

    tearDown(() => generativeService.close());
    test('streamed', () async {
      await replayClient.setUp('test/streamed.json');
      final request = GenerateContentRequest(
        model: 'models/gemini-2.5-flash',
        contents: [
          Content(
            parts: [Part(text: "Explain how AI works in extensive detail")],
          ),
        ],
      );

      final results = generativeService.streamGenerateContent(request);
      final text = StringBuffer();
      await for (final result in results) {
        final parts = result.candidates.firstOrNull?.content?.parts;
        if (parts != null) {
          parts.forEach((p) => text.write(p.text ?? ''));
        }
      }
      expect(text.toString(), hasLength(greaterThan(1000)));
    }, timeout: const Timeout(const Duration(seconds: 60)));
  });
}
