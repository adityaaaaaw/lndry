import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../models/models.dart';
import '../../../../repositories/repositories.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    setState(() => _isLoading = true);
    final repo = ref.read(customerRepositoryProvider);
    try {
      final list = await repo.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMarkAsRead(NotificationModel notification) async {
    final repo = ref.read(customerRepositoryProvider);
    try {
      await repo.markNotificationRead(notification.id);
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final repo = ref.read(customerRepositoryProvider);
    try {
      await repo.markAllNotificationsRead();
      _loadNotifications();
      if (mounted) AppSnackBar.showSuccess(context, 'All notifications read.');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final repo = ref.read(customerRepositoryProvider);
    final previous = List<NotificationModel>.of(_notifications);
    setState(() {
      _notifications.removeWhere((item) => item.id == notification.id);
    });
    try {
      await repo.deleteNotification(notification.id);
    } catch (e) {
      if (mounted) {
        setState(() => _notifications = previous);
        AppSnackBar.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.titleLarge),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        actions: [
          if (_notifications.any((item) => !item.isRead))
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Loading updates...')
            : _notifications.isEmpty
                ? const AppEmptyState(
                    icon: AppIcons.notificationsOutlined,
                    title: 'All Caught Up!',
                    subtitle:
                        'You don\'t have any new laundry order updates or coupon notices currently.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadNotifications(),
                    child: ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, idx) {
                        final notif = _notifications[idx];

                        return Dismissible(
                          key: ValueKey(notif.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card.r),
                            ),
                            child: const Icon(
                              AppIcons.delete,
                              color: AppColors.error,
                            ),
                          ),
                          onDismissed: (_) => _deleteNotification(notif),
                          child: AppCard.outlined(
                            onTap: () {
                              if (!notif.isRead) _onMarkAsRead(notif);
                              if (notif.deepLink != null &&
                                  notif.deepLink!.isNotEmpty) {
                                context.push(notif.deepLink!);
                              }
                            },
                            borderColor: notif.isRead
                                ? AppColors.outline
                                : AppColors.primary.withOpacity(0.3),
                            backgroundColor: notif.isRead
                                ? AppColors.transparent
                                : AppColors.primaryContainer.withOpacity(0.08),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: notif.isRead
                                        ? theme
                                            .colorScheme.surfaceContainerHighest
                                        : AppColors.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    AppIcons.notificationsOutlined,
                                    color: notif.isRead
                                        ? AppColors.onSurfaceVariant
                                        : AppColors.primary,
                                    size: 18.r,
                                  ),
                                ),
                                const Gap(16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                          fontWeight: notif.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      const Gap(4),
                                      Text(
                                        notif.body,
                                        style: AppTypography.bodySmall,
                                      ),
                                      const Gap(8),
                                      Text(
                                        notif.createdAt.timeAgo,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(AppIcons.delete),
                                  onPressed: () => _deleteNotification(notif),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
