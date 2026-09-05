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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_auth/google_cloud_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() async {
  final isOnGce = await ComputeEngineCredentials.isOnComputeEngine();

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
          return switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/email' =>
              http.Response('sa@test.iam.gserviceaccount.com', 200),
            '/computeMetadata/v1/universe/universe-domain' => http.Response(
              'custom.domain.com',
              200,
            ),
            _ => http.Response('Not found', 404),
          };
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          metadataHost: 'test-metadata',
        );

        expect(creds.clientEmail, 'sa@test.iam.gserviceaccount.com');
        expect(creds.universeDomain, 'custom.domain.com');
      });

      test(
        'throws CredentialException on metadata server error for email',
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
              isA<CredentialException>().having(
                (e) => e.message,
                'message',
                contains('Failed to get default service account email'),
              ),
            ),
          );
        },
      );

      test('throws CredentialException on network error for email', () async {
        final mockClient = MockClient(
          (request) async => throw http.ClientException('Connection reset'),
        );

        expect(
          () => ComputeEngineCredentials.create(
            client: mockClient,
            metadataHost: 'test-metadata',
          ),
          throwsA(
            isA<CredentialException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to get default service account email'),
                )
                .having(
                  (e) => e.innerException,
                  'innerException',
                  isA<http.ClientException>(),
                ),
          ),
        );
      });

      test('empty universe-domain', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/universe/universe-domain' => http.Response(
              '',
              200,
            ),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'test-sa@project.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        expect(creds, isA<ServiceAccountSigner>());
        expect(creds.universeDomain, 'googleapis.com');
      });

      test('not found universe-domain', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/universe/universe-domain' => http.Response(
              'Not found',
              404,
            ),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'test-sa@project.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        expect(creds, isA<ServiceAccountSigner>());
        expect(creds.universeDomain, 'googleapis.com');
      });

      test('throws CredentialException on metadata server error for universe '
          'domain', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/email' =>
              http.Response('sa@test.iam.gserviceaccount.com', 200),
            '/computeMetadata/v1/universe/universe-domain' => http.Response(
              'Internal error',
              500,
            ),
            _ => http.Response('Not found', 404),
          },
        );

        expect(
          () => ComputeEngineCredentials.create(
            client: mockClient,
            metadataHost: 'test-metadata',
          ),
          throwsA(
            isA<CredentialException>().having(
              (e) => e.message,
              'message',
              contains('Failed to get universe domain'),
            ),
          ),
        );
      });
    });

    group('accessToken', () {
      test('fetches and caches access token', () async {
        var callCount = 0;
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            callCount++;
            return http.Response(
              jsonEncode({
                'access_token': 'token-$callCount',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.com',
          universeDomain: 'googleapis.com',
          metadataHost: 'test-metadata',
        );

        final token1 = await creds.accessToken();
        expect(token1, 'token-1');
        expect(callCount, 1);

        // Cached
        final token2 = await creds.accessToken();
        expect(token2, 'token-1');
        expect(callCount, 1);

        // Force refresh
        final token3 = await creds.accessToken(forceRefresh: true);
        expect(token3, 'token-2');
        expect(callCount, 2);
      });

      test('shares active request among concurrent callers', () async {
        final completer = Completer<http.Response>();
        var callCount = 0;

        final mockClient = MockClient((request) {
          if (request.url.path.endsWith('/token')) {
            callCount++;
            return completer.future;
          }
          return Future.value(http.Response('Not found', 404));
        });

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.com',
          universeDomain: 'googleapis.com',
          metadataHost: 'test-metadata',
        );

        final future1 = creds.accessToken();
        final future2 = creds.accessToken();
        final future3 = creds.accessToken(forceRefresh: true);

        await pumpEventQueue();
        expect(callCount, 1);

        completer.complete(
          http.Response(
            jsonEncode({
              'access_token': 'shared-token-123',
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
          ),
        );

        final results = await Future.wait([future1, future2, future3]);
        expect(results, [
          'shared-token-123',
          'shared-token-123',
          'shared-token-123',
        ]);
        expect(callCount, 1);
      });

      test(
        'clears active request on failure so subsequent call retries',
        () async {
          final completer = Completer<http.Response>();
          var callCount = 0;

          final mockClient = MockClient((request) {
            if (request.url.path.endsWith('/token')) {
              callCount++;
              if (callCount == 1) {
                return completer.future;
              }
              return Future.value(
                http.Response(
                  jsonEncode({
                    'access_token': 'recovered-token',
                    'expires_in': 3600,
                    'token_type': 'Bearer',
                  }),
                  200,
                ),
              );
            }
            return Future.value(http.Response('Not found', 404));
          });

          final creds = await ComputeEngineCredentials.create(
            client: mockClient,
            clientEmail: 'sa@test.com',
            universeDomain: 'googleapis.com',
            metadataHost: 'test-metadata',
          );

          final future1 = creds.accessToken();
          final future2 = creds.accessToken();

          await pumpEventQueue();
          expect(callCount, 1);

          completer.complete(http.Response('Internal Server Error', 500));

          await expectLater(future1, throwsA(isA<CredentialException>()));
          await expectLater(future2, throwsA(isA<CredentialException>()));
          expect(callCount, 1);

          // Subsequent call should initiate a new request
          final token = await creds.accessToken();
          expect(token, 'recovered-token');
          expect(callCount, 2);
        },
      );

      test('throws CredentialException on HTTP error', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/token' =>
              http.Response('Unauthorized', 401),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.com',
          universeDomain: 'googleapis.com',
          metadataHost: 'test-metadata',
        );

        expect(
          creds.accessToken,
          throwsA(
            isA<CredentialException>().having(
              (e) => e.message,
              'message',
              contains('HTTP 401'),
            ),
          ),
        );
      });

      test('throws CredentialException on network error', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/token' =>
              throw http.ClientException('Network down'),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.com',
          universeDomain: 'googleapis.com',
          metadataHost: 'test-metadata',
        );

        expect(
          creds.accessToken,
          throwsA(
            isA<CredentialException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to get access token'),
                )
                .having(
                  (e) => e.innerException,
                  'innerException',
                  isA<http.ClientException>(),
                ),
          ),
        );
      });

      test('throws CredentialException on invalid JSON', () async {
        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/token' =>
              http.Response('not valid json', 200),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.com',
          universeDomain: 'googleapis.com',
          metadataHost: 'test-metadata',
        );

        expect(
          creds.accessToken,
          throwsA(
            isA<CredentialException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to parse token response'),
                )
                .having(
                  (e) => e.innerException,
                  'innerException',
                  isA<FormatException>(),
                ),
          ),
        );
      });
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

      test('throws SigningException on persistent error from '
          'signBlob', () async {
        final message = utf8.encode('Test error');

        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/token' =>
              http.Response(
                jsonEncode({
                  'access_token': 'token-123',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                }),
                200,
              ),
            '/v1/projects/-/serviceAccounts/sa@test.iam.gserviceaccount.com:signBlob' =>
              http.Response(
                jsonEncode({
                  'error': {
                    'code': 403,
                    'message':
                        'Permission iam.serviceAccounts.signBlob denied.',
                    'status': 'PERMISSION_DENIED',
                  },
                }),
                403,
              ),
            _ => http.Response('Not found', 404),
          },
        );

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
      });

      test('throws SigningException on network error from signBlob', () async {
        final message = utf8.encode('Test network error');

        final mockClient = MockClient(
          (request) async => switch (request.url.path) {
            '/computeMetadata/v1/instance/service-accounts/default/token' =>
              http.Response(
                jsonEncode({
                  'access_token': 'token-123',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                }),
                200,
              ),
            '/v1/projects/-/serviceAccounts/sa@test.iam.gserviceaccount.com:signBlob' =>
              throw http.ClientException('Connection reset by peer'),
            _ => http.Response('Not found', 404),
          },
        );

        final creds = await ComputeEngineCredentials.create(
          client: mockClient,
          clientEmail: 'sa@test.iam.gserviceaccount.com',
          metadataHost: 'test-metadata',
        );

        expect(
          () => creds.sign(message),
          throwsA(
            isA<SigningException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to sign message via IAM signBlob API'),
                )
                .having(
                  (e) => e.innerException,
                  'innerException',
                  isA<http.ClientException>(),
                ),
          ),
        );
      });

      test(
        'signs message using ComputeEngineCredentials',
        tags: ['google-cloud'],
        skip: isOnGce ? null : 'Not running on Google Compute Engine',
        () async {
          final creds = await ComputeEngineCredentials.create();
          expect(creds.clientEmail, contains('@'));

          final message = utf8.encode(
            'Hello from ComputeEngineCredentials test!',
          );
          final signature = await creds.sign(message);

          expect(signature, isNotEmpty);
          expect(signature.length, greaterThan(64));
        },
      );
    });
  });
}
