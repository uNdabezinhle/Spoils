import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoil/main.dart';

void main() {
  testWidgets('Spoils app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpoilApp()));
    await tester.pump();
    expect(find.text('Spoils'), findsOneWidget);
    expect(find.text('Spoil them properly.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}