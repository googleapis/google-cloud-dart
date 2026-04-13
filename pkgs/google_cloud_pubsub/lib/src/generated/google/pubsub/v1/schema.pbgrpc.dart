//
//  Generated code. Do not modify.
//  source: google/pubsub/v1/schema.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../protobuf/empty.pb.dart' as $1;
import 'schema.pb.dart' as $2;

export 'schema.pb.dart';

/// Service for doing schema-related operations.
@$pb.GrpcServiceName('google.pubsub.v1.SchemaService')
class SchemaServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = 'pubsub.googleapis.com';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/pubsub',
  ];

  static final _$createSchema =
      $grpc.ClientMethod<$2.CreateSchemaRequest, $2.Schema>(
          '/google.pubsub.v1.SchemaService/CreateSchema',
          ($2.CreateSchemaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.Schema.fromBuffer(value));
  static final _$getSchema = $grpc.ClientMethod<$2.GetSchemaRequest, $2.Schema>(
      '/google.pubsub.v1.SchemaService/GetSchema',
      ($2.GetSchemaRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $2.Schema.fromBuffer(value));
  static final _$listSchemas =
      $grpc.ClientMethod<$2.ListSchemasRequest, $2.ListSchemasResponse>(
          '/google.pubsub.v1.SchemaService/ListSchemas',
          ($2.ListSchemasRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.ListSchemasResponse.fromBuffer(value));
  static final _$listSchemaRevisions = $grpc.ClientMethod<
          $2.ListSchemaRevisionsRequest, $2.ListSchemaRevisionsResponse>(
      '/google.pubsub.v1.SchemaService/ListSchemaRevisions',
      ($2.ListSchemaRevisionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) =>
          $2.ListSchemaRevisionsResponse.fromBuffer(value));
  static final _$commitSchema =
      $grpc.ClientMethod<$2.CommitSchemaRequest, $2.Schema>(
          '/google.pubsub.v1.SchemaService/CommitSchema',
          ($2.CommitSchemaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.Schema.fromBuffer(value));
  static final _$rollbackSchema =
      $grpc.ClientMethod<$2.RollbackSchemaRequest, $2.Schema>(
          '/google.pubsub.v1.SchemaService/RollbackSchema',
          ($2.RollbackSchemaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.Schema.fromBuffer(value));
  static final _$deleteSchemaRevision =
      $grpc.ClientMethod<$2.DeleteSchemaRevisionRequest, $2.Schema>(
          '/google.pubsub.v1.SchemaService/DeleteSchemaRevision',
          ($2.DeleteSchemaRevisionRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $2.Schema.fromBuffer(value));
  static final _$deleteSchema =
      $grpc.ClientMethod<$2.DeleteSchemaRequest, $1.Empty>(
          '/google.pubsub.v1.SchemaService/DeleteSchema',
          ($2.DeleteSchemaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $1.Empty.fromBuffer(value));
  static final _$validateSchema =
      $grpc.ClientMethod<$2.ValidateSchemaRequest, $2.ValidateSchemaResponse>(
          '/google.pubsub.v1.SchemaService/ValidateSchema',
          ($2.ValidateSchemaRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.ValidateSchemaResponse.fromBuffer(value));
  static final _$validateMessage =
      $grpc.ClientMethod<$2.ValidateMessageRequest, $2.ValidateMessageResponse>(
          '/google.pubsub.v1.SchemaService/ValidateMessage',
          ($2.ValidateMessageRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $2.ValidateMessageResponse.fromBuffer(value));

  SchemaServiceClient(super.channel, {super.options, super.interceptors});

  /// Creates a schema.
  $grpc.ResponseFuture<$2.Schema> createSchema($2.CreateSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$createSchema, request, options: options);
  }

  /// Gets a schema.
  $grpc.ResponseFuture<$2.Schema> getSchema($2.GetSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getSchema, request, options: options);
  }

  /// Lists schemas in a project.
  $grpc.ResponseFuture<$2.ListSchemasResponse> listSchemas(
      $2.ListSchemasRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listSchemas, request, options: options);
  }

  /// Lists all schema revisions for the named schema.
  $grpc.ResponseFuture<$2.ListSchemaRevisionsResponse> listSchemaRevisions(
      $2.ListSchemaRevisionsRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listSchemaRevisions, request, options: options);
  }

  /// Commits a new schema revision to an existing schema.
  $grpc.ResponseFuture<$2.Schema> commitSchema($2.CommitSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$commitSchema, request, options: options);
  }

  /// Creates a new schema revision that is a copy of the provided revision_id.
  $grpc.ResponseFuture<$2.Schema> rollbackSchema(
      $2.RollbackSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$rollbackSchema, request, options: options);
  }

  /// Deletes a specific schema revision.
  $grpc.ResponseFuture<$2.Schema> deleteSchemaRevision(
      $2.DeleteSchemaRevisionRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSchemaRevision, request, options: options);
  }

  /// Deletes a schema.
  $grpc.ResponseFuture<$1.Empty> deleteSchema($2.DeleteSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSchema, request, options: options);
  }

  /// Validates a schema.
  $grpc.ResponseFuture<$2.ValidateSchemaResponse> validateSchema(
      $2.ValidateSchemaRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$validateSchema, request, options: options);
  }

  /// Validates a message against a schema.
  $grpc.ResponseFuture<$2.ValidateMessageResponse> validateMessage(
      $2.ValidateMessageRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$validateMessage, request, options: options);
  }
}

@$pb.GrpcServiceName('google.pubsub.v1.SchemaService')
abstract class SchemaServiceBase extends $grpc.Service {
  $core.String get $name => 'google.pubsub.v1.SchemaService';

  SchemaServiceBase() {
    $addMethod($grpc.ServiceMethod<$2.CreateSchemaRequest, $2.Schema>(
        'CreateSchema',
        createSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.CreateSchemaRequest.fromBuffer(value),
        ($2.Schema value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.GetSchemaRequest, $2.Schema>(
        'GetSchema',
        getSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $2.GetSchemaRequest.fromBuffer(value),
        ($2.Schema value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$2.ListSchemasRequest, $2.ListSchemasResponse>(
            'ListSchemas',
            listSchemas_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $2.ListSchemasRequest.fromBuffer(value),
            ($2.ListSchemasResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ListSchemaRevisionsRequest,
            $2.ListSchemaRevisionsResponse>(
        'ListSchemaRevisions',
        listSchemaRevisions_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.ListSchemaRevisionsRequest.fromBuffer(value),
        ($2.ListSchemaRevisionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.CommitSchemaRequest, $2.Schema>(
        'CommitSchema',
        commitSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.CommitSchemaRequest.fromBuffer(value),
        ($2.Schema value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.RollbackSchemaRequest, $2.Schema>(
        'RollbackSchema',
        rollbackSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.RollbackSchemaRequest.fromBuffer(value),
        ($2.Schema value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.DeleteSchemaRevisionRequest, $2.Schema>(
        'DeleteSchemaRevision',
        deleteSchemaRevision_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.DeleteSchemaRevisionRequest.fromBuffer(value),
        ($2.Schema value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.DeleteSchemaRequest, $1.Empty>(
        'DeleteSchema',
        deleteSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.DeleteSchemaRequest.fromBuffer(value),
        ($1.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ValidateSchemaRequest,
            $2.ValidateSchemaResponse>(
        'ValidateSchema',
        validateSchema_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.ValidateSchemaRequest.fromBuffer(value),
        ($2.ValidateSchemaResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$2.ValidateMessageRequest,
            $2.ValidateMessageResponse>(
        'ValidateMessage',
        validateMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $2.ValidateMessageRequest.fromBuffer(value),
        ($2.ValidateMessageResponse value) => value.writeToBuffer()));
  }

  $async.Future<$2.Schema> createSchema_Pre($grpc.ServiceCall $call,
      $async.Future<$2.CreateSchemaRequest> $request) async {
    return createSchema($call, await $request);
  }

  $async.Future<$2.Schema> getSchema_Pre($grpc.ServiceCall $call,
      $async.Future<$2.GetSchemaRequest> $request) async {
    return getSchema($call, await $request);
  }

  $async.Future<$2.ListSchemasResponse> listSchemas_Pre($grpc.ServiceCall $call,
      $async.Future<$2.ListSchemasRequest> $request) async {
    return listSchemas($call, await $request);
  }

  $async.Future<$2.ListSchemaRevisionsResponse> listSchemaRevisions_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$2.ListSchemaRevisionsRequest> $request) async {
    return listSchemaRevisions($call, await $request);
  }

  $async.Future<$2.Schema> commitSchema_Pre($grpc.ServiceCall $call,
      $async.Future<$2.CommitSchemaRequest> $request) async {
    return commitSchema($call, await $request);
  }

  $async.Future<$2.Schema> rollbackSchema_Pre($grpc.ServiceCall $call,
      $async.Future<$2.RollbackSchemaRequest> $request) async {
    return rollbackSchema($call, await $request);
  }

  $async.Future<$2.Schema> deleteSchemaRevision_Pre($grpc.ServiceCall $call,
      $async.Future<$2.DeleteSchemaRevisionRequest> $request) async {
    return deleteSchemaRevision($call, await $request);
  }

  $async.Future<$1.Empty> deleteSchema_Pre($grpc.ServiceCall $call,
      $async.Future<$2.DeleteSchemaRequest> $request) async {
    return deleteSchema($call, await $request);
  }

  $async.Future<$2.ValidateSchemaResponse> validateSchema_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$2.ValidateSchemaRequest> $request) async {
    return validateSchema($call, await $request);
  }

  $async.Future<$2.ValidateMessageResponse> validateMessage_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$2.ValidateMessageRequest> $request) async {
    return validateMessage($call, await $request);
  }

  $async.Future<$2.Schema> createSchema(
      $grpc.ServiceCall call, $2.CreateSchemaRequest request);
  $async.Future<$2.Schema> getSchema(
      $grpc.ServiceCall call, $2.GetSchemaRequest request);
  $async.Future<$2.ListSchemasResponse> listSchemas(
      $grpc.ServiceCall call, $2.ListSchemasRequest request);
  $async.Future<$2.ListSchemaRevisionsResponse> listSchemaRevisions(
      $grpc.ServiceCall call, $2.ListSchemaRevisionsRequest request);
  $async.Future<$2.Schema> commitSchema(
      $grpc.ServiceCall call, $2.CommitSchemaRequest request);
  $async.Future<$2.Schema> rollbackSchema(
      $grpc.ServiceCall call, $2.RollbackSchemaRequest request);
  $async.Future<$2.Schema> deleteSchemaRevision(
      $grpc.ServiceCall call, $2.DeleteSchemaRevisionRequest request);
  $async.Future<$1.Empty> deleteSchema(
      $grpc.ServiceCall call, $2.DeleteSchemaRequest request);
  $async.Future<$2.ValidateSchemaResponse> validateSchema(
      $grpc.ServiceCall call, $2.ValidateSchemaRequest request);
  $async.Future<$2.ValidateMessageResponse> validateMessage(
      $grpc.ServiceCall call, $2.ValidateMessageRequest request);
}
