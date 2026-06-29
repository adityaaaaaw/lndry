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
import 'core/constants/app_constants.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences and Firebase Core asynchronously before runApp
  final prefs = await SharedPreferences.getInstance();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
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

    // Resolve system preference if themeMode is set to system
    final systemIsDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.isDarkMode = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && systemIsDark);

    return ScreenUtilInit(
      designSize: const Size(
        AppBreakpoints.designWidth,
        AppBreakpoints.designHeight,
      ), // iPhone 14 Pro baseline
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
            return Stack(
              children: [
                if (child != null) child,
                const DevPreviewOverlay(),
              ],
            );
          },
        );
      },
    );
  }
}
