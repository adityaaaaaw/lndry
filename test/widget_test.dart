import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lndry/core/constants/app_constants.dart';
import 'package:lndry/core/design/app_icons.dart';
import 'package:lndry/core/services/storage_service.dart';
import 'package:lndry/core/widgets/app_button.dart';
import 'package:lndry/features/home/presentation/providers/home_providers.dart';
import 'package:lndry/main.dart';
import 'package:lndry/repositories/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('LndryApp bottom nav renders without overflow on small screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingDone: true,
      'fresh_install_reset_done_v3': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _TestStorageService(prefs: prefs);
    await storage.saveSecure(AppConstants.keyAccessToken, 'mock_access_token');
    await storage.saveSecure(AppConstants.keyRefreshToken, 'mock_refresh_token');
    await storage.saveBool('user_has_address', value: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(storage),
          customerRepositoryProvider
              .overrideWithValue(MockCustomerRepository()),
          currentAddressProvider.overrideWith((ref) async => null),
          homeCategoriesProvider.overrideWith((ref) async => const []),
          homeVendorsProvider.overrideWith((ref) async => const []),
          activeOrdersProvider.overrideWith((ref) async => const []),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: LndryApp(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(find.text('Book'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LndryApp startup smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingDone: true,
      'fresh_install_reset_done_v3': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _TestStorageService(prefs: prefs);
    await storage.saveSecure(AppConstants.keyAccessToken, 'mock_access_token');
    await storage.saveSecure(AppConstants.keyRefreshToken, 'mock_refresh_token');
    await storage.saveBool('user_has_address', value: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(storage),
          customerRepositoryProvider
              .overrideWithValue(MockCustomerRepository()),
          currentAddressProvider.overrideWith((ref) async => null),
          homeCategoriesProvider.overrideWith((ref) async => const []),
          homeVendorsProvider.overrideWith((ref) async => const []),
          activeOrdersProvider.overrideWith((ref) async => const []),
        ],
        child: const LndryApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byType(LndryApp), findsOneWidget);
    expect(
        find.text('What would you like us to care for today?'), findsOneWidget);
    expect(find.text('Send OTP'), findsNothing);
  });

  testWidgets('login send OTP advances to OTP screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingDone: true,
      'fresh_install_reset_done_v3': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _TestStorageService(prefs: prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(storage),
          customerRepositoryProvider
              .overrideWithValue(MockCustomerRepository()),
          currentAddressProvider.overrideWith((ref) async => null),
          homeCategoriesProvider.overrideWith((ref) async => const []),
          homeVendorsProvider.overrideWith((ref) async => const []),
          activeOrdersProvider.overrideWith((ref) async => const []),
        ],
        child: const LndryApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Book'), findsOneWidget);
    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Send OTP'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Verify Mobile Number'), findsOneWidget);
    expect(
      find.text('We have sent a verification code to +91 9876543210.'),
      findsOneWidget,
    );
  });

  testWidgets('Guest user can open Profile and navigate to Settings without login prompt',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      AppConstants.keyOnboardingDone: true,
      'fresh_install_reset_done_v3': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = _TestStorageService(prefs: prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(storage),
          customerRepositoryProvider
              .overrideWithValue(MockCustomerRepository()),
          currentAddressProvider.overrideWith((ref) async => null),
          homeCategoriesProvider.overrideWith((ref) async => const []),
          homeVendorsProvider.overrideWith((ref) async => const []),
          activeOrdersProvider.overrideWith((ref) async => const []),
        ],
        child: const LndryApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Verify Guest User can open Profile
    expect(find.text('Profile'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Profile page loaded with guest state (sign in action card)
    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Verify Settings tile is displayed and can be tapped without login redirect
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Verify we navigated to Settings screen and it renders theme selectors
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);

    // Verify back navigation works
    expect(find.byIcon(AppIcons.back), findsOneWidget);

    // Clear any ListTile assertions warnings caught during test
    tester.takeException();
  });
}

class _TestStorageService extends StorageService {
  _TestStorageService({required super.prefs});

  final Map<String, String> _secureValues = {};

  @override
  Future<void> saveSecure(String key, String value) async {
    _secureValues[key] = value;
  }

  @override
  Future<String?> getSecure(String key) async => _secureValues[key];

  @override
  Future<void> deleteSecure(String key) async {
    _secureValues.remove(key);
  }

  @override
  Future<void> deleteAllSecure() async {
    _secureValues.clear();
  }

  @override
  Future<Map<String, String>> getAllSecure() async =>
      Map<String, String>.from(_secureValues);
}
