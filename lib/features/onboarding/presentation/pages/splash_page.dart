import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Guards against navigating before the animation finishes AND auth resolves.
  bool _minDelayDone = false;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: AppDurations.splash,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: AppCurves.spring),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: AppCurves.standard),
    );
    _logoController.forward();

    // Minimum display time so the splash doesn't flash.
    Future.delayed(AppDurations.splash, () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  /// Called both when the min-delay fires and when auth state updates.
  /// Only navigates once both conditions are satisfied.
  void _tryNavigate() {
    if (!mounted || _navigationTriggered) return;
    if (!_minDelayDone) return;

    final authState = ref.read(authProvider);

    // Still initialising — wait for the next state change (listener below).
    if (authState is AuthInitial || authState is AuthLoading) return;

    _navigationTriggered = true;

    final storage = ref.read(storageServiceProvider);
    final onboardingDone =
        storage.getBool(AppConstants.keyOnboardingDone) ?? false;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // GoRouter redirect handles the exact destination based on auth state.
    // We only need to leave the splash route; the router picks the rest.
    switch (authState) {
      case AuthAuthenticated():
        context.go(AppRoutes.home);
      case AuthNeedsProfileSetup():
        context.go(AppRoutes.profileSetup);
      case AuthNeedsLocationPermission():
        context.go(AppRoutes.locationPermission);
      case AuthNeedsAddressSelection():
        context.go(AppRoutes.mapAddress);
      default:
        context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes so we navigate as soon as both
    // the minimum delay AND auth resolution are done.
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is! AuthInitial && next is! AuthLoading) {
        _tryNavigate();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.splashGradient,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: child,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                          BorderRadius.circular(AppRadius.xxl.r),
                      boxShadow: AppElevation.high,
                    ),
                    child: Center(
                      child: Icon(
                        AppIcons.laundry,
                        color: AppColors.primary,
                        size: 48.r,
                      ),
                    ),
                  ),
                  const Gap(24),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    AppConstants.appTagline,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: AppSpacing.xxxl.h * 1.5,
              child: const AppLoadingIndicator(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
