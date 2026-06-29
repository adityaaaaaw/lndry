import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/theme.dart';

/// LNDRY Reusable Bottom Navigation Item Definition
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

/// LNDRY Material 3 Reusable Bottom Navigation Bar
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: backgroundColor ??
          (isDark ? AppColors.darkSurface : AppColors.surface),
      elevation: elevation ?? 0,
      shadowColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      indicatorColor: isDark ? AppColors.primaryDark : AppColors.primaryContainer,
      destinations: items.map((item) {
        final iconWidget = Icon(
          currentIndex == items.indexOf(item) ? item.selectedIcon : item.icon,
          size: 24.r,
        );

        Widget finalIcon = iconWidget;

        if (item.showBadge) {
          finalIcon = Badge(
            label: item.badgeCount != null ? Text(item.badgeCount!.toString()) : null,
            child: iconWidget,
          );
        }

        return NavigationDestination(
          icon: finalIcon,
          label: item.label,
        );
      }).toList(),
    );
  }
}
