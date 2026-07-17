import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../auth/auth_gate.dart';
import '../design/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../config/env.dart';

// ── Page imports ──────────────────────────────────────────────────────────────

import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/auth/presentation/pages/location_permission_page.dart';
import '../../features/auth/presentation/pages/map_address_page.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/category/presentation/pages/category_page.dart';
import '../../features/vendor_listing/presentation/pages/vendor_listing_page.dart';
import '../../features/vendor_details/presentation/pages/vendor_details_page.dart';

import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';

import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';

import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/saved_addresses_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/my_reviews_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/help_page.dart';

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

// ── Router Provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
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
        _globalRedirect(context, state, ref.read(authProvider)),
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
    routes: _routes,
  );
});

// ── Global redirect (auth guard) ──────────────────────────────────────────────

String? _globalRedirect(
  BuildContext context,
  GoRouterState state,
  AuthState authState,
) {
  final path = state.uri.path;
  final returnTo = state.uri.queryParameters['returnTo'];

  const protectedPaths = [
    AppRoutes.profileSetup,
    AppRoutes.locationPermission,
    AppRoutes.mapAddress,
    AppRoutes.cart,
    AppRoutes.checkout,
    AppRoutes.payment,
    AppRoutes.orders,
    AppRoutes.editProfile,
    AppRoutes.address,
    AppRoutes.notifications,
    AppRoutes.myReviews,
  ];

  final isProtectedPath = (protectedPaths.contains(path) ||
      path.startsWith('/orders/details/') ||
      (path.startsWith('/orders/') && path.endsWith('/submitted'))) &&
      !(Env.demoMode && path.startsWith('/profile') && !path.startsWith('/profile-setup'));

  // While initialising or loading, stay put (don't flicker).
  if (authState is AuthInitial || authState is AuthLoading) return null;

  // Check if we are already on an auth or onboarding page.
  final isAuthOrOnboardingPath = path == AppRoutes.login ||
      path == AppRoutes.otp ||
      path == AppRoutes.profileSetup ||
      path == AppRoutes.locationPermission ||
      path == AppRoutes.mapAddress;

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
    if (isAuthOrOnboardingPath) return null;
    if (path != AppRoutes.otp) return otpLocation(returnTo: returnTo);
    return null;
  }

  if (authState is AuthNeedsProfileSetup) {
    if (isAuthOrOnboardingPath) return null;
    if (path != AppRoutes.profileSetup) return AppRoutes.profileSetup;
    return null;
  }

  if (authState is AuthNeedsLocationPermission) {
    if (isAuthOrOnboardingPath) return null;
    if (path != AppRoutes.locationPermission) {
      return AppRoutes.locationPermission;
    }
    return null;
  }

  if (authState is AuthNeedsAddressSelection) {
    if (isAuthOrOnboardingPath) return null;
    if (path != AppRoutes.mapAddress) return AppRoutes.mapAddress;
    return null;
  }

  if (authState is AuthAuthenticated) {
    // ROOT CAUSE FIX: Only redirect from auth/onboarding pages.
    // Do NOT redirect from public pages like /search or /home.
    if (isAuthOrOnboardingPath) {
      return _safeReturnTo(returnTo) ?? AppRoutes.home;
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

// ── Route definitions ─────────────────────────────────────────────────────────

final List<RouteBase> _routes = [
  // ── Splash / Onboarding ───────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.splash,
    name: AppRouteNames.splash,
    pageBuilder: (c, s) =>
        _fadeTransition(context: c, state: s, child: const SplashPage()),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    name: AppRouteNames.onboarding,
    pageBuilder: (c, s) =>
        _fadeTransition(context: c, state: s, child: const OnboardingPage()),
  ),

  // ── Auth ──────────────────────────────────────────────────────────────────
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
  GoRoute(
    path: AppRoutes.profileSetup,
    name: AppRouteNames.profileSetup,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const ProfileSetupPage()),
  ),
  GoRoute(
    path: AppRoutes.locationPermission,
    name: AppRouteNames.locationPermission,
    pageBuilder: (c, s) => _slideTransition(
        context: c, state: s, child: const LocationPermissionPage()),
  ),
  GoRoute(
    path: AppRoutes.mapAddress,
    name: AppRouteNames.mapAddress,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const MapAddressPage()),
  ),

  // ── Vendor discovery (outside shell so no bottom nav shown) ───────────────
  GoRoute(
    path: '/category/:categoryId',
    name: AppRouteNames.category,
    pageBuilder: (c, s) => _slideTransition(
      context: c,
      state: s,
      child: CategoryPage(categoryId: s.pathParameters['categoryId']!),
    ),
  ),
  GoRoute(
    path: '/vendors',
    name: AppRouteNames.vendorListing,
    pageBuilder: (c, s) => _slideTransition(
        context: c, state: s, child: const VendorListingPage()),
  ),
  GoRoute(
    path: '/vendor/:vendorId',
    name: AppRouteNames.vendorDetails,
    pageBuilder: (c, s) => _slideTransition(
      context: c,
      state: s,
      child: VendorDetailsPage(vendorId: s.pathParameters['vendorId']!),
    ),
  ),

  // ── Booking / Checkout (outside shell) ───────────────────────────────────
  GoRoute(
    path: AppRoutes.checkout,
    name: AppRouteNames.checkout,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const CheckoutPage()),
  ),
  GoRoute(
    path: AppRoutes.payment,
    name: AppRouteNames.payment,
    pageBuilder: (c, s) =>
        _slideTransition(context: c, state: s, child: const PaymentPage()),
  ),

  // ── Order confirmation (/orders/:orderId/submitted) ───────────────────────
  GoRoute(
    path: '/orders/:orderId/submitted',
    name: AppRouteNames.orderConfirmation,
    pageBuilder: (c, s) => _fadeTransition(
      context: c,
      state: s,
      child: OrderConfirmationPage(
        orderId: s.pathParameters['orderId']!,
      ),
    ),
  ),

  // ── Dashboard tabs (StatefulShellRoute) ──────────────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, __, shell) => _DashboardShell(navigationShell: shell),
    branches: [
      // Tab 0: Home
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.home,
          name: AppRouteNames.home,
          builder: (c, s) => const HomePage(),
        ),
      ]),

      // Tab 1: Search/Explore
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.search,
          name: AppRouteNames.search,
          builder: (c, s) => const SearchPage(),
        ),
      ]),

      // Tab 2: Cart/Booking
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.cart,
          name: AppRouteNames.cart,
          builder: (c, s) => const CartPage(),
        ),
      ]),

      // Tab 3: Orders
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.orders,
          name: AppRouteNames.orders,
          builder: (c, s) => const OrdersListPage(),
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

      // Tab 4: Profile
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.profile,
          name: AppRouteNames.profile,
          builder: (c, s) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'edit',
              name: AppRouteNames.editProfile,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const EditProfilePage()),
            ),
            GoRoute(
              path: 'address',
              name: AppRouteNames.address,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const SavedAddressesPage()),
            ),
            GoRoute(
              path: 'notifications',
              name: AppRouteNames.notifications,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const NotificationsPage()),
            ),
            GoRoute(
              path: 'reviews',
              name: AppRouteNames.myReviews,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const MyReviewsPage()),
            ),
            GoRoute(
              path: 'settings',
              name: AppRouteNames.settings,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const SettingsPage()),
            ),
            GoRoute(
              path: 'help',
              name: AppRouteNames.help,
              pageBuilder: (c, s) => _slideTransition(
                  context: c, state: s, child: const HelpPage()),
            ),
          ],
        ),
      ]),
    ],
  ),
];

// ── Dashboard Shell ───────────────────────────────────────────────────────────

class _DashboardShell extends ConsumerWidget {
  const _DashboardShell({required this.navigationShell});
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
                      unselected: AppIcons.homeOutlined,
                      selected: AppIcons.home,
                      label: 'Home',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 1,
                      unselected: Icons.grid_view_outlined,
                      selected: Icons.grid_view_rounded,
                      label: 'Explore',
                    ),
                    _CenterBookItem(shell: navigationShell),
                    _NavItem(
                      shell: navigationShell,
                      index: 3,
                      unselected: AppIcons.ordersOutlined,
                      selected: AppIcons.orders,
                      label: 'Orders',
                    ),
                    _NavItem(
                      shell: navigationShell,
                      index: 4,
                      unselected: AppIcons.profileOutlined,
                      selected: AppIcons.profile,
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
          void goToBranch() {
            final navigator = rootNavigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.popUntil((route) => 
                route.settings.name != AppRouteNames.login &&
                route.settings.name != AppRouteNames.otp &&
                route.settings.name != AppRouteNames.profileSetup &&
                route.settings.name != AppRouteNames.locationPermission &&
                route.settings.name != AppRouteNames.mapAddress
              );
            }
            shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            );
          }

          if (index == 3) {
            requireAuthenticated(
              context: context,
              ref: ref,
              returnTo: AppRoutes.orders,
              action: (_, __) => goToBranch(),
            );
            return;
          }
          goToBranch();
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

class _CenterBookItem extends ConsumerWidget {
  const _CenterBookItem({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = shell.currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => requireAuthenticated(
          context: context,
          ref: ref,
          returnTo: AppRoutes.cart,
          action: (actionContext, __) {
            final navigator = rootNavigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.popUntil((route) => 
                route.settings.name != AppRouteNames.login &&
                route.settings.name != AppRouteNames.otp &&
                route.settings.name != AppRouteNames.profileSetup &&
                route.settings.name != AppRouteNames.locationPermission &&
                route.settings.name != AppRouteNames.mapAddress
              );
            }
            shell.goBranch(2, initialLocation: 2 == shell.currentIndex);
          },
        ),
        child: OverflowBox(
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(0, -12.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: AppElevation.fabShadow,
                  ),
                  child: Icon(AppIcons.add, color: AppColors.white, size: 30.r),
                ),
                const Gap(4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Book',
                      maxLines: 1,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            const Icon(AppIcons.error, size: 64, color: AppColors.error),
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
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
