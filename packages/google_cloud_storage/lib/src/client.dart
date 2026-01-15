final class Retry {}

final class ObjectMetadata {
  // TODO: Add all fields.
  final String? bucket;
  final String? name;
  final int? size;
  final int? generation;
  final int? metageneration;
  final String? contentType;
  final DateTime? updated;

  ObjectMetadata(
    this.bucket,
    this.name,
    this.size,
    this.generation,
    this.metageneration,
    this.contentType,
    this.updated,
  );

  // TODO: Allow replacement of all fields.
  ObjectMetadata copyWith({String? bucket, String? name}) =>
      throw UnimplementedError('copyWith');
}

/// Stores and retrieves potentially large, immutable data objects.
// Design Notes:
//
// This implementation is based on the official Google Cloud Storage C++ client:
// https://github.com/googleapis/google-cloud-cpp/blob/113d8fa65360e53e61cba7b90935418557512d4e/google/cloud/storage/client.h#L263
//
// The biggest change is that the `options` varargs are replaced by optional
// named parameters.
//
// The name `StorageService` is used to be consistent with the generated APIs,
// where the term `Client` refers to the underlying (HTTP) transport and the
// abstraction around it has the suffix "Service".
final class StorageService {
  // TODO: Write good documentation.

  Future<ObjectMetadata> objectMetadata(
    String bucketName,
    String objectName, {
    int? generation,
    int? ifMetagenerationMatch,
    int? ifMetagenerationNotMatch,
    int? ifGenerationMatch,
    int? ifGenerationNotMatch,
    bool softDeleted = false,
    Retry? retry,
    // TODO: Add the remaining options.
  }) => throw UnimplementedError('objectMetadata');

  /// TODO: Explain this better.
  ///
  /// Replaces the entire Object metadata with `metadata`. Any fields not not
  /// included in the request will be cleared or set to their default values.
  ///
  /// Only fields accepted by the `Objects: update` API are used,
  /// all other fields are ignored. In particular, [ObjectMetadata.bucket] and
  /// [ObjectMetadata.name] are ignored in favor of the `bucketName` and
  /// `objectName` parameters.
  Future<ObjectMetadata> updateObjectMetadata(
    String bucketName,
    String objectName,
    ObjectMetadata metadata, {
    int? generation,
    // TODO: Add the remaining options.
  }) => throw UnimplementedError('updateObjectMetadata');

  /// TODO: Explain this better.
  ///
  /// Modifies only the specific metadata fields provided by `metadata`.
  /// Any fields not specified remain unchanged.
  ///
  /// Only fields accepted by the `Objects: patch` API are used,
  /// all other fields are ignored. In particular, [ObjectMetadata.bucket] and
  /// [ObjectMetadata.name] are ignored in favor of the `bucketName` and
  /// `objectName` parameters.
  Future<ObjectMetadata> patchObjectMetadata(
    String bucketName,
    String objectName,
    ObjectMetadata metadata, {
    int? generation,
    // TODO: Add the remaining options.
  }) => throw UnimplementedError('patchObjectMetadata');

  // TODO: Implement about 100 more methods.
}
