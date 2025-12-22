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
  } else if (f is List<ProtoMessage> && matcher is List<ProtoMessage>) {
    expect(
      f.map((e) => e.toJson()).toList(),
      matcher.map((e) => e.toJson()).toList(),
    );
  } else if (f is Map<dynamic, ProtoMessage> &&
      matcher is Map<dynamic, ProtoMessage>) {
    expect(
      {for (final e in f.entries) e.key: e.value.toJson()},
      {for (final e in matcher.entries) e.key: e.value.toJson()},
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

    group('map<int64, int64>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapInt64Int64: {}),
          {},
          (m) => m.mapInt64Int64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapInt64Int64: {1: 5}),
          {
            'mapInt64Int64': {'1': '5'},
          },
          (m) => m.mapInt64Int64,
          {1: 5},
        );
      });
    });

    group('map<uint32, uint32>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapUint32Uint32: {}),
          {},
          (m) => m.mapUint32Uint32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapUint32Uint32: {1: 5}),
          {
            'mapUint32Uint32': {'1': 5},
          },
          (m) => m.mapUint32Uint32,
          {1: 5},
        );
      });
    });

    group('map<uint64, uint64>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapUint64Uint64: {}),
          {},
          (m) => m.mapUint64Uint64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapUint64Uint64: {BigInt.one: BigInt.from(5)}),
          {
            'mapUint64Uint64': {'1': '5'},
          },
          (m) => m.mapUint64Uint64,
          {BigInt.one: BigInt.from(5)},
        );
      });
    });

    group('map<sint32, sint32>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapSint32Sint32: {}),
          {},
          (m) => m.mapSint32Sint32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapSint32Sint32: {1: 5}),
          {
            'mapSint32Sint32': {'1': 5},
          },
          (m) => m.mapSint32Sint32,
          {1: 5},
        );
      });
    });

    group('map<sint64, sint64>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapSint64Sint64: {}),
          {},
          (m) => m.mapSint64Sint64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapSint64Sint64: {1: 5}),
          {
            'mapSint64Sint64': {'1': '5'},
          },
          (m) => m.mapSint64Sint64,
          {1: 5},
        );
      });
    });

    group('map<fixed32, fixed32>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapFixed32Fixed32: {}),
          {},
          (m) => m.mapFixed32Fixed32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapFixed32Fixed32: {1: 5}),
          {
            'mapFixed32Fixed32': {'1': 5},
          },
          (m) => m.mapFixed32Fixed32,
          {1: 5},
        );
      });
    });

    group('map<fixed64, fixed64>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapFixed64Fixed64: {}),
          {},
          (m) => m.mapFixed64Fixed64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapFixed64Fixed64: {BigInt.one: BigInt.from(5)}),
          {
            'mapFixed64Fixed64': {'1': '5'},
          },
          (m) => m.mapFixed64Fixed64,
          {BigInt.one: BigInt.from(5)},
        );
      });
    });

    group('map<sfixed32, sfixed32>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapSfixed32Sfixed32: {}),
          {},
          (m) => m.mapSfixed32Sfixed32,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapSfixed32Sfixed32: {1: 5}),
          {
            'mapSfixed32Sfixed32': {'1': 5},
          },
          (m) => m.mapSfixed32Sfixed32,
          {1: 5},
        );
      });
    });

    group('map<sfixed64, sfixed64>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapSfixed64Sfixed64: {}),
          {},
          (m) => m.mapSfixed64Sfixed64,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapSfixed64Sfixed64: {1: 5}),
          {
            'mapSfixed64Sfixed64': {'1': '5'},
          },
          (m) => m.mapSfixed64Sfixed64,
          {1: 5},
        );
      });
    });

    group('map<int32, float>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Float: {}),
          {},
          (m) => m.mapInt32Float,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Float: {1: 1.5}),
          {
            'mapInt32Float': {'1': 1.5},
          },
          (m) => m.mapInt32Float,
          {1: 1.5},
        );
      });
    });

    group('map<int32, double>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Double: {}),
          {},
          (m) => m.mapInt32Double,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapInt32Double: {1: 1.5}),
          {
            'mapInt32Double': {'1': 1.5},
          },
          (m) => m.mapInt32Double,
          {1: 1.5},
        );
      });
    });

    group('map<bool, bool>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapBoolBool: {}),
          {},
          (m) => m.mapBoolBool,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapBoolBool: {true: true}),
          {
            'mapBoolBool': {'true': true},
          },
          (m) => m.mapBoolBool,
          {true: true},
        );
      });
    });

    group('map<string, string>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringString: {}),
          {},
          (m) => m.mapStringString,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(mapStringString: {'foo': 'bar'}),
          {
            'mapStringString': {'foo': 'bar'},
          },
          (m) => m.mapStringString,
          {'foo': 'bar'},
        );
      });
    });

    group('map<string, bytes>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringBytes: {}),
          {},
          (m) => m.mapStringBytes,
          isEmpty,
        );
      });

      test('non-empty', () {
        final bytes = Uint8List.fromList([1]);
        checkField(
          TestAllTypesProto3(mapStringBytes: {'foo': bytes}),
          {
            'mapStringBytes': {'foo': 'AQ=='},
          },
          (m) => m.mapStringBytes,
          {'foo': bytes},
        );
      });
    });

    group('map<string, nested_message>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringNestedMessage: {}),
          {},
          (m) => m.mapStringNestedMessage,
          isEmpty,
        );
      });

      test('non-empty', () {
        final nested = TestAllTypesProto3_NestedMessage(a: 5);
        checkField(
          TestAllTypesProto3(mapStringNestedMessage: {'foo': nested}),
          {
            'mapStringNestedMessage': {
              'foo': {'a': 5},
            },
          },
          (m) => m.mapStringNestedMessage,
          {'foo': nested},
        );
      });
    });

    group('map<string, foreign_message>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringForeignMessage: {}),
          {},
          (m) => m.mapStringForeignMessage,
          isEmpty,
        );
      });

      test('non-empty', () {
        final foreign = ForeignMessage(c: 1);
        checkField(
          TestAllTypesProto3(mapStringForeignMessage: {'foo': foreign}),
          {
            'mapStringForeignMessage': {
              'foo': {'c': 1},
            },
          },
          (m) => m.mapStringForeignMessage,
          {'foo': foreign},
        );
      });
    });

    group('map<string, nested_enum>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringNestedEnum: {}),
          {},
          (m) => m.mapStringNestedEnum,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            mapStringNestedEnum: {'foo': TestAllTypesProto3_NestedEnum.bar},
          ),
          {
            'mapStringNestedEnum': {'foo': 'BAR'},
          },
          (m) => m.mapStringNestedEnum,
          {'foo': TestAllTypesProto3_NestedEnum.bar},
        );
      });
    });

    group('map<string, foreign_enum>', () {
      test('empty', () {
        checkField(
          TestAllTypesProto3(mapStringForeignEnum: {}),
          {},
          (m) => m.mapStringForeignEnum,
          isEmpty,
        );
      });

      test('non-empty', () {
        checkField(
          TestAllTypesProto3(
            mapStringForeignEnum: {'foo': ForeignEnum.foreignBar},
          ),
          {
            'mapStringForeignEnum': {'foo': 'FOREIGN_BAR'},
          },
          (m) => m.mapStringForeignEnum,
          {'foo': ForeignEnum.foreignBar},
        );
      });
    });

    group('oneof', () {
      test('oneof_uint32', () {
        checkField(
          TestAllTypesProto3(oneofUint32: 5),
          {'oneofUint32': 5},
          (m) => m.oneofUint32,
          5,
        );
      });

      test('oneof_nested_message', () {
        final nested = TestAllTypesProto3_NestedMessage(a: 5);
        checkField(
          TestAllTypesProto3(oneofNestedMessage: nested),
          {
            'oneofNestedMessage': {'a': 5},
          },
          (m) => m.oneofNestedMessage,
          nested,
        );
      });

      test('oneof_string', () {
        checkField(
          TestAllTypesProto3(oneofString: 'foo'),
          {'oneofString': 'foo'},
          (m) => m.oneofString,
          'foo',
        );
      });

      test('oneof_bytes', () {
        final bytes = Uint8List.fromList([1]);
        checkField(
          TestAllTypesProto3(oneofBytes: bytes),
          {'oneofBytes': 'AQ=='},
          (m) => m.oneofBytes,
          bytes,
        );
      });

      test('oneof_bool', () {
        checkField(
          TestAllTypesProto3(oneofBool: true),
          {'oneofBool': true},
          (m) => m.oneofBool,
          true,
        );
      });

      test('oneof_uint64', () {
        checkField(
          TestAllTypesProto3(oneofUint64: BigInt.from(5)),
          {'oneofUint64': '5'},
          (m) => m.oneofUint64,
          BigInt.from(5),
        );
      });

      test('oneof_float', () {
        checkField(
          TestAllTypesProto3(oneofFloat: 1.5),
          {'oneofFloat': 1.5},
          (m) => m.oneofFloat,
          1.5,
        );
      });

      test('oneof_double', () {
        checkField(
          TestAllTypesProto3(oneofDouble: 1.5),
          {'oneofDouble': 1.5},
          (m) => m.oneofDouble,
          1.5,
        );
      });

      test('oneof_enum', () {
        checkField(
          TestAllTypesProto3(oneofEnum: TestAllTypesProto3_NestedEnum.bar),
          {'oneofEnum': 'BAR'},
          (m) => m.oneofEnum,
          TestAllTypesProto3_NestedEnum.bar,
        );
      });

      test(
        'oneof_null_value',
        () {
          checkField(
            TestAllTypesProto3(oneofNullValue: NullValue.nullValue),
            {'oneofNullValue': null},
            (m) => m.oneofNullValue,
            NullValue.nullValue,
          );
        },
        skip: 'https://github.com/googleapis/google-cloud-dart/issues/99',
      );

      test(
        'duplicate',
        () {
          expect(
            () => TestAllTypesProto3(oneofUint32: 5, oneofString: 'foo'),
            throwsA(isA<ArgumentError>()),
          );
        },
        skip: 'TODO(https://github.com/googleapis/google-cloud-dart/issues/26)',
      );
    });

    // Well-known types
    group('well-known types', () {
      group('google.protobuf.BoolValue', () {
        test('true', () {
          checkField(
            TestAllTypesProto3(optionalBoolWrapper: BoolValue(value: true)),
            {'optionalBoolWrapper': true},
            (m) => m.optionalBoolWrapper,
            BoolValue(value: true),
          );
        });

        test('false', () {
          checkField(
            TestAllTypesProto3(optionalBoolWrapper: BoolValue(value: false)),
            {'optionalBoolWrapper': false},
            (m) => m.optionalBoolWrapper,
            BoolValue(value: false),
          );
        });
      });

      group('google.protobuf.Int32Value', () {
        test('zero', () {
          checkField(
            TestAllTypesProto3(optionalInt32Wrapper: Int32Value(value: 0)),
            {'optionalInt32Wrapper': 0},
            (m) => m.optionalInt32Wrapper,
            Int32Value(value: 0),
          );
        });
        test('non-zero', () {
          checkField(
            TestAllTypesProto3(optionalInt32Wrapper: Int32Value(value: 5)),
            {'optionalInt32Wrapper': 5},
            (m) => m.optionalInt32Wrapper,
            Int32Value(value: 5),
          );
        });
      });

      group('google.protobuf.Int64Value', () {
        test('zero', () {
          checkField(
            TestAllTypesProto3(optionalInt64Wrapper: Int64Value(value: 0)),
            {'optionalInt64Wrapper': '0'},
            (m) => m.optionalInt64Wrapper,
            Int64Value(value: 0),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(optionalInt64Wrapper: Int64Value(value: 5)),
            {'optionalInt64Wrapper': '5'},
            (m) => m.optionalInt64Wrapper,
            Int64Value(value: 5),
          );
        });
      });

      group('google.protobuf.UInt32Value', () {
        test('zero', () {
          checkField(
            TestAllTypesProto3(optionalUint32Wrapper: Uint32Value(value: 0)),
            {'optionalUint32Wrapper': 0},
            (m) => m.optionalUint32Wrapper,
            Uint32Value(value: 0),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(optionalUint32Wrapper: Uint32Value(value: 5)),
            {'optionalUint32Wrapper': 5},
            (m) => m.optionalUint32Wrapper,
            Uint32Value(value: 5),
          );
        });
      });

      group('google.protobuf.UInt64Value', () {
        test('zero', () {
          checkField(
            TestAllTypesProto3(
              optionalUint64Wrapper: Uint64Value(value: BigInt.zero),
            ),
            {'optionalUint64Wrapper': '0'},
            (m) => m.optionalUint64Wrapper,
            Uint64Value(value: BigInt.zero),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(
              optionalUint64Wrapper: Uint64Value(value: BigInt.from(5)),
            ),
            {'optionalUint64Wrapper': '5'},
            (m) => m.optionalUint64Wrapper,
            Uint64Value(value: BigInt.from(5)),
          );
        });
      });

      group('google.protobuf.FloatValue', () {
        // What about Inf, Nan?
        test('zero', () {
          checkField(
            TestAllTypesProto3(optionalFloatWrapper: FloatValue(value: 0.0)),
            {'optionalFloatWrapper': 0.0},
            (m) => m.optionalFloatWrapper,
            FloatValue(value: 0.0),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(optionalFloatWrapper: FloatValue(value: 1.5)),
            {'optionalFloatWrapper': 1.5},
            (m) => m.optionalFloatWrapper,
            FloatValue(value: 1.5),
          );
        });
      });

      group('google.protobuf.DoubleValue', () {
        // What about Inf, Nan?
        test('zero', () {
          checkField(
            TestAllTypesProto3(optionalDoubleWrapper: DoubleValue(value: 0.0)),
            {'optionalDoubleWrapper': 0.0},
            (m) => m.optionalDoubleWrapper,
            DoubleValue(value: 0.0),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(optionalDoubleWrapper: DoubleValue(value: 1.5)),
            {'optionalDoubleWrapper': 1.5},
            (m) => m.optionalDoubleWrapper,
            DoubleValue(value: 1.5),
          );
        });
      });

      group('google.protobuf.StringValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(optionalStringWrapper: StringValue(value: '')),
            {'optionalStringWrapper': ''},
            (m) => m.optionalStringWrapper,
            StringValue(value: ''),
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              optionalStringWrapper: StringValue(value: 'foo'),
            ),
            {'optionalStringWrapper': 'foo'},
            (m) => m.optionalStringWrapper,
            StringValue(value: 'foo'),
          );
        });
      });

      group('google.protobuf.BytesValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(
              optionalBytesWrapper: BytesValue(value: Uint8List(0)),
            ),
            {'optionalBytesWrapper': ''},
            (m) => m.optionalBytesWrapper,
            BytesValue(value: Uint8List(0)),
          );
        });

        test('non-empty', () {
          final bytes = Uint8List.fromList([1]);
          checkField(
            TestAllTypesProto3(optionalBytesWrapper: BytesValue(value: bytes)),
            {'optionalBytesWrapper': 'AQ=='},
            (m) => m.optionalBytesWrapper,
            BytesValue(value: bytes),
          );
        });
      });

      group('repeated BoolValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedBoolWrapper: []),
            {},
            (m) => m.repeatedBoolWrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedBoolWrapper: [
                BoolValue(value: true),
                BoolValue(value: false),
              ],
            ),
            {
              'repeatedBoolWrapper': [true, false],
            },
            (m) => m.repeatedBoolWrapper,
            [BoolValue(value: true), BoolValue(value: false)],
          );
        });
      });

      group('repeated Int32Value', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedInt32Wrapper: []),
            {},
            (m) => m.repeatedInt32Wrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedInt32Wrapper: [
                Int32Value(value: 1),
                Int32Value(value: 2),
              ],
            ),
            {
              'repeatedInt32Wrapper': [1, 2],
            },
            (m) => m.repeatedInt32Wrapper,
            [Int32Value(value: 1), Int32Value(value: 2)],
          );
        });
      });

      group('repeated Int64Value', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedInt64Wrapper: []),
            {},
            (m) => m.repeatedInt64Wrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedInt64Wrapper: [
                Int64Value(value: 1),
                Int64Value(value: 2),
              ],
            ),
            {
              'repeatedInt64Wrapper': ['1', '2'],
            },
            (m) => m.repeatedInt64Wrapper,
            [Int64Value(value: 1), Int64Value(value: 2)],
          );
        });
      });

      group('repeated Uint32Value', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedUint32Wrapper: []),
            {},
            (m) => m.repeatedUint32Wrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedUint32Wrapper: [
                Uint32Value(value: 1),
                Uint32Value(value: 2),
              ],
            ),
            {
              'repeatedUint32Wrapper': [1, 2],
            },
            (m) => m.repeatedUint32Wrapper,
            [Uint32Value(value: 1), Uint32Value(value: 2)],
          );
        });
      });

      group('repeated Uint64Value', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedUint64Wrapper: []),
            {},
            (m) => m.repeatedUint64Wrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedUint64Wrapper: [
                Uint64Value(value: BigInt.one),
                Uint64Value(value: BigInt.two),
              ],
            ),
            {
              'repeatedUint64Wrapper': ['1', '2'],
            },
            (m) => m.repeatedUint64Wrapper,
            [Uint64Value(value: BigInt.one), Uint64Value(value: BigInt.two)],
          );
        });
      });

      group('repeated FloatValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedFloatWrapper: []),
            {},
            (m) => m.repeatedFloatWrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedFloatWrapper: [
                FloatValue(value: 1.5),
                FloatValue(value: 2.5),
              ],
            ),
            {
              'repeatedFloatWrapper': [1.5, 2.5],
            },
            (m) => m.repeatedFloatWrapper,
            [FloatValue(value: 1.5), FloatValue(value: 2.5)],
          );
        });
      });

      group('repeated DoubleValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedDoubleWrapper: []),
            {},
            (m) => m.repeatedDoubleWrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedDoubleWrapper: [
                DoubleValue(value: 1.5),
                DoubleValue(value: 2.5),
              ],
            ),
            {
              'repeatedDoubleWrapper': [1.5, 2.5],
            },
            (m) => m.repeatedDoubleWrapper,
            [DoubleValue(value: 1.5), DoubleValue(value: 2.5)],
          );
        });
      });

      group('repeated StringValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedStringWrapper: []),
            {},
            (m) => m.repeatedStringWrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedStringWrapper: [
                StringValue(value: 'foo'),
                StringValue(value: 'bar'),
              ],
            ),
            {
              'repeatedStringWrapper': ['foo', 'bar'],
            },
            (m) => m.repeatedStringWrapper,
            [StringValue(value: 'foo'), StringValue(value: 'bar')],
          );
        });
      });

      group('repeated BytesValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedBytesWrapper: []),
            {},
            (m) => m.repeatedBytesWrapper,
            isEmpty,
          );
        });

        test('non-empty', () {
          final bytes1 = Uint8List.fromList([1]);
          final bytes2 = Uint8List.fromList([2]);
          checkField(
            TestAllTypesProto3(
              repeatedBytesWrapper: [
                BytesValue(value: bytes1),
                BytesValue(value: bytes2),
              ],
            ),
            {
              'repeatedBytesWrapper': ['AQ==', 'Ag=='],
            },
            (m) => m.repeatedBytesWrapper,
            [BytesValue(value: bytes1), BytesValue(value: bytes2)],
          );
        });
      });

      group('google.protobuf.Duration', () {
        test('zero', () {
          checkField(
            TestAllTypesProto3(
              optionalDuration: Duration(seconds: 0, nanos: 0),
            ),
            {'optionalDuration': '0s'},
            (m) => m.optionalDuration,
            Duration(seconds: 0, nanos: 0),
          );
        });

        test('non-zero', () {
          checkField(
            TestAllTypesProto3(
              optionalDuration: Duration(seconds: 1, nanos: 500000000),
            ),
            {'optionalDuration': '1.5s'},
            (m) => m.optionalDuration,
            Duration(seconds: 1, nanos: 500000000),
          );
        });
      });

      group('google.protobuf.Timestamp', () {
        test('epoch', () {
          checkField(
            TestAllTypesProto3(
              optionalTimestamp: Timestamp(seconds: 0, nanos: 0),
            ),
            {'optionalTimestamp': '1970-01-01T00:00:00Z'},
            (m) => m.optionalTimestamp,
            Timestamp(seconds: 0, nanos: 0),
          );
        });

        test('non-epoch', () {
          // 2017-01-15T01:30:15.01Z = 1484443815 seconds + 10000000 nanos
          checkField(
            TestAllTypesProto3(
              optionalTimestamp: Timestamp(
                seconds: 1484443815,
                nanos: 10000000,
              ),
            ),
            {'optionalTimestamp': '2017-01-15T01:30:15.010Z'},
            (m) => m.optionalTimestamp,
            Timestamp(seconds: 1484443815, nanos: 10000000),
          );
        });
      });

      group('google.protobuf.FieldMask', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(optionalFieldMask: FieldMask(paths: [])),
            {'optionalFieldMask': ''},
            (m) => m.optionalFieldMask,
            FieldMask(paths: []),
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              optionalFieldMask: FieldMask(
                paths: ['foo.bar', 'baz', 'foo_bar'],
              ),
            ),
            {'optionalFieldMask': 'foo.bar,baz,foo_bar'},
            (m) => m.optionalFieldMask,
            FieldMask(paths: ['foo.bar', 'baz', 'foo_bar']),
          );
        });
      });

      group('google.protobuf.Struct', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(
              optionalStruct: Struct(fields: <String, Value>{}),
            ),
            {'optionalStruct': <String, dynamic>{}},
            (m) => m.optionalStruct,
            Struct(fields: <String, Value>{}),
          );
        });

        test('non-empty', () {
          final s = Struct(
            fields: <String, Value>{
              'a': Value(numberValue: 1.0),
              'b': Value(boolValue: true),
            },
          );
          checkField(
            TestAllTypesProto3(optionalStruct: s),
            {
              'optionalStruct': {'a': 1.0, 'b': true},
            },
            (m) => m.optionalStruct,
            s,
          );
        });
      });

      group('google.protobuf.Any', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(optionalAny: Any(json: {})),
            {'optionalAny': <String, dynamic>{}},
            (m) => m.optionalAny,
            Any(json: {}),
          );
        });

        test('message', () {
          final message = ForeignMessage(c: 5);
          checkField(
            TestAllTypesProto3(optionalAny: Any.from(message)),
            {
              'optionalAny': {
                '@type':
                    'type.googleapis.com/protobuf_test_messages.proto3.ForeignMessage',
                'c': 5,
              },
            },
            (m) => m.optionalAny,
            Any.from(message),
          );
        });
      });

      group('google.protobuf.Value', () {
        test('null', () {
          checkField(
            TestAllTypesProto3(
              optionalValue: Value(nullValue: NullValue.nullValue),
            ),
            {'optionalValue': null},
            (m) => m.optionalValue,
            isNull,
          );
        });

        test('number', () {
          checkField(
            TestAllTypesProto3(optionalValue: Value(numberValue: 1.5)),
            {'optionalValue': 1.5},
            (m) => m.optionalValue,
            Value(numberValue: 1.5),
          );
        });

        test('string', () {
          checkField(
            TestAllTypesProto3(optionalValue: Value(stringValue: 'foo')),
            {'optionalValue': 'foo'},
            (m) => m.optionalValue,
            Value(stringValue: 'foo'),
          );
        });

        test('bool', () {
          checkField(
            TestAllTypesProto3(optionalValue: Value(boolValue: true)),
            {'optionalValue': true},
            (m) => m.optionalValue,
            Value(boolValue: true),
          );
        });
      });

      group('google.protobuf.NullValue', () {
        test('null', () {
          checkField(
            TestAllTypesProto3(optionalNullValue: NullValue.nullValue),
            {}, // XXX
            (m) => m.optionalNullValue,
            NullValue.nullValue,
          );
        });
      });

      group('repeated Duration', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedDuration: []),
            {},
            (m) => m.repeatedDuration,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedDuration: [
                Duration(seconds: 1, nanos: 500000000),
                Duration(seconds: 2, nanos: 0),
              ],
            ),
            {
              'repeatedDuration': ['1.5s', '2s'],
            },
            (m) => m.repeatedDuration,
            [
              Duration(seconds: 1, nanos: 500000000),
              Duration(seconds: 2, nanos: 0),
            ],
          );
        });
      });

      group('repeated Timestamp', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedTimestamp: []),
            {},
            (m) => m.repeatedTimestamp,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedTimestamp: [
                Timestamp(seconds: 0, nanos: 0),
                Timestamp(seconds: 1484443815, nanos: 10000000),
              ],
            ),
            {
              'repeatedTimestamp': [
                '1970-01-01T00:00:00Z',
                '2017-01-15T01:30:15.010Z',
              ],
            },
            (m) => m.repeatedTimestamp,
            [
              Timestamp(seconds: 0, nanos: 0),
              Timestamp(seconds: 1484443815, nanos: 10000000),
            ],
          );
        });
      });

      group('repeated FieldMask', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedFieldmask: []),
            {},
            (m) => m.repeatedFieldmask,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedFieldmask: [
                FieldMask(paths: ['foo', 'bar']),
                FieldMask(paths: ['baz']),
              ],
            ),
            {
              'repeatedFieldmask': ['foo,bar', 'baz'],
            },
            (m) => m.repeatedFieldmask,
            [
              FieldMask(paths: ['foo', 'bar']),
              FieldMask(paths: ['baz']),
            ],
          );
        });
      });

      group('repeated Struct', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedStruct: []),
            {},
            (m) => m.repeatedStruct,
            isEmpty,
          );
        });

        test('non-empty', () {
          final s1 = Struct(
            fields: <String, Value>{'a': Value(numberValue: 1.0)},
          );
          final s2 = Struct(
            fields: <String, Value>{'b': Value(boolValue: true)},
          );
          checkField(
            TestAllTypesProto3(repeatedStruct: [s1, s2]),
            {
              'repeatedStruct': [
                {'a': 1.0},
                {'b': true},
              ],
            },
            (m) => m.repeatedStruct,
            [s1, s2],
          );
        });
      });

      group('repeated Any', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedAny: []),
            {},
            (m) => m.repeatedAny,
            isEmpty,
          );
        });

        test('non-empty', () {
          final message1 = ForeignMessage(c: 5);
          // Value should check that more than value is not set.
          final message2 = Value(nullValue: NullValue.nullValue);
          final message3 = ForeignMessage(c: 6);

          checkField(
            TestAllTypesProto3(
              repeatedAny: [
                Any.from(message1),
                Any.from(message2),
                Any.from(message3),
              ],
            ),
            {
              'repeatedAny': [
                {
                  '@type':
                      'type.googleapis.com/protobuf_test_messages.proto3.ForeignMessage',
                  'c': 5,
                },
                {
                  '@type': 'type.googleapis.com/google.protobuf.Value',
                  'value': null,
                },
                {
                  '@type':
                      'type.googleapis.com/protobuf_test_messages.proto3.ForeignMessage',
                  'c': 6,
                },
              ],
            },
            (m) => m.repeatedAny,
            [Any.from(message1), Any.from(message2), Any.from(message3)],
          );
        });
      });

      group('repeated Value', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedValue: []),
            {},
            (m) => m.repeatedValue,
            isEmpty,
          );
        });

        test('non-empty', () {
          checkField(
            TestAllTypesProto3(
              repeatedValue: [
                Value(numberValue: 1.0),
                Value(nullValue: NullValue.nullValue),
                Value(stringValue: 'foo'),
              ],
            ),
            {
              'repeatedValue': [1.0, null, 'foo'],
            },
            (m) => m.repeatedValue,
            [
              Value(numberValue: 1.0),
              Value(nullValue: NullValue.nullValue),
              Value(stringValue: 'foo'),
            ],
          );
        });
      });

      group('repeated ListValue', () {
        test('empty', () {
          checkField(
            TestAllTypesProto3(repeatedListValue: []),
            {},
            (m) => m.repeatedListValue,
            isEmpty,
          );
        });

        test('non-empty', () {
          // XXX
          final l1 = ListValue(
            values: [Value(numberValue: 1.0), Value(boolValue: true)],
          );
          final l2 = ListValue(values: [Value(stringValue: 'foo')]);
          checkField(
            TestAllTypesProto3(repeatedListValue: [l1, l2]),
            {
              'repeatedListValue': [
                [1.0, true],
                ['foo'],
              ],
            },
            (m) => m.repeatedListValue,
            [l1, l2],
          );
        });
      });
    });
  });
}
