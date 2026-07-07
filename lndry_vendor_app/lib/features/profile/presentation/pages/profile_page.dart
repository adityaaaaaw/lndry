import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../models/models.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        await ref.read(authProvider.notifier).updateProfile(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
            );
        setState(() => _isEditing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to log out of your vendor account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vendor = authState.vendor;

    if (_nameController.text.isEmpty) {
      _nameController.text = vendor.name;
    }
    if (_emailController.text.isEmpty && vendor.email != null) {
      _emailController.text = vendor.email!;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        elevation: 0,
        title: Text(
          'My Profile',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  // reset on cancel
                  _nameController.text = vendor.name;
                  _emailController.text = vendor.email ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile Header Card ────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: AppElevation.medium,
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 40.r),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                size: 16.r, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vendor.name,
                        style: AppTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (vendor.isVerified) ...[ 
                        SizedBox(width: 6.w),
                        Icon(Icons.verified_rounded,
                            color: Colors.amber, size: 20.r),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    vendor.phone,
                    style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.amber, size: 18.r),
                      SizedBox(width: 4.w),
                      Text(
                        '${vendor.averageRating?.toStringAsFixed(1) ?? 'N/A'}',
                        style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${vendor.reviewCount} reviews)',
                        style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // ── Edit Form (conditional) ────────────────────────────────────
            if (_isEditing) ...[
              Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: AppColors.outline.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Business Details',
                          style: AppTypography.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Business Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 12.h),
                      TextFormField(
                        initialValue: vendor.phone,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Verified Phone (cannot change)',
                          prefixIcon: Icon(Icons.phone_android_outlined),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // ── Business Info (read-only view) ─────────────────────────────
            if (!_isEditing) ...[
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: vendor.email ?? 'Not set',
                isDark: isDark,
              ),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value:
                    '${vendor.address.line1}, ${vendor.address.city}, ${vendor.address.state} ${vendor.address.pincode}',
                isDark: isDark,
              ),
              if (vendor.description != null && vendor.description!.isNotEmpty)
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: 'Description',
                  value: vendor.description!,
                  isDark: isDark,
                ),
              SizedBox(height: 8.h),
            ],

            // ── Navigation Menu ────────────────────────────────────────────
            _buildSectionHeader('Account', isDark),
            _buildMenuCard([
              _MenuTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'View order alerts and updates',
                onTap: () => context.push(AppRoutes.notifications),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                subtitle: 'App preferences and theme',
                onTap: () => context.push(AppRoutes.settings),
                isDark: isDark,
                isLast: true,
              ),
            ], isDark),
            SizedBox(height: 16.h),

            _buildSectionHeader('Business', isDark),
            _buildMenuCard([
              _MenuTile(
                icon: Icons.category_outlined,
                label: 'Catalogue & Services',
                subtitle: 'Manage your service offerings',
                onTap: () => context.push(AppRoutes.services),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.price_change_outlined,
                label: 'Garment Pricing',
                subtitle: 'Set rates for each garment type',
                onTap: () => context.push(AppRoutes.pricing),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.people_outlined,
                label: 'Staff Management',
                subtitle: 'Add and manage employees',
                onTap: () => context.push(AppRoutes.employees),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.date_range_outlined,
                label: 'Pickup Slots',
                subtitle: 'Manage availability and capacity',
                onTap: () => context.push(AppRoutes.slots),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory & Supplies',
                subtitle: 'Track laundry supplies and stock',
                onTap: () => context.push(AppRoutes.inventory),
                isDark: isDark,
                isLast: true,
              ),
            ], isDark),
            SizedBox(height: 16.h),

            _buildSectionHeader('Support', isDark),
            _buildMenuCard([
              _MenuTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'Get assistance from our partner team',
                onTap: () => context.push(AppRoutes.help),
                isDark: isDark,
              ),
              _MenuTile(
                icon: Icons.info_outline_rounded,
                label: 'About LNDRY',
                subtitle: 'Version 1.0.0 • © 2026 LNDRY Technologies',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'LNDRY Vendor',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        '© 2026 LNDRY Technologies Pvt. Ltd.',
                  );
                },
                isDark: isDark,
                isLast: true,
              ),
            ], isDark),
            SizedBox(height: 24.h),

            // ── Logout ────────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h, top: 4.h),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
            color: AppColors.outline.withValues(alpha: isDark ? 0.05 : 0.2)),
      ),
      child: Column(children: children),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: AppColors.outline.withValues(alpha: isDark ? 0.05 : 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: AppColors.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary)),
                Text(value,
                    style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.white
                            : AppColors.textBlack)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.r),
          ),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  fontSize: 11.sp, color: AppColors.textSecondary)),
          trailing:
              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: onTap,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        ),
        if (!isLast) const Divider(height: 1, indent: 60),
      ],
    );
  }
}
