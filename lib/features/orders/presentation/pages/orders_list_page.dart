import 'dart:async';

import '../../../../core/design/design_system.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../home/presentation/providers/home_providers.dart';

class OrdersListPage extends ConsumerStatefulWidget {
  const OrdersListPage({super.key});

  @override
  ConsumerState<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends ConsumerState<OrdersListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    final activeAsync = ref.watch(activeOrdersProvider);
    final pastAsync = ref.watch(pastOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Orders', style: AppTypography.titleLarge),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5.r,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(child: Text('Active Orders', style: AppTypography.labelLarge)),
            Tab(child: Text('Order History', style: AppTypography.labelLarge)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Active Orders ───────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(activeOrdersProvider),
            child: activeAsync.when(
              data: (orders) => orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: AppEmptyState(
                        icon: AppIcons.ordersOutlined,
                        title: 'No Active Orders',
                        subtitle:
                            'All set! You don\'t have any active laundry runs currently.',
                        actionLabel: 'Book a Laundry Pickup',
                        onAction: () {
                          final navShell = StatefulNavigationShell.of(context);
                          navShell.goBranch(0); // 0 = Home tab branch
                        },
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => Gap(AppSpacing.md.h),
                      itemBuilder: (context, idx) {
                        final order = orders[idx];
                        return _ActiveOrderTile(order: order);
                      },
                    ),
              loading: () => ListView.separated(
                padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                itemCount: 3,
                separatorBuilder: (_, __) => Gap(AppSpacing.md.h),
                itemBuilder: (_, __) => const AppSkeletonCard(height: 110),
              ),
              error: (err, __) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.invalidate(activeOrdersProvider),
              ),
            ),
          ),

          // ── Tab 2: Past Orders History ──────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(pastOrdersProvider),
            child: pastAsync.when(
              data: (orders) => orders.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: AppEmptyState(
                        icon: AppIcons.document,
                        title: 'No Order History',
                        subtitle: 'You haven\'t completed any orders yet.',
                        actionLabel: 'Explore Services',
                        onAction: () {
                          final navShell = StatefulNavigationShell.of(context);
                          navShell.goBranch(0);
                        },
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => Gap(AppSpacing.md.h),
                      itemBuilder: (context, idx) {
                        final order = orders[idx];
                        return _PastOrderTile(order: order);
                      },
                    ),
              loading: () => ListView.separated(
                padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                itemCount: 3,
                separatorBuilder: (_, __) => Gap(AppSpacing.md.h),
                itemBuilder: (_, __) => const AppSkeletonCard(height: 110),
              ),
              error: (err, __) => AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.invalidate(pastOrdersProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderTile extends ConsumerStatefulWidget {
  const _ActiveOrderTile({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_ActiveOrderTile> createState() => _ActiveOrderTileState();
}

class _ActiveOrderTileState extends ConsumerState<_ActiveOrderTile> {
  bool _isCancelling = false;

  static const List<String> _cancelReasons = [
    'I need to reschedule',
    'Picked a different vendor',
    'Changed my mind',
    'Estimated cost too high',
    'Other',
  ];

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
            Gap(AppSpacing.md.h),
            ..._cancelReasons.map((r) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: AppCard.outlined(
                    borderColor: selectedReason == r
                        ? AppColors.error
                        : AppColors.outline,
                    backgroundColor: selectedReason == r
                        ? AppColors.error.withValues(alpha: 0.08)
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
        setState(() => _isCancelling = true);
        ref
            .read(customerRepositoryProvider)
            .cancelOrder(widget.order.id, reason: reason)
            .then((_) {
          if (mounted) {
            AppSnackBar.showSuccess(context, 'Order cancelled successfully');
            ref.invalidate(activeOrdersProvider);
            ref.invalidate(pastOrdersProvider);
          }
        }).catchError((Object e) {
          if (mounted) {
            AppSnackBar.showError(context, 'Failed to cancel: ${e.toString()}');
          }
        }).whenComplete(() {
          if (mounted) setState(() => _isCancelling = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return AppCard.outlined(
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.12),
      onTap: () => context.go('/orders/details/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${(order.id.length >= 8 ? order.id.substring(order.id.length - 8) : order.id).toUpperCase()}',
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(AppSpacing.sm.w),
              StatusBadge(
                label: order.status.label,
                color: AppColors.primary,
              ),
            ],
          ),
          Gap(AppSpacing.cardGap.h),
          Row(
            children: [
              Icon(AppIcons.clock,
                  size: 14.r, color: AppColors.onSurfaceVariant),
              Gap(AppSpacing.sm.h),
              Expanded(
                child: Text(
                  'Pickup: ${order.scheduledPickupAt?.toDayDate ?? "Scheduled"}',
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md.h),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              Text(
                '${order.items.length} items • ${order.total.toCurrencyDecimal}',
                style: AppTypography.labelMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel button (only when cancellable)
                  if (order.status.isCancellable && !_isCancelling)
                    GestureDetector(
                      onTap: _showCancelSheet,
                      child: Text(
                        'Cancel',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (order.status.isCancellable && !_isCancelling)
                    Gap(AppSpacing.cardGap.h),
                  if (_isCancelling)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.r,
                        color: AppColors.error,
                      ),
                    ),
                  if (_isCancelling) Gap(AppSpacing.sm.w),
                  Text(
                    'Track',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(AppSpacing.xs.w),
                  Icon(AppIcons.forward, size: 14.r, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastOrderTile extends ConsumerStatefulWidget {
  const _PastOrderTile({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_PastOrderTile> createState() => _PastOrderTileState();
}

class _PastOrderTileState extends ConsumerState<_PastOrderTile> {
  bool _isReordering = false;

  Future<void> _handleReorder() async {
    setState(() => _isReordering = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final result = await repo.reorder(widget.order.id);
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          result.message,
        );
        ref.invalidate(activeOrdersProvider);
        ref.invalidate(pastOrdersProvider);
        context.go(AppRoutes.cart);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Reorder failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDelivered = order.status == OrderStatus.delivered;

    return AppCard.outlined(
      onTap: () => context.go('/orders/details/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${(order.id.length >= 8 ? order.id.substring(order.id.length - 8) : order.id).toUpperCase()}',
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(AppSpacing.sm.w),
              StatusBadge(
                label: order.status.label,
                color: isDelivered ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          Gap(AppSpacing.cardGap.h),
          Row(
            children: [
              Icon(AppIcons.calendar,
                  size: 14.r, color: AppColors.onSurfaceVariant),
              Gap(AppSpacing.sm.h),
              Expanded(
                child: Text(
                  'Date: ${order.createdAt.toDateString}',
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Gap(AppSpacing.md.h),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              Text(
                '${order.items.length} items • ${order.total.toCurrencyDecimal}',
                style: AppTypography.labelMedium,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reorder button (show for any terminal order)
                  if (order.status.isTerminal && !_isReordering)
                    GestureDetector(
                      onTap: _handleReorder,
                      child: Text(
                        'Reorder',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (order.status.isTerminal && !_isReordering) Gap(AppSpacing.sm.w),
                  if (_isReordering)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(strokeWidth: 2.r),
                    ),
                  if (_isReordering) Gap(AppSpacing.sm.w),
                  Text(
                    'View Details',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Gap(AppSpacing.xs.w),
                  Icon(AppIcons.forward,
                      size: 14.r, color: AppColors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
