library storage_test;

import 'package:google_cloud_storage/src/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:test/test.dart';
import 'package:test_utils/test_http_client.dart';

void main() async {
  late StorageClient storageClient;
  late TestHttpClient testClient;

  group('StorageClient', () {
    late auth.AutoRefreshingAuthClient autoRefreshingAuthClient;

    setUp(() async {
      autoRefreshingAuthClient = await auth.clientViaApplicationDefaultCredentials(
        scopes: [
          'https://www.googleapis.com/auth/cloud-platform',
          'https://www.googleapis.com/auth/devstorage.full_control',
        ],
      );
      testClient = await TestHttpClient.fromEnvironment(() async => autoRefreshingAuthClient);
      storageClient = StorageClient(testClient);
    });

    tearDown(() {
      storageClient.close();
    });

    test('listBuckets', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_buckets',
      );

      final result = await storageClient.listBuckets();
      expect(result.items, isA<List>());
      await testClient.endTest();
    });

    test('getBucket', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'get_bucket',
      );

      final result = await storageClient.getBucket('my-test-bucket');
      expect(result.name, 'my-test-bucket');
      await testClient.endTest();
    });

    test('listObjects', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'list_objects',
      );

      final result = await storageClient.listObjects('my-test-bucket');
      expect(result.items, isA<List>());
      await testClient.endTest();
    });

    test('getObject', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'get_object',
      );

      final result = await storageClient.getObject('my-test-bucket', 'my-test-object');
      expect(result.name, 'my-test-object');
      await testClient.endTest();
    });

    test('uploadObject', () async {
      await testClient.startTest(
        'google_cloud_storage',
        'upload_object',
      );

      final data = Stream.fromIterable(['Hello World'.codeUnits]);
      final result = await storageClient.uploadObject(
        'my-test-bucket',
        'my-test-object',
        data,
        11,
        contentType: 'text/plain',
      );
      expect(result.name, 'my-test-object');
      await testClient.endTest();
    });
  });
}
