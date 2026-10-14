import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyc_app/app.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KycApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify welcome text is displayed
    expect(find.text('Welcome to KYC Onboarding'), findsOneWidget);
    expect(find.text('Your identity verification app'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
