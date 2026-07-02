import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';

/// Provider for list of all laundry categories on Home screen
final homeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCategories();
});

/// Provider for nearby/recommended vendors list on Home screen
final homeVendorsProvider = FutureProvider<List<VendorModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final addresses = await repo.getAddresses();
  double? lat;
  double? lng;
  if (addresses.isNotEmpty) {
    final addr = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
    lat = addr.coordinates?.latitude;
    lng = addr.coordinates?.longitude;
  }

  final response = await repo.getVendors(
    categoryId: null,
    search: null,
    params: PaginationParams(pageSize: 10, lat: lat, lng: lng),
  );
  return response.items;
});

/// Provider for recommended services on Home screen
final homeRecommendedServicesProvider = FutureProvider<List<ServiceModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  try {
    final vendors = await ref.watch(homeVendorsProvider.future);
    if (vendors.isNotEmpty) {
      return repo.getServicesByVendor(vendors.first.id);
    }
  } catch (_) {}
  return [];
});

/// Provider for active orders tracker on Home screen
final activeOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final response = await repo.getMyOrders(
    params: const PaginationParams(pageSize: 5),
  );
  return response.items.where((o) => o.status.isActive).toList();
});

/// Provider for previous order history on Home screen
final pastOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final response = await repo.getMyOrders(
    params: const PaginationParams(pageSize: 10),
  );
  return response.items.where((o) => !o.status.isActive).toList();
});

/// User address display provider on Home screen
final currentAddressProvider = FutureProvider<AddressModel?>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final addresses = await repo.getAddresses();
  if (addresses.isEmpty) return null;
  return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
});
