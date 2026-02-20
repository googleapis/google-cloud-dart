import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';
import 'package:test_utils/test_http_client.dart';

const _bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String _randomSuffix(int length) => [
  for (int i = 0; i < length; i++)
    _bucketChars[_random.nextInt(_bucketChars.length)],
].join();

String testBucketName(String name) {
  assert(name.length < 55, '"$name" is too long to append a random suffix.');
  return TestHttpClient.isRecording || TestHttpClient.isReplaying
      ? name
      : '$name-${_randomSuffix(59 - name.length)}';
}

String bucketNameWithTearDown(Storage storage, String name) {
  final generatedName = testBucketName(name);
  addTearDown(() async {
    try {
      // Disable bucket versioning so that `deleteObject` deletes all versions.
      await storage.patchBucket(
        generatedName,
        BucketMetadataPatchBuilder()..versioning = null,
      );
      for (final object in await storage.listObjects(generatedName).toList()) {
        await storage.patchObject(
          generatedName,
          object.name!,
          ObjectMetadataPatchBuilder()
            ..eventBasedHold = false
            ..temporaryHold = false,
        );
        await storage.deleteObject(generatedName, object.name!);
      }
      await storage.deleteBucket(generatedName);
    } on NotFoundException {
      // Ignore.
    }
  });
  return generatedName;
}

Future<String> createBucketWithTearDown(
  Storage storage,
  String name, {
  BucketMetadata? metadata,
  bool enableObjectRetention = false,
}) async {
  final bucketName = bucketNameWithTearDown(storage, name);
  final meta = (metadata == null)
      ? BucketMetadata(name: bucketName)
      : metadata.copyWith(name: bucketName);
  await storage.createBucket(
    meta,
    enableObjectRetention: enableObjectRetention,
  );
  return bucketName;
}
