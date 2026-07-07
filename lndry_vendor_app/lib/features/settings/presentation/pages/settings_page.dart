import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _soundAlerts = true;
  bool _autoAcceptOrders = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _darkMode = isDark;

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
          // Notifications Settings
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Get alerts for new incoming orders & chat'),
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Sound Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Play sound on new laundry order arrival'),
              value: _soundAlerts,
              onChanged: (val) => setState(() => _soundAlerts = val),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // Operations Settings
          _buildSectionHeader('Operations'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Auto Accept Orders', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Automatically accept new orders if capacity exists'),
              value: _autoAcceptOrders,
              onChanged: (val) => setState(() => _autoAcceptOrders = val),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // Display Preferences Settings
          _buildSectionHeader('Preferences'),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text('Dark Mode Display', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Toggle between light and dark backgrounds'),
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
                // System notification of theme toggling
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme preference updated in settings')),
                );
              },
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
          ], isDark),
          SizedBox(height: 24.h),

          // Support & Info Settings
          _buildSectionHeader('Support & Legal'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              title: const Text('Partner Support Helpdesk', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to partner helpdesk...')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.primary),
              title: const Text('Terms of Service & SLA', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {},
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.security_outlined, color: AppColors.primary),
              title: const Text('Privacy Policy Statement', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {},
            ),
          ], isDark),
          SizedBox(height: 32.h),

          // App version info footer
          Center(
            child: Text(
              'LNDRY Vendor App • Version 1.0.0-build.382\n© 2026 LNDRY Technologies Pvt. Ltd.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
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
      padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
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
          color: AppColors.outline.withOpacity(isDark ? 0.05 : 0.2),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
