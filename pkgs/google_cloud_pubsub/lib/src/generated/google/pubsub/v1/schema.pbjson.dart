//
//  Generated code. Do not modify.
//  source: google/pubsub/v1/schema.proto
//
// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use schemaViewDescriptor instead')
const SchemaView$json = {
  '1': 'SchemaView',
  '2': [
    {'1': 'SCHEMA_VIEW_UNSPECIFIED', '2': 0},
    {'1': 'BASIC', '2': 1},
    {'1': 'FULL', '2': 2},
  ],
};

/// Descriptor for `SchemaView`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List schemaViewDescriptor = $convert.base64Decode(
    'CgpTY2hlbWFWaWV3EhsKF1NDSEVNQV9WSUVXX1VOU1BFQ0lGSUVEEAASCQoFQkFTSUMQARIICg'
    'RGVUxMEAI=');

@$core.Deprecated('Use encodingDescriptor instead')
const Encoding$json = {
  '1': 'Encoding',
  '2': [
    {'1': 'ENCODING_UNSPECIFIED', '2': 0},
    {'1': 'JSON', '2': 1},
    {'1': 'BINARY', '2': 2},
  ],
};

/// Descriptor for `Encoding`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List encodingDescriptor = $convert.base64Decode(
    'CghFbmNvZGluZxIYChRFTkNPRElOR19VTlNQRUNJRklFRBAAEggKBEpTT04QARIKCgZCSU5BUl'
    'kQAg==');

@$core.Deprecated('Use schemaDescriptor instead')
const Schema$json = {
  '1': 'Schema',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.google.pubsub.v1.Schema.Type',
      '10': 'type'
    },
    {'1': 'definition', '3': 3, '4': 1, '5': 9, '10': 'definition'},
    {'1': 'revision_id', '3': 4, '4': 1, '5': 9, '8': {}, '10': 'revisionId'},
    {
      '1': 'revision_create_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': {},
      '10': 'revisionCreateTime'
    },
  ],
  '4': [Schema_Type$json],
  '7': {},
};

@$core.Deprecated('Use schemaDescriptor instead')
const Schema_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'TYPE_UNSPECIFIED', '2': 0},
    {'1': 'PROTOCOL_BUFFER', '2': 1},
    {'1': 'AVRO', '2': 2},
  ],
};

/// Descriptor for `Schema`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schemaDescriptor = $convert.base64Decode(
    'CgZTY2hlbWESFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lEjEKBHR5cGUYAiABKA4yHS5nb29nbG'
    'UucHVic3ViLnYxLlNjaGVtYS5UeXBlUgR0eXBlEh4KCmRlZmluaXRpb24YAyABKAlSCmRlZmlu'
    'aXRpb24SJwoLcmV2aXNpb25faWQYBCABKAlCBuBBBeBBA1IKcmV2aXNpb25JZBJRChRyZXZpc2'
    'lvbl9jcmVhdGVfdGltZRgGIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IS'
    'cmV2aXNpb25DcmVhdGVUaW1lIjsKBFR5cGUSFAoQVFlQRV9VTlNQRUNJRklFRBAAEhMKD1BST1'
    'RPQ09MX0JVRkZFUhABEggKBEFWUk8QAjpG6kFDChxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2No'
    'ZW1hEiNwcm9qZWN0cy97cHJvamVjdH0vc2NoZW1hcy97c2NoZW1hfQ==');

@$core.Deprecated('Use createSchemaRequestDescriptor instead')
const CreateSchemaRequest$json = {
  '1': 'CreateSchemaRequest',
  '2': [
    {'1': 'parent', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'parent'},
    {
      '1': 'schema',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '8': {},
      '10': 'schema'
    },
    {'1': 'schema_id', '3': 3, '4': 1, '5': 9, '10': 'schemaId'},
  ],
};

/// Descriptor for `CreateSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSchemaRequestDescriptor = $convert.base64Decode(
    'ChNDcmVhdGVTY2hlbWFSZXF1ZXN0EjwKBnBhcmVudBgBIAEoCUIk4EEC+kEeEhxwdWJzdWIuZ2'
    '9vZ2xlYXBpcy5jb20vU2NoZW1hUgZwYXJlbnQSNQoGc2NoZW1hGAIgASgLMhguZ29vZ2xlLnB1'
    'YnN1Yi52MS5TY2hlbWFCA+BBAlIGc2NoZW1hEhsKCXNjaGVtYV9pZBgDIAEoCVIIc2NoZW1hSW'
    'Q=');

@$core.Deprecated('Use getSchemaRequestDescriptor instead')
const GetSchemaRequest$json = {
  '1': 'GetSchemaRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'view',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.google.pubsub.v1.SchemaView',
      '10': 'view'
    },
  ],
};

/// Descriptor for `GetSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSchemaRequestDescriptor = $convert.base64Decode(
    'ChBHZXRTY2hlbWFSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdvb2dsZW'
    'FwaXMuY29tL1NjaGVtYVIEbmFtZRIwCgR2aWV3GAIgASgOMhwuZ29vZ2xlLnB1YnN1Yi52MS5T'
    'Y2hlbWFWaWV3UgR2aWV3');

@$core.Deprecated('Use listSchemasRequestDescriptor instead')
const ListSchemasRequest$json = {
  '1': 'ListSchemasRequest',
  '2': [
    {'1': 'parent', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'parent'},
    {
      '1': 'view',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.google.pubsub.v1.SchemaView',
      '10': 'view'
    },
    {'1': 'page_size', '3': 3, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 4, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListSchemasRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemasRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0U2NoZW1hc1JlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0KK2Nsb3VkcmVzb3'
    'VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RSBnBhcmVudBIwCgR2aWV3GAIgASgO'
    'MhwuZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFWaWV3UgR2aWV3EhsKCXBhZ2Vfc2l6ZRgDIAEoBV'
    'IIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgEIAEoCVIJcGFnZVRva2Vu');

@$core.Deprecated('Use listSchemasResponseDescriptor instead')
const ListSchemasResponse$json = {
  '1': 'ListSchemasResponse',
  '2': [
    {
      '1': 'schemas',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '10': 'schemas'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListSchemasResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemasResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0U2NoZW1hc1Jlc3BvbnNlEjIKB3NjaGVtYXMYASADKAsyGC5nb29nbGUucHVic3ViLn'
    'YxLlNjaGVtYVIHc2NoZW1hcxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQYWdlVG9r'
    'ZW4=');

@$core.Deprecated('Use listSchemaRevisionsRequestDescriptor instead')
const ListSchemaRevisionsRequest$json = {
  '1': 'ListSchemaRevisionsRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'view',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.google.pubsub.v1.SchemaView',
      '10': 'view'
    },
    {'1': 'page_size', '3': 3, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 4, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListSchemaRevisionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemaRevisionsRequestDescriptor = $convert.base64Decode(
    'ChpMaXN0U2NoZW1hUmV2aXNpb25zUmVxdWVzdBI4CgRuYW1lGAEgASgJQiTgQQL6QR4KHHB1Yn'
    'N1Yi5nb29nbGVhcGlzLmNvbS9TY2hlbWFSBG5hbWUSMAoEdmlldxgCIAEoDjIcLmdvb2dsZS5w'
    'dWJzdWIudjEuU2NoZW1hVmlld1IEdmlldxIbCglwYWdlX3NpemUYAyABKAVSCHBhZ2VTaXplEh'
    '0KCnBhZ2VfdG9rZW4YBCABKAlSCXBhZ2VUb2tlbg==');

@$core.Deprecated('Use listSchemaRevisionsResponseDescriptor instead')
const ListSchemaRevisionsResponse$json = {
  '1': 'ListSchemaRevisionsResponse',
  '2': [
    {
      '1': 'schemas',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '10': 'schemas'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListSchemaRevisionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSchemaRevisionsResponseDescriptor =
    $convert.base64Decode(
        'ChtMaXN0U2NoZW1hUmV2aXNpb25zUmVzcG9uc2USMgoHc2NoZW1hcxgBIAMoCzIYLmdvb2dsZS'
        '5wdWJzdWIudjEuU2NoZW1hUgdzY2hlbWFzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4'
        'dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use commitSchemaRequestDescriptor instead')
const CommitSchemaRequest$json = {
  '1': 'CommitSchemaRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'schema',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '8': {},
      '10': 'schema'
    },
  ],
};

/// Descriptor for `CommitSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitSchemaRequestDescriptor = $convert.base64Decode(
    'ChNDb21taXRTY2hlbWFSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdvb2'
    'dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZRI1CgZzY2hlbWEYAiABKAsyGC5nb29nbGUucHVic3Vi'
    'LnYxLlNjaGVtYUID4EECUgZzY2hlbWE=');

@$core.Deprecated('Use rollbackSchemaRequestDescriptor instead')
const RollbackSchemaRequest$json = {
  '1': 'RollbackSchemaRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'revision_id', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'revisionId'},
  ],
};

/// Descriptor for `RollbackSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rollbackSchemaRequestDescriptor = $convert.base64Decode(
    'ChVSb2xsYmFja1NjaGVtYVJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxwdWJzdWIuZ2'
    '9vZ2xlYXBpcy5jb20vU2NoZW1hUgRuYW1lEiQKC3JldmlzaW9uX2lkGAIgASgJQgPgQQJSCnJl'
    'dmlzaW9uSWQ=');

@$core.Deprecated('Use deleteSchemaRevisionRequestDescriptor instead')
const DeleteSchemaRevisionRequest$json = {
  '1': 'DeleteSchemaRevisionRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'revision_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'revisionId',
    },
  ],
};

/// Descriptor for `DeleteSchemaRevisionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSchemaRevisionRequestDescriptor =
    $convert.base64Decode(
        'ChtEZWxldGVTY2hlbWFSZXZpc2lvblJlcXVlc3QSOAoEbmFtZRgBIAEoCUIk4EEC+kEeChxwdW'
        'JzdWIuZ29vZ2xlYXBpcy5jb20vU2NoZW1hUgRuYW1lEiYKC3JldmlzaW9uX2lkGAIgASgJQgUY'
        'AeBBAVIKcmV2aXNpb25JZA==');

@$core.Deprecated('Use deleteSchemaRequestDescriptor instead')
const DeleteSchemaRequest$json = {
  '1': 'DeleteSchemaRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
  ],
};

/// Descriptor for `DeleteSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSchemaRequestDescriptor = $convert.base64Decode(
    'ChNEZWxldGVTY2hlbWFSZXF1ZXN0EjgKBG5hbWUYASABKAlCJOBBAvpBHgoccHVic3ViLmdvb2'
    'dsZWFwaXMuY29tL1NjaGVtYVIEbmFtZQ==');

@$core.Deprecated('Use validateSchemaRequestDescriptor instead')
const ValidateSchemaRequest$json = {
  '1': 'ValidateSchemaRequest',
  '2': [
    {'1': 'parent', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'parent'},
    {
      '1': 'schema',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '8': {},
      '10': 'schema'
    },
  ],
};

/// Descriptor for `ValidateSchemaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateSchemaRequestDescriptor = $convert.base64Decode(
    'ChVWYWxpZGF0ZVNjaGVtYVJlcXVlc3QSSwoGcGFyZW50GAEgASgJQjPgQQL6QS0KK2Nsb3Vkcm'
    'Vzb3VyY2VtYW5hZ2VyLmdvb2dsZWFwaXMuY29tL1Byb2plY3RSBnBhcmVudBI1CgZzY2hlbWEY'
    'AiABKAsyGC5nb29nbGUucHVic3ViLnYxLlNjaGVtYUID4EECUgZzY2hlbWE=');

@$core.Deprecated('Use validateSchemaResponseDescriptor instead')
const ValidateSchemaResponse$json = {
  '1': 'ValidateSchemaResponse',
};

/// Descriptor for `ValidateSchemaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateSchemaResponseDescriptor =
    $convert.base64Decode('ChZWYWxpZGF0ZVNjaGVtYVJlc3BvbnNl');

@$core.Deprecated('Use validateMessageRequestDescriptor instead')
const ValidateMessageRequest$json = {
  '1': 'ValidateMessageRequest',
  '2': [
    {'1': 'parent', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'parent'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '8': {}, '9': 0, '10': 'name'},
    {
      '1': 'schema',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.pubsub.v1.Schema',
      '9': 0,
      '10': 'schema'
    },
    {'1': 'message', '3': 4, '4': 1, '5': 12, '10': 'message'},
    {
      '1': 'encoding',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.google.pubsub.v1.Encoding',
      '10': 'encoding'
    },
  ],
  '8': [
    {'1': 'schema_spec'},
  ],
};

/// Descriptor for `ValidateMessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateMessageRequestDescriptor = $convert.base64Decode(
    'ChZWYWxpZGF0ZU1lc3NhZ2VSZXF1ZXN0EksKBnBhcmVudBgBIAEoCUIz4EEC+kEtCitjbG91ZH'
    'Jlc291cmNlbWFuYWdlci5nb29nbGVhcGlzLmNvbS9Qcm9qZWN0UgZwYXJlbnQSNwoEbmFtZRgC'
    'IAEoCUIh+kEeChxwdWJzdWIuZ29vZ2xlYXBpcy5jb20vU2NoZW1hSABSBG5hbWUSMgoGc2NoZW'
    '1hGAMgASgLMhguZ29vZ2xlLnB1YnN1Yi52MS5TY2hlbWFIAFIGc2NoZW1hEhgKB21lc3NhZ2UY'
    'BCABKAxSB21lc3NhZ2USNgoIZW5jb2RpbmcYBSABKA4yGi5nb29nbGUucHVic3ViLnYxLkVuY2'
    '9kaW5nUghlbmNvZGluZ0INCgtzY2hlbWFfc3BlYw==');

@$core.Deprecated('Use validateMessageResponseDescriptor instead')
const ValidateMessageResponse$json = {
  '1': 'ValidateMessageResponse',
};

/// Descriptor for `ValidateMessageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List validateMessageResponseDescriptor =
    $convert.base64Decode('ChdWYWxpZGF0ZU1lc3NhZ2VSZXNwb25zZQ==');
