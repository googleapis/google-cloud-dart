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

String _bucketName(String name) {
  assert(name.length < 55, '"$name" is too long to append a random suffix.');
  return TestHttpClient.isRecording || TestHttpClient.isReplaying
      ? name
      : '$name-${_randomSuffix(59 - name.length)}';
}

String bucketNameWithTearDown(Storage storage, String name) {
  final generatedName = _bucketName(name);
  addTearDown(() async {
    try {
      await storage.deleteBucket(generatedName);
    } on NotFoundException {
      // Ignore.
    }
  });
  return generatedName;
}
