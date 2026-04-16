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

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:google_cloud_storage/src/crc32c.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

Uint8List randomUint8List(int length, {int? seed}) {
  final random = Random(seed);
  final l = Uint8List(length);
  for (var i = 0; i < length; ++i) {
    l[i] = random.nextInt(255);
  }
  return l;
}

final small = randomUint8List(100);
final large = randomUint8List(5_000_000);

void uploadObjectFromSinkTest(Storage Function() createStorage) {
  late Storage storage;

  setUp(() {
    storage = createStorage();
  });

  tearDown(() => storage.close());

  test('metadata is not set', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_no_meta',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'object');
    final metadata = await sink.close();
    expect(metadata.contentType, 'application/octet-stream');
  });

  test('metadata is set without contentType', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_wo_ct',
    );

    final sink = storage.uploadObjectFromSink(
      bucketName,
      'object',
      metadata: ObjectMetadata(metadata: {'customMetadata': 'value'}),
    );
    final metadata = await sink.close();
    expect(metadata.contentType, 'application/octet-stream');
    expect(metadata.metadata?['customMetadata'], 'value');
  });

  test('metadata is set with contentType', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_with_ct',
    );

    final sink = storage.uploadObjectFromSink(
      bucketName,
      'object',
      metadata: ObjectMetadata(
        contentType: 'text/plain',
        metadata: {'customMetadata': 'value'},
      ),
    );
    final metadata = await sink.close();
    expect(metadata.contentType, 'text/plain');
    expect(metadata.metadata?['customMetadata'], 'value');
  });

  test('with if generation match success', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_overwrite_if_gen_match_ok',
    );

    final oldGeneration = (await storage.uploadObject(
      bucketName,
      'object1',
      utf8.encode('Hello World!'),
    )).generation;

    final sink = storage.uploadObjectFromSink(
      bucketName,
      'object1',
      ifGenerationMatch: oldGeneration,
    )..add(const <int>[1, 2, 3]);
    final newGeneration = (await sink.close()).generation;
    expect(newGeneration, isNot(oldGeneration));
  });

  test('with if generation match failure', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_overwrite_if_gen_match_fail',
    );

    await storage.uploadObject(
      bucketName,
      'object1',
      utf8.encode('Hello World!'),
    );
    final sink = storage.uploadObjectFromSink(
      bucketName,
      'object1',
      ifGenerationMatch: BigInt.from(1234),
    )..add(const <int>[1, 2, 3]);
    await expectLater(sink.close, throwsA(isA<PreconditionFailedException>()));
  });

  test('immediate close', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_immediate_close',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, isEmpty);
  });

  test('zero length adds', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_zero_length_adds',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'object')
      ..add([])
      ..add([]);
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'object');
    expect(downloaded, isEmpty);
  });

  test('empty stream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_empty_stream',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'object');
    await sink.addStream(const Stream.empty());
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'object');
    expect(downloaded, isEmpty);
  });

  test('empty list stream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_empty_list_stream',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'object');
    await sink.addStream(Stream.fromIterable([[], []]));
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'object');
    expect(downloaded, isEmpty);
  });

  test('small adds', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_no_meta',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add([1, 2, 3])
      ..add([4, 5, 6]);
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3, 4, 5, 6]);
  });

  test('small add, large add, small add', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_s_l_s',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add(small)
      ..add(large)
      ..add(small);
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, small + large + small);
  });

  test('small stream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_small_stream',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');

    await sink.addStream(
      Stream.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]),
    );
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3, 4, 5, 6]);
  });

  test('stream with small, large, small', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_stream_s_l_s',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');

    await sink.addStream(Stream.fromIterable([small, large, small]));
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, small + large + small);
  });

  test('stream with large, large, large', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_stream_l_l_l',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');

    await sink.addStream(Stream.fromIterable([large, large, large]));
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, large + large + large);
  });

  test('mixed adds and streams', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_mixed',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add([1, 2, 3])
      ..add([4, 5, 6]);
    await sink.addStream(
      Stream.fromIterable([
        [7, 8, 9],
        [10, 11, 12],
      ]),
    );
    sink
      ..add([13, 14, 15])
      ..add([16, 17, 18]);
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [for (var i = 0; i < 18; i++) i + 1]);
  });

  test('upload exactly 256KB via addStream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_chunk_size',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');
    final exact = randomUint8List(256 * 1024);
    await sink.addStream(Stream.fromIterable([exact]));
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, exact);
  });

  test('duplicate close', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_duplicate_close',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add([1, 2, 3]);
    await sink.close();
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3]);
  });

  test('add after close', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_add_after_close',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add([1, 2, 3]);
    await sink.close();
    expect(() => sink.add([1, 2, 3]), throwsStateError);

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3]);
  });

  test('addStream after close', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_add_stream_after_close',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name')
      ..add([1, 2, 3]);
    await sink.close();
    await expectLater(
      () => sink.addStream(
        Stream.fromIterable([
          [1, 2, 3],
        ]),
      ),
      throwsStateError,
    );

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3]);
  });

  test('add during addStream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_add_w_as',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');
    final c = StreamController<List<int>>()..add([1, 2, 3]);

    final addStream = sink.addStream(c.stream);
    expect(() => sink.add([1, 2, 3]), throwsStateError);
    c.add([4, 5, 6]);
    await c.close();

    await addStream;
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3, 4, 5, 6]);
  });

  test('addStream during addStream', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_as_w_as',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'name');
    final c = StreamController<List<int>>()..add([1, 2, 3]);

    final addStream = sink.addStream(c.stream);
    await expectLater(
      sink.addStream(
        Stream.fromIterable([
          [1, 2, 3],
          [4, 5, 6],
        ]),
      ),
      throwsStateError,
    );
    c.add([4, 5, 6]);
    await c.close();

    await addStream;
    await sink.close();

    final downloaded = await storage.downloadObject(bucketName, 'name');
    expect(downloaded, [1, 2, 3, 4, 5, 6]);
  });

  test('hashes', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_hashes',
    );

    final data = [1, 2, 3, 4, 5, 6];
    final expectedCrc32c = (Crc32c()..update(data)).toBase64();
    final expectedMd5Hash = base64Encode(crypto.md5.convert(data).bytes);

    final sink = storage.uploadObjectFromSink(bucketName, 'object')..add(data);
    final metadata = await sink.close();
    expect(metadata.crc32c, expectedCrc32c);
    expect(metadata.md5Hash, expectedMd5Hash);
  });

  test('ResumeableUpload.metadata is set', () async {
    final bucketName = await createBucketWithTearDown(
      storage,
      'ul_obj_from_sink_metadata',
    );

    final sink = storage.uploadObjectFromSink(bucketName, 'object')
      ..add([1, 2, 3, 4, 5, 6]);
    expect(sink.metadata, isNull);
    await sink.close();
    expect(sink.metadata?.size, BigInt.from(6));
  });
}

void main() {
  group('upload object from sink', () {
    group('google-cloud', tags: ['google-cloud'], () {
      uploadObjectFromSinkTest(Storage.new);
    });

    group('storage-testbench', tags: ['storage-testbench'], () {
      late Storage storage;
      late RetryTestHttpClient client;

      setUp(() {
        client = RetryTestHttpClient(http.Client());
        storage = Storage(
          projectId: 'test-project',
          apiEndpoint: 'localhost:9000',
          useAuthWithCustomEndpoint: false,
          client: client,
        );
      });

      tearDown(() => storage.close());

      uploadObjectFromSinkTest(() => storage);

      test('return 503 after 256K', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_sink_503_after_256k',
        );

        client.instructions = 'return-503-after-256K';

        final sink = storage.uploadObjectFromSink(
          bucketName,
          'object',
          retry: const NoDelayRetry(),
        )..add(large);
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'object');
        expect(downloaded, large);
      });

      test('return 503 during session creation (idempotent)', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_sink_503_sess_create',
        );

        final retryTestCreator = RetryTestCreator(http.Client());
        final id = await retryTestCreator.createRetryTest({
          'instructions': {
            'storage.objects.insert': ['return-503'],
          },
        });
        client.retryTestId = id;

        final sink = storage.uploadObjectFromSink(
          bucketName,
          'object',
          ifGenerationMatch: BigInt.zero, // Makes session creation idempotent
          retry: const NoDelayRetry(),
        )..add(small);
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'object');
        expect(downloaded, small);

        client.retryTestId = null;
        await retryTestCreator.close();
      });

      test(
        'fails without retry on 503 during session creation (non-idempotent)',
        () async {
          final bucketName = await createBucketWithTearDown(
            storage,
            'ul_obj_from_sink_503_sess_create_fail',
          );

          final retryTestCreator = RetryTestCreator(http.Client());
          final id = await retryTestCreator.createRetryTest({
            'instructions': {
              'storage.objects.insert': ['return-503'],
            },
          });
          client.retryTestId = id;

          final sink = storage.uploadObjectFromSink(
            bucketName,
            'object',
            // No ifGenerationMatch, hence non-idempotent
          )..add(small);

          await expectLater(sink.close(), throwsA(isA<ServiceException>()));

          await retryTestCreator.close();
        },
      );
    });

    test('first close fails and second close succeeds', () async {
      late String actualHash;

      final responses =
          <(String, Future<http.Response> Function(http.Request))>[
            (
              'POST',
              (request) async => http.Response(
                '',
                200,
                headers: {'location': 'http://example.com/location'},
              ),
            ),
            // First close fails. Throw a StateError to avoid triggering retry
            // loops.
            ('PUT', (request) async => throw StateError('message')),
            // Second close succeeds.
            (
              'PUT',
              (request) async {
                actualHash = request.headers['x-goog-hash']!;
                return http.Response('{}', 200);
              },
            ),
          ];

      final mockClient = MockClient((request) async {
        if (responses.isEmpty) {
          throw StateError(
            'Unexpected call (method: ${request.method}, '
            'uri: ${request.url})',
          );
        }
        final (expectedMethod, handler) = responses.removeAt(0);
        if (request.method != expectedMethod) {
          throw StateError(
            'Expected $expectedMethod but got ${request.method} '
            'for ${request.url}',
          );
        }
        return await handler(request);
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final data = [1, 2, 3, 4, 5, 6];
      final sink = storage.uploadObjectFromSink('bucket', 'object')..add(data);

      await expectLater(sink.close, throwsA(isA<StateError>()));
      await sink.close();
      expect(actualHash, 'crc32c=T037qw==,md5=asHla8ePAxBZvnvoVFIsTA==');
      expect(responses, isEmpty);
    });

    test('fails if server acknowledged bytes is less than expected', () async {
      final responses =
          <(String, Future<http.Response> Function(http.Request))>[
            (
              'POST',
              (request) async => http.Response(
                '',
                200,
                headers: {'location': 'http://example.com/location'},
              ),
            ),
            // First chunk upload works.
            (
              'PUT',
              (request) async =>
                  http.Response('', 308, headers: {'range': 'bytes=0-262143'}),
            ),
            // Second chunk upload fails.
            ('PUT', (request) async => throw http.ClientException('message')),
            // Status check returns a range smaller than what was acknowledged
            // previously.
            (
              'PUT',
              (request) async =>
                  http.Response('', 308, headers: {'range': 'bytes=0-1000'}),
            ),
          ];

      final mockClient = MockClient((request) async {
        if (responses.isEmpty) {
          throw StateError(
            'Unexpected call (method: ${request.method}, '
            'uri: ${request.url})',
          );
        }
        final (expectedMethod, handler) = responses.removeAt(0);
        if (request.method != expectedMethod) {
          throw StateError(
            'Expected $expectedMethod but got ${request.method} '
            'for ${request.url}',
          );
        }
        return await handler(request);
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final sink = storage.uploadObjectFromSink(
        'bucket',
        'object',
        retry: const NoDelayRetry(),
      );

      final chunk = Uint8List(256 * 1024);
      await expectLater(
        sink.addStream(Stream.fromIterable([chunk, chunk])),
        throwsA(isA<StateError>()),
      );
      expect(responses, isEmpty);
    });

    test('succeeds if second chunk fails and retries', () async {
      final responses =
          <(String, Future<http.Response> Function(http.Request))>[
            (
              'POST',
              (request) async => http.Response(
                '',
                200,
                headers: {'location': 'http://example.com/location'},
              ),
            ),
            // First chunk (256K) upload works.
            (
              'PUT',
              (request) async =>
                  http.Response('', 308, headers: {'range': 'bytes=0-262143'}),
            ),
            // Second chunk (256K) upload fails.
            ('PUT', (request) async => throw http.ClientException('message')),
            // Status check indicates that only the first chunk is received.
            (
              'PUT',
              (request) async =>
                  http.Response('', 308, headers: {'range': 'bytes=0-262143'}),
            ),
            // Retry for the second chunk upload works.
            (
              'PUT',
              (request) async =>
                  http.Response('', 308, headers: {'range': 'bytes=0-524287'}),
            ),
            // Final 0 byte close.
            ('PUT', (request) async => http.Response('{}', 200)),
          ];

      final mockClient = MockClient((request) async {
        if (responses.isEmpty) {
          throw StateError(
            'Unexpected call (method: ${request.method}, '
            'uri: ${request.url})',
          );
        }
        final (expectedMethod, handler) = responses.removeAt(0);
        if (request.method != expectedMethod) {
          throw StateError(
            'Expected $expectedMethod but got ${request.method} '
            'for ${request.url}',
          );
        }
        return await handler(request);
      });

      final storage = Storage(client: mockClient, projectId: 'fake project');

      final sink = storage.uploadObjectFromSink(
        'bucket',
        'object',
        retry: const NoDelayRetry(),
      );

      final chunk = Uint8List(256 * 1024);
      await sink.addStream(Stream.fromIterable([chunk, chunk]));
      await sink.close();

      expect(responses, isEmpty);
    });

    test(
      'retries if server acknowledges fewer bytes than sent in a chunk',
      () async {
        final responses =
            <(String, Future<http.Response> Function(http.Request))>[
              (
                'POST',
                (request) async => http.Response(
                  '',
                  200,
                  headers: {'location': 'http://example.com/location'},
                ),
              ),
              // First chunk (256K) upload works, but only acknowledges 100K.
              (
                'PUT',
                (request) async =>
                    http.Response('', 308, headers: {'range': 'bytes=0-99999'}),
              ),
              // Retry for the rest of the first chunk (128K).
              // Buffer was 256K, initialExpected was 0.
              // currentExpected is 131072.
              (
                'PUT',
                (request) async {
                  expect(request.contentLength, 262144);
                  expect(request.headers['Content-Range'], 'bytes 0-262143/*');
                  return http.Response(
                    '',
                    308,
                    headers: {'range': 'bytes=0-262143'},
                  );
                },
              ),
              // Final 0 byte close.
              ('PUT', (request) async => http.Response('{}', 200)),
            ];

        final mockClient = MockClient((request) async {
          if (responses.isEmpty) {
            throw StateError(
              'Unexpected call (method: ${request.method}, '
              'uri: ${request.url})',
            );
          }
          final (expectedMethod, handler) = responses.removeAt(0);
          if (request.method != expectedMethod) {
            throw StateError(
              'Expected $expectedMethod but got ${request.method} '
              'for ${request.url}',
            );
          }
          return await handler(request);
        });

        final storage = Storage(client: mockClient, projectId: 'fake project');

        final sink = storage.uploadObjectFromSink(
          'bucket',
          'object',
          retry: const NoDelayRetry(),
        );

        final chunk = Uint8List(256 * 1024);
        await sink.addStream(Stream.fromIterable([chunk]));
        await sink.close();

        expect(responses, isEmpty);
      },
    );
  });
}
