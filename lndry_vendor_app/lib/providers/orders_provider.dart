import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../shared/repositories/base_repository.dart';

import 'dashboard_provider.dart';
import 'analytics_provider.dart';

class OrdersFilter {
  const OrdersFilter({
    this.status,
    this.page = 1,
  });
  final String? status;
  final int page;

  OrdersFilter copyWith({
    String? status,
    int? page,
  }) {
    return OrdersFilter(
      status: status ?? this.status,
      page: page ?? this.page,
    );
  }
}

class OrdersNotifier extends StateNotifier<AsyncValue<PaginatedResponse<OrderModel>>> {
  OrdersNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  final VendorRepository _repo;
  final Ref _ref;
  OrdersFilter _filter = const OrdersFilter();

  OrdersFilter get filter => _filter;

  Future<void> fetchOrders({String? status, int page = 1}) async {
    state = const AsyncValue.loading();
    try {
      _filter = _filter.copyWith(status: status, page: page);
      final resp = await _repo.getIncomingOrders(
        status: _filter.status,
        params: PaginationParams(page: _filter.page),
      );
      state = AsyncValue.data(resp);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _syncStats() {
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(analyticsStatsProvider);
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      await _repo.acceptOrder(orderId);
      _syncStats();
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId, {String? reason}) async {
    try {
      await _repo.rejectOrder(orderId, reason: reason);
      _syncStats();
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStage(String orderId, String stage) async {
    try {
      await _repo.updateProcessingStage(orderId, stage);
      _syncStats();
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reconcile(
    String orderId, {
    List<Map<String, dynamic>>? confirmedLines,
    double? confirmedWeightKg,
    String? adjustmentReason,
  }) async {
    try {
      await _repo.reconcileOrder(
        orderId,
        confirmedLines: confirmedLines,
        confirmedWeightKg: confirmedWeightKg,
        adjustmentReason: adjustmentReason,
      );
      _syncStats();
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }
}

final ordersListProvider = StateNotifierProvider.autoDispose<
    OrdersNotifier, AsyncValue<PaginatedResponse<OrderModel>>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  return OrdersNotifier(repo, ref);
});

final orderDetailsProvider = FutureProvider.family.autoDispose<OrderModel, String>((ref, id) async {
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.getOrder(id);
});

// Used by dashboard to jump to a specific orders tab
final selectedOrdersTabProvider = StateProvider<int>((ref) => 0);
