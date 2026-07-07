import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_system.dart';
import '../../providers/auth_provider.dart';

// ── Page imports ──────────────────────────────────────────────────────────────

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/services/presentation/pages/services_page.dart';
import '../../features/pricing/presentation/pages/pricing_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/employees/presentation/pages/employees_page.dart';
import '../../features/slots/presentation/pages/slots_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

// ── Custom Transitions ────────────────────────────────────────────────────────

CustomTransitionPage<T> _slideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.pageRoute,
      reverseTransitionDuration: AppDurations.pageRoute,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: animation, curve: AppCurves.decelerate)),
        child: child,
      ),
    );

CustomTransitionPage<T> _fadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.pageRoute,
      reverseTransitionDuration: AppDurations.pageRoute,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: AppCurves.standard),
        child: child,
      ),
    );

// ── Vendor Router Provider ─────────────────────────────────────────────────────

final vendorRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref
    ..onDispose(refreshListenable.dispose)
    ..listen<AuthState>(authProvider, (_, __) {
      refreshListenable.value++;
    });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    redirect: (context, state) =>
        _vendorRedirect(context, state, ref.read(authProvider)),
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
    routes: _vendorRoutes,
  );
});

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

// ── Vendor-specific redirect (auth guard) ─────────────────────────────────────

String? _vendorRedirect(
  BuildContext context,
  GoRouterState state,
  AuthState authState,
) {
  final path = state.uri.path;
  final returnTo = state.uri.queryParameters['returnTo'];

  const protectedPaths = [
    AppRoutes.dashboard,
    AppRoutes.orders,
    AppRoutes.services,
    AppRoutes.pricing,
    AppRoutes.inventory,
    AppRoutes.employees,
    AppRoutes.slots,
    AppRoutes.analytics,
    AppRoutes.notifications,
    AppRoutes.profile,
    AppRoutes.settings,
  ];

  final isProtectedPath = protectedPaths.contains(path) ||
      path.startsWith('/orders/details/');

  // While initialising or loading, stay put (don't flicker).
  if (authState is AuthInitial || authState is AuthLoading) return null;

  // Check if we are already on an auth page.
  final isAuthPath = path == AppRoutes.login || path == AppRoutes.otp;

  // Auth error: allow public browsing and send protected routes to login.
  if (authState is AuthError) {
    if (isProtectedPath) return loginLocation(returnTo: state.uri.toString());
    return null;
  }

  if (authState is AuthUnauthenticated) {
    if (isProtectedPath) return loginLocation(returnTo: state.uri.toString());
    return null;
  }

  if (authState is AuthOtpSent) {
    if (path == AppRoutes.otp) return null;
    return otpLocation(returnTo: returnTo);
  }

  if (authState is AuthAuthenticated) {
    // Only redirect from auth pages.
    if (isAuthPath) {
      return _safeReturnTo(returnTo) ?? AppRoutes.dashboard;
    }
    return null;
  }

  return null;
}

String? _safeReturnTo(String? returnTo) {
  if (returnTo == null || returnTo.isEmpty) return null;
  final uri = Uri.tryParse(returnTo);
  if (uri == null || uri.hasScheme || uri.host.isNotEmpty) return null;
  if (uri.path == AppRoutes.login || uri.path == AppRoutes.otp) return null;
  return returnTo;
}

// ── Vendor Route definitions ─────────────────────────────────────────────────

final List<RouteBase> _vendorRoutes = [
  // ── Splash ───────────────────────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.splash,
    name: AppRouteNames.splash,
    pageBuilder: (c, s) =>
        _fadeTransition(context: c, state: s, child: const SplashPage()),
  ),

  // ── Auth ────────────────────────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.login,
    name: AppRouteNames.login,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const LoginPage()),
  ),
  GoRoute(
    path: AppRoutes.otp,
    name: AppRouteNames.otp,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const OtpPage()),
  ),

  // ── Dashboard (StatefulShellRoute with bottom nav) ───────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, __, shell) => _VendorShell(navigationShell: shell),
    branches: [
      // Tab 0: Dashboard
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          name: AppRouteNames.dashboard,
          builder: (c, s) => const DashboardPage(),
        ),
      ]),

      // Tab 1: Orders
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.orders,
          name: AppRouteNames.orders,
          builder: (c, s) => const OrdersPage(),
          routes: [
            GoRoute(
              path: 'details/:orderId',
              name: AppRouteNames.orderDetails,
              pageBuilder: (c, s) => _slideTransition(
                context: c,
                state: s,
                child: OrderDetailsPage(orderId: s.pathParameters['orderId']!),
              ),
            ),
          ],
        ),
      ]),

      // Tab 2: Services
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.services,
          name: AppRouteNames.services,
          builder: (c, s) => const ServicesPage(),
        ),
      ]),

      // Tab 3: Analytics
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.analytics,
          name: AppRouteNames.analytics,
          builder: (c, s) => const AnalyticsPage(),
        ),
      ]),

      // Tab 4: Profile
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.profile,
          name: AppRouteNames.profile,
          builder: (c, s) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'settings',
              name: AppRouteNames.settings,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const SettingsPage()),
            ),
            GoRoute(
              path: 'notifications',
              name: AppRouteNames.notifications,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const NotificationsPage()),
            ),
          ],
        ),
      ]),
    ],
  ),

  // ── Additional routes (outside shell) ────────────────────────────────────────
  GoRoute(
    path: AppRoutes.pricing,
    name: AppRouteNames.pricing,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const PricingPage()),
  ),
  GoRoute(
    path: AppRoutes.inventory,
    name: AppRouteNames.inventory,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const InventoryPage()),
  ),
  GoRoute(
    path: AppRoutes.employees,
    name: AppRouteNames.employees,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const EmployeesPage()),
  ),
  GoRoute(
    path: AppRoutes.slots,
    name: AppRouteNames.slots,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const SlotsPage()),
  ),
];

// ── Vendor Dashboard Shell ───────────────────────────────────────────────────

class _VendorShell extends ConsumerWidget {
  const _VendorShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navHeight = 72.h;
    final navBottom = 12.h + safeBottom;

    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: navHeight + navBottom + 12.h,
                ),
                child: navigationShell,
              ),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: navBottom,
              child: Container(
                height: navHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.outline.withOpacity(isDark ? 0.12 : 0.45),
                    width: 1,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      shell: navigationShell,
                      index: 0,
                      unselected: Icons.dashboard_outlined,
                      selected: Icons.dashboard,
                      label: 'Home',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 1,
                      unselected: Icons.receipt_long_outlined,
                      selected: Icons.receipt_long,
                      label: 'Orders',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 2,
                      unselected: Icons.category_outlined,
                      selected: Icons.category,
                      label: 'Services',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 3,
                      unselected: Icons.bar_chart_outlined,
                      selected: Icons.bar_chart,
                      label: 'Analytics',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 4,
                      unselected: Icons.person_outline,
                      selected: Icons.person,
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  const _NavItem({
    required this.shell,
    required this.index,
    required this.unselected,
    required this.selected,
    required this.label,
  });

  final StatefulNavigationShell shell;
  final int index;
  final IconData unselected;
  final IconData selected;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = shell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selected : unselected,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22.r,
            ),
            const Gap(4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.caption.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Page ────────────────────────────────────────────────────────────────

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Page not found', style: AppTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown route',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
