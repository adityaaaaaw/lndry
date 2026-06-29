import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';
import '../../../../shared/repositories/base_repository.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Orders', style: AppTypography.titleLarge),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Order History'),
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
                        subtitle: 'All set! You don\'t have any active laundry runs currently.',
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
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, idx) {
                        final order = orders[idx];
                        return _ActiveOrderTile(order: order);
                      },
                    ),
              loading: () => ListView.separated(
                padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                itemCount: 3,
                separatorBuilder: (_, __) => const Gap(16),
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
                      separatorBuilder: (_, __) => const Gap(16),
                      itemBuilder: (context, idx) {
                        final order = orders[idx];
                        return _PastOrderTile(order: order);
                      },
                    ),
              loading: () => ListView.separated(
                padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                itemCount: 3,
                separatorBuilder: (_, __) => const Gap(16),
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

class _ActiveOrderTile extends StatelessWidget {
  const _ActiveOrderTile({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      borderColor: AppColors.primary.withOpacity(0.3),
      backgroundColor: AppColors.primaryContainer.withOpacity(0.12),
      onTap: () => context.go('/orders/details/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${(order.id.length >= 8 ? order.id.substring(order.id.length - 8) : order.id).toUpperCase()}',
                style: AppTypography.titleSmall,
              ),
              StatusBadge(
                label: order.status.label,
                color: AppColors.primary,
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Icon(AppIcons.clock, size: 14.r, color: AppColors.onSurfaceVariant),
              const Gap(6),
              Text(
                'Pickup: ${order.scheduledPickupAt?.toDayDate ?? "Scheduled"}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} items • ${order.total.toCurrencyDecimal}',
                style: AppTypography.labelMedium,
              ),
              Row(
                children: [
                  Text(
                    'Track Order',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
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

class _PastOrderTile extends StatelessWidget {
  const _PastOrderTile({required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == OrderStatus.delivered;

    return AppCard.outlined(
      onTap: () => context.go('/orders/details/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${(order.id.length >= 8 ? order.id.substring(order.id.length - 8) : order.id).toUpperCase()}',
                style: AppTypography.titleSmall,
              ),
              StatusBadge(
                label: order.status.label,
                color: isDelivered ? AppColors.success : AppColors.error,
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Icon(AppIcons.calendar, size: 14.r, color: AppColors.onSurfaceVariant),
              const Gap(6),
              Text(
                'Date: ${order.createdAt.toDateString}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} items • ${order.total.toCurrencyDecimal}',
                style: AppTypography.labelMedium,
              ),
              Row(
                children: [
                  Text(
                    'View Details',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Gap(4),
                  Icon(AppIcons.forward, size: 14.r, color: AppColors.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
