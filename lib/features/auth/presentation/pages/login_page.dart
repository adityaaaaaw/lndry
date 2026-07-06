import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/validators.dart';
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

  Future<void> _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      await ref.read(authProvider.notifier).sendOtp(phone);
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is AuthError) {
        AppSnackBar.showError(context, authState.message);
        return;
      }
      if (authState is AuthOtpSent) {
        context.push(otpLocation(returnTo: returnToFrom(context)));
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Sending verification code...')
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(40),

                      // Brand Logo
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 40.r,
                            height: 40.r,
                            fit: BoxFit.contain,
                            semanticLabel: 'LNDRY logo',
                          ),
                        ),
                      ),
                      const Gap(24),

                      Text(
                        'Welcome to LNDRY',
                        style: AppTypography.headlineLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(8),
                      Text(
                        'Enter your mobile number to get started',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(48),

                      // Phone input
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

                      AppButton(
                        label: 'Send OTP',
                        onPressed: _onSendOtp,
                      ),
                      const Gap(32),

                      // Terms notice
                      Text(
                        'By continuing, you agree to LNDRY\'s Terms of Service and Privacy Policy.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
