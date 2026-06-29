import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final phone = _phoneController.text.trim();
        await ref.read(authProvider.notifier).sendOtp(phone);
        if (mounted) {
          context.go(AppRoutes.otp);
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
            ? const AppLoadingPage(message: 'Sending verification code...')
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h * 2,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(40),
                      // Centered Brand Logo
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                          ),
                          child: Icon(
                            AppIcons.laundry,
                            color: AppColors.primary,
                            size: 40.r,
                          ),
                        ),
                      ),
                      const Gap(24),
                      Text(
                        'Welcome to Lndry',
                        style: AppTypography.headlineLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        'Enter your mobile number to continue',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(48),

                      // Input Form Field
                      AppTextField(
                        label: 'Mobile Number',
                        hint: 'Enter 10-digit number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixText: '+91 ',
                        prefixIcon: const Icon(AppIcons.phone),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: Validators.phone,
                      ),
                      const Gap(32),

                      // Submit Button
                      AppButton(
                        label: 'Send OTP',
                        onPressed: _onSendOtp,
                      ),
                      const Gap(32),

                      // Social Connect Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: AppTypography.caption,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const Gap(24),
                      Row(
                        children: [
                          // Custom polished Google button
                          Expanded(
                            child: AppButton.outlined(
                              label: 'Google',
                              icon: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                  width: 16.r,
                                  height: 16.r,
                                  errorBuilder: (_, __, ___) => Text(
                                    'G',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await ref.read(authProvider.notifier).signInWithGoogle();
                                  final authState = ref.read(authProvider);
                                  if (authState is AuthError && mounted) {
                                    AppSnackBar.showError(context, authState.message);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppSnackBar.showError(context, e.toString());
                                  }
                                }
                              },
                            ),
                          ),
                          const Gap(16),
                          // Custom polished Apple button
                          Expanded(
                            child: AppButton.outlined(
                              label: 'Apple',
                              icon: Icon(
                                Icons.apple,
                                size: 22.r,
                                color: isDark ? AppColors.white : AppColors.black,
                              ),
                              onPressed: () => AppSnackBar.showInfo(
                                context,
                                'Apple login simulated.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
