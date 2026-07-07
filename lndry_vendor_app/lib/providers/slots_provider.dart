import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class SlotsNotifier extends StateNotifier<AsyncValue<List<PickupSlotModel>>> {
  SlotsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchSlots();
  }

  final VendorRepository _repo;

  Future<void> fetchSlots() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getPickupSlots();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSlot({
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    int? maxOrders,
  }) async {
    try {
      await _repo.createPickupSlot(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        maxOrders: maxOrders,
      );
      await fetchSlots();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleSlot(String id, bool isActive) async {
    try {
      await _repo.updatePickupSlot(id, isActive: isActive);
      await fetchSlots();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCapacity(String id, int maxOrders) async {
    try {
      await _repo.updatePickupSlot(id, maxOrders: maxOrders);
      await fetchSlots();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeSlot(String id) async {
    try {
      await _repo.deletePickupSlot(id);
      await fetchSlots();
    } catch (e) {
      rethrow;
    }
  }
}

final slotsListProvider = StateNotifierProvider.autoDispose<
    SlotsNotifier, AsyncValue<List<PickupSlotModel>>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  return SlotsNotifier(repo);
});

// FutureProvider for daily capacity limit settings
final dailyCapacityProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(vendorRepositoryProvider);
  return repo.getCapacity();
});
