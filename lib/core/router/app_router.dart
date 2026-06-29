import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../design/design_system.dart';
import '../../providers/auth_provider.dart';

// Let's import the actual onboarding / auth pages
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/auth/presentation/pages/location_permission_page.dart';
import '../../features/auth/presentation/pages/map_address_page.dart';

// Client Customer Home Modules
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/category/presentation/pages/category_page.dart';
import '../../features/vendor_listing/presentation/pages/vendor_listing_page.dart';
import '../../features/vendor_details/presentation/pages/vendor_details_page.dart';

// Checkout & Cart Modules
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';

// Orders module
import '../../features/orders/presentation/pages/orders_list_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';

// Profile Module
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/saved_addresses_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/profile/presentation/pages/help_page.dart';

// ── Reusable Custom Transitions ──────────────────────────────────────────────

CustomTransitionPage<T> buildPageWithSlideTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.pageRoute,
    reverseTransitionDuration: AppDurations.pageRoute,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: AppCurves.decelerate,
        )),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.pageRoute,
    reverseTransitionDuration: AppDurations.pageRoute,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppCurves.standard,
        ),
        child: child,
      );
    },
  );
}

// ── App Router Provider ───────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to Auth State to trigger route recalculation on change
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) => _globalRedirect(context, state, authState),
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
    routes: _routes,
  );
});

// ── Global redirect (auth guard) ─────────────────────────────────────────────

String? _globalRedirect(BuildContext context, GoRouterState state, AuthState authState) {
  final path = state.uri.path;

  final publicPaths = [
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.otp,
  ];

  if (authState is AuthInitial || authState is AuthLoading) {
    return null;
  }

  if (authState is AuthUnauthenticated) {
    if (!publicPaths.contains(path)) {
      return AppRoutes.login;
    }
    return null;
  }

  if (authState is AuthOtpSent) {
    if (path != AppRoutes.otp) {
      return AppRoutes.otp;
    }
    return null;
  }

  if (authState is AuthNeedsProfileSetup) {
    if (path != AppRoutes.profileSetup) {
      return AppRoutes.profileSetup;
    }
    return null;
  }

  if (authState is AuthNeedsLocationPermission) {
    if (path != AppRoutes.locationPermission) {
      return AppRoutes.locationPermission;
    }
    return null;
  }

  if (authState is AuthNeedsAddressSelection) {
    if (path != AppRoutes.mapAddress) {
      return AppRoutes.mapAddress;
    }
    return null;
  }

  if (authState is AuthAuthenticated) {
    if (publicPaths.contains(path) ||
        path == AppRoutes.profileSetup ||
        path == AppRoutes.locationPermission ||
        path == AppRoutes.mapAddress) {
      return AppRoutes.home;
    }
    return null;
  }

  return null;
}

final List<RouteBase> _routes = [
  // ── Splash / Onboarding ──────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.splash,
    name: AppRouteNames.splash,
    pageBuilder: (context, state) => buildPageWithFadeTransition(
      context: context,
      state: state,
      child: const SplashPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    name: AppRouteNames.onboarding,
    pageBuilder: (context, state) => buildPageWithFadeTransition(
      context: context,
      state: state,
      child: const OnboardingPage(),
    ),
  ),

  // ── Auth ─────────────────────────────────────────────────────────────────
  GoRoute(
    path: AppRoutes.login,
    name: AppRouteNames.login,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const LoginPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.otp,
    name: AppRouteNames.otp,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const OtpPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.profileSetup,
    name: AppRouteNames.profileSetup,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const ProfileSetupPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.locationPermission,
    name: AppRouteNames.locationPermission,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const LocationPermissionPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.mapAddress,
    name: AppRouteNames.mapAddress,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const MapAddressPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.checkout,
    name: AppRouteNames.checkout,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const CheckoutPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.payment,
    name: AppRouteNames.payment,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const PaymentPage(),
    ),
  ),
  GoRoute(
    path: AppRoutes.orderConfirmation,
    name: AppRouteNames.orderConfirmation,
    pageBuilder: (context, state) => buildPageWithFadeTransition(
      context: context,
      state: state,
      child: OrderConfirmationPage(
        orderId: state.pathParameters['orderId']!,
      ),
    ),
  ),
  GoRoute(
    path: '/category/:categoryId',
    name: AppRouteNames.category,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: CategoryPage(
        categoryId: state.pathParameters['categoryId']!,
      ),
    ),
  ),
  GoRoute(
    path: '/vendors',
    name: AppRouteNames.vendorListing,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: const VendorListingPage(),
    ),
  ),
  GoRoute(
    path: '/vendor/:vendorId',
    name: AppRouteNames.vendorDetails,
    pageBuilder: (context, state) => buildPageWithSlideTransition(
      context: context,
      state: state,
      child: VendorDetailsPage(
        vendorId: state.pathParameters['vendorId']!,
      ),
    ),
  ),

  // ── Stateful Shell Navigation (Dashboard Tabs) ───────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, __, navigationShell) =>
        _DashboardShell(navigationShell: navigationShell),
    branches: [
      // ── Tab 1: Home ────────────────────────────────────────────────────────
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.home,
          name: AppRouteNames.home,
          builder: (context, state) => const HomePage(),
        ),
      ]),

      // ── Tab 2: Search ──────────────────────────────────────────────────────
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.search,
          name: AppRouteNames.search,
          builder: (context, state) => const SearchPage(),
        ),
      ]),

      // ── Tab 3: Cart ────────────────────────────────────────────────────────
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.cart,
          name: AppRouteNames.cart,
          builder: (context, state) => const CartPage(),
        ),
      ]),

      // ── Tab 4: Orders ──────────────────────────────────────────────────────
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.orders,
          name: AppRouteNames.orders,
          builder: (context, state) => const OrdersListPage(),
          routes: [
            GoRoute(
              path: 'details/:orderId',
              name: AppRouteNames.orderDetails,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: OrderDetailsPage(
                  orderId: state.pathParameters['orderId']!,
                ),
              ),
            ),
          ],
        ),
      ]),

      // ── Tab 5: Profile ─────────────────────────────────────────────────────
      StatefulShellBranch(routes: [
        GoRoute(
          path: AppRoutes.profile,
          name: AppRouteNames.profile,
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'address',
              name: AppRouteNames.address,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const SavedAddressesPage(),
              ),
            ),
            GoRoute(
              path: 'notifications',
              name: AppRouteNames.notifications,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const NotificationsPage(),
              ),
            ),
            GoRoute(
              path: 'edit',
              name: AppRouteNames.editProfile,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const EditProfilePage(),
              ),
            ),
            GoRoute(
              path: 'settings',
              name: AppRouteNames.settings,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const SettingsPage(),
              ),
            ),
            GoRoute(
              path: 'help',
              name: AppRouteNames.help,
              pageBuilder: (context, state) => buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const HelpPage(),
              ),
            ),
          ],
        ),
      ]),
    ],
  ),
];

// ── Dashboard Shell Widget ───────────────────────────────────────────────────

class _DashboardShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _DashboardShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // The page content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 64.h),
              child: navigationShell,
            ),
          ),
          // The custom bottom nav bar
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
                  _buildNavItem(context, 0, AppIcons.homeOutlined, AppIcons.home, 'Home'),
                  _buildNavItem(context, 1, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Explore'),
                  _buildCenterBookItem(context),
                  _buildNavItem(context, 3, AppIcons.ordersOutlined, AppIcons.orders, 'Orders'),
                  _buildNavItem(context, 4, AppIcons.profileOutlined, AppIcons.profile, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = navigationShell.currentIndex == index;
    final primaryColor = AppColors.primary;
    final secondaryColor = const Color(0xFF495467);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => navigationShell.goBranch(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryColor : secondaryColor,
              size: 22.r,
            ),
            const Gap(4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterBookItem(BuildContext context) {
    final isSelected = navigationShell.currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => navigationShell.goBranch(2),
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
              child: Icon(
                AppIcons.laundry,
                color: AppColors.white,
                size: 20.r,
              ),
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
  final Exception? error;
  const _ErrorPage({this.error});

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
            Text(error?.toString() ?? '', style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
