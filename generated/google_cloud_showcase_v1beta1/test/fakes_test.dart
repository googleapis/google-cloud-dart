// Copyright 2025 Google LLC
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

/// Tests the generated fakes in the Echo service, see:
/// https://github.com/googleapis/gapic-showcase/blob/main/schema/google/showcase/v1beta1/echo.proto
library;

import 'package:google_cloud_longrunning/longrunning.dart';
import 'package:google_cloud_protobuf/protobuf.dart';
import 'package:google_cloud_showcase_v1beta1/showcase.dart';
import 'package:google_cloud_showcase_v1beta1/testing.dart';
import 'package:test/test.dart';

final class MyFakeEcho extends FakeEcho {
  @override
  Future<EchoResponse> echo(EchoRequest request) async =>
      EchoResponse(content: request.content ?? '');
}

void main() async {
  group('fake subclass', () {
    test('overridden method', () async {
      final service = MyFakeEcho();
      final response = await service.echo(EchoRequest(content: 'Test'));
      expect(response.content, 'Test');
    });

    test('not overridden method', () async {
      final service = MyFakeEcho();
      await expectLater(
        () => service.expand(ExpandRequest(content: 'Test')),
        throwsUnsupportedError,
      );
    });
  });

  group('fake tests', () {
    group('simple method', () {
      test('registered callback', () async {
        final service = FakeEcho(
          echo: (request) async => EchoResponse(content: request.content ?? ''),
        );
        final response = await service.echo(EchoRequest(content: 'Test'));
        expect(response.content, 'Test');
      });

      test('no callback', () async {
        final service = FakeEcho();
        await expectLater(
          () => service.echo(EchoRequest(content: 'Test')),
          throwsUnsupportedError,
        );
      });

      test('after close', () async {
        final service = FakeEcho(
          echo: (request) async => EchoResponse(content: request.content ?? ''),
        )..close();
        await expectLater(
          () => service.echo(EchoRequest(content: 'Test')),
          throwsStateError,
        );
      });
    });

    group('stream response method', () {
      test('registered callback', () async {
        final service = FakeEcho(
          expand: (request) async* {
            yield EchoResponse(content: request.content);
          },
        );
        expect(
          service.expand(ExpandRequest(content: 'Test')),
          emitsInOrder([
            isA<EchoResponse>().having((r) => r.content, 'content', 'Test'),
            emitsDone,
          ]),
        );
      });

      test('no callback', () async {
        final service = FakeEcho();
        expect(
          () => service.expand(ExpandRequest(content: 'Test')),
          throwsUnsupportedError,
        );
      });

      test('after close', () async {
        final service = FakeEcho(
          expand: (request) async* {
            yield EchoResponse(content: request.content);
          },
        )..close();
        expect(
          () => service.expand(ExpandRequest(content: 'Test')),
          throwsStateError,
        );
      });
    });

    group('long running operations method', () {
      test('registered callback', () async {
        final service = FakeEcho(
          wait: (request) async => Operation<WaitResponse, WaitMetadata>(
            name: 'operations/123',
            done: true,
            response: Any.from(WaitResponse(content: 'Done')),
            operationHelper: OperationHelper(
              WaitResponse.fromJson,
              WaitMetadata.fromJson,
            ),
          ),
        );
        final operation = await service.wait(WaitRequest());
        expect(operation.name, 'operations/123');
        expect(operation.done, isTrue);
        expect(operation.responseAsMessage?.content, 'Done');
      });

      test('no callback', () async {
        final service = FakeEcho();
        await expectLater(
          () => service.wait(WaitRequest()),
          throwsUnsupportedError,
        );
      });

      test('after close', () async {
        final service = FakeEcho(
          wait: (request) async => Operation<WaitResponse, WaitMetadata>(),
        )..close();
        await expectLater(() => service.wait(WaitRequest()), throwsStateError);
      });
    });
  });
}
