import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/repositories.dart';

final _profileStatsProvider = FutureProvider<UserStats>((ref) async {
  return ref.watch(customerRepositoryProvider).getUserStats();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await AppDialog.show(
      context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to sign out of your LNDRY account?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final signedIn = authState is AuthAuthenticated;
    final user = ref.watch(currentUserProvider);
    final statsAsync = signedIn ? ref.watch(_profileStatsProvider) : null;

    // Build initials for avatar fallback.
    final displayName = user?.name ?? '';
    final initials = displayName.trim().isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : 'G';

    final userPhone = user?.phone ?? '';
    final emailOrPhone = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : userPhone.isNotEmpty
            ? '+91 $userPhone'
            : 'Sign in to manage bookings and account details';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Account', style: AppTypography.titleLarge),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH.w,
            vertical: AppSpacing.pagePaddingV.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── User Header ─────────────────────────────────────────────────
              AppCard.outlined(
                padding: EdgeInsets.all(AppSpacing.md.r),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: (user?.avatarUrl != null &&
                              user!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child:
                          (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                              ? Text(
                                  initials,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                    ),
                    SizedBox(width: AppSpacing.cardGap.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.isNotEmpty ? displayName : 'Guest',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Gap(AppSpacing.xs.h),
                          Text(
                            emailOrPhone,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Gap(AppSpacing.md.h),

              // ── Stats or Guest card ───────────────────────────────────────
              if (statsAsync != null)
                statsAsync.when(
                  data: (stats) => AppCard.outlined(
                    padding: EdgeInsets.all(AppSpacing.md.r),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: 'Orders',
                            value: stats.totalOrders.toString(),
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Spent',
                            value: stats.totalSpent.toCurrencyDecimal,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            label: 'Points',
                            value: stats.loyaltyPoints.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const AppSkeletonCard(height: 72),
                  error: (_, __) => const SizedBox.shrink(),
                )
              else
                AppCard.outlined(
                  padding: EdgeInsets.all(AppSpacing.md.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Browsing as guest',
                          style: AppTypography.labelLarge),
                      Gap(AppSpacing.md.h),
                      Text(
                        'Sign in when you are ready to book, save addresses, or view orders.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              Gap(AppSpacing.md.h),

              // ── Orders shortcut ──────────────────────────────────────────────
              AppCard.outlined(
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.12),
                onTap: () => requireAuthenticated(
                  context: context,
                  ref: ref,
                  returnTo: AppRoutes.orders,
                  action: (context, _) {
                    final navShell = StatefulNavigationShell.of(context);
                    navShell.goBranch(3);
                  },
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.ordersOutlined,
                        color: AppColors.primary, size: 24.r),
                    SizedBox(width: AppSpacing.cardGap.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('View Order History',
                              style: AppTypography.labelLarge),
                          Text('Track active orders and history',
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Icon(AppIcons.forward,
                        color: AppColors.primary, size: 16.r),
                  ],
                ),
              ),
              Gap(AppSpacing.sectionGap.h),

              Text('Account Details', style: AppTypography.titleMedium),
              Gap(AppSpacing.cardGap.h),

              // ── Menu tiles ─────────────────────────────────────────────────
              AppCard.outlined(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: AppIcons.profile,
                      label: 'Edit Profile',
                      onTap: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: AppRoutes.editProfile,
                        action: (context, _) =>
                            context.push(AppRoutes.editProfile),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outline),
                    _SettingsTile(
                      icon: AppIcons.location,
                      label: 'Saved Addresses',
                      onTap: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: AppRoutes.address,
                        action: (context, _) => context.push(AppRoutes.address),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outline),
                    _SettingsTile(
                      icon: AppIcons.notificationsOutlined,
                      label: 'Notifications',
                      onTap: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: AppRoutes.notifications,
                        action: (context, _) =>
                            context.push(AppRoutes.notifications),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outline),
                    _SettingsTile(
                      icon: Icons.star_border_rounded,
                      label: 'My Reviews',
                      onTap: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: AppRoutes.myReviews,
                        action: (context, _) =>
                            context.push(AppRoutes.myReviews),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outline),
                    _SettingsTile(
                      icon: AppIcons.settings,
                      label: 'Settings',
                      onTap: () => requireAuthenticated(
                        context: context,
                        ref: ref,
                        returnTo: AppRoutes.settings,
                        action: (context, _) =>
                            context.push(AppRoutes.settings),
                      ),
                    ),
                    Divider(height: 1, color: AppColors.outline),
                    _SettingsTile(
                      icon: AppIcons.info,
                      label: 'Help & Support',
                      onTap: () => context.push(AppRoutes.help),
                    ),
                  ],
                ),
              ),
              Gap(AppSpacing.sectionGap.h * 1.5),

              signedIn
                  ? AppButton.outlined(
                      label: 'Sign Out',
                      icon: const Icon(AppIcons.close, color: AppColors.error),
                      foregroundColor: AppColors.error,
                      onPressed: () => _onLogout(context, ref),
                    )
                  : AppButton(
                      label: 'Sign In',
                      onPressed: () => context.push(loginLocation(
                        returnTo: AppRoutes.profile,
                      )),
                    ),
              Gap(AppSpacing.sectionGap.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap(AppSpacing.xs.h),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 20.r),
      title: Text(label, style: AppTypography.bodyMedium),
      trailing: Icon(AppIcons.forward, color: AppColors.outline, size: 14.r),
      onTap: onTap,
    );
  }
}
