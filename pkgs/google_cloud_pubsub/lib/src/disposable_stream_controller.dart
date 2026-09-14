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

import 'package:meta/meta.dart';

/// A single-subscription stream controller that can be disposed of whether or
/// not its [stream] was ever listened to.
///
/// Disposing of a plain [StreamController] is surprisingly delicate. The future
/// returned by [StreamController.close] only completes once the done event has
/// been delivered, so it never completes while the stream has no listener, and
/// any event added before the first listener subscribes is retained until it is
/// delivered. Both keep the controller and its buffered events alive.
///
/// The remedy is to drain the stream, but a single-subscription stream can only
/// be listened to once, so draining a stream that already had a listener throws
/// a [StateError]. [StreamController.hasListener] cannot distinguish the two
/// cases: it is `false` both before the first listener subscribes and after
/// that listener has canceled.
///
/// This class remembers whether a listener ever subscribed, so [dispose] can
/// drain only when doing so is safe.
@internal
final class DisposableStreamController<T> {
  late final StreamController<T> _controller;

  /// Whether [stream] has ever been listened to.
  bool _wasListenedTo = false;

  /// Whether [dispose] is currently discarding undelivered events.
  bool _isDiscarding = false;

  /// Creates a controller that invokes [onListen] when its [stream] gains a
  /// listener and [onCancel] when that listener cancels.
  ///
  /// Neither callback is invoked for the listener that [dispose] uses to
  /// discard undelivered events.
  DisposableStreamController({
    void Function()? onListen,
    void Function()? onCancel,
  }) {
    _controller = StreamController<T>(
      onListen: () {
        _wasListenedTo = true;
        if (!_isDiscarding) onListen?.call();
      },
      onCancel: () {
        if (!_isDiscarding) onCancel?.call();
      },
    );
  }

  /// The stream of events added to this controller.
  Stream<T> get stream => _controller.stream;

  /// Whether [dispose] has been called.
  bool get isClosed => _controller.isClosed;

  /// Whether [stream] currently has an active listener.
  ///
  /// This is `false` both before the first listener subscribes and after that
  /// listener has canceled. Events added while it is `false` are never
  /// delivered.
  bool get hasListener => _controller.hasListener;

  /// Adds [event] to the [stream].
  void add(T event) => _controller.add(event);

  /// Closes the controller and discards any event that was never delivered.
  ///
  /// The returned future completes once the controller is closed. It never
  /// completes with an error, and it is safe to ignore.
  ///
  /// Does nothing if the controller is already disposed of.
  Future<void> dispose() {
    if (_controller.isClosed) return Future<void>.value();
    if (!_wasListenedTo) {
      _isDiscarding = true;
      unawaited(_controller.stream.drain<void>().catchError((_) {}));
    }
    return _controller.close().catchError((_) {});
  }
}
