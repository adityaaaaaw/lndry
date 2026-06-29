import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();

        await ref.read(authProvider.notifier).completeProfile(
              name: name,
              email: email,
            );

        if (mounted) {
          context.go(AppRoutes.locationPermission);
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Saving profile details...')
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h * 1.5,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(20),
                      Text(
                        'Setup Your Profile',
                        style: AppTypography.headlineLarge,
                      ),
                      const Gap(12),
                      Text(
                        'Please tell us a bit more about yourself to personalize your laundry service.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const Gap(40),

                      // Mock Avatar Picker
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56.r,
                              backgroundColor: AppColors.primaryContainer,
                              child: Icon(
                                AppIcons.profile,
                                size: 48.r,
                                color: AppColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  AppIcons.camera,
                                  color: AppColors.white,
                                  size: 16.r,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(48),

                      // Name Input
                      AppTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        prefixIcon: const Icon(AppIcons.profile),
                        validator: Validators.name,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const Gap(24),

                      // Email Input
                      AppTextField(
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(AppIcons.email),
                        validator: Validators.email,
                      ),
                      const Gap(48),

                      // Submit Button
                      AppButton(
                        label: 'Save & Continue',
                        onPressed: _onSave,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
