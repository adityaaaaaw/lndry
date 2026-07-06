import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_otp_input.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/constants/app_constants.dart';
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
  int _timerSeconds = 0;
  bool _canResend = false;
  Timer? _resendTimer;

  // Cached values from the OtpSent state so we can restore after an error.
  String _cachedPhone = '';
  String _cachedChallengeId = '';
  String? _cachedDevOtp;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _timerSeconds = 30;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timerSeconds--;
        if (_timerSeconds <= 0) {
          _timerSeconds = 0;
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _onVerify() async {
    if (_otpCode.length < 4) {
      setState(
          () => _errorText = 'Please enter the complete verification code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await ref.read(authProvider.notifier).verifyOtp(_otpCode);

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState is AuthError) {
      // Show error in-place; restore OtpSent so user can retry.
      setState(() {
        _isLoading = false;
        _errorText = authState.message;
      });
      // Restore OTP state so the user doesn't get stuck.
      ref.read(authProvider.notifier).restoreOtpState(
            _cachedPhone,
            _cachedChallengeId,
            devOtp: _cachedDevOtp,
          );
    } else {
      setState(() => _isLoading = false);
      if (authState is AuthNeedsProfileSetup) {
        context.push(AppRoutes.profileSetup);
      } else if (authState is AuthNeedsLocationPermission) {
        context.push(AppRoutes.locationPermission);
      } else if (authState is AuthNeedsAddressSelection) {
        context.push(AppRoutes.mapAddress);
      }
    }
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    final authState = ref.read(authProvider);
    if (authState is! AuthOtpSent) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(authState.phone);
      _startResendTimer();
      if (mounted)
        AppSnackBar.showSuccess(
            context, 'A new verification code has been sent.');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Cache phone/challengeId for error recovery.
    if (authState is AuthOtpSent) {
      _cachedPhone = authState.phone;
      _cachedChallengeId = authState.challengeId;
      _cachedDevOtp = authState.devOtp;
    }

    final phone = _cachedPhone;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          onPressed: () {
            // Cancel OTP flow and return to login.
            ref.read(authProvider.notifier).clearError();
            if (context.mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(loginLocation(
                  returnTo: returnToFrom(context) ?? AppRoutes.home,
                ));
              }
            }
          },
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
                      phone.isNotEmpty
                          ? 'We have sent a verification code to +91 $phone.'
                          : 'Enter the verification code sent to your number.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const Gap(48),

                    AppOtpInput(
                      length: AppConstants.otpLength,
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

                    // Resend row
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
