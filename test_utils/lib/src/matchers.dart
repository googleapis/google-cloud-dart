import 'package:collection/collection.dart';
import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:test/test.dart';

Matcher messageEquals(ProtoMessage expected) =>
    const TypeMatcher<ProtoMessage>()
        .having(
          (actual) => actual.qualifiedName,
          'qualifiedName',
          expected.qualifiedName,
        )
        .having((actual) => actual.toJson(), 'json', expected.toJson());
