import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';

class NotificationRecord {
  NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final String type; // order, payment, system
  bool isRead;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationRecord> _notifications = [
    NotificationRecord(
      id: '1',
      title: 'New Order Received',
      body: 'Order #ORD-F8E39 is waiting for your confirmation.',
      time: '2 mins ago',
      type: 'order',
    ),
    NotificationRecord(
      id: '2',
      title: 'Pickup Partner Assigned',
      body: 'Rider Rajesh is going for pickup of order #ORD-D72E1.',
      time: '15 mins ago',
      type: 'order',
      isRead: true,
    ),
    NotificationRecord(
      id: '3',
      title: 'Payment Reconciled',
      body: 'Payout of ₹3,420.00 has been credited to your bank account.',
      time: '3 hours ago',
      type: 'payment',
      isRead: true,
    ),
    NotificationRecord(
      id: '4',
      title: 'System Maintenance',
      body: 'Partner Portal APIs will be offline for 30 minutes at midnight.',
      time: '1 day ago',
      type: 'system',
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
          'Notifications',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64.r,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Notifications Yet',
                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Operational push updates and payouts alerts will appear here.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(16.r),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, idx) {
                final item = _notifications[idx];
                final iconBg = item.type == 'order'
                    ? AppColors.primaryContainer
                    : (item.type == 'payment' ? AppColors.successContainer : Color(0xFFFFECEE));
                final iconColor = item.type == 'order'
                    ? AppColors.primary
                    : (item.type == 'payment' ? AppColors.success : AppColors.error);
                final icon = item.type == 'order'
                    ? Icons.local_laundry_service_rounded
                    : (item.type == 'payment' ? Icons.account_balance_wallet_rounded : Icons.info_rounded);

                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeNotification(item.id),
                  child: Card(
                    elevation: 0,
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(
                        color: AppColors.outline.withOpacity(isDark ? 0.05 : 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14.r),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 22.r),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.title,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                        color: isDark ? AppColors.white : AppColors.textBlack,
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8.r,
                                        height: 8.r,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  item.body,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
