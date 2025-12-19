import 'dart:convert';
import 'dart:typed_data';

import 'package:google_cloud_protobuf/protobuf.dart';
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

  final f = feature(TestAllTypesProto3.fromJson(message.toJson()));
  if (f is ProtoMessage) {
    expect(f.toJson(), (matcher as ProtoMessage).toJson());
  } else if (f is List && f.isNotEmpty && f.first is ProtoMessage) {
    expect(
      f.map((e) => (e as ProtoMessage).toJson()).toList(),
      (matcher as List).map((e) => (e as ProtoMessage).toJson()).toList(),
    );
  } else {
    expect(f, matcher);
  }
}

void main() async {
  group('test', () {
    group('int32', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalInt32: 0),
          {},
          (m) => m.optionalInt32,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalInt32: 1),
          {'optionalInt32': 1},
          (m) => m.optionalInt32,
          1,
        );
      });
    });

    group('int64', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalInt64: 0),
          {},
          (m) => m.optionalInt64,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalInt64: 1),
          {'optionalInt64': '1'},
          (m) => m.optionalInt64,
          1,
        );
      });
    });

    group('uint32', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalUint32: 0),
          {},
          (m) => m.optionalUint32,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalUint32: 1),
          {'optionalUint32': 1},
          (m) => m.optionalUint32,
          1,
        );
      });
    });

    group('uint64', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalUint64: BigInt.zero),
          {},
          (m) => m.optionalUint64,
          BigInt.zero,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalUint64: BigInt.one),
          {'optionalUint64': '1'},
          (m) => m.optionalUint64,
          BigInt.one,
        );
      });
    });

    group('sint32', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalSint32: 0),
          {},
          (m) => m.optionalSint32,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalSint32: 1),
          {'optionalSint32': 1},
          (m) => m.optionalSint32,
          1,
        );
      });
    });

    group('sint64', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalSint64: 0),
          {},
          (m) => m.optionalSint64,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalSint64: 1),
          {'optionalSint64': '1'},
          (m) => m.optionalSint64,
          1,
        );
      });
    });

    group('fixed32', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalFixed32: 0),
          {},
          (m) => m.optionalFixed32,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalFixed32: 1),
          {'optionalFixed32': 1},
          (m) => m.optionalFixed32,
          1,
        );
      });
    });

    group('fixed64', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalFixed64: BigInt.zero),
          {},
          (m) => m.optionalFixed64,
          BigInt.zero,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalFixed64: BigInt.one),
          {'optionalFixed64': '1'},
          (m) => m.optionalFixed64,
          BigInt.one,
        );
      });
    });

    group('sfixed32', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalSfixed32: 0),
          {},
          (m) => m.optionalSfixed32,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalSfixed32: 1),
          {'optionalSfixed32': 1},
          (m) => m.optionalSfixed32,
          1,
        );
      });
    });

    group('sfixed64', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalSfixed64: 0),
          {},
          (m) => m.optionalSfixed64,
          0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalSfixed64: 1),
          {'optionalSfixed64': '1'},
          (m) => m.optionalSfixed64,
          1,
        );
      });
    });

    group('float', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalFloat: 0.0),
          {},
          (m) => m.optionalFloat,
          0.0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalFloat: 1.5),
          {'optionalFloat': 1.5},
          (m) => m.optionalFloat,
          1.5,
        );
      });

      test('NaN', () {
        checkField(
          TestAllTypesProto3(optionalFloat: double.nan),
          {'optionalFloat': 'NaN'},
          (m) => m.optionalFloat,
          isNaN,
        );
      });

      test('Infinity', () {
        checkField(
          TestAllTypesProto3(optionalFloat: double.infinity),
          {'optionalFloat': 'Infinity'},
          (m) => m.optionalFloat,
          double.infinity,
        );
      });

      test('-Infinity', () {
        checkField(
          TestAllTypesProto3(optionalFloat: double.negativeInfinity),
          {'optionalFloat': '-Infinity'},
          (m) => m.optionalFloat,
          double.negativeInfinity,
        );
      });
    });

    group('double', () {
      test('zero', () {
        checkField(
          TestAllTypesProto3(optionalDouble: 0.0),
          {},
          (m) => m.optionalDouble,
          0.0,
        );
      });

      test('non-zero', () {
        checkField(
          TestAllTypesProto3(optionalDouble: 1.5),
          {'optionalDouble': 1.5},
          (m) => m.optionalDouble,
          1.5,
        );
      });

      test('NaN', () {
        checkField(
          TestAllTypesProto3(optionalDouble: double.nan),
          {'optionalDouble': 'NaN'},
          (m) => m.optionalDouble,
          isNaN,
        );
      });

      test('Infinity', () {
        checkField(
          TestAllTypesProto3(optionalDouble: double.infinity),
          {'optionalDouble': 'Infinity'},
          (m) => m.optionalDouble,
          double.infinity,
        );
      });

      test('-Infinity', () {
        checkField(
          TestAllTypesProto3(optionalDouble: double.negativeInfinity),
          {'optionalDouble': '-Infinity'},
          (m) => m.optionalDouble,
          double.negativeInfinity,
        );
      });
    });

    group('bool', () {
      test('false', () {
        checkField(
          TestAllTypesProto3(optionalBool: false),
          {},
          (m) => m.optionalBool,
          false,
        );
      });

      test('true', () {
        checkField(
          TestAllTypesProto3(optionalBool: true),
          {'optionalBool': true},
          (m) => m.optionalBool,
          true,
        );
      });
    });

    group('string', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(optionalString: ''),
          {},
          (m) => m.optionalString,
          '',
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(optionalString: 'foo'),
          {'optionalString': 'foo'},
          (m) => m.optionalString,
          'foo',
        );
      });
    });

    group('bytes', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(optionalBytes: Uint8List(0)),
          {},
          (m) => m.optionalBytes,
          Uint8List(0),
        );
      });

      test('non-empty', () {
        final bytes = Uint8List.fromList([1]);
        checkField(
          TestAllTypesProto3(optionalBytes: bytes),
          {'optionalBytes': 'AQ=='},
          (m) => m.optionalBytes,
          bytes,
        );
      });
    });

    group('nested_message', () {
      test('empty', () {
        final nested = TestAllTypesProto3_NestedMessage();
        checkField(
          TestAllTypesProto3(optionalNestedMessage: nested),
          {'optionalNestedMessage': <String, dynamic>{}},
          (m) => m.optionalNestedMessage,
          nested,
        );
      });

      test('non-empty', () {
        final nested = TestAllTypesProto3_NestedMessage(a: 5);
        checkField(
          TestAllTypesProto3(optionalNestedMessage: nested),
          {
            'optionalNestedMessage': {'a': 5},
          },
          (m) => m.optionalNestedMessage,
          nested,
        );
      });
    });

    group('foreign_message', () {
      test('empty', () {
        final foreign = ForeignMessage();
        checkField(
          TestAllTypesProto3(optionalForeignMessage: foreign),
          {'optionalForeignMessage': <String, dynamic>{}},
          (m) => m.optionalForeignMessage,
          foreign,
        );
      });

      test('non-empty', () {
        final foreign = ForeignMessage(c: 1);
        checkField(
          TestAllTypesProto3(optionalForeignMessage: foreign),
          {
            'optionalForeignMessage': {'c': 1},
          },
          (m) => m.optionalForeignMessage,
          foreign,
        );
      });
    });

    group('nested_enum', () {
      test('default', () {
        checkField(
          TestAllTypesProto3(
            optionalNestedEnum: TestAllTypesProto3_NestedEnum.foo,
          ),
          {},
          (m) => m.optionalNestedEnum,
          TestAllTypesProto3_NestedEnum.foo,
        );
      });

      test('non-default', () {
        checkField(
          TestAllTypesProto3(
            optionalNestedEnum: TestAllTypesProto3_NestedEnum.bar,
          ),
          {'optionalNestedEnum': 'BAR'},
          (m) => m.optionalNestedEnum,
          TestAllTypesProto3_NestedEnum.bar,
        );
      });
    });

    group('foreign_enum', () {
      test('default', () {
        checkField(
          TestAllTypesProto3(optionalForeignEnum: ForeignEnum.foreignFoo),
          {},
          (m) => m.optionalForeignEnum,
          ForeignEnum.foreignFoo,
        );
      });

      test('non-default', () {
        checkField(
          TestAllTypesProto3(optionalForeignEnum: ForeignEnum.foreignBar),
          {'optionalForeignEnum': 'FOREIGN_BAR'},
          (m) => m.optionalForeignEnum,
          ForeignEnum.foreignBar,
        );
      });
    });

    group('aliased_enum', () {
      test('default', () {
        checkField(
          TestAllTypesProto3(
            optionalAliasedEnum: TestAllTypesProto3_AliasedEnum.ALIAS_FOO,
          ),
          {},
          (m) => m.optionalAliasedEnum,
          TestAllTypesProto3_AliasedEnum.ALIAS_FOO,
        );
      });

      test('non-default', () {
        checkField(
          TestAllTypesProto3(
            optionalAliasedEnum: TestAllTypesProto3_AliasedEnum.ALIAS_BAR,
          ),
          {'optionalAliasedEnum': 'ALIAS_BAR'},
          (m) => m.optionalAliasedEnum,
          TestAllTypesProto3_AliasedEnum.ALIAS_BAR,
        );
      });
    });

    group('string_piece', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(optionalStringPiece: ''),
          {},
          (m) => m.optionalStringPiece,
          '',
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(optionalStringPiece: 'foo'),
          {'optionalStringPiece': 'foo'},
          (m) => m.optionalStringPiece,
          'foo',
        );
      });
    });

    group('cord', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(optionalCord: ''),
          {},
          (m) => m.optionalCord,
          '',
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(optionalCord: 'foo'),
          {'optionalCord': 'foo'},
          (m) => m.optionalCord,
          'foo',
        );
      });
    });

    group('recursive_message', () {
      test('empty', () {
        final recursive = TestAllTypesProto3();
        checkField(
          TestAllTypesProto3(recursiveMessage: recursive),
          {'recursiveMessage': <String, dynamic>{}},
          (m) => m.recursiveMessage,
          recursive,
        );
      });

      test('non-empty', () {
        final recursive = TestAllTypesProto3(optionalInt32: 1);
        checkField(
          TestAllTypesProto3(recursiveMessage: recursive),
          {
            'recursiveMessage': {'optionalInt32': 1},
          },
          (m) => m.recursiveMessage,
          recursive,
        );
      });
    });

    // Repeated

    group('repeated int32', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedInt32: []),
          {},
          (m) => m.repeatedInt32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedInt32: [1, 2, 3]),
          {
            'repeatedInt32': [1, 2, 3],
          },
          (m) => m.repeatedInt32,
          [1, 2, 3],
        );
      });
    });

    group('repeated int64', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedInt64: []),
          {},
          (m) => m.repeatedInt64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedInt64: [1, 2, 3]),
          {
            'repeatedInt64': ['1', '2', '3'],
          },
          (m) => m.repeatedInt64,
          [1, 2, 3],
        );
      });
    });

    group('repeated uint32', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedUint32: []),
          {},
          (m) => m.repeatedUint32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedUint32: [1, 2, 3]),
          {
            'repeatedUint32': [1, 2, 3],
          },
          (m) => m.repeatedUint32,
          [1, 2, 3],
        );
      });
    });

    group('repeated uint64', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedUint64: []),
          {},
          (m) => m.repeatedUint64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            repeatedUint64: [BigInt.one, BigInt.from(2), BigInt.from(3)],
          ),
          {
            'repeatedUint64': ['1', '2', '3'],
          },
          (m) => m.repeatedUint64,
          [BigInt.one, BigInt.from(2), BigInt.from(3)],
        );
      });
    });

    group('repeated sint32', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedSint32: []),
          {},
          (m) => m.repeatedSint32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedSint32: [1, 2, 3]),
          {
            'repeatedSint32': [1, 2, 3],
          },
          (m) => m.repeatedSint32,
          [1, 2, 3],
        );
      });
    });

    group('repeated sint64', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedSint64: []),
          {},
          (m) => m.repeatedSint64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedSint64: [1, 2, 3]),
          {
            'repeatedSint64': ['1', '2', '3'],
          },
          (m) => m.repeatedSint64,
          [1, 2, 3],
        );
      });
    });

    group('repeated fixed32', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedFixed32: []),
          {},
          (m) => m.repeatedFixed32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedFixed32: [1, 2, 3]),
          {
            'repeatedFixed32': [1, 2, 3],
          },
          (m) => m.repeatedFixed32,
          [1, 2, 3],
        );
      });
    });

    group('repeated fixed64', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedFixed64: []),
          {},
          (m) => m.repeatedFixed64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            repeatedFixed64: [BigInt.one, BigInt.from(2), BigInt.from(3)],
          ),
          {
            'repeatedFixed64': ['1', '2', '3'],
          },
          (m) => m.repeatedFixed64,
          [BigInt.one, BigInt.from(2), BigInt.from(3)],
        );
      });
    });

    group('repeated sfixed32', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedSfixed32: []),
          {},
          (m) => m.repeatedSfixed32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedSfixed32: [1, 2, 3]),
          {
            'repeatedSfixed32': [1, 2, 3],
          },
          (m) => m.repeatedSfixed32,
          [1, 2, 3],
        );
      });
    });

    group('repeated sfixed64', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedSfixed64: []),
          {},
          (m) => m.repeatedSfixed64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedSfixed64: [1, 2, 3]),
          {
            'repeatedSfixed64': ['1', '2', '3'],
          },
          (m) => m.repeatedSfixed64,
          [1, 2, 3],
        );
      });
    });

    group('repeated float', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedFloat: []),
          {},
          (m) => m.repeatedFloat,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedFloat: [1.5, 2.5]),
          {
            'repeatedFloat': [1.5, 2.5],
          },
          (m) => m.repeatedFloat,
          [1.5, 2.5],
        );
      });
    });

    group('repeated double', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedDouble: []),
          {},
          (m) => m.repeatedDouble,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedDouble: [1.5, 2.5]),
          {
            'repeatedDouble': [1.5, 2.5],
          },
          (m) => m.repeatedDouble,
          [1.5, 2.5],
        );
      });
    });

    group('repeated bool', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedBool: []),
          {},
          (m) => m.repeatedBool,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedBool: [true, false]),
          {
            'repeatedBool': [true, false],
          },
          (m) => m.repeatedBool,
          [true, false],
        );
      });
    });

    group('repeated string', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedString: []),
          {},
          (m) => m.repeatedString,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedString: ['foo', 'bar']),
          {
            'repeatedString': ['foo', 'bar'],
          },
          (m) => m.repeatedString,
          ['foo', 'bar'],
        );
      });
    });

    group('repeated bytes', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedBytes: []),
          {},
          (m) => m.repeatedBytes,
          isEmpty,
        );
      });

      test('non-empty', () {
        final bytes1 = Uint8List.fromList([1]);
        final bytes2 = Uint8List.fromList([2]);
        checkField(
          TestAllTypesProto3(repeatedBytes: [bytes1, bytes2]),
          {
            'repeatedBytes': ['AQ==', 'Ag=='],
          },
          (m) => m.repeatedBytes,
          [bytes1, bytes2],
        );
      });
    });

    group('repeated nested_message', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedNestedMessage: []),
          {},
          (m) => m.repeatedNestedMessage,
          isEmpty,
        );
      });

      test('non-empty', () {
        final nested1 = TestAllTypesProto3_NestedMessage(a: 5);
        final nested2 = TestAllTypesProto3_NestedMessage(a: 10);
        checkField(
          TestAllTypesProto3(repeatedNestedMessage: [nested1, nested2]),
          {
            'repeatedNestedMessage': [
              {'a': 5},
              {'a': 10},
            ],
          },
          (m) => m.repeatedNestedMessage,
          [nested1, nested2],
        );
      });
    });

    group('repeated foreign_message', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedForeignMessage: []),
          {},
          (m) => m.repeatedForeignMessage,
          isEmpty,
        );
      });

      test('non-empty', () {
        final foreign1 = ForeignMessage(c: 1);
        final foreign2 = ForeignMessage(c: 2);
        checkField(
          TestAllTypesProto3(repeatedForeignMessage: [foreign1, foreign2]),
          {
            'repeatedForeignMessage': [
              {'c': 1},
              {'c': 2},
            ],
          },
          (m) => m.repeatedForeignMessage,
          [foreign1, foreign2],
        );
      });
    });

    group('repeated nested_enum', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedNestedEnum: []),
          {},
          (m) => m.repeatedNestedEnum,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            repeatedNestedEnum: [
              TestAllTypesProto3_NestedEnum.foo,
              TestAllTypesProto3_NestedEnum.bar,
            ],
          ),
          {
            'repeatedNestedEnum': ['FOO', 'BAR'],
          },
          (m) => m.repeatedNestedEnum,
          [
            TestAllTypesProto3_NestedEnum.foo,
            TestAllTypesProto3_NestedEnum.bar,
          ],
        );
      });
    });

    group('repeated foreign_enum', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedForeignEnum: []),
          {},
          (m) => m.repeatedForeignEnum,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            repeatedForeignEnum: [
              ForeignEnum.foreignFoo,
              ForeignEnum.foreignBar,
            ],
          ),
          {
            'repeatedForeignEnum': ['FOREIGN_FOO', 'FOREIGN_BAR'],
          },
          (m) => m.repeatedForeignEnum,
          [ForeignEnum.foreignFoo, ForeignEnum.foreignBar],
        );
      });
    });

    group('repeated string_piece', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedStringPiece: []),
          {},
          (m) => m.repeatedStringPiece,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedStringPiece: ['foo', 'bar']),
          {
            'repeatedStringPiece': ['foo', 'bar'],
          },
          (m) => m.repeatedStringPiece,
          ['foo', 'bar'],
        );
      });
    });

    group('repeated cord', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(repeatedCord: []),
          {},
          (m) => m.repeatedCord,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(repeatedCord: ['foo', 'bar']),
          {
            'repeatedCord': ['foo', 'bar'],
          },
          (m) => m.repeatedCord,
          ['foo', 'bar'],
        );
      });
    });

    group('map<int32, int32>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Int32: {}),
          {},
          (m) => m.mapInt32Int32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Int32: {1: 5}),
          {
            'mapInt32Int32': {'1': 5},
          },
          (m) => m.mapInt32Int32,
          {1: 5},
        );
      });
    });
  });
}
