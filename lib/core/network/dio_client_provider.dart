// ignore_for_file: inference_failure_on_function_invocation

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../config/env.dart';
import '../services/storage_service.dart';
import '../constants/app_constants.dart';
import 'api_response.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';
import '../../repositories/mock/mock_customer_repository.dart';

// ── Dio Client Provider ─────────────────────────────────────────────────────────

final dioClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final dio = _createDio(storage, ref);
  return dio;
});

Dio _createDio(StorageService storage, Ref ref) {
  print('[DIO] Initialized with Base URL: ${Env.baseUrl}');
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(milliseconds: Env.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: Env.receiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: Env.receiveTimeoutMs),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // ── Auth interceptor: inject Bearer token ──────────────────────────────────
  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) async {
      final requestUrl = '${options.baseUrl}${options.path}';
      print('[DIO REQUEST] ${options.method} -> $requestUrl');
      // Don't add auth header for auth endpoints
      final path = options.path;
      if (_isPublicEndpoint(path)) {
        return handler.next(options);
      }

      try {
        final token = await storage.getSecure(AppConstants.keyAccessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Secure storage read failed; proceed without token
      }

      return handler.next(options);
    },
    onError: (error, handler) async {
      // Attempt token refresh on 401
      if (error.response?.statusCode == 401) {
        try {
          final refreshToken =
              await storage.getSecure(AppConstants.keyRefreshToken);
          if (refreshToken != null && refreshToken.isNotEmpty) {
            // Attempt refresh
            final refreshDio = Dio(
              BaseOptions(
                baseUrl: Env.baseUrl,
                connectTimeout:
                    const Duration(milliseconds: Env.connectTimeoutMs),
                receiveTimeout:
                    const Duration(milliseconds: Env.receiveTimeoutMs),
              ),
            );

            final resp = await refreshDio.post(
              ApiEndpoints.refreshToken,
              data: {'refreshToken': refreshToken},
            );

            final data = resp.data as Map<String, dynamic>?;
            final body = data?['data'] as Map<String, dynamic>?;

            if (body != null) {
              final newAccess = body['accessToken'] as String?;
              final newRefresh = body['refreshToken'] as String?;

              if (newAccess != null) {
                await storage.saveSecure(
                    AppConstants.keyAccessToken, newAccess);
                if (newRefresh != null) {
                  await storage.saveSecure(
                      AppConstants.keyRefreshToken, newRefresh);
                }

                // Retry the original request with new token
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccess';
                final retryResponse = await dio.fetch(error.requestOptions);
                return handler.resolve(retryResponse);
              }
            }
          }
        } catch (_) {
          // Refresh failed; clear session and let error propagate
          await storage.clearSession();
        }
      }

      return handler.next(error);
    },
  ));

  // ── Error interceptor: parse structured API errors ─────────────────────────
  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) {
      if (Env.demoMode &&
          (error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           error.message?.contains('SocketException') == true ||
           error.message?.contains('Connection refused') == true ||
           error.message?.contains('Network is unreachable') == true ||
           error.message?.contains('Failed host lookup') == true)) {
        ref.read(useMocksProvider.notifier).state = true;
      }
      final apiException = _parseError(error);
      error = DioException(
        requestOptions: error.requestOptions,
        response: error.response,
        type: error.type,
        error: apiException,
        message: apiException.message,
      );
      handler.next(error);
    },
  ));

  // ── Logging interceptor (debug only) ──────────────────────────────────────
  if (Env.enableNetworkLogging) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: false,
      ),
    );
  }

  return dio;
}

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Paths that do not require an auth token.
bool _isPublicEndpoint(String path) {
  final normalized = path.replaceAll(Env.baseUrl, '');
  return normalized.startsWith('/auth/send-otp') ||
      normalized.startsWith('/auth/verify-otp') ||
      normalized.startsWith('/auth/refresh-token') ||
      normalized.startsWith('/service-categories') ||
      normalized.startsWith('/discovery') ||
      normalized.startsWith('/banners') ||
      normalized.startsWith('/theme') ||
      normalized.startsWith('/tip-presets') ||
      normalized.startsWith('/payment-offers') ||
      normalized.startsWith('/garment-types') ||
      normalized.startsWith('/garment_rates') ||
      normalized.startsWith('/health');
}

/// Parse a [DioException] into a structured [ApiException].
ApiException _parseError(DioException error) {
  // Timeout
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ApiException.timeout();
  }

  // No internet / connection refused
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown) {
    return ApiException.networkError(
      error.message ?? 'No internet connection',
    );
  }

  // Try parsing structured error body
  final response = error.response;
  if (response != null && response.data is Map<String, dynamic>) {
    final apiError = ApiError.fromJson(response.data as Map<String, dynamic>);
    return ApiException.fromApiError(
      apiError,
      statusCode: response.statusCode,
    );
  }

  // Fallback
  return ApiException(
    message: error.message ?? 'Request failed',
    statusCode: response?.statusCode,
  );
}

// ── Helper: create a Dio instance that can be used outside providers ───────────
/// Useful for one-shot requests (e.g. refresh token) where the full provider
/// infrastructure is not needed.
Dio createSimpleDio() => Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(milliseconds: Env.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: Env.receiveTimeoutMs),
      ),
    );
