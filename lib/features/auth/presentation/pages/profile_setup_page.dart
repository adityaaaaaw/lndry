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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).completeProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
      // Navigation is handled by GoRouter redirect watching authProvider state.
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Saving profile...')
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
                      Text('Setup Your Profile',
                          style: AppTypography.headlineLarge),
                      const Gap(12),
                      Text(
                        'Tell us a bit about yourself to personalise your experience.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const Gap(40),

                      // Avatar with tappable camera icon
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56.r,
                              backgroundColor: AppColors.primaryContainer,
                              child: Icon(AppIcons.profile,
                                  size: 48.r, color: AppColors.primary),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  // TODO(backend): wire image_picker + upload
                                  AppSnackBar.showInfo(
                                    context,
                                    'Photo upload available after backend integration.',
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(AppIcons.camera,
                                      color: AppColors.white, size: 16.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(48),

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
                      AppTextField(
                        label: 'Email Address',
                        hint: 'Enter your email (optional)',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(AppIcons.email),
                        validator: Validators.emailOptional,
                      ),
                      const Gap(48),
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
