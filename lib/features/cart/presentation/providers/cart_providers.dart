import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/env.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';

// ── Cart State ────────────────────────────────────────────────────────────────

class CartState {
  const CartState({
    required this.cart,
    required this.services,
    this.isInitialised = false,
  });

  final CartModel cart;
  final List<ServiceModel> services;
  final bool isInitialised;

  double get subtotal {
    if (!Env.useMocksForVisualTestsOnly) return 0.0;
    double total = 0.0;
    for (final item in cart.items) {
      final svc = services.firstWhere(
        (s) => s.id == item.serviceId,
        orElse: () => const ServiceModel(
          id: '',
          vendorId: '',
          name: '',
          description: '',
          category: ServiceCategory.wash,
          minWeightKg: 0,
        ),
      );
      if (svc.id.isNotEmpty) {
        final price = svc.pricePerKg ?? svc.pricePerPiece ?? 0.0;
        total += price * item.quantity;
      }
    }
    return total;
  }

  // NOTE: These mock-phase calculations will be removed when the backend
  // delivers server-side quote amounts (spec §6 / §11).
  double get platformFee => subtotal * 0.05;
  double get gstAmount => subtotal * 0.18;
  double get total => subtotal + platformFee + gstAmount;

  int get totalQuantity => cart.itemCount;

  CartState copyWith({
    CartModel? cart,
    List<ServiceModel>? services,
    bool? isInitialised,
  }) =>
      CartState(
        cart: cart ?? this.cart,
        services: services ?? this.services,
        isInitialised: isInitialised ?? this.isInitialised,
      );
}

// ── Cart Notifier ─────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._repo)
      : super(CartState(cart: CartModel(items: const []), services: const []));

  final CustomerRepository _repo;

  /// Loads cart from repository.  Safe to call multiple times;
  /// skips the fetch if already initialised unless [force] = true.
  Future<void> init({bool force = false}) async {
    if (state.isInitialised && !force) return;

    final cart = await _repo.getCart();
    final services = await _resolveAllServices();
    state = CartState(cart: cart, services: services, isInitialised: true);
  }

  /// Force-refreshes cart + services.  Called by VendorDetailsPage after
  /// adding items so the Cart tab is up-to-date without requiring a tab switch.
  Future<void> refresh() => init(force: true);

  Future<List<ServiceModel>> _resolveAllServices() async {
    final services = <ServiceModel>[];
    try {
      final vendors =
          await _repo.getVendors(params: PaginationParams(pageSize: 50));
      for (final v in vendors.items) {
        final list = await _repo.getServicesByVendor(v.id);
        services.addAll(list);
      }
    } catch (_) {}
    // Deduplicate by id.
    final seen = <String>{};
    return services.where((s) => seen.add(s.id)).toList();
  }

  Future<void> updateQuantity(String serviceId, int newQty) async {
    final item = state.cart.items.firstWhere(
      (i) => i.serviceId == serviceId,
      orElse: () => CartItem(id: '', serviceId: '', quantity: 0),
    );
    if (item.id.isEmpty) return;

    final CartModel updated;
    if (newQty <= 0) {
      updated = await _repo.removeFromCart(item.id);
    } else {
      updated =
          await _repo.updateCartItem(cartItemId: item.id, quantity: newQty);
    }
    state = state.copyWith(cart: updated);
  }

  Future<void> clear() async {
    await _repo.clearCart();
    state = const CartState(
        cart: CartModel(items: []), services: [], isInitialised: true);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// NOT autoDispose — cart state persists across tab switches.
/// Call cartStateProvider.notifier.refresh() after adding items from
/// vendor details page.
final cartStateProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CartNotifier(repo);
});
