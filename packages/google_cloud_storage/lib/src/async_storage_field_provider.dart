import 'dart:async';

import 'package:google_cloud/google_cloud.dart' show computeProjectId;
import 'package:google_cloud_rpc/service_client.dart' show ServiceClient;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class AsyncStorageFieldProvider {
  ServiceClient? _cachedServiceClient;
  final FutureOr<http.Client> _httpClient;
  final FutureOr<String> _projectId;

  static FutureOr<http.Client> _calculateClient(
    http.Client? client,
    String? emulatorHost,
  ) => switch ((client, emulatorHost)) {
    (final http.Client client, _) => client,
    (null, final String _) => http.Client(),
    (null, null) => auth.clientViaApplicationDefaultCredentials(
      scopes: [
        'https://www.googleapis.com/auth/cloud-platform',
        'https://www.googleapis.com/auth/devstorage.read_write',
      ],
    ),
  };

  //
  static FutureOr<String> _calculateProjectId(
    String? projectId,
    String? emulatorHost,
  ) => switch ((projectId, emulatorHost)) {
    (final String projectId, _) => projectId,
    // This is the default project ID used by the Python client:
    // https://github.com/googleapis/python-storage/blob/4d98e32c82811b4925367d2fee134cb0b2c0dae7/google/cloud/storage/client.py#L152
    (null, final String _) => '<none>',
    (null, null) => computeProjectId(),
  };

  FutureOr<ServiceClient> get _serviceClient async =>
      _cachedServiceClient ??= ServiceClient(client: await _httpClient);

  AsyncStorageFieldProvider({
    String? projectId,
    http.Client? client,
    String? emulatorHost,
  }) : _projectId = _calculateProjectId(projectId, emulatorHost),
       _httpClient = _calculateClient(client, emulatorHost);

  Future<T> run<T>(
    Future<T> Function(
      ServiceClient serviceClient,
      http.Client httpClient,
      String projectId,
    )
    operation,
  ) async =>
      operation(await _serviceClient, await _httpClient, await _projectId);

  void close() {
    switch (_cachedServiceClient) {
      case null:
        switch (_httpClient) {
          case final Future<http.Client> future:
            // Swallow any asynchronous errors because there is nothing that we
            // can do about it always.
            future.then((client) => client.close(), onError: (_) {});
            break;
          case final http.Client client:
            client.close();
            break;
        }
      case final ServiceClient serviceClient:
        serviceClient.close();
        break;
    }
  }
}
