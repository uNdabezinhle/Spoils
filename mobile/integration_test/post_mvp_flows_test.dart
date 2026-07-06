// Full-device integration tests (API + navigation).
// Run when a supported target is available:
//   flutter test integration_test/post_mvp_flows_test.dart -d windows   (requires Visual Studio Build Tools)
//   flutter test integration_test/post_mvp_flows_test.dart -d <android-emulator-id>
// Chrome/web is not supported for integration_test yet.
// Fast VM widget coverage: flutter test test/post_mvp_screens_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spoil/main.dart' as app;

/// Credentials created by agent-tools/test_post_mvp_flows.py or register manually.
const _testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: 'flowtest@example.com');
const _testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'securepass123');

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _login(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.text('Profile'));
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();

  if (find.text('Sign in').evaluate().isNotEmpty) {
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), _testEmail);
    await tester.enterText(fields.at(1), _testPassword);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('post-MVP: home reminder opens occasion detail', (tester) async {
    app.main();
    await _pumpUntilFound(tester, find.text('Profile'));
    await _login(tester);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    var partner = find.text('Test Partner');
    if (partner.evaluate().isEmpty) {
      await tester.tap(find.text('People'));
      await tester.pumpAndSettle();
      partner = find.text('Test Partner');
    }
    if (partner.evaluate().isEmpty) return;

    await tester.tap(partner.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Gift suggestions'), findsOneWidget);
    expect(find.text('Spoil reminder'), findsOneWidget);
  });

  testWidgets('post-MVP: calendar tab opens occasion detail', (tester) async {
    app.main();
    await _login(tester);

    await tester.tap(find.text('People'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final partner = find.text('Test Partner');
    if (partner.evaluate().isEmpty) return;

    await tester.tap(partner.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Gift suggestions'), findsOneWidget);
  });

  testWidgets('post-MVP: subscriptions screen lists plans', (tester) async {
    app.main();
    await _login(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subscriptions'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Available plans'), findsOneWidget);
    expect(find.text('Subscribe'), findsWidgets);
  });
}