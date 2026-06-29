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
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Loading updates...')
            : _notifications.isEmpty
                ? const AppEmptyState(
                    icon: AppIcons.notificationsOutlined,
                    title: 'All Caught Up!',
                    subtitle: 'You don\'t have any new laundry order updates or coupon notices currently.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _loadNotifications(),
                    child: ListView.separated(
                      padding: EdgeInsets.all(AppSpacing.pagePaddingH.w),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemBuilder: (context, idx) {
                        final notif = _notifications[idx];

                        return AppCard.outlined(
                          onTap: () {
                            if (!notif.isRead) _onMarkAsRead(notif);
                          },
                          borderColor: notif.isRead ? AppColors.outline : AppColors.primary.withOpacity(0.3),
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
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  AppIcons.notificationsOutlined,
                                  color: notif.isRead ? AppColors.onSurfaceVariant : AppColors.primary,
                                  size: 18.r,
                                ),
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif.title,
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
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
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
