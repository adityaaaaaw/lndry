/// Generic response envelope from the LNDRY backend: `{ success, message, data, pagination? }`.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
  });

  final bool success;
  final String message;
  final T? data;
  final ApiPagination? pagination;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      pagination: json['pagination'] != null
          ? ApiPagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Pagination metadata matching the backend format.
class ApiPagination {
  const ApiPagination({
    required this.currentPage,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  final int currentPage;
  final int pageSize;
  final int total;
  final int totalPages;

  factory ApiPagination.fromJson(Map<String, dynamic> json) => ApiPagination(
        currentPage: json['page'] as int? ?? 1,
        pageSize: json['limit'] as int? ?? 20,
        total: json['total'] as int? ?? 0,
        totalPages: json['totalPages'] as int? ?? 1,
      );
}

/// Error envelope from the backend: `{ success: false, message, code?, failures? }`.
class ApiError {
  const ApiError({
    required this.success,
    required this.message,
    this.code,
    this.failures = const [],
  });

  final bool success;
  final String message;
  final String? code;
  final List<Map<String, dynamic>> failures;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? 'Unknown error',
        code: json['code'] as String?,
        failures: (json['failures'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
}
