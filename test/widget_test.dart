import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lndry/main.dart';
import 'package:lndry/core/services/storage_service.dart';

void main() {
  testWidgets('LndryApp startup smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(StorageService(prefs: prefs)),
        ],
        child: const LndryApp(),
      ),
    );

    // Verify that the app builds without errors and initializes router/theme
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(LndryApp), findsOneWidget);
  });
}
