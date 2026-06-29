import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/widgets/domain_cards.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  bool _isLoading = true;
  OrderModel? _order;
  VendorModel? _vendor;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);

    try {
      final o = await repo.getOrderById(widget.orderId);
      final v = await repo.getVendorById(o.vendorId);
      if (mounted) {
        setState(() {
          _order = o;
          _vendor = v;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // List of all timeline statuses in chronological order
  final List<OrderStatus> _timelineSteps = const [
    OrderStatus.pending,          // Placed
    OrderStatus.confirmed,        // Accepted
    OrderStatus.pickedUp,         // Picked Up
    OrderStatus.processing,       // Processing
    OrderStatus.ready,            // Ready
    OrderStatus.outForDelivery,   // Out for Delivery
    OrderStatus.delivered,        // Delivered
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Loading tracking details...'),
      );
    }

    if (_order == null) {
      return Scaffold(
        body: AppErrorWidget.fullscreen(
          title: 'Order Not Found',
          message: 'We couldn\'t load tracking details for order #${widget.orderId}.',
          onRetry: _loadOrderDetails,
        ),
      );
    }

    final currentStatusIdx = _timelineSteps.indexOf(_order!.status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Order #${(_order!.id.length >= 8 ? _order!.id.substring(_order!.id.length - 8) : _order!.id).toUpperCase()}',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.orders),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Vendor Details Box ──────────────────────────────────────
              if (_vendor != null) ...[
                AppCard.outlined(
                  backgroundColor: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(AppIcons.store, color: AppColors.primary, size: 24.r),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_vendor!.name, style: AppTypography.titleMedium),
                            Text(
                              'Estimated Delivery: ${_order!.estimatedDeliveryAt?.toDayDate ?? "Processing"}',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),
              ],

              // ── 2. Status-Based Tracking Timeline ──────────────────────────
              Text('Order Tracking Timeline', style: AppTypography.titleMedium),
              const Gap(16),
              AppCard.outlined(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _timelineSteps.length,
                  itemBuilder: (context, idx) {
                    final step = _timelineSteps[idx];
                    final isCompleted = idx <= currentStatusIdx;
                    final isCurrent = idx == currentStatusIdx;
                    final showLine = idx < _timelineSteps.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side line/dot indicator
                          Column(
                            children: [
                              Container(
                                width: 16.r,
                                height: 16.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted
                                      ? AppColors.primary
                                      : AppColors.outline,
                                  border: isCurrent
                                      ? Border.all(
                                          color: AppColors.primaryContainer,
                                          width: 3.r,
                                        )
                                      : null,
                                ),
                              ),
                              if (showLine)
                                Expanded(
                                  child: Container(
                                    width: 2.w,
                                    color: isCompleted
                                        ? AppColors.primary
                                        : AppColors.outline,
                                  ),
                                ),
                            ],
                          ),
                          const Gap(16),

                          // Right side text label
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.label,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: isCompleted
                                          ? theme.colorScheme.onSurface
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    _getStatusDescription(step),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Gap(24),

              // ── 3. Billing Summary Details Box ─────────────────────────────
              PriceCard(
                subtotal: _order!.subtotal,
                platformFee: _order!.platformFee,
                gstAmount: _order!.gstAmount,
                total: _order!.total,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDescription(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Your order request has been placed successfully.',
        OrderStatus.confirmed => 'The laundry vendor has accepted your order.',
        OrderStatus.pickedUp => 'Your clothes have been picked up from your address.',
        OrderStatus.processing => 'Clothes are being washed and ironed at the store.',
        OrderStatus.ready => 'Garments are ready for dispatch delivery.',
        OrderStatus.outForDelivery => 'Delivery partner is bringing garments to your location.',
        OrderStatus.delivered => 'Order delivered safely. Thank you for choosing LNDRY!',
        OrderStatus.cancelled => 'This order was cancelled.',
        OrderStatus.refunded => 'Your order payment has been refunded.',
      };
}
