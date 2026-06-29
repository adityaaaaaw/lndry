import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// LNDRY Reusable Search Bar
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search for laundry, dry clean...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.input.r),
        boxShadow: AppElevation.low,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.inputText,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.inputHint,
          prefixIcon: Icon(
            AppIcons.search,
            size: 20.r,
            color: AppColors.onSurfaceVariant,
          ),
          suffixIcon: onFilterTap != null
              ? IconButton(
                  icon: Icon(
                    AppIcons.filter,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  onPressed: onFilterTap,
                )
              : null,
          filled: true,
          fillColor: AppColors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
          ),
        ),
      ),
    );
  }
}
