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

import 'package:google_cloud_pubsub/src/disposable_stream_controller.dart';
import 'package:test/test.dart';

void main() {
  group('DisposableStreamController', () {
    test('dispose completes when the stream was never listened to', () async {
      final controller = DisposableStreamController<int>()..add(1);

      // Without discarding the undelivered event this never completes.
      await controller.dispose().timeout(const Duration(seconds: 5));

      expect(controller.isClosed, isTrue);
    });

    test('dispose completes after the listener has canceled', () async {
      final controller = DisposableStreamController<int>()..add(1);
      final subscription = controller.stream.listen((_) {});
      await subscription.cancel();

      // A stream that has already been listened to must not be listened to
      // again, so discarding here would throw `Bad state: Stream has already
      // been listened to`.
      await controller.dispose().timeout(const Duration(seconds: 5));

      expect(controller.isClosed, isTrue);
    });

    test('dispose completes while a listener is still attached', () async {
      final received = <int>[];
      final controller = DisposableStreamController<int>()..add(1);
      final subscription = controller.stream.listen(received.add);
      addTearDown(subscription.cancel);

      await controller.dispose().timeout(const Duration(seconds: 5));

      expect(received, [1]);
      expect(controller.isClosed, isTrue);
    });

    test('dispose is idempotent', () async {
      final controller = DisposableStreamController<int>()..add(1);

      await controller.dispose().timeout(const Duration(seconds: 5));
      await controller.dispose().timeout(const Duration(seconds: 5));

      expect(controller.isClosed, isTrue);
    });

    test('onListen and onCancel report real listeners', () async {
      var listenCount = 0;
      var cancelCount = 0;
      final controller = DisposableStreamController<int>(
        onListen: () => listenCount++,
        onCancel: () => cancelCount++,
      );

      expect(controller.hasListener, isFalse);
      final subscription = controller.stream.listen((_) {});
      expect(listenCount, 1);
      expect(controller.hasListener, isTrue);

      await subscription.cancel();
      expect(cancelCount, 1);
      expect(controller.hasListener, isFalse);

      await controller.dispose().timeout(const Duration(seconds: 5));
    });

    test('onListen and onCancel are not called while discarding', () async {
      var listenCount = 0;
      var cancelCount = 0;
      final controller = DisposableStreamController<int>(
        onListen: () => listenCount++,
        onCancel: () => cancelCount++,
      )..add(1);

      await controller.dispose().timeout(const Duration(seconds: 5));

      expect(listenCount, 0);
      expect(cancelCount, 0);
    });
  });
}
