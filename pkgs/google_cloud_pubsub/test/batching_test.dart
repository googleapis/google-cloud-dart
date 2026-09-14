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

@TestOn('vm')
library;

import 'dart:async';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/batching.dart';
import 'package:test/test.dart';

void main() {
  group('Batcher', () {
    test('flushes when maxMessages is reached', () async {
      final completer = Completer<List<int>>();
      Batcher<int>(
          settings: BatchingSettings(
            maxMessages: 3,
            maxDelay: const Duration(seconds: 1),
          ),
          itemSize: (item) => 1,
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
          settings: BatchingSettings(
            maxBytes: 10,
            maxDelay: const Duration(seconds: 1),
          ),
          itemSize: (item) => item,
          onBatch: (batch) async {
            completer.complete(batch);
          },
        )
        ..add(4)
        ..add(6); // 4 + 6 = 10, which reaches maxBytes

      final result = await completer.future;
      expect(result, [4, 6]);
    });

    test(
      'flushes existing items before adding item that would exceed maxBytes',
      () async {
        final batches = <List<int>>[];
        final batcher =
            Batcher<int>(
                settings: BatchingSettings(
                  maxBytes: 10,
                  maxDelay: const Duration(seconds: 1),
                ),
                itemSize: (item) => item,
                onBatch: (batch) async {
                  batches.add(batch);
                },
              )
              ..add(6)
              ..add(
                6,
              ); // 6 + 6 = 12 > 10, so first 6 is flushed, second 6 is buffered
        await Future<void>.delayed(Duration.zero);
        expect(
          batches,
          equals([
            [6],
          ]),
        );
        await batcher.close();
        expect(
          batches,
          equals([
            [6],
            [6],
          ]),
        );
      },
    );

    test('flushes after maxDelay', () async {
      final completer = Completer<List<int>>();
      Batcher<int>(
          settings: BatchingSettings(
            maxMessages: 10,
            maxDelay: const Duration(milliseconds: 100),
          ),
          itemSize: (item) => 1,
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
        settings: BatchingSettings(
          maxMessages: 10,
          maxDelay: const Duration(seconds: 10),
        ),
        itemSize: (item) => 1,
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
        settings: BatchingSettings(maxMessages: 10),
        itemSize: (item) => 1,
        onBatch: (_) async {},
      );

      await batcher.close();
      expect(() => batcher.add(1), throwsStateError);
    });

    test('synchronous throws from onBatch are safely caught', () async {
      var threw = false;
      final batcher = Batcher<int>(
        settings: BatchingSettings(
          maxMessages: 1,
          maxDelay: const Duration(milliseconds: 10),
        ),
        itemSize: (item) => 1,
        onBatch: (batch) {
          threw = true;
          throw Exception('sync throw in onBatch');
        },
      );

      // add(1) triggers immediate flush because maxMessages: 1.
      // Should not throw synchronously from add.
      expect(() => batcher.add(1), returnsNormally);
      expect(threw, isTrue);

      // close() should rethrow the unhandled exception
      await expectLater(batcher.close(), throwsA(isA<Exception>()));
    });

    test(
      'asynchronous errors in onBatch do not hang close() and are rethrown',
      () async {
        final batcher = Batcher<int>(
          settings: BatchingSettings(maxMessages: 1),
          itemSize: (item) => 1,
          onBatch: (batch) => Future.error(Exception('async error in onBatch')),
        );

        expect(() => batcher.add(1), returnsNormally);
        await expectLater(batcher.close(), throwsA(isA<Exception>()));
      },
    );

    test('synchronous Error in onBatch is rethrown by close()', () async {
      final batcher = Batcher<int>(
        settings: BatchingSettings(maxMessages: 1),
        itemSize: (item) => 1,
        onBatch: (batch) => throw StateError('sync bug in onBatch'),
      );

      expect(() => batcher.add(1), returnsNormally);
      await expectLater(batcher.close(), throwsStateError);
    });

    test('asynchronous Error in onBatch is rethrown by close()', () async {
      final batcher = Batcher<int>(
        settings: BatchingSettings(maxMessages: 1),
        itemSize: (item) => 1,
        onBatch: (batch) => Future.error(StateError('async bug in onBatch')),
      );

      expect(() => batcher.add(1), returnsNormally);
      await expectLater(batcher.close(), throwsStateError);
    });

    test(
      'non-Exception object thrown in onBatch is rethrown by close()',
      () async {
        final batcher = Batcher<int>(
          settings: BatchingSettings(maxMessages: 1),
          itemSize: (item) => 1,
          // ignore: only_throw_errors
          onBatch: (batch) => throw 'raw string throw',
        );

        expect(() => batcher.add(1), returnsNormally);
        await expectLater(batcher.close(), throwsA(equals('raw string throw')));
      },
    );

    test(
      'single item exceeding maxBytes on empty buffer flushes immediately',
      () async {
        final completer = Completer<List<int>>();
        final batcher = Batcher<int>(
          settings: BatchingSettings(
            maxBytes: 10,
            maxDelay: const Duration(seconds: 10),
          ),
          itemSize: (item) => item,
          onBatch: (batch) async => completer.complete(batch),
        )..add(15);
        expect(await completer.future, equals([15]));
        await batcher.close();
      },
    );
  });

  group('BatchingSettings', () {
    test('defaults are initialized correctly', () {
      final settings = BatchingSettings();
      expect(settings.maxMessages, equals(100));
      expect(settings.maxBytes, equals(1024 * 1024));
      expect(settings.maxDelay, equals(const Duration(milliseconds: 10)));
    });

    test('equality and hashCode', () {
      final a = BatchingSettings();
      final b = BatchingSettings();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = BatchingSettings(maxMessages: 50);
      expect(a, isNot(equals(c)));
      expect(a.toString(), contains('BatchingSettings'));
    });

    test('parameter validation error messages are harmonized', () {
      expect(
        () => BatchingSettings(maxMessages: 0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxMessages: -1),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxBytes: 0),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxBytes: -10),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxDelay: Duration.zero),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxDelay: const Duration(milliseconds: -1)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
      expect(
        () => BatchingSettings(maxDelay: const Duration(seconds: -10)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Must be greater than zero',
          ),
        ),
      );
    });
  });

  group('Batcher.baseSize', () {
    test('counts towards maxBytes', () async {
      final batches = <List<int>>[];
      // Base 6 plus two items of 2 reaches maxBytes; a third would exceed it.
      Batcher<int>(
          settings: BatchingSettings(
            maxMessages: 100,
            maxBytes: 10,
            maxDelay: const Duration(seconds: 10),
          ),
          baseSize: 6,
          itemSize: (item) => 2,
          onBatch: (batch) async => batches.add(batch),
        )
        ..add(1)
        ..add(2);
      await Future<void>.delayed(Duration.zero);
      expect(batches, [
        [1, 2],
      ]);
    });

    test('is reapplied to each subsequent batch', () async {
      final batches = <List<int>>[];
      Batcher<int>(
          settings: BatchingSettings(
            maxMessages: 100,
            maxBytes: 10,
            maxDelay: const Duration(seconds: 10),
          ),
          baseSize: 6,
          itemSize: (item) => 2,
          onBatch: (batch) async => batches.add(batch),
        )
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4);
      await Future<void>.delayed(Duration.zero);
      expect(batches, [
        [1, 2],
        [3, 4],
      ]);
    });

    test('defaults to zero, preserving the plain item-sum behaviour', () async {
      final batches = <List<int>>[];
      final batcher = Batcher<int>(
        settings: BatchingSettings(
          maxMessages: 100,
          maxBytes: 10,
          maxDelay: const Duration(seconds: 10),
        ),
        itemSize: (item) => 2,
        onBatch: (batch) async => batches.add(batch),
      );

      for (var i = 1; i <= 5; i++) {
        batcher.add(i);
      }
      await Future<void>.delayed(Duration.zero);
      expect(batches, [
        [1, 2, 3, 4, 5],
      ]);
    });
  });

  group('resolveServerLimits', () {
    test('rejects a maxBytes the caller set above the limit', () {
      expect(
        () => resolveServerLimits(
          BatchingSettings(maxBytes: 50000000),
          maxBytes: maxPublishRequestBytes,
          requestDescription: 'Publish request',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'batching.maxBytes')
              .having((e) => e.invalidValue, 'invalidValue', 50000000),
        ),
      );
    });

    test('rejects a maxMessages above the limit', () {
      expect(
        () => resolveServerLimits(
          BatchingSettings(maxMessages: 5000),
          maxBytes: maxPublishRequestBytes,
          maxMessages: maxPublishRequestMessages,
          requestDescription: 'Publish request',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'batching.maxMessages')
              .having((e) => e.invalidValue, 'invalidValue', 5000),
        ),
      );
    });

    test('leaves settings within the limits untouched', () {
      final settings = BatchingSettings(maxMessages: 10, maxBytes: 2048);
      final resolved = resolveServerLimits(
        settings,
        maxBytes: maxPublishRequestBytes,
        maxMessages: maxPublishRequestMessages,
        requestDescription: 'Publish request',
      );
      expect(identical(resolved, settings), isTrue);
    });

    test('narrows a maxBytes the caller never set', () {
      // The default suits publishing and is larger than an acknowledgment
      // request allows. Rejecting it would mean nobody could set only
      // maxMessages on a subscription.
      final settings = BatchingSettings(maxMessages: 10);
      final resolved = resolveServerLimits(
        settings,
        maxBytes: maxAcknowledgeRequestBytes,
        requestDescription: 'Acknowledge request',
      );
      expect(settings.maxBytes, greaterThan(maxAcknowledgeRequestBytes));
      expect(resolved.maxBytes, maxAcknowledgeRequestBytes);
      expect(resolved.maxMessages, 10);
    });

    test('rejects the same value when the caller set it explicitly', () {
      // Same number as the default, but chosen rather than inherited.
      expect(
        () => resolveServerLimits(
          BatchingSettings(maxBytes: 1024 * 1024),
          maxBytes: maxAcknowledgeRequestBytes,
          requestDescription: 'Acknowledge request',
        ),
        throwsArgumentError,
      );
    });

    test('preserves maxDelay when narrowing', () {
      const maxDelay = Duration(seconds: 7);
      final resolved = resolveServerLimits(
        BatchingSettings(maxDelay: maxDelay),
        maxBytes: maxAcknowledgeRequestBytes,
        requestDescription: 'Acknowledge request',
      );
      expect(resolved.maxDelay, maxDelay);
    });

    test('leaves maxMessages alone when no message limit applies', () {
      final resolved = resolveServerLimits(
        BatchingSettings(maxMessages: 5000),
        maxBytes: maxAcknowledgeRequestBytes,
        requestDescription: 'Acknowledge request',
      );
      expect(resolved.maxMessages, 5000);
      expect(resolved.maxBytes, maxAcknowledgeRequestBytes);
    });
  });

  group('server limits', () {
    test('match the documented Pub/Sub quotas', () {
      // https://cloud.google.com/pubsub/quotas. Pub/Sub documents these in
      // decimal units, so "10MB" is 10,000,000 bytes rather than 10 MiB.
      expect(maxPublishRequestBytes, 10 * 1000 * 1000);
      expect(maxPublishRequestMessages, 1000);
      expect(maxAcknowledgeRequestBytes, 512 * 1000);
    });

    test('publish defaults stay within them', () {
      final settings = PublishSettings().batching;
      expect(settings.maxBytes, lessThanOrEqualTo(maxPublishRequestBytes));
      expect(
        settings.maxMessages,
        lessThanOrEqualTo(maxPublishRequestMessages),
      );
    });

    test('acknowledgment defaults stay within them', () {
      // The publish-oriented default of 1 MiB is twice what the server allows
      // for an Acknowledge or ModifyAckDeadline request.
      final settings = AckSettings().batching;
      expect(settings.maxBytes, maxAcknowledgeRequestBytes);
      expect(settings.maxBytes, lessThanOrEqualTo(maxAcknowledgeRequestBytes));
    });
  });
}
