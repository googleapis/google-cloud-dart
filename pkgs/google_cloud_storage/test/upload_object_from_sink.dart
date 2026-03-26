import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_storage/google_cloud_storage.dart';
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

void main() async {
  late Storage storage;
  final small = randomUint8List(100);
  final large = randomUint8List(5_000_000);

  group('upload object from sink', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() {
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('metadata is not set', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_sink_no_meta',
        );

        final sink = storage.uploadObjectFromSink(bucketName, 'object');
        await sink.close();

        final metadata = await storage.objectMetadata(bucketName, 'object');
        expect(metadata.contentType, 'application/octet-stream');
      });

      test('metadata is set without contentType', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_sink_cust_meta',
        );

        final sink = storage.uploadObjectFromSink(
          bucketName,
          'object',
          metadata: ObjectMetadata(metadata: {'customMetadata': 'value'}),
        );
        await sink.close();

        final metadata = await storage.objectMetadata(bucketName, 'object');
        expect(metadata.contentType, 'application/octet-stream');
        expect(metadata.metadata?['customMetadata'], 'value');
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
        expect(downloaded, List.generate(18, (i) => i + 1));
      });

      test('addStream during addStream', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_sink_add_w_as',
        );

        final sink = storage.uploadObjectFromSink(bucketName, 'name');
        final c = StreamController<List<int>>();
        c.add([1, 2, 3]);

        final addStream1Future = sink.addStream(c.stream);
        expect(() => sink.add([1, 2, 3]), throwsStateError);
        c.add([4, 5, 6]);
        await c.close();

        await addStream1Future;
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
        final c = StreamController<List<int>>();
        c.add([1, 2, 3]);

        final addStream1Future = sink.addStream(c.stream);
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

        await addStream1Future;
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, [1, 2, 3, 4, 5, 6]);
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
    });
  });
}
