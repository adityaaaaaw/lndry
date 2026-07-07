import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? AppColors.white : AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Operational Analytics',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats Row cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricSummaryCard(
                    title: 'Fulfillment Rate',
                    value: '98.4%',
                    subText: '+0.5% vs last week',
                    icon: Icons.offline_pin_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildMetricSummaryCard(
                    title: 'Avg Ticket Size',
                    value: '₹345.00',
                    subText: '+₹12.00 vs last month',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Native custom Bar Chart: Order Volume Trends
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Volume (Weekly)',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 160.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar('Mon', 45, AppColors.primary),
                        _buildBar('Tue', 60, AppColors.primary),
                        _buildBar('Wed', 85, AppColors.primary),
                        _buildBar('Thu', 50, AppColors.primary),
                        _buildBar('Fri', 95, AppColors.electricLavender),
                        _buildBar('Sat', 120, AppColors.electricLavender),
                        _buildBar('Sun', 110, AppColors.electricLavender),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Category Distribution breakdown
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Revenue Share',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  _buildCategoryProgressRow('Wash & Iron', 0.45, '₹14,500 (45%)', AppColors.primary),
                  _buildCategoryProgressRow('Dry Cleaning', 0.28, '₹9,020 (28%)', AppColors.secondary),
                  _buildCategoryProgressRow('Steam Ironing', 0.17, '₹5,480 (17%)', AppColors.warning),
                  _buildCategoryProgressRow('Premium care', 0.10, '₹3,220 (10%)', AppColors.electricLavender),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Turnaround / SLA Performance Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.outline.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SLA & Customer Retention',
                    style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRadialRepresentation('94%', 'On-Time Delivery', AppColors.success),
                      _buildRadialRepresentation('82%', 'Repeat Customers', AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
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
              Icon(icon, color: color, size: 24.r),
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          Text(subText, style: TextStyle(color: AppColors.success, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildBar(String day, int count, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        Container(
          width: 16.w,
          height: (count * 1.0).h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
          ),
        ),
        SizedBox(height: 6.h),
        Text(day, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCategoryProgressRow(String category, double pct, String details, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(details, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8.h,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadialRepresentation(String pct, String title, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60.r,
              height: 60.r,
              child: CircularProgressIndicator(
                value: double.parse(pct.replaceAll('%', '')) / 100.0,
                strokeWidth: 6.r,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              pct,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Text(title, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
