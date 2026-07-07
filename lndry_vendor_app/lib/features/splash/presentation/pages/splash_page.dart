import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/design/design_system.dart';
import '../../../../providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500)).then((_) {
      if (mounted) {
        setState(() {
          _timerDone = true;
        });
        _checkNavigation();
      }
    });
  }

  void _checkNavigation() {
    if (!_timerDone) return;
    final state = ref.read(authProvider);
    if (state is AuthAuthenticated) {
      context.go(AppRoutes.dashboard);
    } else if (state is AuthUnauthenticated || state is AuthError) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to navigate as soon as initialization completes
    ref.listen<AuthState>(authProvider, (previous, next) {
      _checkNavigation();
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(32.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_laundry_service_rounded,
                  size: 64.r,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'LNDRY Vendor',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Partner Portal',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 64.h),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
