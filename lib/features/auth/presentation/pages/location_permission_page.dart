import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../providers/auth_provider.dart';

class LocationPermissionPage extends ConsumerStatefulWidget {
  const LocationPermissionPage({super.key});

  @override
  ConsumerState<LocationPermissionPage> createState() =>
      _LocationPermissionPageState();
}

class _LocationPermissionPageState extends ConsumerState<LocationPermissionPage> {
  bool _isLoading = false;

  void _onGrantPermission() async {
    setState(() => _isLoading = true);
    // Simulate checking system permissions and granting
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() => _isLoading = false);
      AppSnackBar.showSuccess(context, 'Location permission granted.');
      await ref.read(authProvider.notifier).completeLocationSetup();
      if (mounted) {
        context.go(AppRoutes.mapAddress);
      }
    }
  }

  void _onSkip() async {
    // Standard skip setup
    await ref.read(authProvider.notifier).completeLocationSetup();
    if (mounted) {
      context.go(AppRoutes.mapAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePaddingH.w,
            vertical: AppSpacing.pagePaddingV.h,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Location Illustration
              Center(
                child: Container(
                  width: 140.r,
                  height: 140.r,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainerHigh
                        : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.location,
                    size: 64.r,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Gap(48),

              // Title
              Text(
                'Enable Location Services',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const Gap(16),

              // Description
              Text(
                'LNDRY requires access to your location to find the closest laundry vendors and coordinate pickups and deliveries.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),

              // Actions
              AppButton(
                label: 'Allow Location Access',
                isLoading: _isLoading,
                onPressed: _onGrantPermission,
              ),
              const Gap(16),
              AppButton.text(
                label: 'Enter Address Manually',
                onPressed: _onSkip,
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}
