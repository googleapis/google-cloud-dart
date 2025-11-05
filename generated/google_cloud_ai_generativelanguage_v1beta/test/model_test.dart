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
  late ModelService modelService;
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
      modelService = ModelService(client: replayClient);
    });

    tearDown(() => modelService.close());
    test('list', () async {
      await replayClient.setUp('test/list.json');
      final request = ListModelsRequest();

      final result = await modelService.listModels(request);
      expect(result.models.first.name, isNotEmpty);
    });
  });
}
