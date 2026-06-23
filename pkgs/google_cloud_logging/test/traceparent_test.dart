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

import 'dart:async';

import 'package:google_cloud_logging/interop.dart';
import 'package:google_cloud_logging/src/traceparent.dart';
import 'package:test/test.dart';

void main() {
  group('parseTraceparent', () {
    test('valid sampled traceparent', () {
      final parsed = parseTraceparent(
        '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      );
      expect(parsed, isNotNull);
      expect(parsed!.traceId, '4bf92f3577b34da6a3ce929d0e0e4736');
      expect(parsed.spanId, '00f067aa0ba902b7');
      expect(parsed.traceSampled, isTrue);
    });

    test('valid unsampled traceparent', () {
      final parsed = parseTraceparent(
        '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00',
      );
      expect(parsed, isNotNull);
      expect(parsed!.traceId, '4bf92f3577b34da6a3ce929d0e0e4736');
      expect(parsed.spanId, '00f067aa0ba902b7');
      expect(parsed.traceSampled, isFalse);
    });

    test('invalid version ff', () {
      final parsed = parseTraceparent(
        'ff-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      );
      expect(parsed, isNull);
    });

    test('invalid traceId all zeros', () {
      final parsed = parseTraceparent(
        '00-00000000000000000000000000000000-00f067aa0ba902b7-01',
      );
      expect(parsed, isNull);
    });

    test('invalid spanId all zeros', () {
      final parsed = parseTraceparent(
        '00-4bf92f3577b34da6a3ce929d0e0e4736-0000000000000000-01',
      );
      expect(parsed, isNull);
    });

    test('invalid format components', () {
      expect(
        parseTraceparent(
          '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7',
        ),
        isNull,
      );
      expect(
        parseTraceparent(
          '00-4bf92f3577b34da6a3ce929d0e0e473-00f067aa0ba902b7-01',
        ),
        isNull,
      );
      expect(
        parseTraceparent(
          '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b-01',
        ),
        isNull,
      );
    });
  });

  group('formatTraceparent', () {
    test('null traceparent returns empty map', () {
      expect(formatTraceparent('my-project', null), isEmpty);
    });

    test('invalid traceparent returns empty map', () {
      expect(formatTraceparent('my-project', 'invalid-traceparent'), isEmpty);
    });

    test('valid traceparent with projectId', () {
      final formatted = formatTraceparent(
        'my-project',
        '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      );
      expect(formatted, {
        'logging.googleapis.com/trace':
            'projects/my-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
        'logging.googleapis.com/spanId': '00f067aa0ba902b7',
        'logging.googleapis.com/trace_sampled': true,
      });
    });

    test('valid traceparent with null projectId', () {
      final formatted = formatTraceparent(
        null,
        '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      );
      expect(formatted, {
        'logging.googleapis.com/spanId': '00f067aa0ba902b7',
        'logging.googleapis.com/trace_sampled': true,
      });
    });
  });

  group('structuredTraceFromZone', () {
    test('empty zone returns empty map', () {
      expect(structuredTraceFromZone('my-project'), isEmpty);
    });

    test('extracts traceparent and project from zone values', () {
      runZoned(
        () {
          final trace = structuredTraceFromZone(null);
          expect(trace, {
            'logging.googleapis.com/trace':
                'projects/zone-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
            'logging.googleapis.com/spanId': '00f067aa0ba902b7',
            'logging.googleapis.com/trace_sampled': true,
          });
        },
        zoneValues: {
          traceparentHeaderValueZoneVariable:
              '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          googleCloudProjectIdZoneVariable: 'zone-project',
        },
      );
    });

    test('explicit projectId overrides zone google_cloud_project', () {
      runZoned(
        () {
          final trace = structuredTraceFromZone('explicit-project');
          expect(trace, {
            'logging.googleapis.com/trace':
                'projects/explicit-project/traces/4bf92f3577b34da6a3ce929d0e0e4736',
            'logging.googleapis.com/spanId': '00f067aa0ba902b7',
            'logging.googleapis.com/trace_sampled': true,
          });
        },
        zoneValues: {
          traceparentHeaderValueZoneVariable:
              '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
          googleCloudProjectIdZoneVariable: 'zone-project',
        },
      );
    });
  });
}
