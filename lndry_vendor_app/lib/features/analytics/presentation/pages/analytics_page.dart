import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/analytics_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final period = ref.watch(analyticsPeriodProvider);
    final statsAsync = ref.watch(analyticsStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.white : AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Analytics',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
        actions: [
          // Period toggle
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'month', label: Text('Month')),
              ],
              selected: {period},
              onSelectionChanged: (selected) {
                ref.read(analyticsPeriodProvider.notifier).state =
                    selected.first;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 64.r, color: AppColors.error),
                SizedBox(height: 16.h),
                Text('Failed to load analytics',
                    style: AppTypography.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text(err.toString(),
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => ref.invalidate(analyticsStatsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => _AnalyticsContent(stats: stats, isDark: isDark),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.stats, required this.isDark});

  final Map<String, dynamic> stats;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final totalRevenue = (stats['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (stats['total_orders'] as num?)?.toInt() ?? 0;
    final deliveredOrders =
        (stats['delivered_orders'] as num?)?.toInt() ?? 0;
    final fulfillmentRate =
        (stats['fulfillment_rate'] as num?)?.toDouble() ?? 0.0;
    final avgTicket =
        (stats['avg_ticket_size'] as num?)?.toDouble() ?? 0.0;
    final repeatRate =
        (stats['repeat_customer_rate'] as num?)?.toDouble() ?? 0.0;
    final onTimeRate =
        (stats['on_time_delivery_rate'] as num?)?.toDouble() ?? 0.0;
    final dailyData =
        (stats['daily_data'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final categoryBreakdown =
        (stats['category_breakdown'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    final maxOrders = dailyData.isEmpty
        ? 1
        : dailyData
            .map((d) => (d['orders'] as num).toInt())
            .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary KPI Cards ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Total Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  sub: '$deliveredOrders orders delivered',
                  icon: Icons.currency_rupee_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _KpiCard(
                  title: 'Avg Ticket Size',
                  value: '₹${avgTicket.toStringAsFixed(0)}',
                  sub: 'per completed order',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xFF00B4DB),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'Fulfillment Rate',
                  value: '${fulfillmentRate.toStringAsFixed(1)}%',
                  sub: 'of $totalOrders total orders',
                  icon: Icons.offline_pin_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _KpiCard(
                  title: 'Total Orders',
                  value: '$totalOrders',
                  sub: 'in selected period',
                  icon: Icons.local_laundry_service_rounded,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Order Volume Chart ─────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Volume (Last 7 Days)',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  height: 160.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: dailyData.map((d) {
                      final label = d['label'] as String;
                      final count = (d['orders'] as num).toInt();
                      final heightFraction =
                          maxOrders > 0 ? count / maxOrders : 0.0;
                      return _BarColumn(
                        label: label,
                        count: count,
                        heightFraction: heightFraction,
                        color: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── Category Revenue Breakdown ─────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Revenue Share',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                if (categoryBreakdown.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: Text(
                        'No delivered orders in this period.',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...List.generate(categoryBreakdown.length, (i) {
                    final cat = categoryBreakdown[i];
                    final name = cat['name'] as String;
                    final revenue =
                        (cat['revenue'] as num).toDouble();
                    final pct = (cat['percentage'] as num).toDouble();
                    final colors = [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.warning,
                      AppColors.electricLavender,
                      AppColors.success,
                    ];
                    return _CategoryRow(
                      name: name,
                      revenue: revenue,
                      percentage: pct,
                      color: colors[i % colors.length],
                    );
                  }),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // ── SLA & Retention ───────────────────────────────────────────────
          _SectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SLA & Customer Retention',
                  style: AppTypography.bodyLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RadialKpi(
                      value: onTimeRate,
                      label: 'On-Time Delivery',
                      color: AppColors.success,
                    ),
                    _RadialKpi(
                      value: repeatRate,
                      label: 'Repeat Customers',
                      color: AppColors.primary,
                    ),
                    _RadialKpi(
                      value: fulfillmentRate,
                      label: 'Fulfillment Rate',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: AppElevation.low,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.r),
              ),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.textBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(title,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold)),
          Text(sub,
              style: TextStyle(
                  color: color, fontSize: 10.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.count,
    required this.heightFraction,
    required this.color,
  });

  final String label;
  final int count;
  final double heightFraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 10.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          width: 20.w,
          height: (heightFraction * 120).h.clamp(4.h, 120.h),
          decoration: BoxDecoration(
            color: count > 0 ? color : AppColors.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
          ),
        ),
        SizedBox(height: 6.h),
        Text(label,
            style: TextStyle(
                fontSize: 10.sp, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.revenue,
    required this.percentage,
    required this.color,
  });

  final String name;
  final double revenue;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
              Text(
                '₹${revenue.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.sp),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 8.h,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialKpi extends StatelessWidget {
  const _RadialKpi({
    required this.value,
    required this.label,
    required this.color,
  });

  final double value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64.r,
              height: 64.r,
              child: CircularProgressIndicator(
                value: (value / 100.0).clamp(0.0, 1.0),
                strokeWidth: 6.r,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
