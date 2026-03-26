import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() async {
  late Storage storage;

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

        await storage.foo(
          bucketName,
          'name',
          List.generate(256 * 1024, (i) => i % 256),
          [1, 2, 3],
          metadata: ObjectMetadata(contentType: 'text/plain'),
        );

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, isEmpty);
      });
    });
  });
}
