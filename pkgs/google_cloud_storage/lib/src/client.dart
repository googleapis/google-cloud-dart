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
import 'dart:convert';

import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_rpc/service_client.dart';
import 'package:http/http.dart' as http;

import '../google_cloud_storage.dart';
import 'bucket.dart';
import 'bucket_metadata_json.dart';
import 'bucket_metadata_patch_builder.dart'
    show BucketMetadataPatchBuilderJsonEncodable;
import 'common_json.dart';
import 'default_http_client_web.dart'
    if (dart.library.io) 'default_http_client_vm.dart';
import 'default_project_id_web.dart'
    if (dart.library.io) 'default_project_id_vm.dart';
import 'file_download.dart';
import 'file_upload.dart';
import 'object_metadata_json.dart';
import 'object_metadata_patch_builder.dart'
    show ObjectMetadataPatchBuilderJsonEncodable;
import 'resumeable_upload.dart';
import 'storage_emulator_host_web.dart'
    if (dart.library.io) 'storage_emulator_host_vm.dart';

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

  /// A value that can be passed as the `projectId` parameter to the [Storage]
  /// constructor to explicitly indicate that there is no project.
  ///
  /// Any requests that require a project ID will fail with a [StateError].
  // Valid project ids cannot contain '<' or '>' and must start with a letter.
  static const String noProject = '<none>';

  static final _httpPattern = RegExp(r'^https?://');

  Future<String> get _requiredProjectId async {
    final id = await _projectId;
    if (id == noProject) {
      throw StateError('a project ID is required');
    }
    return id;
  }

  static FutureOr<http.Client> _calculateClient(
    FutureOr<http.Client>? client,
    String? emulatorHost,
  ) => switch ((client, emulatorHost)) {
    (final client?, _) => client,
    (null, _?) => http.Client(),
    (null, null) => defaultHttpClient(),
  };

  static FutureOr<String> _calculateProjectId(
    String? projectId,
    String? emulatorHost,
  ) => switch ((projectId, emulatorHost)) {
    (final String projectId, _) => projectId,
    // The project id is not meaningful when using the emulator.
    // This is the default project ID used by the Python client:
    // https://github.com/googleapis/python-storage/blob/4d98e32c82811b4925367d2fee134cb0b2c0dae7/google/cloud/storage/client.py#L152
    (null, _?) => '<none>',
    (null, null) => defaultProjectId(),
  };

  FutureOr<ServiceClient> get _serviceClient async =>
      _cachedServiceClient ??= ServiceClient(client: await _httpClient);

  static Uri _calculateBaseUrl(
    String? apiEndpoint,
    bool useAuthWithCustomEndpoint,
    String? emulatorHost,
  ) {
    if (apiEndpoint != null) {
      if (useAuthWithCustomEndpoint) return Uri.https(apiEndpoint);
      return Uri.http(apiEndpoint);
    }

    if (emulatorHost case String host) {
      if (_httpPattern.hasMatch(host)) {
        return Uri.parse(host);
      }
      return Uri.http(host);
    }

    return Uri.https('storage.googleapis.com');
  }

  Storage._(this._projectId, this._baseUrl, this._httpClient);

  /// Constructs a client used to communicate with [Google Cloud Storage][].
  ///
  /// On the Dart VM, by default, the client will use your
  /// [default application credentials][] to communicate with the production
  /// [Google Cloud Storage][] service and use the project inferred from the
  /// environment.
  ///
  /// In the browser, by default, the client will not use any credentials and
  /// will not use a project.
  ///
  /// You can explicitly provide a project ID by passing [projectId]. The
  /// special constant [noProject] can be passed to indicate that there is no
  /// project. If [noProject] is passed, then any requests that require a
  /// project will fail with a [StateError].
  ///
  /// To disable authentication (e.g. if you only wish to access public data) or
  /// to use authentication other than the default application credentials, you
  /// can provide your own [client].
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
  /// [Google Cloud Storage]: https://cloud.google.com/storage
  /// [Cloud Storage for Firebase Emulator]: https://firebase.google.com/docs/emulator-suite/connect_storage
  /// [default application credentials]: https://docs.cloud.google.com/docs/authentication/application-default-credentials
  factory Storage({
    String? projectId,
    String? apiEndpoint,
    bool useAuthWithCustomEndpoint = true,
    FutureOr<http.Client>? client,
  }) {
    // Ensure that the same value of `storageEmulatorHost` is used everywhere in
    // the constructor.
    final emulatorHost = storageEmulatorHost;
    return Storage._(
      _calculateProjectId(projectId, emulatorHost),
      _calculateBaseUrl(apiEndpoint, useAuthWithCustomEndpoint, emulatorHost),
      _calculateClient(client, emulatorHost),
    );
  }

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
    if (_cachedServiceClient case final serviceClient?) {
      serviceClient.close();
      return;
    }

    switch (_httpClient) {
      case final Future<http.Client> future:
        // Swallow any asynchronous errors because there is nothing that we
        // can do about it always.
        future.then((client) => client.close(), onError: (_) {});
      case final http.Client client:
        client.close();
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
    final url = _requestUrl(
      ['storage', 'v1', 'b'],
      {
        'project': await _requiredProjectId,
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

  /// Deletes an ACL entry on the specified [Google Cloud Storage bucket].
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the bucket or ACL does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/delete).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<void> deleteBucketAcl(
    String bucket,
    String entity, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl', entity], {});
    await serviceClient.delete(url);
  }, isIdempotent: false);

  /// Returns the ACL entry for the specified entity on the specified
  /// [Google Cloud Storage bucket].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// Throws [NotFoundException] if the bucket or ACL entry does not exist.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/get).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketAccessControl> getBucketAcl(
    String bucket,
    String entity, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl', entity], {});
    final j = await serviceClient.get(url);
    return bucketAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: true);

  /// Creates a new ACL entry on the specified [Google Cloud Storage bucket].
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the bucket does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// {@template bucket_acl_role_docs}
  /// [role] specifies the access permission for the entity. There are three
  /// roles that can be assigned to an entity:
  /// 1. `READER`s can get the bucket, though no acl property will be returned,
  ///    and list the bucket's objects.
  /// 2. `WRITER`s are `READER`s, and they can insert objects into the bucket
  ///    and delete the bucket's objects.
  /// 3. `OWNER`s are `WRITER`s, and they can get the acl property of a bucket,
  ///    update a bucket, and call all [BucketAccessControl]-related methods on
  ///    the bucket.
  /// {@endtemplate}
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/insert).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketAccessControl> insertBucketAcl(
    String bucket,
    String entity,
    String role, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl'], {});
    final j = await serviceClient.post(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return bucketAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: false);

  /// A list of Access Control List (ACL) entries on the specified
  /// [Google Cloud Storage bucket].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the bucket does not exist.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/list).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<List<BucketAccessControl>> listBucketAcl(
    String bucket, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl'], {});
    final j = await serviceClient.get(url);
    final items = j['items'] as List<Object?>? ?? const [];
    return [
      for (final item in items)
        bucketAccessControlFromJson(item as Map<String, Object?>)!,
    ];
  }, isIdempotent: true);

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
      final url = _requestUrl(
        ['storage', 'v1', 'b'],
        {
          'maxResults': ?maxResults?.toString(),
          'project': await _requiredProjectId,
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
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket],
      {
        'ifMetagenerationMatch': ?ifMetagenerationMatch?.toString(),
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

  /// Patches an Access Control List (ACL) entry on the specified
  /// [Google Cloud Storage bucket].
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the bucket or ACL does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// {@macro bucket_acl_role_docs}
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/patch).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketAccessControl> patchBucketAcl(
    String bucket,
    String entity,
    String role, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl', entity], {});
    final j = await serviceClient.patch(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return bucketAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: false);

  /// Updates an Access Control List (ACL) entry on the specified
  /// [Google Cloud Storage bucket].
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the bucket or ACL does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// {@macro bucket_acl_role_docs}
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/bucketAccessControls/update).
  ///
  /// [Google Cloud Storage bucket]: https://docs.cloud.google.com/storage/docs/buckets
  Future<BucketAccessControl> updateBucketAcl(
    String bucket,
    String entity,
    String role, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(['storage', 'v1', 'b', bucket, 'acl', entity], {});
    final j = await serviceClient.put(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return bucketAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: false);

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

  /// Deletes an ACL entry on the specified [Google Cloud Storage object].
  ///
  /// This operation is idempotent if [generation] is set.
  ///
  /// Throws [NotFoundException] if the object or ACL does not exist.
  ///
  /// {@template acl_entity_docs}
  /// [entity] specifies the entity holding the permission. Supported formats:
  /// - `user-emailAddress`
  /// - `group-emailAddress`
  /// - `domain-domain`
  /// - `project-team-projectNumber`
  /// - `allUsers`
  /// - `allAuthenticatedUsers`
  ///
  /// For example:
  /// - The user `liz@example.com` would be `"user-liz@example.com"`.
  /// - The group `example@googlegroups.com` would be
  ///   `"group-example@googlegroups.com"`.
  /// - To refer to all members of the domain `example.com`, the entity would
  ///   be `"domain-example.com"`.
  /// {@endtemplate}
  ///
  /// If set, [generation] selects a specific revision of this object whose ACL
  /// should be modified.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/delete).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  Future<void> deleteObjectAcl(
    String bucket,
    String object,
    String entity, {
    BigInt? generation,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object, 'acl', entity],
      {'generation': ?generation?.toString()},
    );
    await serviceClient.delete(url);
  }, isIdempotent: generation != null);

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

  /// Returns the ACL entry for the specified entity on the specified
  /// [Google Cloud Storage object].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// Throws [NotFoundException] if the object or ACL entry does not exist.
  ///
  /// If set, [generation] selects a specific revision of this object whose ACL
  /// should be retrieved.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/get).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://cloud.google.com/storage/docs/requester-pays
  Future<ObjectAccessControl> getObjectAcl(
    String bucket,
    String object,
    String entity, {
    BigInt? generation,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object, 'acl', entity],
      {'generation': ?generation?.toString()},
    );
    final j = await serviceClient.get(url);
    return objectAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: true);

  /// Creates a new ACL entry on the specified [Google Cloud Storage object].
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// [role] specifies the access permission for the entity. There are two roles
  /// that can be assigned to an object:
  /// 1. `READER` can get an object, though the `acl` property will not be
  ///    revealed.
  /// 2. `OWNER` are `READER`s, and they can get the `acl` property, update the
  ///    object's metadata, and call all [ObjectAccessControl]-related methods
  ///    on the object. The owner of an object is always an `OWNER`.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/insert).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  Future<ObjectAccessControl> insertObjectAcl(
    String bucket,
    String object,
    String entity,
    String role, {
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl([
      'storage',
      'v1',
      'b',
      bucket,
      'o',
      object,
      'acl',
    ], {});
    final j = await serviceClient.post(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return objectAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: false);

  /// A list of Access Control List (ACL) entries on the specified
  /// [Google Cloud Storage object].
  ///
  /// This operation is read-only and always idempotent.
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// If set, [generation] selects a specific revision of this object whose ACL
  /// should be retrieved.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/list).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<List<ObjectAccessControl>> listObjectAcl(
    String bucket,
    String object, {
    BigInt? generation,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object, 'acl'],
      {'generation': ?generation?.toString()},
    );
    final j = await serviceClient.get(url);
    final items = j['items'] as List<Object?>? ?? const [];
    return [
      for (final item in items)
        objectAccessControlFromJson(item as Map<String, Object?>)!,
    ];
  }, isIdempotent: true);

  /// A stream of objects contained in [bucket] in lexicographical order by
  /// name.
  ///
  /// If [delimiter] is set, returns results in a directory-like mode, with
  /// `'/'` being a common value for the delimiter. The result will only
  /// include objects whose names do not contain `delimiter`, or whose names
  /// only have instances of `delimiter` in their `prefix`.
  ///
  /// If [includeTrailingDelimiter] is `true`, then objects that end in the
  /// [delimiter] will be returned in the items list.
  ///
  /// If [prefix] is set, filters results to objects whose names begin with
  /// this prefix.
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
    String? delimiter,
    bool? includeTrailingDelimiter,
    int? maxResults,
    String? prefix,
    String? projection,
    bool? softDeleted,
    String? userProject,
    bool? versions,
  }) async* {
    String? nextPageToken;

    do {
      final serviceClient = await _serviceClient;
      final url = _requestUrl(
        ['storage', 'v1', 'b', bucket, 'o'],
        {
          'delimiter': ?delimiter,
          'includeTrailingDelimiter': ?includeTrailingDelimiter?.toString(),
          'maxResults': ?maxResults?.toString(),
          'pageToken': ?nextPageToken,
          'prefix': ?prefix,
          'projection': ?projection,
          'softDeleted': ?softDeleted?.toString(),
          'userProject': ?userProject,
          'versions': ?versions?.toString(),
        },
      );
      final json = await serviceClient.get(url);
      nextPageToken = json['nextPageToken'] as String?;

      for (final object in json['items'] as List<Object?>? ?? const []) {
        yield objectMetadataFromJson(object as Map<String, Object?>);
      }
    } while (nextPageToken != null);
  }

  /// Grant read access to [Google Cloud Storage objects] for anonymous users.
  ///
  /// This operation is not idempotent.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the object does not exist.
  ///
  /// [Google Cloud Storage objects]: https://docs.cloud.google.com/storage/docs/objects
  Future<void> makeObjectPublic(
    String bucket,
    String object, {
    RetryRunner retry = defaultRetry,
  }) => insertObjectAcl(bucket, object, 'allUsers', 'READER', retry: retry);

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
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
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

  /// Moves an object from one name to another in the same bucket.
  ///
  /// This operation is atomic and idempotent if [ifSourceGenerationMatch] or
  /// [ifGenerationMatch] is set.
  ///
  /// Throws [NotFoundException] if the source object does not exist.
  ///
  /// If set, [ifSourceGenerationMatch] makes the operation conditional on
  /// whether the source object's current generation matches the given value.
  ///
  /// If set, [ifGenerationMatch] makes the operation conditional on whether
  /// the destination object's current generation matches the given value.
  /// A value of `0` indicates that the destination object must not already
  /// exist.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/move).
  ///
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> moveObject(
    String bucket,
    String sourceObject,
    String destinationObject, {
    BigInt? ifSourceGenerationMatch,
    BigInt? ifGenerationMatch,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(
    () async {
      final serviceClient = await _serviceClient;
      final url = _requestUrl(
        [
          'storage',
          'v1',
          'b',
          bucket,
          'o',
          sourceObject,
          'moveTo',
          'o',
          destinationObject,
        ],
        {
          'ifSourceGenerationMatch': ?ifSourceGenerationMatch?.toString(),
          'ifGenerationMatch': ?ifGenerationMatch?.toString(),
          'projection': ?projection,
          'userProject': ?userProject,
        },
      );
      final j = await serviceClient.post(url);
      return objectMetadataFromJson(j as Map<String, Object?>);
    },
    isIdempotent: ifSourceGenerationMatch != null || ifGenerationMatch != null,
  );

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

  /// Patches an Access Control List (ACL) entry on the specified
  /// [Google Cloud Storage object].
  ///
  /// This operation is idempotent if [generation] is set.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the object or ACL does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// [role] specifies the access permission for the entity. Acceptable values
  /// are `"OWNER"` and `"READER"`.
  ///
  /// If set, [generation] selects a specific revision of this object whose ACL
  /// should be modified.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/patch).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectAccessControl> patchObjectAcl(
    String bucket,
    String object,
    String entity,
    String role, {
    BigInt? generation,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object, 'acl', entity],
      {'generation': ?generation?.toString()},
    );
    final j = await serviceClient.patch(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return objectAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: generation != null);

  /// Rewrites an object from a source to a destination.
  ///
  /// This operation is executed entirely on Google Cloud Storage servers and
  /// can handle objects of any size by automatically rewriting them in chunks
  /// if necessary.
  ///
  /// This operation is idempotent if [ifGenerationMatch] is set.
  ///
  /// Throws [NotFoundException] if the source object does not exist.
  ///
  /// [sourceBucket] is the bucket containing the source object.
  /// [sourceObject] is the name of the source object.
  /// [destinationBucket] is the bucket where the rewritten object will be
  /// placed.
  /// [destinationObject] is the name of the destination object.
  ///
  /// If set, [metadata] will be applied to the destination object, overriding
  /// any metadata copied from the source object.
  ///
  /// If set, [sourceGeneration] selects a specific revision of the source
  /// object to rewrite.
  ///
  /// If set, [ifSourceGenerationMatch] makes the operation conditional on
  /// whether the source object's current generation matches the given value.
  /// If the generation does not match, a [PreconditionFailedException] is
  /// thrown.
  ///
  /// If set, [ifGenerationMatch] makes the operation conditional on whether
  /// the destination object's current generation matches the given value.
  /// A value of [BigInt.zero] indicates that the destination object must not
  /// already exist. If the generation does not match, a
  /// [PreconditionFailedException] is thrown.
  ///
  /// [destinationPredefinedAcl] applies a predefined set of access controls
  /// to the destination object, such as `"publicRead"`.
  ///
  /// [projection] controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, [userProject] is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// If set, [maxBytesRewrittenPerCall] limits the number of bytes rewritten
  /// in a single call. If specified the value must be an integral multiple of
  /// 1 MiB (`1048576`).
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/rewrite).
  ///
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> rewriteObject(
    String sourceBucket,
    String sourceObject,
    String destinationBucket,
    String destinationObject, {
    ObjectMetadata? metadata,
    BigInt? sourceGeneration,
    BigInt? ifSourceGenerationMatch,
    BigInt? ifGenerationMatch,
    String? destinationPredefinedAcl,
    String? projection,
    String? userProject,
    BigInt? maxBytesRewrittenPerCall,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    String? rewriteToken;
    ObjectMetadata? result;
    var body = metadata == null
        ? null
        : _JsonEncodableWrapper(objectMetadataToJson(metadata));

    do {
      final url = _requestUrl(
        [
          'storage',
          'v1',
          'b',
          sourceBucket,
          'o',
          sourceObject,
          'rewriteTo',
          'b',
          destinationBucket,
          'o',
          destinationObject,
        ],
        {
          'rewriteToken': ?rewriteToken,
          'sourceGeneration': ?sourceGeneration?.toString(),
          'ifSourceGenerationMatch': ?ifSourceGenerationMatch?.toString(),
          'ifGenerationMatch': ?ifGenerationMatch?.toString(),
          'destinationPredefinedAcl': ?destinationPredefinedAcl,
          'projection': ?projection,
          'userProject': ?userProject,
          'maxBytesRewrittenPerCall': ?maxBytesRewrittenPerCall?.toString(),
        },
      );
      final j =
          await serviceClient.post(url, body: body) as Map<String, Object?>;
      final done = j['done'] as bool;
      rewriteToken = j['rewriteToken'] as String?;
      if (done) {
        result = objectMetadataFromJson(j['resource'] as Map<String, Object?>);
      }
      body = null;
    } while (result == null);

    return result;
  }, isIdempotent: ifGenerationMatch != null);

  /// Updates an Access Control List (ACL) entry on the specified
  /// [Google Cloud Storage object].
  ///
  /// This operation is idempotent if [generation] is set.
  ///
  /// If the bucket has uniform bucket-level access enabled, this operation
  /// will fail with [BadRequestException].
  ///
  /// Throws [NotFoundException] if the object or ACL does not exist.
  ///
  /// {@macro acl_entity_docs}
  ///
  /// [role] specifies the access permission for the entity. Acceptable values
  /// are `"OWNER"` and `"READER"`.
  ///
  /// If set, [generation] selects a specific revision of this object whose ACL
  /// should be modified.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objectAccessControls/update).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectAccessControl> updateObjectAcl(
    String bucket,
    String object,
    String entity,
    String role, {
    BigInt? generation,
    RetryRunner retry = defaultRetry,
  }) => retry.run(() async {
    final serviceClient = await _serviceClient;
    final url = _requestUrl(
      ['storage', 'v1', 'b', bucket, 'o', object, 'acl', entity],
      {'generation': ?generation?.toString()},
    );
    final j = await serviceClient.put(
      url,
      body: _JsonEncodableWrapper({'entity': entity, 'role': role}),
    );
    return objectAccessControlFromJson(j as Map<String, Object?>)!;
  }, isIdempotent: generation != null);

  /// Creates or updates the content of a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// `metadata.name` does not match [name], a [BadRequestException] is thrown.
  ///
  /// If set, [ifGenerationMatch] makes updating the object content conditional
  /// on whether the object's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of [BigInt.zero] indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/insert).
  ///
  /// For example:
  ///
  /// ```dart
  /// final metadata = await storage.uploadObject(
  ///   'my-bucket',
  ///   'hello.txt',
  ///   [1, 2, 3],
  ///   ifGenerationMatch: BigInt.zero, // Only insert if the object doesn't exist.
  /// );
  /// ```
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> uploadObject(
    String bucket,
    String name,
    List<int> content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    // TODO(https://github.com/googleapis/google-cloud-dart/issues/115):
    // support ifMetagenerationNotMatch.
    //
    // If `ifMetagenerationNotMatch` is set, the server will respond with a 304
    // status code and an empty body. This will cause `objects.insert` to throw
    // `TypeError` during JSON deserialization.
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => retry.run(
    () async => uploadFile(
      await _httpClient,
      _requestUrl(
        ['upload', 'storage', 'v1', 'b', bucket, 'o'],
        {
          'uploadType': 'multipart',
          'name': name,
          'ifGenerationMatch': ?ifGenerationMatch?.toString(),
          'predefinedAcl': ?predefinedAcl,
          'projection': ?projection,
          'userProject': ?userProject,
        },
      ),
      content,
      metadata: metadata,
    ),
    isIdempotent: ifGenerationMatch != null,
  );

  /// Creates or updates the content of a [Google Cloud Storage object][] using
  /// a [StreamSink].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// [metadata] is `null` or `metadata.contentType` is `null`, the content type
  /// will be `'application/octet-stream'`. If `metadata.name` does not
  /// match [name], a [BadRequestException] is thrown.
  ///
  /// If set, [ifGenerationMatch] makes updating the object content conditional
  /// on whether the object's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of [BigInt.zero] indicates that the object must not already exist.
  ///
  /// For example:
  ///
  /// ```dart
  /// final sink = storage.uploadObjectFromSink(
  ///   'my-bucket',
  ///   'hello.txt',
  ///   ifGenerationMatch: BigInt.zero, // Only insert if the object doesn't exist.
  /// );
  /// sink.add([1, 2, 3]);
  /// await sink.close();
  /// ```
  ///
  /// See [API reference docs](https://docs.cloud.google.com/storage/docs/performing-resumable-uploads#chunked-upload).
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  ResumableUploadSink uploadObjectFromSink(
    String bucket,
    String name, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    RetryRunner retry = defaultRetry,
  }) => uploadFileStream(
    _httpClient,
    _requestUrl(
      ['upload', 'storage', 'v1', 'b', bucket, 'o'],
      {
        'ifGenerationMatch': ?ifGenerationMatch?.toString(),
        'name': name,
        'uploadType': 'resumable',
      },
    ),
    isIdempotent: ifGenerationMatch != null,
    metadata: metadata,
    retry: retry,
  );

  /// Creates or updates the content of a [Google Cloud Storage object][].
  ///
  /// This operation is idempotent if `ifGenerationMatch` is set.
  ///
  /// If [metadata] is non-null, it will be used as the object's metadata. If
  /// [metadata] is `null` or `metadata.contentType` is `null`, the content type
  /// will be `'text/plain'`. If `metadata.name` does not match [name], a
  /// [BadRequestException] is thrown.
  ///
  /// If set, `ifGenerationMatch` makes updating the object content conditional
  /// on whether the object's generation matches the provided value. If the
  /// generation does not match, a [PreconditionFailedException] is thrown.
  /// A value of `0` indicates that the object must not already exist.
  ///
  /// If set, `predefinedAcl` applies a predefined set of access controls to the
  /// object, such as `"publicRead"`. If [UniformBucketLevelAccess.enabled] is
  /// `true`, then setting `predefinedAcl` will result in a
  /// [BadRequestException].
  ///
  /// `projection` controls the level of detail returned in the response. A
  /// value of `"full"` returns all object properties, while a value of
  /// `"noAcl"` (the default) omits the `owner` and `acl` properties.
  ///
  /// If set, `userProject` is the project to be billed for this request. This
  /// argument must be set for [Requester Pays] buckets.
  ///
  /// See [API reference docs](https://cloud.google.com/storage/docs/json_api/v1/objects/insert).
  ///
  /// For example:
  ///
  /// ```dart
  /// final metadata = await storage.uploadObjectFromString(
  ///   'my-bucket',
  ///   'hello.txt',
  ///   'Hello, World!',
  ///   ifGenerationMatch: BigInt.zero, // Only insert if the object doesn't exist.
  /// );
  /// ```
  ///
  /// [Google Cloud Storage object]: https://docs.cloud.google.com/storage/docs/json_api/v1/objects
  /// [Requester Pays]: https://docs.cloud.google.com/storage/docs/requester-pays
  Future<ObjectMetadata> uploadObjectFromString(
    String bucket,
    String name,
    String content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    // TODO(https://github.com/googleapis/google-cloud-dart/issues/115):
    // support ifMetagenerationNotMatch.
    //
    // If `ifMetagenerationNotMatch` is set, the server will respond with a 304
    // status code and an empty body. This will cause `objects.insert` to throw
    // `TypeError` during JSON deserialization.
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) {
    final md = switch (metadata) {
      ObjectMetadata(contentType: _?) => metadata,
      ObjectMetadata() => metadata.copyWith(contentType: 'text/plain'),
      null => ObjectMetadata(contentType: 'text/plain'),
    };
    return uploadObject(
      bucket,
      name,
      utf8.encode(content),
      metadata: md,
      ifGenerationMatch: ifGenerationMatch,
      predefinedAcl: predefinedAcl,
      projection: projection,
      userProject: userProject,
      retry: retry,
    );
  }
}
