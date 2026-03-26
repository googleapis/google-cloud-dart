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

        final x = storage.foo(
          bucketName,
          'name',
          metadata: ObjectMetadata(contentType: 'text/plain'),
        );

        x.add([1, 2, 3]);
        x.add([4, 5, 6]);
        await x.close();

        final downloaded = await storage.downloadObject(bucketName, 'name');
        expect(downloaded, [1, 2, 3, 4, 5, 6]);
      });
    });
  });
}
