import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/design/design_system.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../repositories/mock/mock_customer_repository.dart';
import '../../../../config/env.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Guards against navigating before the animation finishes AND auth resolves.
  bool _minDelayDone = false;
  bool _navigationTriggered = false;
  bool _connectivityCheckDone = false;

  Future<void> _checkConnectivity() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(milliseconds: 1500),
        receiveTimeout: const Duration(milliseconds: 1500),
      ));
      // Ping the categories endpoint or another public endpoint
      await dio.get('/categories');
    } catch (e) {
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
           e.type == DioExceptionType.sendTimeout ||
           e.type == DioExceptionType.receiveTimeout ||
           e.type == DioExceptionType.connectionError ||
           e.message?.contains('SocketException') == true ||
           e.message?.contains('Connection refused') == true)) {
        ref.read(useMocksProvider.notifier).state = true;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: AppCurves.standard),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: AppCurves.standard),
    );
    _logoController.forward();

    setState(() => _connectivityCheckDone = true);

    // Minimum display time so the splash doesn't flash.
    Future.delayed(AppDurations.splash, () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  /// Called both when the min-delay fires and when auth state updates.
  /// Only navigates once both conditions are satisfied.
  void _tryNavigate() {
    if (!mounted || _navigationTriggered) return;
    if (!_minDelayDone || !_connectivityCheckDone) return;

    final authState = ref.read(authProvider);

    // Still initialising — wait for the next state change (listener below).
    if (authState is AuthInitial || authState is AuthLoading) return;

    _navigationTriggered = true;

    final storage = ref.read(storageServiceProvider);
    final onboardingDone =
        storage.getBool(AppConstants.keyOnboardingDone) ?? false;

    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // GoRouter redirect handles the exact destination based on auth state.
    // We only need to leave the splash route; the router picks the rest.
    switch (authState) {
      case AuthAuthenticated():
        context.go(AppRoutes.home);
      case AuthNeedsProfileSetup():
        context.go(AppRoutes.profileSetup);
      case AuthNeedsLocationPermission():
        context.go(AppRoutes.locationPermission);
      case AuthNeedsAddressSelection():
        context.go(AppRoutes.mapAddress);
      case AuthUnauthenticated():
        context.go(AppRoutes.home);
      default:
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes so we navigate as soon as both
    // the minimum delay AND auth resolution are done.
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is! AuthInitial && next is! AuthLoading) {
        _tryNavigate();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.splashGradient,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: child,
                ),
              ),
              child: Image.asset(
                'assets/images/logo/lndry_logo.png',
                width: 200.r,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                semanticLabel: 'LNDRY logo',
              ),
            ),
            Positioned(
              bottom: AppSpacing.xxxl.h * 1.5,
              child: const AppLoadingIndicator(color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
