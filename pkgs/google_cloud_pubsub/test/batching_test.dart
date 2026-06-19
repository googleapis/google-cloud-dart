import 'dart:async';

import 'package:google_cloud_pubsub/src/batching.dart';
import 'package:test/test.dart';

void main() {
  group('Batcher', () {
    test('flushes when maxMessages is reached', () async {
      final completer = Completer<List<int>>();
      final batcher = Batcher<int>(
        settings: const BatchingSettings(
          maxMessages: 3,
          maxDelay: Duration(seconds: 1),
        ),
        itemSize: (i) => 1,
        onBatch: (batch) async {
          completer.complete(batch);
        },
      );

      batcher
        ..add(1)
        ..add(2)
        ..add(3);

      final result = await completer.future;
      expect(result, [1, 2, 3]);
    });

    test('flushes when maxBytes is reached', () async {
      final completer = Completer<List<int>>();
      final batcher = Batcher<int>(
        settings: const BatchingSettings(
          maxBytes: 10,
          maxDelay: Duration(seconds: 1),
        ),
        itemSize: (i) => i,
        onBatch: (batch) async {
          completer.complete(batch);
        },
      );

      batcher
        ..add(4)
        ..add(6); // 4 + 6 = 10, which reaches maxBytes

      final result = await completer.future;
      expect(result, [4, 6]);
    });

    test('flushes after maxDelay', () async {
      final completer = Completer<List<int>>();
      final batcher = Batcher<int>(
        settings: const BatchingSettings(
          maxMessages: 10,
          maxDelay: Duration(milliseconds: 100),
        ),
        itemSize: (i) => 1,
        onBatch: (batch) async {
          completer.complete(batch);
        },
      );

      batcher
        ..add(1)
        ..add(2);

      final result = await completer.future;
      expect(result, [1, 2]);
    });
  });
}
