import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).verifyOtp(_otpController.text.trim());
    }
  }

  void _resendOtp(String phone) {
    if (_canResend) {
      ref.read(authProvider.notifier).sendOtp(phone);
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneNum = authState is AuthOtpSent ? authState.phone : '';
    if (authState is AuthOtpSent && authState.devOtp != null && _otpController.text.isEmpty) {
      _otpController.text = authState.devOtp!;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.white : AppColors.textBlack,
            ),
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SMS Icon
                    Center(
                      child: Container(
                        width: 96.r,
                        height: 96.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 48.r,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Headings
                    Text(
                      'Verify Mobile',
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      phoneNum.isNotEmpty
                          ? 'Enter the 6-digit OTP code sent to $phoneNum'
                          : 'Enter the verification code sent to your mobile',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    // OTP Input Field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.textBlack,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'OTP Code',
                        hintText: '123456',
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          letterSpacing: 8,
                        ),
                        prefixIcon: const Icon(Icons.lock_person_rounded),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP code';
                        }
                        if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid 6-digit code';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Verify Button
                    SizedBox(
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: authState is AuthLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg.r),
                          ),
                        ),
                        child: authState is AuthLoading
                            ? SizedBox(
                                width: 24.r,
                                height: 24.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(AppColors.white),
                                ),
                              )
                            : const Text('Verify Code'),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Resend Timer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _canResend ? "Didn't receive code? " : "Resend code in ",
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        _canResend
                            ? TextButton(
                                onPressed: () => _resendOtp(phoneNum),
                                child: Text(
                                  'Resend OTP',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Text(
                                '${_secondsRemaining}s',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),

                    // Error Banner
                    if (authState is AuthError) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                authState.message,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
