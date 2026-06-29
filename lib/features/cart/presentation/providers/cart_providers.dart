import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';

class CartState {
  const CartState({
    required this.cart,
    required this.services,
  });

  final CartModel cart;
  final List<ServiceModel> services;

  double get subtotal {
    double total = 0.0;
    for (final item in cart.items) {
      final svc = services.firstWhere(
        (s) => s.id == item.serviceId,
        orElse: () => const ServiceModel(id: '', vendorId: '', name: '', description: '', category: ServiceCategory.wash, minWeightKg: 0),
      );
      if (svc.id.isNotEmpty) {
        final price = svc.pricePerKg ?? svc.pricePerPiece ?? 0.0;
        total += price * item.quantity;
      }
    }
    return total;
  }

  double get platformFee => subtotal * 0.05; // 5% platform fee
  double get gstAmount => subtotal * 0.18;   // 18% GST
  double get total => subtotal + platformFee + gstAmount;

  int get totalQuantity => cart.itemCount;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._repo) : super(const CartState(cart: CartModel(items: []), services: []));

  final CustomerRepository _repo;

  Future<void> init() async {
    final cart = await _repo.getCart();
    final services = <ServiceModel>[];

    // Fetch details for all services currently in cart
    for (final item in cart.items) {
      // Find matching vendor and service details
      final svc = await _findService(item.serviceId);
      if (svc != null) {
        services.add(svc);
      }
    }

    state = CartState(cart: cart, services: services);
  }

  Future<ServiceModel?> _findService(String serviceId) async {
    try {
      // Direct mock search
      final vendors = await _repo.getVendors();
      for (final v in vendors.items) {
        final list = await _repo.getServicesByVendor(v.id);
        final found = list.where((s) => s.id == serviceId);
        if (found.isNotEmpty) return found.first;
      }
    } catch (_) {}
    return null;
  }

  void updateQuantity(String serviceId, int newQty) async {
    final item = state.cart.items.firstWhere(
      (i) => i.serviceId == serviceId,
      orElse: () => const CartItem(id: '', serviceId: '', quantity: 0),
    );

    if (item.id.isEmpty) return;

    if (newQty <= 0) {
      final updatedCart = await _repo.removeFromCart(item.id);
      state = CartState(cart: updatedCart, services: state.services);
    } else {
      final updatedCart = await _repo.updateCartItem(cartItemId: item.id, quantity: newQty);
      state = CartState(cart: updatedCart, services: state.services);
    }
  }

  void clear() async {
    await _repo.clearCart();
    state = const CartState(cart: CartModel(items: []), services: []);
  }
}

final cartStateProvider =
    StateNotifierProvider.autoDispose<CartNotifier, CartState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CartNotifier(repo);
});
