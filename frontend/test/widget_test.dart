import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_brain/screens/splash_and_onboarding.dart';

void main() {
  testWidgets('WelcomeOnboardingScreen displays PDF Brain branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeOnboardingScreen(),
      ),
    );

    expect(find.text('PDF Brain'), findsOneWidget);
  });
}