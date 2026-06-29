import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _onLogout(BuildContext context, WidgetRef ref) async {
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Account Profile', style: AppTypography.titleLarge),
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
              // ── 1. User Header Box ─────────────────────────────────────────
              AppCard.outlined(
                padding: EdgeInsets.all(AppSpacing.md.r),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(AppIcons.profile, size: 32.r, color: AppColors.primary),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest Customer',
                            style: AppTypography.titleMedium,
                          ),
                          Text(
                            user?.email ?? 'laundry.partner@lndry.com',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // ── 2. Order History Shortcut ──────────────────────────────────
              AppCard.outlined(
                borderColor: AppColors.primary.withOpacity(0.3),
                backgroundColor: AppColors.primaryContainer.withOpacity(0.12),
                onTap: () {
                  // Switch to Orders branch Tab 4
                  final navShell = StatefulNavigationShell.of(context);
                  navShell.goBranch(3); // 3 = Orders branch index
                },
                child: Row(
                  children: [
                    Icon(AppIcons.ordersOutlined, color: AppColors.primary, size: 24.r),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('View Order History', style: AppTypography.labelLarge),
                          Text('Track your active orders and history', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Icon(AppIcons.forward, color: AppColors.primary, size: 16.r),
                  ],
                ),
              ),
              const Gap(24),

              Text('Account Details', style: AppTypography.titleMedium),
              const Gap(12),

              // ── 3. Navigation Settings Options list ────────────────────────
              AppCard.outlined(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: AppIcons.profile,
                      label: 'Edit Profile Details',
                      onTap: () => context.go('/profile/edit'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.location,
                      label: 'Saved Delivery Addresses',
                      onTap: () => context.go('/profile/address'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.notificationsOutlined,
                      label: 'Notifications History',
                      onTap: () => context.go('/profile/notifications'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.settings,
                      label: 'Application Settings',
                      onTap: () => context.go('/profile/settings'),
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: AppIcons.info,
                      label: 'Help & FAQ Support',
                      onTap: () => context.go('/profile/help'),
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // ── 4. Logout trigger Button ────────────────────────────────────
              AppButton.outlined(
                label: 'Logout Account',
                icon: const Icon(AppIcons.close, color: AppColors.error),
                foregroundColor: AppColors.error,
                onPressed: () => _onLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap});
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
