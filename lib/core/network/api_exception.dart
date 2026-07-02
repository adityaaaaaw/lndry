import 'api_response.dart';

/// Thrown by [ApiClient] when a backend request fails.
/// Contains the parsed [ApiError] envelope (or a fallback for network errors).
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.failures = const [],
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code (e.g. 400, 401, 500). Null for network/timeout errors.
  final int? statusCode;

  /// Backend error code (e.g. 'INVALID_OTP', 'ORDER_FAILED').
  final String? code;

  /// Per-item validation failures (e.g. multi-vendor order issues).
  final List<Map<String, dynamic>> failures;

  /// Whether this is a transient network error (retryable).
  bool get isNetworkError => statusCode == null;

  /// Whether the client should attempt a token refresh.
  bool get isUnauthorized => statusCode == 401;

  /// Whether the upstream service is unavailable.
  bool get isServerError => statusCode != null && statusCode! >= 500;

  factory ApiException.fromApiError(ApiError err, {int? statusCode}) =>
      ApiException(
        message: err.message,
        code: err.code,
        failures: err.failures,
        statusCode: statusCode,
      );

  factory ApiException.networkError(String message) =>
      ApiException(message: message, code: 'NETWORK_ERROR');

  factory ApiException.timeout() =>
      ApiException(message: 'Request timed out', code: 'TIMEOUT');

  factory ApiException.unknown([String? message]) =>
      ApiException(message: message ?? 'An unexpected error occurred');

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
