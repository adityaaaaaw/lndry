import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../design/design_system.dart';
import '../../providers/auth_provider.dart';

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
  final authState = ref.watch(authProvider);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) => _globalRedirect(context, state, authState),
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

  // Public paths that don't require authentication.
  const publicPaths = [
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.otp,
  ];

  // While initialising or loading, stay put (don't flicker).
  if (authState is AuthInitial || authState is AuthLoading) return null;

  // Auth error: redirect to login so the user can retry.
  if (authState is AuthError) {
    if (!publicPaths.contains(path)) return AppRoutes.login;
    return null;
  }

  if (authState is AuthUnauthenticated) {
    if (!publicPaths.contains(path)) return AppRoutes.login;
    return null;
  }

  if (authState is AuthOtpSent) {
    if (path != AppRoutes.otp) return AppRoutes.otp;
    return null;
  }

  if (authState is AuthNeedsProfileSetup) {
    if (path != AppRoutes.profileSetup) return AppRoutes.profileSetup;
    return null;
  }

  if (authState is AuthNeedsLocationPermission) {
    if (path != AppRoutes.locationPermission)
      return AppRoutes.locationPermission;
    return null;
  }

  if (authState is AuthNeedsAddressSelection) {
    if (path != AppRoutes.mapAddress) return AppRoutes.mapAddress;
    return null;
  }

  if (authState is AuthAuthenticated) {
    // Redirect away from auth/onboarding screens once signed in.
    final isAuthPath = publicPaths.contains(path) ||
        path == AppRoutes.profileSetup ||
        path == AppRoutes.locationPermission ||
        path == AppRoutes.mapAddress;
    if (isAuthPath) return AppRoutes.home;
    return null;
  }

  return null;
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

class _DashboardShell extends StatelessWidget {
  const _DashboardShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 64.h + MediaQuery.paddingOf(context).bottom,
              ),
              child: navigationShell,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 64.h + MediaQuery.paddingOf(context).bottom,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: AppColors.outline.withOpacity(isDark ? 0.1 : 0.3),
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
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
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isSelected = shell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selected : unselected,
              color: isSelected ? AppColors.primary : const Color(0xFF495467),
              size: 22.r,
            ),
            const Gap(4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF495467),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterBookItem extends StatelessWidget {
  const _CenterBookItem({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final isSelected = shell.currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            shell.goBranch(2, initialLocation: 2 == shell.currentIndex),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8174EA), Color(0xFF7C5BE2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5BE2).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(AppIcons.laundry, color: AppColors.white, size: 20.r),
            ),
            const Gap(2),
            Text(
              'Cart',
              style: AppTypography.caption.copyWith(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : const Color(0xFF495467),
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
