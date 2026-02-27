import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../google_cloud_storage.dart';

@internal
Blob newBlob(Storage storage, String bucketName, String name) =>
    Blob._(storage, bucketName, name);

final class Blob {
  final Storage storage;
  final String bucketName;
  final String name;

  Blob._(this.storage, this.bucketName, this.name);

  Future<void> delete({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    RetryRunner retry = defaultRetry,
  }) => storage.deleteObject(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    retry: retry,
  );

  Future<Uint8List> download({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.downloadObject(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    userProject: userProject,
    retry: retry,
  );

  Future<ObjectMetadata> patch(
    ObjectMetadataPatchBuilder metadata, {
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.patchObject(
    bucketName,
    name,
    metadata,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    predefinedAcl: predefinedAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  Future<ObjectMetadata> metadata({
    BigInt? generation,
    BigInt? ifGenerationMatch,
    BigInt? ifMetagenerationMatch,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.objectMetadata(
    bucketName,
    name,
    generation: generation,
    ifGenerationMatch: ifGenerationMatch,
    ifMetagenerationMatch: ifMetagenerationMatch,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );

  Future<ObjectMetadata> upload(
    List<int> content, {
    ObjectMetadata? metadata,
    BigInt? ifGenerationMatch,
    String? predefinedAcl,
    String? projection,
    String? userProject,
    RetryRunner retry = defaultRetry,
  }) => storage.insertObject(
    bucketName,
    name,
    content,
    metadata: metadata,
    ifGenerationMatch: ifGenerationMatch,
    predefinedAcl: predefinedAcl,
    projection: projection,
    userProject: userProject,
    retry: retry,
  );
}
