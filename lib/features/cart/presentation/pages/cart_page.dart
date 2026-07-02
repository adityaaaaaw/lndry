import '../../../../config/env.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../providers/cart_providers.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() async {
    setState(() => _isLoading = true);
    await ref.read(cartStateProvider.notifier).init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(cartStateProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Loading cart items...'),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Cart', style: AppTypography.titleLarge),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        actions: [
          if (state.cart.isNotEmpty)
            IconButton(
              icon: const Icon(AppIcons.delete, color: AppColors.error),
              onPressed: () async {
                final confirm = await AppDialog.show(
                  context,
                  title: 'Clear Cart?',
                  message:
                      'Are you sure you want to remove all items from your cart?',
                  confirmLabel: 'Clear All',
                  isDestructive: true,
                );
                if (confirm == true) {
                  ref.read(cartStateProvider.notifier).clear();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: state.cart.isEmpty
            ? AppEmptyState(
                icon: AppIcons.cartOutlined,
                title: 'Your Cart is Empty',
                subtitle:
                    'Add items from your favorite laundry service vendor menu to get started.',
                actionLabel: 'Browse Laundries',
                onAction: () {
                  final navShell = StatefulNavigationShell.of(context);
                  navShell.goBranch(1); // 1 = Search/Explore tab branch
                },
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await ref.read(cartStateProvider.notifier).init();
                },
                child: Column(
                  children: [
                    // Items listing
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.cart.items.length,
                        separatorBuilder: (_, __) => const Gap(12),
                        itemBuilder: (context, idx) {
                          final item = state.cart.items[idx];
                          final svc = state.services.firstWhere(
                            (s) => s.id == item.serviceId,
                            orElse: () => ServiceModel(
                              id: item.serviceId,
                              vendorId: '',
                              name: 'Laundry Item',
                              description: 'Processing services',
                              category: ServiceCategory.wash,
                              minWeightKg: 0,
                              pricePerKg: 99,
                            ),
                          );

                          return ServiceCard(
                            service: svc,
                            quantity: item.quantity,
                            onAdd: () => ref
                                .read(cartStateProvider.notifier)
                                .updateQuantity(svc.id, item.quantity + 1),
                            onRemove: () => ref
                                .read(cartStateProvider.notifier)
                                .updateQuantity(svc.id, item.quantity - 1),
                          );
                        },
                      ),
                    ),

                    // Pricing summary & proceed CTA
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.pagePaddingH.w,
                        vertical: AppSpacing.pagePaddingV.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.dialog.r),
                        ),
                        boxShadow: AppElevation.high,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (Env.useMocksForVisualTestsOnly)
                            PriceCard(
                              subtotal: state.subtotal,
                              platformFee: state.platformFee,
                              gstAmount: state.gstAmount,
                              total: state.total,
                            )
                          else
                            Text(
                              'Final payable amount is calculated securely by the backend during checkout.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const Gap(20),
                          AppButton(
                            label: 'Proceed to Checkout',
                            onPressed: () => context.push(AppRoutes.checkout),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
