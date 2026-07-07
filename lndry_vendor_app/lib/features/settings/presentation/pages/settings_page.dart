import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushNotifications = true;
  bool _soundAlerts = true;
  bool _autoAcceptOrders = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.white : AppColors.textBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          // ── Appearance ───────────────────────────────────────────────────
          _buildSectionHeader('Appearance'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('Switch between light and dark interface'),
              value: themeMode == ThemeMode.dark,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).setThemeMode(
                      val ? ThemeMode.dark : ThemeMode.light,
                    );
              },
              activeColor: AppColors.primary,
              secondary: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: AppColors.primary,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.palette_outlined,
                  color: AppColors.primary),
              title: const Text('Use System Theme',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Follow device light/dark setting'),
              trailing: themeMode == ThemeMode.system
                  ? Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20.r)
                  : null,
              onTap: () {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Using system theme')),
                );
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // ── Notifications ─────────────────────────────────────────────────
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Push Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('Alerts for new orders, payouts & updates'),
              value: _pushNotifications,
              onChanged: (val) =>
                  setState(() => _pushNotifications = val),
              activeColor: AppColors.primary,
              secondary: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Sound Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('Play sound on new order arrival'),
              value: _soundAlerts,
              onChanged: (val) => setState(() => _soundAlerts = val),
              activeColor: AppColors.primary,
              secondary: const Icon(Icons.volume_up_outlined,
                  color: AppColors.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // ── Operations ────────────────────────────────────────────────────
          _buildSectionHeader('Operations'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Auto-Accept Orders',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text(
                  'Automatically accept orders when capacity is available'),
              value: _autoAcceptOrders,
              onChanged: (val) =>
                  setState(() => _autoAcceptOrders = val),
              activeColor: AppColors.primary,
              secondary: const Icon(Icons.auto_awesome_outlined,
                  color: AppColors.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // ── Support & Legal ───────────────────────────────────────────────
          _buildSectionHeader('Support & Legal'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.help_outline_rounded,
                  color: AppColors.primary),
              title: const Text('Partner Helpdesk',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Get support from the LNDRY partner team'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Connecting to partner helpdesk…')),
                );
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.primary),
              title: const Text('Terms of Service & SLA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Opening Terms of Service…')),
                );
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.security_outlined,
                  color: AppColors.primary),
              title: const Text('Privacy Policy',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Opening Privacy Policy…')),
                );
              },
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 32.h),

          Center(
            child: Text(
              'LNDRY Vendor App • Version 1.0.0\n© 2026 LNDRY Technologies Pvt. Ltd.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: AppColors.outline.withValues(alpha: isDark ? 0.05 : 0.2),
        ),
      ),
      child: Column(children: children),
    );
  }
}
