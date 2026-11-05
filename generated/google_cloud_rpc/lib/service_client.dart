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

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:google_cloud_protobuf/protobuf.dart' show JsonEncodable;
import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'retry.dart';
import 'src/version.dart';
import 'src/web.dart'
    if (dart.library.io) 'src/vm.dart'
    show clientDartVersion, userAgentForClient;

export 'dart:typed_data' show Uint8List;

export 'src/web.dart'
    if (dart.library.io) 'src/vm.dart'
    show httpClientFromApiKey;

const String _clientKey = 'x-goog-api-client';
const String _userAgentKey = 'user-agent';

// ignore: prefer_const_declarations
String get _baseClientName =>
    'gl-dart/$clientDartVersion gax/$packageVersion rest/$packageVersion';

const String _contentTypeKey = 'content-type';
const String _typeJson = 'application/json';

/// A low-level mechanism to communicate with Google APIs.
///
/// Every request method takes a `retry` argument that decides whether, and
/// how, failed attempts are retried. It defaults to [noRetry]: a
/// [ServiceClient] doesn't know whether an operation is safe to repeat, so the
/// caller must decide.
///
/// Every request method also takes a `timeout` argument. If it is set, an
/// attempt that doesn't complete within `timeout` fails with a
/// [TimeoutException]. The timeout applies to each attempt separately, and
/// `retry` decides whether an attempt that timed out is retried. For example,
/// [ExponentialRetry.onCodes] treats a [TimeoutException] as
/// [Code.deadlineExceeded].
///
/// For a streaming request, `timeout` limits the whole stream, including time
/// that the caller spends with its subscription paused. Streaming request
/// methods also take a `streamWaitTimeout` argument, which limits the wait for
/// the response to start, and then each wait for more data. Time that the
/// caller spends with its subscription paused doesn't count towards
/// `streamWaitTimeout`.
///
/// If the server responds to a streaming request with server-sent events,
/// events reach the caller as they arrive, so a timeout after the response
/// starts ends the stream with a [TimeoutException], and isn't retried.
///
/// An attempt that times out may continue in the background, but its response
/// is discarded.
class ServiceClient {
  // As of 2026-10-16 there is no consistent timeout behavior for RPCs across
  // implementations.
  //
  // For unary (non-streaming) requests:
  // - Go, Python, and Node.js apply the timeout to the entire call, i.e., all
  //   retries must complete within the timeout period.
  // - Java and Rust apply the timeout to each request attempt independently and
  //   use retry settings to limit the total call time.
  //
  // For streaming requests:
  // - Go has a deadline that applies to the entire stream but with no default
  //   timeout because of a concern for long-lived streams
  //   (see https://github.com/googleapis/gapic-generator-go/issues/411).
  // - Java has three timeout options for streams: a deadline for the entire
  //   stream (`timeout`), a deadline for the gap between messages
  //   (`streamWaitTimeout`), and a deadline for the caller asking for more
  //   data (`streamIdleTimeout`).
  // - Python (gRPC) has a deadline that applies to the entire stream.
  // - Python (REST) has a deadline that applies to the gap between messages.
  // - Node.js and Rust have deadlines that apply to the whole stream.
  //
  // This client follows the Java strategy, except that it does not support
  // `streamIdleTimeout`.

  final http.Client client;

  /// The version of the GAPIC-generated client library (e.g. `0.1.0`),
  /// which will be formatted as `gapic/<version>` in the `x-goog-api-client`
  /// header.
  ///
  /// Set this for client libraries that were generated completely by
  /// automation.
  final String? gapicVersion;

  /// The version of the hand-written client library (e.g. `0.6.4`),
  /// which will be formatted as `gccl/<version>` in the `x-goog-api-client`
  /// header.
  ///
  /// Set this if the client library includes hand-written components.
  final String? gcclVersion;

  /// Creates a `ServiceClient` using [client] for transport.
  ///
  /// The provided [http.Client] must be configured to provide whatever
  /// authentication is required by the API being accessed. You can do that
  /// using
  /// [`package:googleapis_auth`](https://pub.dev/packages/googleapis_auth).
  ///
  /// If [gapicVersion] is set, `gapic/<version>` is included in the
  /// `x-goog-api-client` header.
  ///
  /// If [gcclVersion] is set, `gccl/<version>` is included in the
  /// `x-goog-api-client` header.
  ///
  /// Both [gapicVersion] and [gcclVersion] should be set if the library
  /// includes both automatically-generated and hand-written components.
  /// For example, `package:google_cloud_firestore` (hand-written) wraps
  /// `package:google_cloud_firestore_v1` (generated).
  ServiceClient({required this.client, this.gapicVersion, this.gcclVersion});

  /// The `x-goog-api-client` header value sent with every request.
  String get clientHeader {
    final buffer = StringBuffer(_baseClientName);
    final gapic = gapicVersion?.trim();
    final hasGapic = gapic != null && gapic.isNotEmpty;
    final gccl = gcclVersion?.trim();
    final hasGccl = gccl != null && gccl.isNotEmpty;

    if (hasGapic) {
      buffer.write(' gapic/$gapic');
    }

    if (hasGccl) {
      buffer.write(' gccl/$gccl');
    }

    return buffer.toString();
  }

  /// The `User-Agent` header value sent with every request, or `null` if none
  /// should be sent.
  ///
  /// On the Dart VM, returns `'gcloud-dart/<gcclVersion>'` when
  /// [gcclVersion] is non-empty; otherwise returns `null`.
  String? get userAgentHeader {
    final gccl = gcclVersion?.trim();
    if (gccl == null || gccl.isEmpty) return null;
    return userAgentForClient(gccl);
  }

  Future<Map<String, dynamic>> get(
    Uri url, {
    RetryRunner retry = noRetry,
    Duration? timeout,
  }) => _makeRequest(url, 'GET', retry: retry, timeout: timeout);

  Stream<Map<String, dynamic>> getStreaming(
    Uri url, {
    required bool enableSse,
    RetryRunner retry = noRetry,
    Duration? timeout,
    Duration? streamWaitTimeout,
  }) => _makeStreamingRequest(
    url,
    'GET',
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  );

  Future<Map<String, dynamic>> delete(
    Uri url, {
    RetryRunner retry = noRetry,
    Duration? timeout,
  }) => _makeRequest(url, 'DELETE', retry: retry, timeout: timeout);

  Stream<Map<String, dynamic>> deleteStreaming(
    Uri url, {
    required bool enableSse,
    RetryRunner retry = noRetry,
    Duration? timeout,
    Duration? streamWaitTimeout,
  }) => _makeStreamingRequest(
    url,
    'DELETE',
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  );

  Future<Map<String, dynamic>> patch(
    Uri url, {
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
  }) => _makeRequest(url, 'PATCH', body: body, retry: retry, timeout: timeout);

  Stream<Map<String, dynamic>> patchStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
    Duration? streamWaitTimeout,
  }) => _makeStreamingRequest(
    url,
    'PATCH',
    body: body,
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  );

  Future<Map<String, dynamic>> post(
    Uri url, {
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
  }) => _makeRequest(url, 'POST', body: body, retry: retry, timeout: timeout);

  Stream<Map<String, dynamic>> postStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
    Duration? streamWaitTimeout,
  }) => _makeStreamingRequest(
    url,
    'POST',
    body: body,
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  );

  Future<Map<String, dynamic>> put(
    Uri url, {
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
  }) => _makeRequest(url, 'PUT', body: body, retry: retry, timeout: timeout);

  Stream<Map<String, dynamic>> putStreaming(
    Uri url, {
    required bool enableSse,
    JsonEncodable? body,
    RetryRunner retry = noRetry,
    Duration? timeout,
    Duration? streamWaitTimeout,
  }) => _makeStreamingRequest(
    url,
    'PUT',
    body: body,
    enableSse: enableSse,
    retry: retry,
    timeout: timeout,
    streamWaitTimeout: streamWaitTimeout,
  );

  /// Closes the client and cleans up any resources associated with it.
  ///
  /// Once [close] is called, no other methods should be called.
  void close() => client.close();

  /// Sends a single request, throwing a [ServiceException] if the response
  /// does not have a 2xx status code.
  Future<http.StreamedResponse> _send(
    Uri url,
    String method,
    String? encodedBody,
  ) async {
    // `send` finalizes the request, so every attempt needs a new one.
    final request = http.Request(method, url);
    if (encodedBody != null) {
      request.body = encodedBody;
    }
    request.headers.addAll({
      _clientKey: clientHeader,
      _userAgentKey: ?userAgentHeader,
      if (encodedBody != null) _contentTypeKey: _typeJson,
    });

    final response = await client.send(request);
    final statusOK = response.statusCode >= 200 && response.statusCode < 300;
    if (!statusOK) {
      String? responseBody;
      try {
        responseBody = await response.stream.bytesToString();
      } on FormatException {
        // The response body is not valid UTF-8.
      }
      throw ServiceException.fromHttpResponse(response, responseBody);
    }
    return response;
  }

  Future<Map<String, dynamic>> _makeRequest(
    Uri url,
    String method, {
    JsonEncodable? body,
    required RetryRunner retry,
    required Duration? timeout,
  }) {
    _checkTimeout(timeout, 'timeout');
    final encodedBody = body?._asEncodedJson;
    return retry.run(() async {
      // `timeout` limits the whole attempt, including reading the response.
      final stopwatch = clock.stopwatch()..start();
      final response = await _sendWithTimeout(
        url,
        method,
        encodedBody,
        timeout,
      );
      final responseBody = await utf8.decodeStream(
        _withRemainingTimeout(response.stream, url, timeout, stopwatch),
      );
      return responseBody.isEmpty
          ? {}
          : jsonDecode(responseBody) as Map<String, dynamic>;
    });
  }

  /// Make a request that streams its results using
  /// [Server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html).
  ///
  /// NOTE: most Google APIs do not support Server-sent events.
  Stream<Map<String, dynamic>> _makeStreamingRequest(
    Uri url,
    String method, {
    JsonEncodable? body,
    required bool enableSse,
    required RetryRunner retry,
    required Duration? timeout,
    required Duration? streamWaitTimeout,
  }) {
    _checkTimeout(timeout, 'timeout');
    _checkTimeout(streamWaitTimeout, 'streamWaitTimeout');
    final cancelled = Completer<void>();
    late final StreamController<Map<String, dynamic>> controller;
    // Before the response starts, `timeout` and `streamWaitTimeout` limit the
    // same wait, so only the shorter one matters.
    final startTimeout = switch ((timeout, streamWaitTimeout)) {
      (null, null) => null,
      (Duration t, null) => t,
      (null, Duration t) => t,
      (Duration t1, Duration t2) => t1 < t2 ? t1 : t2,
    };
    final requestUrl = enableSse ? _makeUrlStreaming(url) : url;

    Future<Stream<Map<String, dynamic>>> attempt(String? encodedBody) async {
      if (cancelled.isCompleted) throw _CancelledError();
      // `timeout` limits the whole attempt, including any part of an event
      // stream that is read after the attempt completes.
      final stopwatch = clock.stopwatch()..start();
      final response = await _sendWithTimeout(
        requestUrl,
        method,
        encodedBody,
        startTimeout,
      );
      if (cancelled.isCompleted) {
        _cancel(response).ignore();
        throw _CancelledError();
      }
      final bytes = _withRemainingTimeout(
        _withStallTimeout(response.stream, requestUrl, streamWaitTimeout),
        requestUrl,
        timeout,
        stopwatch,
      );
      switch (http.MediaType.parse(
        response.headers['content-type'] ?? '',
      ).mimeType) {
        case 'application/json':
          // The server responded with a non-streaming response, which should
          // be a list of JSON objects. The whole body is read as part of the
          // attempt, so a failure while reading it can be retried.
          final responseBody = await utf8.decodeStream(
            _untilCancelled(bytes, cancelled.future),
          );
          final json = (jsonDecode(responseBody) as List)
              .cast<Map<String, dynamic>>();
          return Stream.fromIterable(json);
        case 'text/event-stream':
          // The server responded with an event stream, which is what we
          // expect. Events reach the caller as they arrive, so failures after
          // this point are not retried.
          return _decodeEvents(bytes);
        default:
          _cancel(response).ignore();
          throw ServiceException(
            'Unsupported content type: ${response.headers['content-type']}',
            statusCode: response.statusCode,
          );
      }
    }

    Future<void> startRequest() async {
      try {
        final encodedBody = body?._asEncodedJson;
        final messages = await retry.run(() async {
          try {
            return await attempt(encodedBody);
          } on Exception {
            // Don't retry a failure after the caller stopped listening:
            // `ExponentialRetry` would wait before noticing.
            if (cancelled.isCompleted) throw _CancelledError();
            rethrow;
          }
        });
        if (cancelled.isCompleted) {
          // The caller stopped listening as the last attempt completed.
          unawaited(messages.listen(null).cancel());
          return;
        }
        await controller.addStream(messages, cancelOnError: true);
      } catch (e, s) {
        // Once the caller stops listening, there is nobody to report to.
        if (!cancelled.isCompleted) controller.addError(e, s);
      } finally {
        unawaited(controller.close());
      }
    }

    controller = StreamController(
      onListen: () => unawaited(startRequest()),
      onCancel: () {
        if (!cancelled.isCompleted) cancelled.complete();
      },
    );
    return controller.stream;
  }

  /// Sends a request, failing with a [TimeoutException] if the response
  /// doesn't start within [timeout].
  ///
  /// A request that times out isn't aborted, so it may keep running in the
  /// background. If its response starts anyway, the response is cancelled,
  /// because nothing will read it.
  Future<http.StreamedResponse> _sendWithTimeout(
    Uri url,
    String method,
    String? encodedBody,
    Duration? timeout,
  ) {
    final pendingResponse = _send(url, method, encodedBody);
    if (timeout == null) return pendingResponse;
    // TODO: Use `http.Abortable` when it is widely available. In practice,
    // `client` will almost always be a `package:googleapis_auth` wrapper, which
    // does not forward `Abortable.abortTrigger` to the underlying client.
    return pendingResponse.timeout(
      timeout,
      onTimeout: () {
        pendingResponse.then(_cancel).ignore();
        throw TimeoutException(
          'Request to $url did not return any data',
          timeout,
        );
      },
    );
  }

  /// Cancels [response], which releases its connection.
  static Future<void> _cancel(http.StreamedResponse response) =>
      response.stream.listen(null).cancel();

  /// [bytes], failing with a [TimeoutException] if no data arrives for
  /// [timeout].
  ///
  /// Time spent with the subscription paused doesn't count. After a timeout,
  /// the subscription to [bytes] is cancelled.
  static Stream<List<int>> _withStallTimeout(
    Stream<List<int>> bytes,
    Uri url,
    Duration? timeout,
  ) {
    if (timeout == null) return bytes;
    return bytes.timeout(
      timeout,
      onTimeout: (sink) {
        sink
          ..addError(TimeoutException('No data received from $url', timeout))
          ..close();
      },
    );
  }

  /// [stream], failing with a [TimeoutException] if it isn't done by the time
  /// [stopwatch] reaches [timeout].
  ///
  /// Time spent with the subscription paused counts. After a timeout, the
  /// subscription to [stream] is cancelled, even if it is paused.
  static Stream<T> _withRemainingTimeout<T>(
    Stream<T> stream,
    Uri url,
    Duration? timeout,
    Stopwatch stopwatch,
  ) {
    if (timeout == null) return stream;

    late final StreamSubscription<T> subscription;
    late final Timer timer;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            timer.cancel();
            controller.close();
          },
        );
        // `Timer` treats a negative duration as zero. Even if no time remains,
        // data that's already buffered arrives before the timer fires. There is
        // no reason to go out of our way to throw away a response that has
        // already arrived.
        timer = Timer(timeout - stopwatch.elapsed, () {
          unawaited(subscription.cancel());
          controller
            ..addError(
              TimeoutException('Request to $url did not complete', timeout),
            )
            ..close();
        });
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () {
        timer.cancel();
        return subscription.cancel();
      },
    );
    return controller.stream;
  }

  /// [stream], ending with a [_CancelledError] if [cancelled] completes before
  /// [stream] is done.
  ///
  /// After [cancelled] completes, the subscription to [stream] is cancelled,
  /// even if it is paused.
  static Stream<T> _untilCancelled<T>(
    Stream<T> stream,
    Future<void> cancelled,
  ) {
    late final StreamSubscription<T> subscription;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        unawaited(
          cancelled.then((_) {
            if (controller.isClosed) return;
            unawaited(subscription.cancel());
            controller
              ..addError(_CancelledError())
              ..close();
          }),
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () => subscription.cancel(),
    );
    return controller.stream;
  }

  static void _checkTimeout(Duration? timeout, String name) {
    if (timeout != null && timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, name, 'must be positive');
    }
  }

  static Stream<Map<String, dynamic>> _decodeEvents(Stream<List<int>> bytes) {
    // Google APIs only generate "data" events.
    // The SSE specification does not require a space after the colon but
    // Google APIs always generate one.
    const dataPrefix = 'data: ';
    return utf8.decoder
        .bind(bytes)
        .transform(const LineSplitter())
        .where((line) => line.startsWith(dataPrefix))
        .map(
          (line) =>
              jsonDecode(line.substring(dataPrefix.length))
                  as Map<String, dynamic>,
        );
  }

  static Uri _makeUrlStreaming(Uri url) {
    final query = Map.of(url.queryParameters);
    query['alt'] = 'sse';
    return url.replace(queryParameters: query);
  }
}

/// Stops the attempts of a streaming request after the caller cancels its
/// subscription.
///
/// Because this is only raised after the caller cancels its subscription, it
/// is never surfaced outside of this library.
final class _CancelledError extends Error {}

extension on JsonEncodable {
  String get _asEncodedJson => jsonEncode(toJson());
}
