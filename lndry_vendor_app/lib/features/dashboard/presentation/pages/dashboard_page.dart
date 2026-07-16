import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/dashboard_provider.dart';
import '../../../../providers/orders_provider.dart';
import '../../../../models/models.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _isTogglingStatus = false;

  Future<void> _refreshData() async {
    ref.invalidate(dashboardStatsProvider);
    ref.read(ordersListProvider.notifier).fetchOrders();
    try {
      await ref.read(authProvider.notifier).refreshProfile();
    } catch (_) {}
  }

  Future<void> _showStoreStatusDialog(bool isCurrentlyOpen) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(
              isCurrentlyOpen ? Icons.store_mall_directory_outlined : Icons.storefront_rounded,
              color: isCurrentlyOpen ? AppColors.error : AppColors.success,
              size: 24.r,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                isCurrentlyOpen ? 'Close Your Store?' : 'Open Your Store?',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isCurrentlyOpen
              ? 'Customers will not be able to place new orders while your store is closed.'
              : 'Your store will be visible to customers and they can place new orders.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyOpen ? AppColors.error : AppColors.success,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(isCurrentlyOpen ? 'Close Store' : 'Open Store'),
          ),
        ],
      ),
    );
    if (shouldProceed == true && mounted) {
      await _toggleStoreStatus(isCurrentlyOpen);
    }
  }

  Future<void> _toggleStoreStatus(bool currentlyOpen) async {
    setState(() => _isTogglingStatus = true);
    try {
      await ref.read(authProvider.notifier).toggleStoreOpen(!currentlyOpen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentlyOpen ? 'Store is now OPEN' : 'Store is now CLOSED'),
            backgroundColor: !currentlyOpen ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingStatus = false);
    }
  }

  void _goToOrdersTab(int tabIndex) {
    ref.read(selectedOrdersTabProvider.notifier).state = tabIndex;
    context.go(AppRoutes.orders);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final ordersAsync = ref.watch(ordersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vendor = authState.vendor;
    final isOpen = vendor.isOpen;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: vendor.logoUrl != null ? NetworkImage(vendor.logoUrl!) : null,
              child: vendor.logoUrl == null
                  ? Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20.r)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        vendor.name,
                        style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.white : AppColors.textBlack),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vendor.isVerified) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 16.r),
                    ],
                  ]),
                  Text(
                    vendor.description.isNotEmpty ? vendor.description : 'Laundry Partner',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _isTogglingStatus
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Center(
                    child: SizedBox(
                      width: 18.r, height: 18.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => _showStoreStatusDialog(isOpen),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isOpen ? AppColors.success : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.r, height: 8.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOpen ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          SizedBox(width: 4.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppElevation.medium,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTopBannerStat(icon: Icons.star_rounded, label: 'Avg Rating',
                            value: vendor.averageRating?.toStringAsFixed(1) ?? 'N/A', color: Colors.amber),
                        _buildDivider(),
                        _buildTopBannerStat(icon: Icons.reviews_rounded, label: 'Total Reviews',
                            value: '${vendor.reviewCount}', color: AppColors.white),
                        _buildDivider(),
                        _buildTopBannerStat(icon: Icons.timelapse_rounded, label: 'Avg Turnaround',
                            value: '${vendor.estimatedTurnaroundHours} hrs', color: AppColors.white),
                      ],
                    ),
                  ),
                  if (vendor.isVerified)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(20.r),
                            bottomLeft: Radius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'APPROVED',
                          style: AppTypography.badge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 24.h),
              Text("Today's Operations",
                  style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textBlack)),
              SizedBox(height: 12.h),
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12.r, mainAxisSpacing: 12.r, childAspectRatio: 1.4,
                  children: [
                    _buildMetricCard(
                      title: "Today's Revenue",
                      value: '₹${(((stats["revenue_today_paise"] is num ? (stats["revenue_today_paise"] as num).toDouble() : double.tryParse(stats["revenue_today_paise"]?.toString() ?? '')) ?? 0.0) / 100.0).toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                      onTap: () => context.push(AppRoutes.analytics),
                    ),
                    _buildMetricCard(
                      title: 'Pending Orders',
                      value: '${stats["pending_orders"] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C)]),
                      onTap: () => _goToOrdersTab(0),
                    ),
                    _buildMetricCard(
                      title: 'Processing Orders',
                      value: '${stats["processing_orders"] ?? 0}',
                      icon: Icons.local_laundry_service_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                      onTap: () => _goToOrdersTab(1),
                    ),
                    _buildMetricCard(
                      title: 'Ready / Packed',
                      value: '${stats["packed_orders"] ?? 0}',
                      icon: Icons.inventory_2_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
                      onTap: () => _goToOrdersTab(2),
                    ),
                  ],
                ),
                loading: () => SizedBox(height: 150.h, child: const Center(child: CircularProgressIndicator())),
                error: (err, _) => _buildErrorCard(
                  message: 'Failed to load statistics',
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
              ),
              SizedBox(height: 24.h),
              Text('Quick Actions',
                  style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.textBlack)),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(icon: Icons.category_rounded, label: 'Catalogue',
                      onTap: () => context.push(AppRoutes.services)),
                  _buildQuickAction(icon: Icons.date_range_rounded, label: 'Slots',
                      onTap: () => context.push(AppRoutes.slots)),
                  _buildQuickAction(icon: Icons.bar_chart_rounded, label: 'Analytics',
                      onTap: () => context.push(AppRoutes.analytics)),
                  _buildQuickAction(icon: Icons.help_outline_rounded, label: 'Help',
                      onTap: () => context.push(AppRoutes.help)),
                ],
              ),
              SizedBox(height: 28.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Incoming Orders',
                      style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.textBlack)),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.orders),
                    child: Text('View All',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ordersAsync.when(
                data: (response) {
                  final pending = response.items
                      .where((o) => o.status == OrderStatus.waitingForVendorConfirmation)
                      .toList();
                  if (pending.isEmpty) {
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(children: [
                        Icon(Icons.done_all_rounded, size: 48.r, color: AppColors.success),
                        SizedBox(height: 12.h),
                        Text('All caught up!',
                            style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.white : AppColors.textBlack)),
                        SizedBox(height: 4.h),
                        Text('No pending orders at the moment.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ]),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pending.take(3).length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, idx) => _buildIncomingOrderCard(pending[idx]),
                  );
                },
                loading: () => SizedBox(height: 100.h, child: const Center(child: CircularProgressIndicator())),
                error: (err, _) => _buildErrorCard(
                  message: 'Failed to load orders',
                  onRetry: () => ref.read(ordersListProvider.notifier).fetchOrders(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBannerStat({required IconData icon, required String label, required String value, required Color color}) {
    return Column(children: [
      Icon(icon, color: color, size: 24.r),
      SizedBox(height: 4.h),
      Text(value, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.white)),
      Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.white.withValues(alpha: 0.6))),
    ]);
  }

  Widget _buildDivider() =>
      Container(height: 40.h, width: 1, color: AppColors.white.withValues(alpha: 0.2));

  Widget _buildMetricCard({
    required String title, required String value, required IconData icon,
    required Gradient gradient, required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: AppElevation.low,
          ),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 28.r),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value,
                      style: AppTypography.headlineLarge.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.white)),
                  Text(title,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8))),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          width: 78.w,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: AppElevation.low,
            border: Border.all(color: AppColors.outline.withValues(alpha: isDark ? 0.05 : 0.2)),
          ),
          child: Column(children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 22.r),
            ),
            SizedBox(height: 8.h),
            Text(label, style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textBlack)),
          ]),
        ),
      ),
    );
  }

  Widget _buildErrorCard({required String message, required VoidCallback onRetry}) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20.r),
          SizedBox(width: 8.w),
          Expanded(child: Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.error))),
        ]),
        SizedBox(height: 8.h),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ]),
    );
  }

  Widget _buildIncomingOrderCard(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppElevation.low,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Order #${order.id.substring(0, 8).toUpperCase()}',
              style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.textBlack)),
          Text('₹${order.total.toStringAsFixed(2)}',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ]),
        SizedBox(height: 4.h),
        Text('${order.items.length} items • ${order.items.map((i) => i.serviceName).join(", ")}',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                try {
                  await ref.read(ordersListProvider.notifier).rejectOrder(order.id);
                  ref.invalidate(dashboardStatsProvider);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
              child: const Text('Reject'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(ordersListProvider.notifier).acceptOrder(order.id);
                  ref.invalidate(dashboardStatsProvider);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order accepted!')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white),
              child: const Text('Accept'),
            ),
          ),
        ]),
      ]),
    );
  }
}
