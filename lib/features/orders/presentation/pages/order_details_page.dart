import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/shared_widgets.dart';
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
  bool _isCancelling = false;
  bool _isReordering = false;
  bool _isLoadingInvoice = false;
  bool _isLoadingOtp = false;
  OrderModel? _order;
  VendorModel? _vendor;
  InvoiceResult? _invoice;
  OtpResult? _otp;

  static const List<String> _cancelReasons = [
    'I need to reschedule',
    'Picked a different vendor',
    'Changed my mind',
    'Estimated cost too high',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      final o = await repo.getOrderById(widget.orderId);
      VendorModel? v;
      if (o.vendorId.isNotEmpty) {
        try { v = await repo.getVendorById(o.vendorId); } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _order = o;
          _vendor = v;
          _isLoading = false;
          _invoice = null;
          _otp = null;
        });
        unawaited(_maybeFetchInvoice(o));
        unawaited(_maybeFetchOtp(o));
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _maybeFetchInvoice(OrderModel order) async {
    if (order.status != OrderStatus.delivered &&
        order.status != OrderStatus.deliveryOtpVerified) {
      return;
    }
    setState(() => _isLoadingInvoice = true);
    try {
      final invoice = await ref.read(customerRepositoryProvider).getOrderInvoice(widget.orderId);
      if (mounted) setState(() { _invoice = invoice; _isLoadingInvoice = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingInvoice = false);
    }
  }

  Future<void> _maybeFetchOtp(OrderModel order) async {
    if (!order.status.showPickupOtpHint && !order.status.showDeliveryOtpHint) {
      return;
    }
    setState(() => _isLoadingOtp = true);
    try {
      final otp = await ref.read(customerRepositoryProvider).getOrderOtp(widget.orderId);
      if (mounted) setState(() { _otp = otp; _isLoadingOtp = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOtp = false);
    }
  }

  Future<void> _showCancelSheet() async {
    String? selectedReason;

    await AppBottomSheet.show<String>(
      context: context,
      title: 'Cancel Order',
      primaryActionLabel: 'Confirm Cancellation',
      onPrimaryAction: () {
        if (selectedReason != null && selectedReason!.isNotEmpty) {
          Navigator.of(context).pop(selectedReason);
        }
      },
      child: StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Please select a reason for cancelling:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(16),
            ..._cancelReasons.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: AppCard.outlined(
                    borderColor: selectedReason == r
                        ? AppColors.error
                        : AppColors.outline,
                    backgroundColor: selectedReason == r
                        ? AppColors.error.withOpacity(0.08)
                        : AppColors.transparent,
                    onTap: () => setModalState(() => selectedReason = r),
                    child: Text(r, style: AppTypography.bodyMedium),
                  ),
                )),
          ],
        ),
      ),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty && mounted) {
        _executeCancel(reason);
      }
    });
  }

  Future<void> _executeCancel(String reason) async {
    setState(() => _isCancelling = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final updated = await repo.cancelOrder(widget.orderId, reason: reason);
      if (mounted) {
        setState(() {
          _order = updated;
          _isCancelling = false;
        });
        AppSnackBar.showSuccess(context, 'Order cancelled successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        AppSnackBar.showError(context, 'Failed to cancel: ${e.toString()}');
      }
    }
  }

  Future<void> _handleReorder() async {
    setState(() => _isReordering = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final newOrder = await repo.reorder(widget.orderId);
      if (mounted) {
        AppSnackBar.showSuccess(context, 'New order placed! Redirecting...');
        context.go('/orders/details/${newOrder.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isReordering = false);
        AppSnackBar.showError(context, 'Reorder failed: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDownloadInvoice() async {
    if (_invoice?.pdfUrl != null) {
      final uri = Uri.tryParse(_invoice!.pdfUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // Canonical customer-visible forward-progress timeline per spec §4/§6.
  static const List<OrderStatus> _timelineSteps = [
    OrderStatus.waitingForVendorConfirmation,
    OrderStatus.vendorAccepted,
    OrderStatus.goingForPickup,
    OrderStatus.pickedUp,
    OrderStatus.receivedAtVendor,
    OrderStatus.processing,
    OrderStatus.packed,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  String _shortId(String id) => id.length > 8
      ? id.substring(id.length - 8).toUpperCase()
      : id.toUpperCase();

  Color _statusColor(OrderStatus s) {
    if (s.isRejected || s == OrderStatus.paymentFailed) return AppColors.error;
    if (s == OrderStatus.delivered || s == OrderStatus.deliveryOtpVerified)
      return AppColors.success;
    if (s.hasRefundState) return AppColors.warning;
    return AppColors.primary;
  }

  String _stepDescription(OrderStatus s) => switch (s) {
        OrderStatus.waitingForVendorConfirmation =>
          'Order sent to vendor; awaiting acceptance.',
        OrderStatus.vendorAccepted =>
          'Vendor confirmed. Pickup being arranged.',
        OrderStatus.goingForPickup =>
          'Pickup partner is on the way to your address.',
        OrderStatus.pickedUp =>
          'Garments collected and heading to the partner.',
        OrderStatus.receivedAtVendor =>
          'Arrived at laundry. Quantities being confirmed.',
        OrderStatus.processing =>
          'Clothes are being washed, dried and/or ironed.',
        OrderStatus.packed =>
          'Packed and ready. Delivery being arranged.',
        OrderStatus.outForDelivery =>
          'On the way to your delivery address.',
        OrderStatus.delivered =>
          'Delivered. Thank you for choosing LNDRY!',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: AppColors.transparent, elevation: 0),
        body: const AppLoadingPage(message: 'Loading order details...'),
      );
    }

    if (_order == null) {
      return Scaffold(
        body: AppErrorWidget.fullscreen(
          title: 'Order Not Found',
          message: 'We couldn\'t load details for order #${widget.orderId}.',
          onRetry: _loadOrderDetails,
        ),
      );
    }

    final order = _order!;
    final isRejected = order.status.isRejected;
    final isCancelled = order.status == OrderStatus.customerCancelled ||
        order.status == OrderStatus.adminCancelled;
    final currentStepIdx = _timelineSteps.indexOf(order.status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Order #${_shortId(order.id)}',
            style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.orders);
            }
          },
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOrderDetails,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Current status ─────────────────────────────────────────
                Center(
                  child: StatusBadge(
                    label: order.status.label,
                    color: _statusColor(order.status),
                    large: true,
                  ),
                ),
                const Gap(24),

                // ── Vendor info with pickup/delivery estimates ─────────────
                if (_vendor != null) ...[
                  AppCard.outlined(
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surface,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(AppIcons.store,
                              color: AppColors.primary, size: 24.r),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_vendor!.name,
                                  style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold)),
                              if (order.scheduledPickupAt != null)
                                Text(
                                  'Pickup: ${order.scheduledPickupAt!.toDayDate}',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                              if (order.estimatedDeliveryAt != null)
                                Text(
                                  'Delivery: ${order.estimatedDeliveryAt!.toDayDate}',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                ],

                // ── Payment method ─────────────────────────────────────────
                AppCard.outlined(
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.surface,
                  child: Row(
                    children: [
                      Icon(AppIcons.payment,
                          color: AppColors.primary, size: 20.r),
                      const Gap(12),
                      Text(
                        'Payment: ${order.paymentMethod.label}',
                        style: AppTypography.labelMedium,
                      ),
                      const Spacer(),
                      if (order.isPaid)
                        StatusBadge(
                          label: 'Paid',
                          color: AppColors.success,
                        )
                      else
                        StatusBadge(
                          label: 'Unpaid',
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                ),
                const Gap(16),

                // ── Rejection/cancellation banner ─────────────────────────
                if (isRejected) ...[
                  _Banner(
                    icon: AppIcons.error,
                    color: AppColors.error,
                    title: order.status.label,
                    body: order.vendorRejectionReason ??
                        (order.status == OrderStatus.autoRejected
                            ? 'The vendor did not respond in time.'
                            : 'The vendor was unable to accept your order.'),
                  ),
                  const Gap(16),
                ] else if (isCancelled) ...[
                  _Banner(
                    icon: AppIcons.close,
                    color: AppColors.error,
                    title: 'Order Cancelled',
                    body: order.cancellationReason ??
                        'This order has been cancelled.',
                  ),
                  const Gap(16),
                ],

                // ── Timeline ───────────────────────────────────────────────
                if (!isRejected && !isCancelled) ...[
                  Text('Order Timeline', style: AppTypography.titleMedium),
                  const Gap(16),
                  AppCard.outlined(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 24.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _timelineSteps.length,
                      itemBuilder: (context, idx) {
                        final step = _timelineSteps[idx];
                        final isCompleted =
                            currentStepIdx >= 0 && idx <= currentStepIdx;
                        final isCurrent = idx == currentStepIdx;
                        final showLine =
                            idx < _timelineSteps.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 16.r,
                                    height: 16.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted
                                          ? AppColors.primary
                                          : AppColors.outline
                                              .withOpacity(0.5),
                                      border: isCurrent
                                          ? Border.all(
                                              color: AppColors
                                                  .primaryContainer,
                                              width: 3.r)
                                          : null,
                                    ),
                                    child: isCompleted
                                        ? Icon(Icons.check,
                                            size: 10.r,
                                            color: AppColors.white)
                                        : null,
                                  ),
                                  if (showLine)
                                    Expanded(
                                      child: Container(
                                        width: 2.w,
                                        color: isCompleted
                                            ? AppColors.primary
                                            : AppColors.outline
                                                .withOpacity(0.4),
                                      ),
                                    ),
                                ],
                              ),
                              const Gap(16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.label,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                          color: isCompleted
                                              ? AppColors.textBlack
                                              : AppColors
                                                  .onSurfaceVariant,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        _stepDescription(step),
                                        style: AppTypography.bodySmall
                                            .copyWith(
                                          color: AppColors
                                              .onSurfaceVariant,
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
                ],

                // ── Order items ─────────────────────────────────────────
                if (order.items.isNotEmpty) ...[
                  Text('Items', style: AppTypography.titleMedium),
                  const Gap(12),
                  AppCard.outlined(
                    padding: EdgeInsets.all(AppSpacing.md.r),
                    child: Column(
                      children: order.items
                          .map((item) => Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 6.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity} × ${item.serviceName}',
                                        style: AppTypography.bodyMedium,
                                      ),
                                    ),
                                    if (item.totalPrice > 0)
                                      Text(
                                        item.totalPrice.toCurrencyDecimal,
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const Gap(16),
                ],

                // ── Pricing summary ─────────────────────────────────────
                if (order.total > 0) ...[
                  PriceCard(
                    subtotal: order.subtotal,
                    platformFee: order.platformFee,
                    gstAmount: order.gstAmount,
                    total: order.total,
                  ),
                  const Gap(24),
                ],

                // ── OTP Section (Pickup or Delivery) ────────────────────
                if (_otp != null) ...[
                  Text('Security OTP', style: AppTypography.titleMedium),
                  const Gap(12),
                  AppCard.outlined(
                    backgroundColor: AppColors.primaryContainer.withOpacity(0.15),
                    borderColor: AppColors.primary.withOpacity(0.3),
                    padding: EdgeInsets.all(AppSpacing.md.r),
                    child: Column(
                      children: [
                        Icon(
                          _otp!.type == 'pickup'
                              ? Icons.pin_rounded
                              : Icons.verified_user_rounded,
                          color: AppColors.primary,
                          size: 32.r,
                        ),
                        const Gap(8),
                        Text(
                          _otp!.type == 'pickup'
                              ? 'Pickup OTP'
                              : 'Delivery OTP',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Provide this code to the partner:',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Gap(12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.input.r),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            _otp!.otp,
                            style: AppTypography.headlineSmall.copyWith(
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Expires at ${_otp!.expiresAt.toTimeString}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                ],

                // ── Invoice Section (Delivered orders) ──────────────────
                if (_invoice != null) ...[
                  Text('Invoice', style: AppTypography.titleMedium),
                  const Gap(12),
                  AppCard.outlined(
                    onTap: _handleDownloadInvoice,
                    padding: EdgeInsets.all(AppSpacing.md.r),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.document,
                            color: AppColors.primary,
                            size: 24.r,
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice #${_invoice!.id.length >= 8 ? _invoice!.id.substring(_invoice!.id.length - 8).toUpperCase() : _invoice!.id.toUpperCase()}',
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Total: ${_invoice!.total.toCurrencyDecimal}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          AppIcons.download,
                          color: AppColors.primary,
                          size: 20.r,
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),
                ],

                // ── Action buttons (Cancel / Reorder) ───────────────────
                Row(
                  children: [
                    // Cancel button (when cancellable)
                    if (order.status.isCancellable)
                      Expanded(
                        child: AppButton.outlined(
                          label: 'Cancel Order',
                          icon: const Icon(AppIcons.close, size: 18),
                          foregroundColor: AppColors.error,
                          isLoading: _isCancelling,
                          isDisabled: _isCancelling,
                          onPressed: _showCancelSheet,
                        ),
                      ),
                    if (order.status.isCancellable) const Gap(12),
                    // Reorder button (terminal orders except customer/admin-cancelled)
                    if (order.status.isTerminal &&
                        order.status != OrderStatus.customerCancelled &&
                        order.status != OrderStatus.adminCancelled)
                      Expanded(
                        child: AppButton(
                          label: 'Reorder',
                          icon: const Icon(Icons.repeat_rounded, size: 18),
                          isLoading: _isReordering,
                          isDisabled: _isReordering,
                          onPressed: _handleReorder,
                        ),
                      ),
                  ],
                ),
                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Banner widget ─────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.card.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.r),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelLarge.copyWith(
                        color: color, fontWeight: FontWeight.bold)),
                const Gap(4),
                Text(body,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
