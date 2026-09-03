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

import 'package:google_cloud_pubsub/src/batching.dart';
import 'package:test/test.dart';

void main() {
  group('Batcher', () {
    test('flushes when maxMessages is reached', () async {
      final completer = Completer<List<int>>();
      Batcher<int>(
          settings: const BatchingSettings(
            maxMessages: 3,
            maxDelay: Duration(seconds: 1),
          ),
          itemSize: (i) => 1,
          onBatch: (batch) async {
            completer.complete(batch);
          },
        )
        ..add(1)
        ..add(2)
        ..add(3);

      final result = await completer.future;
      expect(result, [1, 2, 3]);
    });

    test('flushes when maxBytes is reached', () async {
      final completer = Completer<List<int>>();
      Batcher<int>(
          settings: const BatchingSettings(
            maxBytes: 10,
            maxDelay: Duration(seconds: 1),
          ),
          itemSize: (i) => i,
          onBatch: (batch) async {
            completer.complete(batch);
          },
        )
        ..add(4)
        ..add(6); // 4 + 6 = 10, which reaches maxBytes

      final result = await completer.future;
      expect(result, [4, 6]);
    });

    test('flushes after maxDelay', () async {
      final completer = Completer<List<int>>();
      Batcher<int>(
          settings: const BatchingSettings(
            maxMessages: 10,
            maxDelay: Duration(milliseconds: 100),
          ),
          itemSize: (i) => 1,
          onBatch: (batch) async {
            completer.complete(batch);
          },
        )
        ..add(1)
        ..add(2);

      final result = await completer.future;
      expect(result, [1, 2]);
    });

    test('close flushes pending items and awaits in-flight batches', () async {
      final inFlightCompleter = Completer<void>();
      var batchStarted = false;
      var batchCompleted = false;

      final batcher = Batcher<int>(
        settings: const BatchingSettings(
          maxMessages: 10,
          maxDelay: Duration(seconds: 10),
        ),
        itemSize: (i) => 1,
        onBatch: (batch) async {
          batchStarted = true;
          await inFlightCompleter.future;
          batchCompleted = true;
        },
      )..add(42);

      var closeFinished = false;
      final closeFuture = batcher.close().then((_) {
        closeFinished = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(batchStarted, isTrue);
      expect(closeFinished, isFalse);

      inFlightCompleter.complete();
      await closeFuture;

      expect(batchCompleted, isTrue);
      expect(closeFinished, isTrue);
    });

    test('calling add after close throws StateError', () async {
      final batcher = Batcher<int>(
        settings: const BatchingSettings(maxMessages: 10),
        itemSize: (i) => 1,
        onBatch: (_) async {},
      );

      await batcher.close();
      expect(() => batcher.add(1), throwsStateError);
    });
  });
}
