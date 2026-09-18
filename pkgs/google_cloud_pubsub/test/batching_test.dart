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
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_cloud_pubsub/google_cloud_pubsub.dart';
import 'package:google_cloud_pubsub/src/batching.dart';
import 'package:google_cloud_pubsub/src/generated/google/pubsub/v1/pubsub.pb.dart'
    as grpc;
import 'package:google_cloud_pubsub/src/wire_size.dart';
import 'package:test/test.dart';

void main() {
  group('Batcher', () {
    test('flushes when maxMessages or maxBytes is reached', () async {
      final batches = <List<int>>[];
      final batcher =
          Batcher<int>(
              settings: BatchingSettings(
                maxMessages: 3,
                maxBytes: 10,
                maxDelay: const Duration(seconds: 1),
              ),
              itemSize: (item) => item,
              onBatch: (batch) async => batches.add(batch),
            )
            ..add(2)
            ..add(3)
            ..add(4) // 3 items -> flushes [2, 3, 4]
            ..add(6)
            ..add(6); // 6 + 6 > 10 -> flushes [6], buffers [6]

      await Future<void>.delayed(Duration.zero);
      expect(batches, [
        [2, 3, 4],
        [6],
      ]);
      await batcher.close();
      expect(batches, [
        [2, 3, 4],
        [6],
        [6],
      ]);
    });

    test('accounts for baseSize in every batch', () async {
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

    test('flushes after maxDelay and awaits in-flight on close()', () async {
      final inFlight = Completer<void>();
      final batches = <List<int>>[];
      final batcher = Batcher<int>(
        settings: BatchingSettings(
          maxMessages: 10,
          maxDelay: const Duration(milliseconds: 20),
        ),
        itemSize: (_) => 1,
        onBatch: (batch) async {
          batches.add(batch);
          await inFlight.future;
        },
      )..add(1);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(batches, [
        [1],
      ]);

      var closed = false;
      final closeFuture = batcher.close().then((_) => closed = true);
      expect(() => batcher.add(2), throwsStateError);
      expect(closed, isFalse);

      inFlight.complete();
      await closeFuture;
      expect(closed, isTrue);
    });
  });

  group('BatchingSettings & resolveServerLimits', () {
    test('validates positive settings and server quotas', () {
      expect(() => BatchingSettings(maxMessages: 0), throwsArgumentError);
      expect(() => BatchingSettings(maxBytes: 0), throwsArgumentError);
      expect(
        () => BatchingSettings(maxDelay: Duration.zero),
        throwsArgumentError,
      );

      expect(
        () => resolveServerLimits(
          BatchingSettings(maxBytes: 50 * 1000 * 1000),
          maxBytes: maxPublishRequestBytes,
          requestDescription: 'Publish request',
        ),
        throwsArgumentError,
      );
      expect(
        () => resolveServerLimits(
          BatchingSettings(maxMessages: 5000),
          maxBytes: maxPublishRequestBytes,
          maxMessages: maxPublishRequestMessages,
          requestDescription: 'Publish request',
        ),
        throwsArgumentError,
      );

      // Unspecified maxBytes is narrowed to maxAcknowledgeRequestBytes,
      // whereas an explicitly set 1 MiB maxBytes throws.
      final narrowed = resolveServerLimits(
        BatchingSettings(maxMessages: 10),
        maxBytes: maxAcknowledgeRequestBytes,
        requestDescription: 'Acknowledge request',
      );
      expect(narrowed.maxBytes, maxAcknowledgeRequestBytes);
      expect(
        () => resolveServerLimits(
          BatchingSettings(maxBytes: 1024 * 1024),
          maxBytes: maxAcknowledgeRequestBytes,
          requestDescription: 'Acknowledge request',
        ),
        throwsArgumentError,
      );
    });
  });

  group('wire_size', () {
    test('publishRequestMessageSize matches serialized PublishRequest', () {
      const topic = 'projects/example-project/topics/example-topic';
      final random = Random(20260914);
      final messages = <grpc.PubsubMessage>[];
      var predicted = lengthDelimitedSize(1, utf8.encode(topic).length);

      for (var i = 0; i < 100; i++) {
        final data = Uint8List.fromList(
          List<int>.filled(random.nextInt(2000), 0),
        );
        final attributes = <String, String>{
          if (i.isEven) 'key-$i': 'välué-${'x' * (i * 2)}',
        };
        messages.add(
          grpc.PubsubMessage()
            ..data = data
            ..attributes.addAll(attributes),
        );
        predicted += publishRequestMessageSize(
          Message(data: data, attributes: attributes),
        );
      }

      final actual =
          (grpc.PublishRequest()
                ..topic = topic
                ..messages.addAll(messages))
              .writeToBuffer()
              .length;
      expect(predicted, actual);
    });
  });
}
