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

import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ComputeEngineCredentials', () {
    group('create', () {
      test('explicitly provided email and universe domain', () async {
        var metadataCalled = false;
        final mockClient = MockClient((request) async {
          metadataCalled = true;
          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'explicit@iam.gserviceaccount.com',
          universeDomain: 'explicit.domain.com',
          metadataHost: 'test-metadata',
        );

        expect(creds.clientEmail, 'explicit@iam.gserviceaccount.com');
        expect(creds.universeDomain, 'explicit.domain.com');
        expect(metadataCalled, isFalse);
      });

      test('fetches email and universe domain', () async {
        final mockClient = MockClient((request) async {
          expect(request.headers['metadata-flavor'], 'Google');
          final path = request.url.path;
          if (path ==
              '/computeMetadata/v1/instance/service-accounts/default/email') {
            return http.Response('sa@test.iam.gserviceaccount.com', 200);
          }
          if (path == '/computeMetadata/v1/universe/universe-domain') {
            return http.Response('custom.domain.com', 200);
          }
          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          metadataHost: 'test-metadata',
        );

        expect(creds.clientEmail, 'sa@test.iam.gserviceaccount.com');
        expect(creds.universeDomain, 'custom.domain.com');
      });

      test(
        'throws SigningException on metadata server error for email',
        () async {
          final mockClient = MockClient(
            (request) async => http.Response('Internal server error', 500),
          );

          expect(
            () => ComputeEngineCredentials.create(
              client: mockClient,
              metadataHost: 'test-metadata',
            ),
            throwsA(
              isA<SigningException>().having(
                (e) => e.message,
                'message',
                contains('Failed to get default service account email'),
              ),
            ),
          );
        },
      );

      test('empty universe-domain', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/universe-domain')) {
            return http.Response('', 200);
          }
          fail('Unexpected request: $request');
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'test-sa@project.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        expect(creds, isA<ServiceAccountSigner>());
        expect(creds.universeDomain, 'googleapis.com');
      });

      test('not found universe-domain', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/universe-domain')) {
            return http.Response('Not found', 404);
          }
          fail('Unexpected request: $request');
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'test-sa@project.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        expect(creds, isA<ServiceAccountSigner>());
        expect(creds.universeDomain, 'googleapis.com');
      });

      test(
        'throws SigningException on metadata server error for universe domain',
        () async {
          final mockClient = MockClient((request) async {
            final path = request.url.path;
            if (path ==
                '/computeMetadata/v1/instance/service-accounts/default/email') {
              return http.Response('sa@test.iam.gserviceaccount.com', 200);
            }
            if (path == '/computeMetadata/v1/universe/universe-domain') {
              return http.Response('Internal error', 500);
            }
            return http.Response('Not found', 404);
          });

          expect(
            () => ComputeEngineCredentials.create(
              client: mockClient,
              metadataHost: 'test-metadata',
            ),
            throwsA(
              isA<SigningException>().having(
                (e) => e.message,
                'message',
                contains('Failed to get universe domain'),
              ),
            ),
          );
        },
      );
    });

    group('isOnComputeEngine', () {
      test(
        'returns true when metadata server responds with Google flavor',
        () async {
          final mockClient = MockClient(
            (request) async => http.Response(
              'ok',
              200,
              headers: {'metadata-flavor': 'Google'},
            ),
          );

          final isGce = await ComputeEngineCredentials.isOnComputeEngine(
            client: mockClient,
            metadataHost: 'test-metadata',
          );
          expect(isGce, isTrue);
        },
      );

      test('returns false when status is not 200', () async {
        final mockClient = MockClient(
          (request) async => http.Response(
            'forbidden',
            403,
            headers: {'metadata-flavor': 'Google'},
          ),
        );

        final isGce = await ComputeEngineCredentials.isOnComputeEngine(
          client: mockClient,
          metadataHost: 'test-metadata',
        );
        expect(isGce, isFalse);
      });

      test('returns false when metadata-flavor header is missing', () async {
        final mockClient = MockClient(
          (request) async => http.Response('ok', 200),
        );

        final isGce = await ComputeEngineCredentials.isOnComputeEngine(
          client: mockClient,
          metadataHost: 'test-metadata',
        );
        expect(isGce, isFalse);
      });

      test('returns false on network exception', () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Connection refused');
        });

        final isGce = await ComputeEngineCredentials.isOnComputeEngine(
          client: mockClient,
          metadataHost: 'test-metadata',
        );
        expect(isGce, isFalse);
      });
    });

    group('sign', () {
      test('happy path', () async {
        final expectedMessage = utf8.encode('Hello, Cloud!');
        final mockSignatureBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
        var tokenCallCount = 0;
        var signBlobCallCount = 0;

        final mockClient = MockClient((request) async {
          if (request.url.path ==
              '/computeMetadata/v1/instance/service-accounts/default/token') {
            tokenCallCount++;
            return http.Response(
              jsonEncode({
                'access_token': 'mock-access-token-123',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
            );
          }

          if (request.url.path ==
              '/v1/projects/-/serviceAccounts/sa@test.iam.gserviceaccount.com:signBlob') {
            signBlobCallCount++;
            expect(request.method, 'POST');
            expect(request.url.host, 'iamcredentials.googleapis.com');
            expect(
              request.headers['authorization'],
              'Bearer mock-access-token-123',
            );
            expect(request.headers['content-type'], 'application/json');

            final bodyJson = jsonDecode(request.body) as Map<String, dynamic>;
            expect(bodyJson['payload'], base64.encode(expectedMessage));

            return http.Response(
              jsonEncode({
                'keyId': 'key-123',
                'signedBlob': base64.encode(mockSignatureBytes),
              }),
              200,
            );
          }

          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        final signature = await creds.sign(expectedMessage);
        expect(signature, equals(mockSignatureBytes));
        expect(tokenCallCount, 1);
        expect(signBlobCallCount, 1);

        // Subsequent call reuses cached token:
        await creds.sign(expectedMessage);
        expect(tokenCallCount, 1);
        expect(signBlobCallCount, 2);
      });

      test('retries on 401 token expiry with refreshed token', () async {
        final message = utf8.encode('Test message');
        final mockSignatureBytes = Uint8List.fromList([1, 2, 3]);
        var tokenCount = 0;
        var signBlobAttempts = 0;

        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            tokenCount++;
            return http.Response(
              jsonEncode({
                'access_token': 'token-$tokenCount',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
            );
          }

          if (request.url.path.endsWith(':signBlob')) {
            signBlobAttempts++;
            if (signBlobAttempts == 1) {
              expect(request.headers['authorization'], 'Bearer token-1');
              return http.Response('Unauthorized', 401);
            }
            expect(request.headers['authorization'], 'Bearer token-2');
            return http.Response(
              jsonEncode({
                'keyId': 'key-id',
                'signedBlob': base64.encode(mockSignatureBytes),
              }),
              200,
            );
          }

          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        final signature = await creds.sign(message);
        expect(signature, equals(mockSignatureBytes));
        expect(signBlobAttempts, 2);
        expect(tokenCount, 2);
      });

      test('retries on 500 error', () async {
        final message = utf8.encode('Test retry');
        final mockSignatureBytes = Uint8List.fromList([7, 8, 9]);
        var signBlobAttempts = 0;

        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': 'token-123',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
            );
          }

          if (request.url.path.endsWith(':signBlob')) {
            signBlobAttempts++;
            if (signBlobAttempts == 1) {
              return http.Response('Internal Server Error', 500);
            }
            return http.Response(
              jsonEncode({
                'keyId': 'key-id',
                'signedBlob': base64.encode(mockSignatureBytes),
              }),
              200,
            );
          }

          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        final signature = await creds.sign(message);
        expect(signature, equals(mockSignatureBytes));
        expect(signBlobAttempts, 2);
      });

      test(
        'throws SigningException on persistent error from signBlob',
        () async {
          final message = utf8.encode('Test error');

          final mockClient = MockClient((request) async {
            if (request.url.path.endsWith('/token')) {
              return http.Response(
                jsonEncode({
                  'access_token': 'token-123',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                }),
                200,
              );
            }

            if (request.url.path.endsWith(':signBlob')) {
              return http.Response(
                jsonEncode({
                  'error': {
                    'code': 403,
                    'message':
                        'Permission iam.serviceAccounts.signBlob denied.',
                    'status': 'PERMISSION_DENIED',
                  },
                }),
                403,
              );
            }

            return http.Response('Not found', 404);
          });

          final creds = await ComputeEngineCredentials.create(
            client: mockClient,
            clientEmail: 'sa@test.iam.gserviceaccount.com',
            metadataHost: 'test-metadata',
          );

          expect(
            () => creds.sign(message),
            throwsA(
              isA<SigningException>().having(
                (e) => e.message,
                'message',
                contains('Permission iam.serviceAccounts.signBlob denied'),
              ),
            ),
          );
        },
      );
    });
  });
}
