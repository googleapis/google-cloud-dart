library google_cloud_storage;

import 'package:http/http.dart' as http;

import 'bucket.dart';
import 'package:google_cloud_rpc/service_client.dart';

// _RETRYABLE_STATUS_CODES = (
//     http.client.TOO_MANY_REQUESTS,  # 429
//     http.client.REQUEST_TIMEOUT,  # 408
//     http.client.INTERNAL_SERVER_ERROR,  # 500
//     http.client.BAD_GATEWAY,  # 502
//     http.client.SERVICE_UNAVAILABLE,  # 503
//     http.client.GATEWAY_TIMEOUT,  # 504
// )
class StorageService {
  final ServiceClient _client;
  static const _host = 'storage.googleapis.com';

  StorageService({required http.Client client})
    : _client = ServiceClient(client: client);

  Bucket bucket(String bucketName) {
    return Bucket(name: bucketName);
  }

  /// Creates a new bucket.
  ///
  /// See https://cloud.google.com/storage/docs/json_api/v1/buckets/insert
  Future<Bucket> createBucket({
    required String bucketName,
    String? project,
    String? userProject,
    String? location,
  }) async {
    final query = {
      if (project != null) 'project': project,
      if (userProject != null) 'userProject': userProject,
      if (location != null) 'location': location,
    };

    final body = Bucket(name: bucketName);

    final url = Uri.https(_host, 'storage/v1/b', query);
    final response = await _client.post(url, body: body);

    return Bucket.fromJson(response);
  }

  void close() {
    _client.close();
  }
}
