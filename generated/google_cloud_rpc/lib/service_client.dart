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
import 'dart:typed_data' show BytesBuilder;

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
    show clientDartVersion, httpClientFromApiKey;

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
/// how, failed attempts are retried. `retry` defaults to [noRetry]: a
/// [ServiceClient] doesn't know whether an operation is safe to repeat, so the
/// caller must decide.
///
/// Every request method also takes a `timeout` argument. If `timeout` is set,
/// an attempt that doesn't complete within `timeout` fails with a
/// [TimeoutException]. The timeout applies to each attempt separately, and
/// `retry` decides whether an attempt that timed out is retried. For example,
/// [ExponentialRetry.onCodes] treats a [TimeoutException] as
/// [Code.deadlineExceeded]. If the final attempt fails with a
/// [TimeoutException], then there is no guarantee that the server did not
/// complete the request successfully.
///
/// For a streaming request, `timeout` limits the whole stream, including time
/// that the stream subscription is paused. Streaming request methods also take
/// a `streamWaitTimeout` argument, which limits the wait for the response to
/// start, and then the maximum delay between events. Time that the stream
/// subscription is paused doesn't count towards `streamWaitTimeout`.
///
/// If the server responds to a streaming request with server-sent events,
/// events reach the caller as they arrive. If a timeout happens after a
/// response has started, the response stream ends with a [TimeoutException] and
/// is not retried.
class ServiceClient {
  // As of 2026-10-16 there is no consistent timeout behavior for RPCs across
  // Google Cloud client libraries:
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

  /// Sends a single request, completing when the response starts.
  ///
  /// The response may have any status code: [_Call] handles it.
  Future<http.StreamedResponse> _send(
    Uri url,
    String method,
    String? encodedBody,
  ) {
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

    return client.send(request);
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
    return _Call(
      url,
      () => _send(url, method, encodedBody),
      retry,
      timeout: timeout,
      isStreaming: false,
    ).messages.single;
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
    final requestUrl = enableSse ? _makeUrlStreaming(url) : url;
    // Encoded when the stream is listened to, like everything else.
    late final encodedBody = body?._asEncodedJson;
    return _Call(
      requestUrl,
      () => _send(requestUrl, method, encodedBody),
      retry,
      timeout: timeout,
      stallTimeout: streamWaitTimeout,
      isStreaming: true,
    ).messages;
  }

  /// The MIME type of [response], or `null` if its `content-type` header is
  /// missing or malformed.
  static String? _mimeType(http.BaseResponse response) {
    final contentType = response.headers['content-type'];
    if (contentType == null) return null;
    try {
      return http.MediaType.parse(contentType).mimeType;
    } on FormatException {
      return null;
    }
  }

  static void _checkTimeout(Duration? timeout, String name) {
    if (timeout != null && timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, name, 'must be positive');
    }
  }

  static Stream<Map<String, dynamic>> _decodeEvents(
    http.StreamedResponse response,
  ) {
    // Google APIs only generate "data" events.
    // The SSE specification does not require a space after the colon but
    // Google APIs always generate one.
    const dataPrefix = 'data: ';
    return response.stream
        .toStringStream()
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

/// A request, from its first attempt to the end of its response.
///
/// A call makes attempts until one succeeds, or fails in a way that `retry`
/// doesn't retry. An attempt first waits for its response to start. Then it
/// either reads the whole body of the response (an error, a single message or
/// a JSON list of messages), or it forwards the events of the response as
/// they arrive.
///
/// An attempt fails with a [TimeoutException] if it isn't over within
/// `timeout`, or if the server shows no sign of life for `stallTimeout` while
/// the listener isn't paused.
///
/// Everything that can happen to a call is handled by a method that runs
/// without waiting for anything, so the state of the call can't change under
/// it. [_attempt] tells what an abandoned attempt was waiting for that the
/// attempt is over.
final class _Call {
  final Uri _url;
  final Future<http.StreamedResponse> Function() _send;
  final RetryRunner _retry;
  final Duration? _timeout;
  final Duration? _stallTimeout;

  /// Whether the response is a stream of messages, rather than one message.
  final bool _isStreaming;

  final _controller = StreamController<Map<String, dynamic>>();

  /// How long to wait before each attempt after the first.
  late final Iterator<Duration> _delays;

  /// Identifies the attempt that is in progress, if any.
  Object? _attempt;

  /// Whether the attempt that is in progress is retried if it fails.
  var _canRetry = true;

  /// Whether the response of the attempt that is in progress has started.
  var _hasResponse = false;

  /// Reads the response of the attempt that is in progress.
  StreamSubscription<Object?>? _subscription;

  Timer? _deadlineTimer;
  Timer? _stallTimer;
  Timer? _retryTimer;

  _Call(
    this._url,
    this._send,
    this._retry, {
    required Duration? timeout,
    Duration? stallTimeout,
    required bool isStreaming,
  }) : _timeout = timeout,
       _stallTimeout = stallTimeout,
       _isStreaming = isStreaming {
    _controller.onListen = () {
      _controller
        ..onPause = _pause
        ..onResume = _resume
        ..onCancel = _cancel;
      _delays = _retry.delays().iterator;
      _startAttempt();
    };
  }

  /// The messages of the response: exactly one, unless the call is streaming.
  ///
  /// The first attempt starts when this is listened to.
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void _startAttempt() {
    final attempt = _attempt = Object();
    _canRetry = true;
    _hasResponse = false;
    if (_timeout case final timeout?) {
      _deadlineTimer = Timer(
        timeout,
        () => _timeOut(
          _hasResponse
              ? 'Request to $_url did not complete'
              : 'Request to $_url did not return any data',
          timeout,
        ),
      );
    }
    _restartStallTimer();
    // TODO: Use `http.Abortable` when it is widely available. In practice,
    // `client` will almost always be a `package:googleapis_auth` wrapper, which
    // does not forward `Abortable.abortTrigger` to the underlying client.
    unawaited(
      Future.sync(_send).then(
        (response) {
          if (identical(attempt, _attempt)) {
            _run(() => _onResponse(response));
          } else {
            // The request of an abandoned attempt isn't aborted, so its
            // response may start anyway. Nothing will read it.
            _cancelResponse(response).ignoreExceptions();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(attempt, _attempt)) {
            _fail(error, stackTrace);
          } else if (error is! Exception) {
            // Nobody waits for an abandoned attempt, so there is nobody to
            // report an `Exception` to. An `Error` is a bug, so it is still
            // reported, as an uncaught error.
            Error.throwWithStackTrace(error, stackTrace);
          }
        },
      ),
    );
  }

  void _onResponse(http.StreamedResponse response) {
    _hasResponse = true;
    _restartStallTimer();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _readBody(response, (bytes) {
        String? responseBody;
        try {
          responseBody = utf8.decode(bytes);
        } on FormatException {
          // The response body is not valid UTF-8.
        }
        throw ServiceException.fromHttpResponse(response, responseBody);
      });
    } else if (!_isStreaming) {
      _readBody(response, (bytes) {
        final responseBody = utf8.decode(bytes);
        _controller.add(
          responseBody.isEmpty
              ? {}
              : jsonDecode(responseBody) as Map<String, dynamic>,
        );
        _succeed();
      });
    } else {
      switch (ServiceClient._mimeType(response)) {
        case 'application/json':
          // The server responded with a non-streaming response, which should
          // be a list of JSON objects. The whole body is read as part of the
          // attempt, so a failure while reading it can be retried.
          _readBody(response, (bytes) {
            (jsonDecode(utf8.decode(bytes)) as List)
                .cast<Map<String, dynamic>>()
                .forEach(_controller.add);
            _succeed();
          });
        case 'text/event-stream':
          // The server responded with an event stream, which is what we
          // expect. Events reach the caller as they arrive, so failures after
          // this point are not retried.
          _canRetry = false;
          _listen(
            ServiceClient._decodeEvents(response),
            _controller.add,
            _succeed,
          );
        default:
          _cancelResponse(response).ignoreExceptions();
          throw ServiceException(
            'Unsupported content type: ${response.headers['content-type']}',
            statusCode: response.statusCode,
          );
      }
    }
  }

  /// Reads the whole body of [response], and then calls [onDone] with it.
  void _readBody(
    http.StreamedResponse response,
    void Function(List<int> bytes) onDone,
  ) {
    final body = BytesBuilder(copy: false);
    _listen(
      // An empty chunk doesn't show that the server is still sending the body.
      response.stream.where((chunk) => chunk.isNotEmpty),
      body.add,
      () => onDone(body.takeBytes()),
    );
  }

  /// Listens to [stream], which is read from the response of the attempt that
  /// is in progress.
  ///
  /// The attempt fails if [stream] has an error, or if [onDone] throws.
  void _listen<T>(
    Stream<T> stream,
    void Function(T event) onData,
    void Function() onDone,
  ) {
    final attempt = _attempt;
    bool isOver() => !identical(attempt, _attempt);
    final subscription = stream.listen(
      (event) {
        if (isOver()) return;
        onData(event);
        _restartStallTimer();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isOver()) _fail(error, stackTrace);
      },
      onDone: () {
        if (isOver()) return;
        _subscription = null;
        _run(onDone);
      },
    );
    if (isOver()) {
      // `stream` ended, and with it the attempt, as soon as it was listened
      // to.
      subscription.cancel().ignoreExceptions();
    } else {
      _subscription = subscription;
      if (_controller.isPaused) subscription.pause();
    }
  }

  void _pause() {
    _stallTimer?.cancel();
    // The response is paused a microtask later, so that it can first deliver
    // what it has already scheduled. If the response is done after the event
    // that the listener is handling, then the attempt ends now, rather than
    // being able to time out while the listener is paused.
    scheduleMicrotask(() {
      final subscription = _subscription;
      if (subscription != null &&
          !subscription.isPaused &&
          _controller.isPaused) {
        subscription.pause();
      }
    });
  }

  void _resume() {
    _subscription?.resume();
    _restartStallTimer();
  }

  Future<void>? _cancel() {
    _retryTimer?.cancel();
    // Unlike `_endAttempt`, this tells the listener whether the response was
    // cancelled successfully.
    final subscription = _subscription;
    _subscription = null;
    _endAttempt();
    return subscription?.cancel();
  }

  /// Ends the call, after the attempt that is in progress succeeded.
  void _succeed() {
    _endAttempt();
    unawaited(_controller.close());
  }

  /// Ends the attempt that is in progress, which failed with [error].
  ///
  /// Makes another attempt if `retry` says so. Otherwise, the call fails.
  void _fail(Object error, StackTrace stackTrace) {
    _endAttempt();
    if (_canRetry &&
        error is Exception &&
        _retry.isRetryable(error) &&
        _delays.moveNext()) {
      _retryTimer = Timer(_delays.current, _startAttempt);
    } else {
      _controller.addError(error, stackTrace);
      unawaited(_controller.close());
    }
  }

  void _timeOut(String message, Duration duration) =>
      _fail(TimeoutException(message, duration), StackTrace.current);

  /// Abandons the attempt that is in progress, if any: stops its timers, and
  /// stops reading its response.
  void _endAttempt() {
    _attempt = null;
    _deadlineTimer?.cancel();
    _stallTimer?.cancel();
    _subscription?.cancel().ignoreExceptions();
    _subscription = null;
  }

  /// Runs [action] as part of the attempt that is in progress, which fails if
  /// [action] throws.
  void _run(void Function() action) {
    try {
      action();
    } catch (e, s) {
      _fail(e, s);
    }
  }

  /// Restarts the clock of `stallTimeout`, because the server showed a sign of
  /// life, or because the listener resumed.
  void _restartStallTimer() {
    final stallTimeout = _stallTimeout;
    if (stallTimeout == null || _attempt == null || _controller.isPaused) {
      return;
    }
    _stallTimer?.cancel();
    _stallTimer = Timer(
      stallTimeout,
      () => _timeOut(
        _hasResponse
            ? 'No data received from $_url'
            : 'Request to $_url did not return any data',
        stallTimeout,
      ),
    );
  }
}

/// Cancels [response], which releases its connection.
Future<void> _cancelResponse(http.StreamedResponse response) =>
    response.stream.listen(null).cancel();

extension on JsonEncodable {
  String get _asEncodedJson => jsonEncode(toJson());
}

extension on Future<void> {
  void ignoreExceptions() {
    unawaited(catchError((_) {}, test: (e) => e is Exception));
  }
}
