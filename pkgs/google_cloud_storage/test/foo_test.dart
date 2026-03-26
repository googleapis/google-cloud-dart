import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_storage/google_cloud_storage.dart';
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

  group('upload object', () {
    group('google-cloud', tags: ['google-cloud'], () {
      setUp(() {
        storage = Storage();
      });

      tearDown(() => storage.close());

      test('new, no metadata', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_str_no_meta',
        );

        final sink = storage.uploadObjectFromSink(bucketName, 'name')
          ..add([1, 2, 3])
          ..add([4, 5, 6]);
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, [1, 2, 3, 4, 5, 6]);
      });

      test('small, large write', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_str_no_meta',
        );

        final sink = storage.uploadObjectFromSink(bucketName, 'name')
          ..add(small)
          ..add(large)
          ..add(small);
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, small + large + small);
      });

      test('stream', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_str_no_meta',
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

      test('stream 1', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_str_no_meta',
        );

        final sink = storage.uploadObjectFromSink(bucketName, 'name');

        await sink.addStream(Stream.fromIterable([small, large, small]));
        await sink.close();

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, small + large + small);
      });

      test('mixed', () async {
        final bucketName = await createBucketWithTearDown(
          storage,
          'ul_obj_from_str_no_meta',
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
          'ul_obj_from_str_no_meta',
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
          'ul_obj_from_str_no_meta',
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
    });
  });
}
