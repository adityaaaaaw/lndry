import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/storage_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<_OnboardingItem> _slides = const [
    _OnboardingItem(
      icon: AppIcons.laundry,
      title: 'Easy Scheduling',
      description: 'Book your laundry pickup with just a few taps. Choose slots that fit your daily schedule.',
    ),
    _OnboardingItem(
      icon: AppIcons.dry,
      title: 'Premium Garment Care',
      description: 'Your clothes are treated by certified vendors using premium care detergents and dry cleans.',
    ),
    _OnboardingItem(
      icon: AppIcons.delivery,
      title: 'Super-Fast Delivery',
      description: 'Fresh, clean, and neatly ironed clothes delivered straight to your doorstep within 24 hours.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.normal,
        curve: AppCurves.standard,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveBool(AppConstants.keyOnboardingDone, value: true);
    if (mounted) {
      context.go(AppRoutes.login);
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
            children: [
              // Header Skip Button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              // Page Slider
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium Animated Illustration
                          _OnboardingIllustration(
                            icon: slide.icon,
                            index: index,
                            currentIndex: _currentIndex,
                          ),
                          const Gap(48),
                          Text(
                            slide.title,
                            style: AppTypography.headlineLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textBlack,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Gap(16),
                          Text(
                            slide.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Footer: Indicators & CTA Button
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: AppDurations.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.full.r),
                        ),
                      ),
                    ),
                  ),
                  const Gap(40),
                  AppButton(
                    label: _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                    onPressed: _onNext,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

// ── Layered Animated Onboarding Illustration Widget ─────────────────────────

class _OnboardingIllustration extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;

  const _OnboardingIllustration({
    required this.icon,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(seconds: 4),
        builder: (context, floatVal, child) {
          // Continuous floating animation
          final double floatOffset = 6 * (floatVal - 0.5).abs();
          return Transform.translate(
            offset: Offset(0, -floatOffset),
            child: child,
          );
        },
        child: Container(
          width: 200.r,
          height: 200.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryContainer, Color(0xFFF3E8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating decorative ring
              Container(
                width: 170.r,
                height: 170.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 84.r,
                color: AppColors.primary,
              ),
              // Sparkles overlay for premium care
              if (icon == AppIcons.dry)
                Positioned(
                  top: 24.h,
                  right: 24.w,
                  child: Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 24.r),
                ),
              // Location marker overlay for super-fast delivery
              if (icon == AppIcons.delivery)
                Positioned(
                  bottom: 24.h,
                  right: 24.w,
                  child: Icon(AppIcons.location, color: AppColors.secondary, size: 24.r),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
