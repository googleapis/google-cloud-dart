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

@TestOn('vm')
library;

import 'package:google_cloud_firestore_v1/firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:test_utils/cloud.dart';

const databaseId = '(default)';

void firestoreTest(Future<Firestore> Function() createFirestore) async {
  late Firestore firestoreService;

  setUp(() async {
    firestoreService = await createFirestore();
  });

  tearDown(() => firestoreService.close());

  test('getDocument', () async {
    final r = await firestoreService.createDocument(
      CreateDocumentRequest(
        parent: 'projects/$projectId/databases/$databaseId/documents',
        collectionId: 'users',
        document: Document(fields: {'firstName': Value(stringValue: 'Brian')}),
      ),
    );
    addTearDown(
      () =>
          firestoreService.deleteDocument(DeleteDocumentRequest(name: r.name)),
    );

    final doc = await firestoreService.getDocument(
      GetDocumentRequest(name: r.name),
    );
    expect(doc.fields['firstName']?.stringValue, 'Brian');
  });
}

void main() {
  group('firestore_v1', () {
    group('google-cloud', tags: ['google-cloud'], () {
      firestoreTest(
        () async => Firestore(
          client: await auth.clientViaApplicationDefaultCredentials(
            scopes: ['https://www.googleapis.com/auth/cloud-platform'],
          ),
        ),
      );
    });

    group('firebase-emulator', tags: ['firebase-emulator'], () {
      firestoreTest(
        () async => Firestore(
          client: http.Client(),
          endPoint: Uri.http('127.0.0.1:8080'),
        ),
      );
    });
  });
}
