import 'dart:convert';

import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'retry.dart';

class StorageInternal implements StorageService {
  static const _host = 'storage.googleapis.com';

  final http.Client client;

  StorageInternal(this.client);

  @override
  Future<Bucket> createBucket({
    required String bucketName,
    String? project,
    Retry retry = defaultRetry,
  }) async {
    final query = {if (project != null) 'project': project};

    final body = Bucket(name: bucketName);

    final url = Uri.https(_host, 'storage/v1/b', query);
    final response = await retry.run(() => http.post(url, body: body));

    return Bucket.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteBucket(
    String bucketName, {
    Retry retry = defaultRetry,
  }) async {
    final url = Uri.https(_host, 'storage/v1/b/$bucketName');
    await retry.run(() => client.delete(url));
  }

  void close() {
    client.close();
  }
}
