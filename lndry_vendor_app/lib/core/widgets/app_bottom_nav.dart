import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../theme/theme.dart';

/// LNDRY reusable bottom navigation item definition.
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.showBadge = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;
  final bool showBadge;
}

/// LNDRY design-system bottom navigation with a raised center Book action.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  final int currentIndex;
  final List<AppBottomNavItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 12.h),
      child: Container(
        height: 72.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.full.r),
          boxShadow: elevation == 0 ? AppElevation.none_ : AppElevation.medium,
          border: Border.all(
            color: AppColors.outline.withOpacity(isDark ? 0.12 : 0.45),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _DesignNavItem(
                  item: items[i],
                  isSelected: currentIndex == i,
                  isCenter: i == items.length ~/ 2,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesignNavItem extends StatelessWidget {
  const _DesignNavItem({
    required this.item,
    required this.isSelected,
    required this.isCenter,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    final iconData = isSelected ? item.selectedIcon : item.icon;
    final icon = Icon(
      isCenter ? AppIcons.add : iconData,
      color: isCenter ? AppColors.white : color,
      size: isCenter ? 28.r : 22.r,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.translate(
        offset: isCenter ? Offset(0, -12.h) : Offset.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppElevation.fabShadow,
                ),
                child: Center(child: icon),
              )
            else if (item.showBadge)
              Badge(
                label: item.badgeCount != null
                    ? Text(item.badgeCount!.toString())
                    : null,
                child: icon,
              )
            else
              icon,
            Gap(isCenter ? 4 : 4),
            Text(
              isCenter ? 'Book' : item.label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
