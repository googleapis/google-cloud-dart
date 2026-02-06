import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';
import 'package:test_utils/test_http_client.dart';

const _bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String uniqueBucketName() => [
  for (int i = 0; i < 32; i++)
    _bucketChars[_random.nextInt(_bucketChars.length)],
].join();

String bucketName(String name) {
  final bucketName = TestHttpClient.isRecording || TestHttpClient.isReplaying
      ? name
      : uniqueBucketName();

  return bucketName;
}

String bucketNameWithCleanup(Storage storage, String name) {
  final generatedName = bucketName(name);

  addTearDown(() => storage.deleteBucket(generatedName));

  return generatedName;
}
