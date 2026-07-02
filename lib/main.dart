import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/tokens/breakpoints.dart';
import 'core/services/storage_service.dart';
import 'core/widgets/widgets.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Firebase initialisation is best-effort; the app runs without it in
  // offline/mock mode (FCM, auth still wired when backend is delivered).
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[LNDRY] Firebase init skipped: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageServiceProvider.overrideWithValue(StorageService(prefs: prefs)),
      ],
      child: const LndryApp(),
    ),
  );
}

class LndryApp extends ConsumerWidget {
  const LndryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Keep the static flag in sync with the resolved theme so
    // AppColors dynamic getters return the correct value.
    final systemIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemIsDark);

    return ScreenUtilInit(
      designSize: const Size(
        AppBreakpoints.designWidth,
        AppBreakpoints.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          key: ValueKey(themeMode),
          title: 'LNDRY',
          debugShowCheckedModeBanner: Env.showDebugBanner,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, child) {
            // DevPreviewOverlay is only shown in debug builds and only
            // when Env.showDevPreviewOverlay is true. It is never shown
            // in profile or release builds.
            return Stack(
              children: [
                if (child != null) child,
                if (Env.showDevPreviewOverlay) const DevPreviewOverlay(),
              ],
            );
          },
        );
      },
    );
  }
}
