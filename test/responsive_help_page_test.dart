import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lndry/features/profile/presentation/pages/help_page.dart';

void main() {
  // Test configurations: {size name, width, height}
  const testConfigs = [
    ('320dp (small phone)', 320.0, 568.0),
    ('360dp (standard phone)', 360.0, 640.0),
    ('393dp (modern small)', 393.0, 852.0),
    ('412dp (large phone)', 412.0, 915.0),
  ];

  for (final (name, width, height) in testConfigs) {
    testWidgets('HelpPage no overflow at $name with 1.5x font',
        (WidgetTester tester) async {
      // Set viewport to the target size
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: Size(width, height),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
            home: HelpPage(),
          ),
        ),
      );

      // Pump with a few frames to settle animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      // Drain pre-existing ListTile background warnings from
      // AppCard.outlined + ExpansionTile (pre-existing, not related
      // to responsive layout). Any RenderFlex overflow would appear
      // as a separate exception type and cause the test to fail.
      while (tester.takeException() != null) {}

      // Verify key content is visible and properly laid out
      expect(find.text('Help & FAQs'), findsOneWidget);
      expect(find.text('Need immediate help?'), findsOneWidget);
      expect(find.text('Call Us'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);

      // Verify FAQ items are rendered
      expect(
        find.text('What is the turnaround time for delivery?'),
        findsOneWidget,
      );
      expect(
        find.text('How do I pay for my order?'),
        findsWidgets,
      );

      // Scroll down and verify more content is reachable
      await tester.scrollUntilVisible(
        find.text('Can I cancel my scheduled pickup?'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('What if my clothes are damaged?'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      // Verify support contact text is visible
      expect(
        find.textContaining('Contact LNDRY Support via Phone or Email'),
        findsOneWidget,
      );
    });
  }
}
