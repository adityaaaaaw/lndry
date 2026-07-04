import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../providers/auth_provider.dart';
import '../../core/design/design_system.dart';
import '../router/app_routes.dart';

typedef PendingAuthAction = FutureOr<void> Function(
  BuildContext context,
  WidgetRef ref,
);

final pendingAuthActionProvider = StateProvider<PendingAuthAction?>((ref) {
  return null;
});

bool isAuthenticated(AuthState state) => state is AuthAuthenticated;

String currentRouteLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.toString();
  } catch (_) {
    return AppRoutes.home;
  }
}

String loginLocation({required String returnTo}) {
  return Uri(
    path: AppRoutes.login,
    queryParameters: returnTo.isEmpty ? null : {'returnTo': returnTo},
  ).toString();
}

String otpLocation({String? returnTo}) {
  return Uri(
    path: AppRoutes.otp,
    queryParameters:
        returnTo == null || returnTo.isEmpty ? null : {'returnTo': returnTo},
  ).toString();
}

String? returnToFrom(BuildContext context) {
  final value = GoRouterState.of(context).uri.queryParameters['returnTo'];
  return value == null || value.isEmpty ? null : value;
}

Future<void> requireAuthenticated({
  required BuildContext context,
  required WidgetRef ref,
  required PendingAuthAction action,
  String? returnTo,
}) async {
  if (isAuthenticated(ref.read(authProvider))) {
    await action(context, ref);
    return;
  }

  // Show polished sign-in prompt before navigating to login
  final shouldProceed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _LoginPromptSheet(),
  );

  if (shouldProceed != true) return;
  if (!context.mounted) return;

  final target = returnTo ?? currentRouteLocation(context);
  ref.read(pendingAuthActionProvider.notifier).state = action;
  context.push(loginLocation(returnTo: target));
}

/// Polished login prompt bottom sheet displayed when a guest tries a protected action.
class _LoginPromptSheet extends StatelessWidget {
  const _LoginPromptSheet();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingH.w,
        vertical: AppSpacing.pagePaddingV.h,
      ),        child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Gap(AppSpacing.lg.h),

              // Icon circle
              Container(
                width: 72.r,
                height: 72.r,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.profile,
                  size: 36.r,
                  color: AppColors.primary,
                ),
              ),
              Gap(AppSpacing.md.h),

              // Title
              Text(
                'Sign in to continue',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Gap(AppSpacing.sm.h),

              // Description
              Text(
                'Create an account to:',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Gap(AppSpacing.md.h),

              // Benefits list
              ...['Book laundry services', 'Save addresses', 'Track orders', 'View invoices']
                  .map((benefit) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.done,
                              size: 18.r,
                              color: AppColors.success,
                            ),
                            Gap(AppSpacing.sm.w),
                            Text(
                              benefit,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark ? AppColors.darkTextBody : AppColors.lightTextBody,
                              ),
                            ),
                          ],
                        ),
                      )),

              Gap(AppSpacing.xl.h),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button.r),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: AppTypography.buttonText.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Gap(AppSpacing.sm.h),

              // Maybe Later button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Maybe Later',
                    style: AppTypography.buttonText.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
              Gap(AppSpacing.md.h),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingAuthActionRunner extends ConsumerStatefulWidget {
  const PendingAuthActionRunner({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PendingAuthActionRunner> createState() =>
      _PendingAuthActionRunnerState();
}

class _PendingAuthActionRunnerState
    extends ConsumerState<PendingAuthActionRunner> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is! AuthAuthenticated) return;

      final action = ref.read(pendingAuthActionProvider);
      if (action == null) return;

      ref.read(pendingAuthActionProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await action(context, ref);
      });
    });

    return widget.child;
  }
}
