import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/env.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../cart/presentation/providers/cart_providers.dart';

class VendorCartState {
  const VendorCartState({
    required this.items,
    required this.services,
  });

  final List<CartItem> items;
  final List<ServiceModel> services;

  double get subtotal {
    if (!Env.useMocksForVisualTestsOnly) return 0.0;
    double total = 0.0;
    for (final item in items) {
      final svc = services.firstWhere((s) => s.id == item.serviceId,
          orElse: () => const ServiceModel(
              id: '',
              vendorId: '',
              name: '',
              description: '',
              category: ServiceCategory.wash,
              minWeightKg: 0));
      if (svc.id.isNotEmpty) {
        final price = svc.pricePerKg ?? svc.pricePerPiece ?? 0.0;
        total += price * item.quantity;
      }
    }
    return total;
  }

  double get platformFee => subtotal * 0.05; // 5% platform fee
  double get gstAmount => subtotal * 0.18; // 18% GST
  double get total => subtotal + platformFee + gstAmount;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

class VendorCartNotifier extends StateNotifier<VendorCartState> {
  VendorCartNotifier(this._repo, this._ref)
      : super(const VendorCartState(items: [], services: []));

  final CustomerRepository _repo;
  final Ref _ref;

  Future<void> init(String vendorId, {bool includeCart = true}) async {
    final list = await _repo.getServicesByVendor(vendorId);
    final filteredItems = <CartItem>[];

    if (includeCart) {
      final cart = await _repo.getCart();
      final svcIds = list.map((s) => s.id).toSet();
      filteredItems.addAll(
        cart.items.where((i) => svcIds.contains(i.serviceId)),
      );
    }

    state = VendorCartState(
      items: filteredItems,
      services: list,
    );
  }

  Future<void> updateQuantity(String serviceId, int delta) async {
    final updatedItems = List<CartItem>.from(state.items);
    final idx = updatedItems.indexWhere((i) => i.serviceId == serviceId);

    if (idx >= 0) {
      final current = updatedItems[idx];
      final newQty = current.quantity + delta;

      if (newQty <= 0) {
        updatedItems.removeAt(idx);
        final c = await _repo.getCart();
        final item = c.items.firstWhere((i) => i.serviceId == serviceId,
            orElse: () => const CartItem(id: '', serviceId: '', quantity: 0));
        if (item.id.isNotEmpty) await _repo.removeFromCart(item.id);
      } else {
        updatedItems[idx] = current.copyWith(quantity: newQty);
        final c = await _repo.getCart();
        final item = c.items.firstWhere((i) => i.serviceId == serviceId,
            orElse: () => const CartItem(id: '', serviceId: '', quantity: 0));
        if (item.id.isNotEmpty) {
          await _repo.updateCartItem(cartItemId: item.id, quantity: newQty);
        }
      }
    } else if (delta > 0) {
      final newItem = CartItem(
        id: 'ci_${DateTime.now().millisecondsSinceEpoch}',
        serviceId: serviceId,
        quantity: delta,
      );
      updatedItems.add(newItem);
      await _repo.addToCart(serviceId: serviceId, quantity: delta);
    }

    state = VendorCartState(
      items: updatedItems,
      services: state.services,
    );

    await _ref.read(cartStateProvider.notifier).refresh();
  }
}

final vendorCartProvider =
    StateNotifierProvider.autoDispose<VendorCartNotifier, VendorCartState>(
        (ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return VendorCartNotifier(repo, ref);
});
