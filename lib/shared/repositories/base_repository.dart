import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';

/// Abstract base repository — all repositories extend this.
abstract class BaseRepository {
  const BaseRepository();
}

/// Pagination metadata
class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        currentPage: json['current_page'] as int? ?? 1,
        totalPages: json['total_pages'] as int? ?? 1,
        totalItems: json['total_items'] as int? ?? 0,
        pageSize: json['page_size'] as int? ?? AppConstants.defaultPageSize,
      );
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.meta,
  });

  final List<T> items;
  final PaginationMeta meta;
}

/// Filter / Sort helpers
class PaginationParams {
  const PaginationParams({
    this.page = 1,
    this.pageSize = AppConstants.defaultPageSize,
    this.search,
    this.sortBy,
    this.sortDesc = false,
    this.lat,
    this.lng,
  });

  final int page;
  final int pageSize;
  final String? search;
  final String? sortBy;
  final bool sortDesc;
  final double? lat;
  final double? lng;

  Map<String, dynamic> toQueryParams() => {
        'page': page,
        'page_size': pageSize,
        if (search != null && search!.isNotEmpty) 'search': search,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortBy != null) 'sort_desc': sortDesc,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}
