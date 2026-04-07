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

import 'package:shelf_google_cloud/shelf_google_cloud.dart';
import 'package:test/test.dart';

void main() {
  group('parseTraceContext', () {
    test('parses full context', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef/1054454457908058113;o=1',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, '0ea22cbe236fd801');
      expect(context.traceSampled, true);
    });

    test('parses without sampled flag', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef/123',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, '000000000000007b');
      expect(context.traceSampled, isFalse);
    });

    test(
      'parses format without trace options but trailing semicolon flag off',
      () {
        final context = TraceContextData.parse(
          projectId: 'test-project',
          traceHeader: '0123456789abcdef0123456789abcdef/123;o=0',
        );
        expect(
          context.traceId,
          'projects/test-project/traces/0123456789abcdef0123456789abcdef',
        );
        expect(context.spanId, '000000000000007b');
        expect(context.traceSampled, false);
      },
    );

    test('parses minimal trace', () {
      final context = TraceContextData.parse(
        projectId: 'test-project',
        traceHeader: '0123456789abcdef0123456789abcdef',
      );
      expect(
        context.traceId,
        'projects/test-project/traces/0123456789abcdef0123456789abcdef',
      );
      expect(context.spanId, isNull);
      expect(context.traceSampled, isFalse);
    });
  });

  group('TraceContextData.asPayloadMap', () {
    test('full context includes everything', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
        traceSampled: true,
      );
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
        'logging.googleapis.com/trace_sampled': true,
      });
    });

    test('omits spanId when null', () {
      final context = TraceContextData(traceId: 'test-trace');
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
      });
    });

    test('omits traceSampled when false', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
        // traceSampled: false, // Default
      );
      expect(context.asPayloadMap(), {
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
      });
    });

    test('merges with existing payload', () {
      final context = TraceContextData(
        traceId: 'test-trace',
        spanId: 'test-span',
      );
      final payload = {'message': 'hello', 'count': 42};
      expect(context.asPayloadMap(payload), {
        'message': 'hello',
        'count': 42,
        'logging.googleapis.com/trace': 'test-trace',
        'logging.googleapis.com/spanId': 'test-span',
      });
    });
  });
}
