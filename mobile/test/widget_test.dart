import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoil/main.dart';

void main() {
  testWidgets('Spoil app loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SpoilApp()));
    expect(find.text('Spoil'), findsOneWidget);
    expect(find.text('Spoil them properly.'), findsOneWidget);
  });
}