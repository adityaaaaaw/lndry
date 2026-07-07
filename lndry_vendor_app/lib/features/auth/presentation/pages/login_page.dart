import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String phone) {
    var normalized = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (normalized.startsWith('+91')) {
      normalized = normalized.substring(3);
    } else if (normalized.startsWith('91') && normalized.length == 12) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }

  bool _isValidIndianMobile(String normalized) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(normalized);
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      final normalized = _normalizePhoneNumber(_phoneController.text);
      ref.read(authProvider.notifier).sendOtp(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
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
                    // Brand Icon
                    Center(
                      child: Container(
                        width: 96.r,
                        height: 96.r,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_laundry_service_rounded,
                          size: 48.r,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Headings
                    Text(
                      'Welcome Back',
                      style: AppTypography.headlineLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter your mobile number to manage your laundry operations',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),

                    // Phone Input Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.white : AppColors.textBlack,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        hintText: '98765 43210',
                        prefixIcon: Icon(Icons.phone_android_rounded),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Mobile number is required';
                        }
                        final normalized = _normalizePhoneNumber(value);
                        if (!_isValidIndianMobile(normalized)) {
                          return 'Please enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Submit Button
                    SizedBox(
                      height: 54.h,
                      child: ElevatedButton(
                        onPressed: authState is AuthLoading ? null : _sendOtp,
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
                            : const Text('Get OTP'),
                      ),
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
