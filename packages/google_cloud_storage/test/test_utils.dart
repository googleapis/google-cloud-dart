import 'dart:math';

import 'package:google_cloud_storage/google_cloud_storage.dart';
import 'package:test/test.dart';
import 'package:test_utils/test_http_client.dart';

const _bucketChars = 'abcdefghijklmnopqrstuvwxyz0123456789';
final _random = Random();

String uniqueBucketName() => [
  for (int i = 0; i < 60; i++)
    _bucketChars[_random.nextInt(_bucketChars.length)],
].join();

String bucketName(String name) =>
    TestHttpClient.isRecording || TestHttpClient.isReplaying
    ? name
    : '$name-${uniqueBucketName()}'.substring(0, 60);

String bucketNameWithTearDown(Storage storage, String name) {
  final generatedName = bucketName(name);
  addTearDown(() async {
    try {
      await storage.deleteBucket(generatedName);
    } on NotFoundException {
      // Ignore.
    }
  });
  return generatedName;
}
