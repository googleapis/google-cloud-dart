// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:io';

import 'package:google_cloud/google_cloud.dart' show computeProjectId;
import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'bucket.dart';
import 'bucket_metadata_json.dart';
import 'bucket_metadata_patch_builder.dart'
    show BucketMetadataPatchBuilderJsonEncodable;
import 'file_download.dart';
import 'file_upload.dart';
import 'object_metadata_json.dart';
import 'object_metadata_patch_builder.dart'
    show ObjectMetadataPatchBuilderJsonEncodable;

class _JsonEncodableWrapper implements JsonEncodable {
  final Object json;

  _JsonEncodableWrapper(this.json);

  @override
  Object? toJson() => json;
}

/// API for storing and retrieving potentially large, immutable data objects.
///
/// See [Google Cloud Storage](https://cloud.google.com/storage).
final class Storage {
  ServiceClient? _cachedServiceClient;
  final FutureOr<http.Client> _httpClient;
  final FutureOr<String> _projectId;
  final Uri _baseUrl;

  static String? _getStorageEmulatorHost() =>
      Platform.environment['STORAGE_EMULATOR_HOST'];

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

  static Uri _calculateBaseUrl(
    String? apiEndpoint,
    bool useAuthWithCustomEndpoint,
  ) {
    if (apiEndpoint != null) {
      if (useAuthWithCustomEndpoint) return Uri.https(apiEndpoint);
      return Uri.http(apiEndpoint);
    }

    if (_getStorageEmulatorHost() case String host) {
      if (RegExp(r'^https?://').hasMatch(host)) {
        return Uri.parse(host);
      }
      return Uri.http(host);
    }

    return Uri.https('storage.googleapis.com');
  }

  /// Constructs a client used to communicate with [Google Cloud Storage][].
  ///
  /// By default, the client will use your [default application credentials][]
  /// to communicate with the production [Google Cloud Storage][] service and
  /// use the project inferred from the environment.
  ///
  /// You can explicitly provide a project ID by passing [projectId].
  ///
  /// To target an emulator, you can set the `'STORAGE_EMULATOR_HOST'`
  /// environment variable to the address at which your emulator is running.
  /// For example, set `STORAGE_EMULATOR_HOST=127.0.0.1:9199` to use the
  /// [Cloud Storage for Firebase Emulator][] with its default settings.
  ///
  /// You can also change the API endpoint by passing [apiEndpoint]. For
  /// example, `'localhost:9199'`. If the endpoint does not require credentials
  /// or TLS (e.g. the emulator) then set [useAuthWithCustomEndpoint] to
  /// `false`.
  ///
  /// To disable authentication (e.g. if you only wish to access public data) or
  /// to use authentication other than the default application credentials, you
  /// can provide your own [client].
  ///
  /// [Google Cloud Storage]: https://cloud.google.com/storage
  /// [Cloud Storage for Firebase Emulator]: https://firebase.google.com/docs/emulator-suite/connect_storage
  /// [default application credentials]: https://docs.cloud.google.com/docs/authentication/application-default-credentials
  Storage({
    String? projectId,
    String? apiEndpoint,
    bool useAuthWithCustomEndpoint = true,
    http.Client? client,
  }) : _projectId = _calculateProjectId(projectId, _getStorageEmulatorHost()),
       _httpClient = _calculateClient(client, _getStorageEmulatorHost()),
       _baseUrl = _calculateBaseUrl(apiEndpoint, useAuthWithCustomEndpoint);

  Uri _requestUrl(
    Iterable<String>? pathSegments,
    Map<String, dynamic>? queryParameters,
  ) => _baseUrl.replace(
    pathSegments: pathSegments,
    queryParameters: queryParameters,
  );

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// Once [close] is called, no other methods should be called.
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

  // Bucket-related methods, keep alphabetized.

  /// A [Google Cloud Storage bucket][] with the given [name].
  ///
  /// [name] should be a valid [bucket name][].
  ///
  /// The bucket need not actually exist on Google Cloud Storage. This method
  /// does not perform any network operations.
  ///
  /// [bucket name]: https://cloud.google.com/storage/docs/bucket-naming
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Bucket bucket(String name) => newBucket(this, name);

  /// Information about a [Google Cloud Storage bucket][].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the bucket does not exist.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the bucket metadata
  /// conditional on whether the bucket's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/get).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<BucketMetadata> bucketMetadata(
    String bucket, {
    BigInt? ifMetagenerationMatch,
    String? userProject,
    String? projection,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket],
      {
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
        'projection': ?projection,
        'userProject': ?userProject,
      },
    );
    final j = await serviceClient.get(url);
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: true);

  /// Create a new [Google Cloud Storage bucket][].
  ///
  /// This operation is always idempotent. Throws [ConflictException] if the
  /// bucket already exists.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/insert).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketMetadata> createBucket(
    BucketMetadata metadata, {
    bool enableObjectRetention = false,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final projectId = await _projectId;
    final url = _requestUrl(
      ['storage', 'v1', 'b'],
      {
        'project': projectId,
        'enableObjectRetention': enableObjectRetention.toString(),
      },
    );
    final j = await serviceClient.post(
      url,
      body: _JsonEncodableWrapper(bucketMetadataToJson(metadata)),
    );
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: true);

  /// Deletes an already-empty [Google Cloud Storage bucket][].
  ///
  /// This operation is idempotent if `ifMetagenerationMatch` is set.
  ///
  /// Throws [NotFoundException] if the bucket does not exist. Throws
  /// [ConflictException] if the bucket is not empty.
  ///
  /// If set, `ifMetagenerationMatch` makes deleting the bucket conditional on
  /// whether the bucket's metageneration matches the provided value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/delete).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<void> deleteBucket(
    String bucket, {
    BigInt? ifMetagenerationMatch,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket],
      {
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
        'userProject': ?userProject,
      },
    );
    await serviceClient.delete(url);
  }, isIdempotent: ifMetagenerationMatch != null);

  /// A stream of buckets in the project in lexicographical order by name.
  ///
  /// [prefix] filters the returned buckets to those whose names begin with the
  /// specified prefix.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If [softDeleted] is `true`, then the stream will include **only**
  /// [soft-deleted buckets][]. If `false`, then the stream will not include
  /// soft-deleted buckets.
  ///
  /// [maxResults] limits the number of buckets returned in a single API
  /// response. This does not affect the output but does affect the trade-off
  /// between latency and memory usage; a larger value will result in fewer
  /// network requests but higher memory usage.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/list).
  ///
  /// [soft-deleted buckets]: https://cloud.google.com/storage/docs/soft-delete
  Stream<BucketMetadata> listBuckets({
    String? prefix,
    String? projection,
    bool? softDeleted,
    int? maxResults,
  }) async* {
    String? nextPageToken;

    do {
      final serviceClient = await _serviceClient;
      final projectId = await _projectId;
      final url = _requestUrl(
        ['storage', 'v1', 'b'],
        {
          'maxResults': ?maxResults?.toString(),
          'project': projectId,
          'pageToken': ?nextPageToken,
          'projection': ?projection,
          'prefix': ?prefix,
          'softDeleted': ?softDeleted?.toString(),
        },
      );
      final json = await serviceClient.get(url);
      nextPageToken = json['nextPageToken'] as String?;

      for (final bucket in json['items'] as List<Object?>? ?? const []) {
        yield bucketMetadataFromJson(bucket as Map<String, Object?>);
      }
    } while (nextPageToken != null);
  }

  /// Update a [Google Cloud Storage bucket][].
  ///
  /// This operation is idempotent if [ifMetagenerationMatch] is set.
  ///
  /// If set, [ifMetagenerationMatch] makes updating the bucket metadata
  /// conditional on whether the bucket's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If set, [predefinedAcl] applies a predefined set of access controls to the
  /// bucket, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// For example:
  ///
  /// ```dart
  ///  final patchMetadata = BucketMetadataPatchBuilder()
  ///    ..autoclass = null
  ///    ..versioning = BucketVersioning(enabled: true);
  ///  await storage.patchBucket(
  ///    'my-bucket',
  ///    patchMetadata,
  ///  );
  /// ```
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/buckets/patch).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<BucketMetadata> patchBucket(
    String bucket,
    BucketMetadataPatchBuilder metadata, {
    BigInt? ifMetagenerationMatch,
    // TODO(https://github.com/googleapis/google-cloud-dart/issues/115):
    // support ifMetagenerationNotMatch.
    //
    // If `ifMetagenerationNotMatch` is set, the server will respond with a 304
    // status code and an empty body. This will cause `buckets.patch` to throw
    // `TypeError` during JSON deserialization.
    String? predefinedAcl,
    String? predefinedDefaultObjectAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final projectId = await _projectId;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket],
      {
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
        'project': projectId,
        'predefinedAcl': ?predefinedAcl,
        'predefinedDefaultObjectAcl': ?predefinedDefaultObjectAcl,
        'projection': ?projection,
        'userProject': ?userProject,
      },
    );
    final j = await serviceClient.patch(
      url,
      body: BucketMetadataPatchBuilderJsonEncodable(metadata),
    );
    return bucketMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: ifMetagenerationMatch != null);

  // Object-related methods, keep alphabetized.

  /// Deletes a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `generation` or `ifGenerationMatch` is
  /// set.
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If set, `generation` selects a specific revision of this object (as
  /// opposed to the latest version) to delete.
  ///
  /// If set, `ifGenerationMatch` makes the operation conditional on whether the
  /// object's current generation matches the given value. If the generation
  /// does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, `ifMetagenerationMatch` makes the operation conditional on whether
  /// the object's current metageneration matches the given value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/delete).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  Future<void> deleteObject(
    String bucket,
    String object, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object],
      {
        'generation': ?generation?.toString(),
        'ifGenerationMatch': ?ifGenerationMatch?.toString(),
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
      },
    );
    await serviceClient.delete(url);
  }, isIdempotent: ifGenerationMatch != null || generation != null);

  /// Download the content of a [Google Cloud Storage object][] as bytes.
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// If non-null, [generation] downloads a specific version of the object
  /// instead of the latest version.
  ///
  /// If non-null, [ifGenerationMatch] makes retrieving the object's data
  /// conditional on whether the object's generation matches the provided
  /// value. If the generation does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the object's data
  /// conditional on whether the object's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/get).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<Uint8List> downloadObject(
    String bucket,
    String object, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(
    () async => downloadFile(
      await _httpClient,
      _requestUrl(
        ['storage', 'v1', 'b', bucket, 'o', object],
        {
          'alt': 'media',
          'generation': ?generation?.toString(),
          'ifGenerationMatch': ?ifGenerationMatch?.toString(),
          'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
          'userProject': ?userProject,
        },
      ),
    ),
    isIdempotent: true,
  );

  /// Creates or updates the content of a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// `metadata.name` does not match [name], a [BadRequestException] is thrown.
  ///
  /// If set, `ifGenerationMatch` makes updating the object content conditional
  /// on whether the objects's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of `0` indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/insert).
  ///
  /// For example:
  ///
  /// ```dart
  /// final metadata = await storage.insertObject(
  ///   'my-bucket',
  ///   'hello.txt',
  ///   utf8.encode('Hello, World!'),
  ///   contentType: 'text/plain',
  ///   ifGenerationMatch: 0, // Only insert if the object doesn't exist.
  /// );
  /// ```
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> insertObject(
    String bucket,
    String name,
    List<int> content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    // TODO(https://github.com/googleapis/google-cloud-dart/issues/115):
    // support ifMetagenerationNotMatch.
    //
    // If `ifMetagenerationNotMatch` is set, the server will respond with a 304
    // status code and an empty body. This will cause `buckets.patch` to throw
    // `TypeError` during JSON deserialization.
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final projectId = await _projectId;
    return uploadFile(
      await _httpClient,
      _requestUrl(
        ['upload', 'storage', 'v1', 'b', bucket, 'o'],
        {
          'uploadType': 'multipart',
          'name': name,
          'project': projectId,
          'ifGenerationMatch': ?ifGenerationMatch?.toString(),
          'predefinedAcl': ?predefinedAcl,
          'projection': ?projection,
          'userProject': ?userProject,
        },
      ),
      content,
      metadata: metadata,
    );
  }, isIdempotent: ifGenerationMatch != null);

  /// A stream of objects contained in [bucket] in lexicographical order by
  /// name.
  ///
  /// If [softDeleted] is `true`, then the stream will include **only**
  /// [soft-deleted objects][]. If `false`, then the stream will not include
  /// soft-deleted objects.
  ///
  /// If [versions] is `true`, then the stream will include all versions of
  /// each object in increasing order by version number.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// [maxResults] limits the number of objects returned in a single API
  /// response. This does not affect the output but does affect the trade-off
  /// between latency and memory usage; a larger value will result in fewer
  /// network requests but higher memory usage.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/list).
  ///
  /// [soft-deleted objects]: https://cloud.google.com/storage/docs/soft-delete
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Stream<ObjectMetadata> listObjects(
    String bucket, {
    bool? softDeleted,
    bool? versions,
    String? projection,
    String? userProject,
    int? maxResults,
  }) async* {
    String? nextPageToken;

    do {
      final serviceClient = await _serviceClient;
      final url = _requestUrl(
        ['storage', 'v1', 'b', bucket, 'o'],
        {
          'softDeleted': ?softDeleted?.toString(),
          'versions': ?versions?.toString(),
          'maxResults': ?maxResults?.toString(),
          'pageToken': ?nextPageToken,
          'projection': ?projection,
          'userProject': ?userProject,
        },
      );
      final json = await serviceClient.get(url);
      nextPageToken = json['nextPageToken'] as String?;

      for (final object in json['items'] as List<Object?>? ?? const []) {
        yield objectMetadataFromJson(object as Map<String, Object?>);
      }
    } while (nextPageToken != null);
  }

  /// Information about a [Google Cloud Storage object].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If non-null, [generation] returns a specific version of the object
  /// instead of the latest version.
  ///
  /// If non-null, [ifGenerationMatch] makes retrieving the object metadata
  /// conditional on whether the object's generation matches the provided
  /// value. If the generation does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// If non-null, [ifMetagenerationMatch] makes retrieving the object metadata
  /// conditional on whether the object's metageneration matches the provided
  /// value. If the metageneration does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all bucket properties, while a value of
  /// `"noAcl"` (the default) omits the `owner`, `acl`, and `defaultObjectAcl`
  /// properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/get).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> objectMetadata(
    String bucket,
    String object, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object],
      {
        'generation': ?generation?.toString(),
        'ifGenerationMatch': ?ifGenerationMatch?.toString(),
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
        'projection': ?projection,
        'userProject': ?userProject,
      },
    );
    final j = await serviceClient.get(url);
    return objectMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: true);

  /// Updates the metadata associated with a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if [ifMetagenerationMatch] is set.
  ///
  /// If set, [generation] selects a specific revision of this object (as
  /// opposed to the latest version) to patch.
  ///
  /// If set, [ifGenerationMatch] makes the operation conditional on whether the
  /// object's current generation matches the given value. If the generation
  /// does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, [ifMetagenerationMatch] makes the operation conditional on whether
  /// the object's current metageneration matches the given value. If the
  /// metageneration does not match, a [PreconditionFailedException] is thrown.
  ///
  /// If set, [predefinedAcl] applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting [predefinedAcl] will result in a
  /// [BadRequestException].
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/patch).
  ///
  /// For example:
  ///
  /// ```dart
  ///  final patchMetadata = ObjectMetadataPatchBuilder()
  ///    ..contentType = 'text/plain'
  ///    ..metadata = {'key': 'value'};
  ///  await storage.patchObject(
  ///    'my-bucket',
  ///    'my-object',
  ///    patchMetadata,
  ///  );
  /// ```
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> patchObject(
    String bucket,
    String name,
    ObjectMetadataPatchBuilder metadata, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', name],
      {
        'generation': ?generation?.toString(),
        'ifGenerationMatch': ?ifGenerationMatch?.toString(),
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
        'predefinedAcl': ?predefinedAcl,
        'projection': ?projection,
        'userProject': ?userProject,
      },
    );
    final j = await serviceClient.patch(
      url,
      body: ObjectMetadataPatchBuilderJsonEncodable(metadata),
    );
    return objectMetadataFromJson(j as Map<String, Object?>);
  }, isIdempotent: ifMetagenerationMatch != null);
}
