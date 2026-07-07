import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// LNDRY Reusable AppBar conforming to production Material 3 guidelines.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.bottom,
    this.onBackPress,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTypography.titleLarge.copyWith(
                    color: foregroundColor ??
                        (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.darkSurface : AppColors.surface),
      foregroundColor: foregroundColor ??
          (isDark ? AppColors.darkOnSurface : AppColors.onSurface),
      elevation: elevation ?? 0,
      scrolledUnderElevation: 1.r,
      shadowColor: AppColors.shadow.withOpacity(0.08),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: AppColors.transparent,
              statusBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: AppColors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
      leading: showBackButton && Navigator.of(context).canPop()
          ? IconButton(
              icon: Icon(
                AppIcons.back,
                size: 20.r,
              ),
              onPressed: onBackPress ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
