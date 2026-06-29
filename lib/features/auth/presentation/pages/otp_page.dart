import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_otp_input.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  String _otpCode = '';
  bool _isLoading = false;
  String? _errorText;
  late int _timerSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _timerSeconds = AppDurations.otpResend.inSeconds;
      _canResend = false;
    });
    _tick();
  }

  void _tick() async {
    while (_timerSeconds > 0 && mounted && !_canResend) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _timerSeconds--;
          if (_timerSeconds == 0) {
            _canResend = true;
          }
        });
      }
    }
  }

  void _onVerify() async {
    if (_otpCode.length != 4) {
      setState(() => _errorText = 'Please enter the 4-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyOtp(_otpCode);
      final authState = ref.read(authProvider);

      if (mounted) {
        if (authState is AuthNeedsProfileSetup) {
          context.go(AppRoutes.profileSetup);
        } else if (authState is AuthNeedsLocationPermission) {
          context.go(AppRoutes.locationPermission);
        } else if (authState is AuthNeedsAddressSelection) {
          context.go(AppRoutes.mapAddress);
        } else if (authState is AuthAuthenticated) {
          context.go(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onResend() async {
    final authState = ref.read(authProvider);
    if (authState is AuthOtpSent) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authProvider.notifier).sendOtp(authState.phone);
        _startResendTimer();
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Verification code sent again (1234).');
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
    final authState = ref.watch(authProvider);
    final phone = authState is AuthOtpSent ? authState.phone : '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingPage(message: 'Verifying code...')
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH.w,
                  vertical: AppSpacing.pagePaddingV.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Gap(20),
                    Text(
                      'Verify Mobile Number',
                      style: AppTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'We have sent a verification code to +91 $phone. Enter the code below.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Use code: 1234',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(48),

                    // Custom OTP Input Component
                    AppOtpInput(
                      length: 4,
                      errorText: _errorText,
                      onChanged: (val) => setState(() {
                        _otpCode = val;
                        _errorText = null;
                      }),
                      onCompleted: (val) {
                        _otpCode = val;
                        _onVerify();
                      },
                    ),
                    const Gap(40),

                    // Timer & Resend Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        if (_canResend)
                          GestureDetector(
                            onTap: _onResend,
                            child: Text(
                              'Resend OTP',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Resend in ${_timerSeconds.toString().padLeft(2, '0')}s',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const Gap(48),

                    // Submit Verification Button
                    AppButton(
                      label: 'Verify & Continue',
                      onPressed: _onVerify,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
