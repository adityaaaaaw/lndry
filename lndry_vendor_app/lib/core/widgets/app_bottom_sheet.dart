import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../theme/theme.dart';
import 'app_button.dart';

/// LNDRY Reusable Bottom Sheet modal templates.
/// Features a premium easeOutBack spring animation on entry.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final Widget child;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool isScrollControlled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: isDark ? AppColors.darkSurfaceContainer : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet.r),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _SpringSlideUpTransition(
          child: AppBottomSheet(
            title: title,
            primaryActionLabel: primaryActionLabel,
            onPrimaryAction: onPrimaryAction,
            secondaryActionLabel: secondaryActionLabel,
            onSecondaryAction: onSecondaryAction,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePaddingH.w,
          vertical: AppSpacing.pagePaddingV.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Gap(16),

            // Content Child
            Flexible(child: child),
            const Gap(24),

            // Action Buttons
            if (primaryActionLabel != null) ...[
              AppButton(
                label: primaryActionLabel!,
                onPressed: onPrimaryAction ?? () => Navigator.of(context).pop(),
              ),
              const Gap(12),
            ],
            if (secondaryActionLabel != null) ...[
              AppButton.outlined(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpringSlideUpTransition extends StatefulWidget {
  final Widget child;
  const _SpringSlideUpTransition({required this.child});

  @override
  State<_SpringSlideUpTransition> createState() => _SpringSlideUpTransitionState();
}

class _SpringSlideUpTransitionState extends State<_SpringSlideUpTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}
