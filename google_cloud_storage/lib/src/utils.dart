
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

bool _isRetryable(int statusCode) {
  return const [408, 429, 500, 502, 503, 504].contains(statusCode);
}

Future<T> retry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double multiplier = 2.0,
  Duration maxDelay = const Duration(seconds: 30),
}) async {
  int attempts = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      attempts++;
      return await action();
    } catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }

      if (e is http.ClientException) {
         // Always retry ClientException (network issues)
      } else if (e is http.Response) { 
          // Check for retryable status codes if the exception object has one (unlikely for standard ClientException, but good for custom ones)
          // Actually, standard http calls don't throw on status codes, so this check will be inside the action or we wrap the action.
          // For this utility, we assume 'action' might throw specific exceptions we want to retry on,
          // OR we just retry on ANY exception that seems transient.
      } else {
         // For other exceptions, maybe don't retry?
         // For simplicity, let's retry on ClientException and specific logic if we can.
         // However, standard http.Client.get doesn't throw on 500. It returns a Response.
         // So the 'action' must return the Response, and we check it.
         rethrow;
      }
      
      await Future.delayed(delay);
      delay *= multiplier;
      if (delay > maxDelay) {
        delay = maxDelay;
      }
    }
  }
}

/// Helper to wrap an HTTP request with retry logic.
Future<http.Response> retryRequest(
  Future<http.Response> Function() requestFn, {
  int maxAttempts = 3,
}) async {
  int attempts = 0;
  Duration delay = const Duration(seconds: 1);
  final random = Random();

  while (true) {
    attempts++;
    try {
      final response = await requestFn();
      if (attempts >= maxAttempts || !_isRetryable(response.statusCode)) {
        return response;
      }
    } catch (e) {
      if (attempts >= maxAttempts || e is! http.ClientException) {
        rethrow;
      }
    }

    // Exponential backoff with jitter
    final jitter = random.nextDouble() * 0.1; // 10% jitter
    final sleep = delay * (1 + jitter);
    await Future.delayed(sleep);
    delay *= 2;
  }
}
