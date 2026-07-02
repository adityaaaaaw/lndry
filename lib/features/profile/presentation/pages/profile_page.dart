import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

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
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);

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
        : '?';

    // Email: show verified phone if no email, never fallback to vendor address.
    final userPhone = user?.phone ?? '';
    final emailOrPhone = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : userPhone.isNotEmpty
            ? '+91 $userPhone'
            : 'No contact info';

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
                    // Avatar: show photo URL when available, else initials.
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.primaryContainer,
                      backgroundImage: (user?.avatarUrl != null &&
                              user!.avatarUrl!.isNotEmpty)
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user?.avatarUrl == null ||
                              user!.avatarUrl!.isEmpty)
                          ? Text(
                              initials,
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const Gap(16),
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
                          const Gap(2),
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
              const Gap(16),

              // ── Orders shortcut ──────────────────────────────────────────────
              AppCard.outlined(
                borderColor: AppColors.primary.withOpacity(0.3),
                backgroundColor: AppColors.primaryContainer.withOpacity(0.12),
                onTap: () {
                  final navShell = StatefulNavigationShell.of(context);
                  navShell.goBranch(3);
                },
                child: Row(
                  children: [
                    Icon(AppIcons.ordersOutlined,
                        color: AppColors.primary, size: 24.r),
                    const Gap(16),
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
              const Gap(24),

              Text('Account Details', style: AppTypography.titleMedium),
              const Gap(12),

              AppCard.outlined(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: AppIcons.profile,
                      label: 'Edit Profile',
                      onTap: () => context.push(AppRoutes.editProfile),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.location,
                      label: 'Saved Addresses',
                      onTap: () => context.push(AppRoutes.address),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.notificationsOutlined,
                      label: 'Notifications',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.settings,
                      label: 'Settings',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.info,
                      label: 'Help & Support',
                      onTap: () => context.push(AppRoutes.help),
                    ),
                  ],
                ),
              ),
              const Gap(32),

              AppButton.outlined(
                label: 'Sign Out',
                icon: const Icon(AppIcons.close, color: AppColors.error),
                foregroundColor: AppColors.error,
                onPressed: () => _onLogout(context, ref),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
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
      leading:
          Icon(icon, color: AppColors.onSurfaceVariant, size: 20.r),
      title: Text(label, style: AppTypography.bodyMedium),
      trailing:
          Icon(AppIcons.forward, color: AppColors.outline, size: 14.r),
      onTap: onTap,
    );
  }
}
