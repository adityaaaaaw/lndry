import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

class ServicesNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  ServicesNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchServices();
  }

  final VendorRepository _repo;

  Future<void> fetchServices() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getMyServices();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addService(ServiceModel service) async {
    try {
      await _repo.addService(service);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel service) async {
    try {
      await _repo.updateService(service);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _repo.deleteService(serviceId);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleAvailability(String serviceId, bool isAvailable) async {
    try {
      await _repo.toggleServiceAvailability(serviceId, isAvailable);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }
}

final servicesListProvider = StateNotifierProvider.autoDispose<
    ServicesNotifier, AsyncValue<List<ServiceModel>>>((ref) {
  final repo = ref.watch(vendorRepositoryProvider);
  return ServicesNotifier(repo);
});
