import 'package:google_cloud_protobuf_test_messages_proto3/google_cloud_protobuf_test_messages_proto3.dart';
import 'package:test/test.dart';

// https://github.com/protocolbuffers/protobuf/blob/main/src/google/protobuf/test_messages_proto3.proto

void checkField(
  TestAllTypesProto3 message,
  Object expectedJson,
  Object? Function(TestAllTypesProto3) feature,
  dynamic matcher,
) {
  expect(message.toJson(), expectedJson);
  expect(feature(TestAllTypesProto3.fromJson(message.toJson())), matcher);
}

const minInt32 = -140737488355328;
const maxInt32 = 140737488355327;
const minInt64 = -9223372036854775808;
const maxInt64 = 9223372036854775807;

void main() async {
  group('test', () {
    group('int32', () {
      test('min', () {
        checkField(
          TestAllTypesProto3(optionalInt32: minInt32),
          {'optionalInt32': minInt32},
          (m) => m.optionalInt32,
          minInt32,
        );
      });

      test('max', () {
        checkField(
          TestAllTypesProto3(optionalInt32: maxInt32),
          {'optionalInt32': maxInt32},
          (m) => m.optionalInt32,
          maxInt32,
        );
      });
    });

    group('int64', () {
      test('min', () {
        checkField(
          TestAllTypesProto3(optionalInt64: minInt64),
          {'optionalInt64': '-9223372036854775808'},
          (m) => m.optionalInt64,
          minInt64,
        );
      });

      test('max', () {
        checkField(
          TestAllTypesProto3(optionalInt64: maxInt64),
          {'optionalInt64': '9223372036854775807'},
          (m) => m.optionalInt64,
          maxInt64,
        );
      });
    });

    group('map<int32, int32>', () {
      test('min', () {
        checkField(
          TestAllTypesProto3(mapInt32Int32: {minInt32: minInt32}),
          {
            'mapInt32Int32': {'-140737488355328': minInt32},
          },
          (m) => m.mapInt32Int32,
          {minInt32: minInt32},
        );
      });

      test('max', () {
        checkField(
          TestAllTypesProto3(mapInt32Int32: {maxInt32: maxInt32}),
          {
            'mapInt32Int32': {'140737488355327': maxInt32},
          },
          (m) => m.mapInt32Int32,
          {maxInt32: maxInt32},
        );
      });
    });
  });
}
