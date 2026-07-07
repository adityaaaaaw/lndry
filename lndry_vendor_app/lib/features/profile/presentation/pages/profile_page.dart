import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save details: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final vendor = authState.vendor;
    if (_nameController.text.isEmpty) {
      _nameController.text = vendor.name;
    }
    if (_emailController.text.isEmpty && vendor.email != null) {
      _emailController.text = vendor.email!;
    }

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
          'Shop Profile',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textBlack,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shop Header Info Card
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 36.r),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vendor.name,
                          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (vendor.isVerified) ...[
                          SizedBox(width: 6.w),
                          Icon(Icons.verified_rounded, color: AppColors.primary, size: 20.r),
                        ],
                      ],
                    ),
                    if (vendor.description != null && vendor.description!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        vendor.description!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 18.r),
                        SizedBox(width: 4.w),
                        Text(
                          vendor.averageRating?.toStringAsFixed(1) ?? 'N/A',
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(' (${vendor.reviewCount} reviews)', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Shop Form fields
              Text('Contact & General details', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop / Business Name',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12.h),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Business Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12.h),

                    // Non editable Phone
                    TextFormField(
                      initialValue: vendor.phone,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Verified Business Phone',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Owner Name
                    TextFormField(
                      initialValue: vendor.ownerName,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name (Linked)',
                        prefixIcon: Icon(Icons.person_pin_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Shop Address Card
              Text('Shop Address Location', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
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
                    Text(vendor.address.line1, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    if (vendor.address.line2 != null && vendor.address.line2!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(vendor.address.line2!, style: AppTypography.bodyMedium),
                    ],
                    SizedBox(height: 4.h),
                    Text(
                      '${vendor.address.city}, ${vendor.address.state} - ${vendor.address.pincode}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28.h),

              // Save Changes Action
              ElevatedButton(
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
                        child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                      )
                    : const Text('Save Profile Changes'),
              ),
              SizedBox(height: 12.h),

              // Logout Action
              OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout Session'),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
