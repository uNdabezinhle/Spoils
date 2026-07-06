import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoil/features/catalog/models/product_model.dart';
import 'package:spoil/features/reminders/models/recipient_model.dart';
import 'package:spoil/features/reminders/providers/reminders_provider.dart';
import 'package:spoil/features/reminders/screens/occasion_detail_screen.dart';
import 'package:spoil/features/subscriptions/models/subscription_models.dart';
import 'package:spoil/features/subscriptions/providers/subscriptions_provider.dart';
import 'package:spoil/features/subscriptions/screens/subscriptions_screen.dart';

void main() {
  testWidgets('OccasionDetailScreen shows gift suggestions', (tester) async {
    const occasionId = 1;
    const detail = OccasionDetailModel(
      id: occasionId,
      recipientId: 10,
      recipientName: 'Test Partner',
      relationship: 'Partner',
      type: 'birthday',
      typeLabel: 'Birthday',
      date: '2026-08-01',
      daysUntil: 5,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          occasionDetailProvider(occasionId).overrideWith((ref) async => detail),
          occasionSuggestionsProvider(occasionId).overrideWith(
            (ref) async => const [
              ProductModel(
                id: 1,
                name: 'Spring Bloom',
                slug: 'spring-bloom',
                description: 'Flowers',
                basePrice: '449',
                imageUrl: '',
                categoryName: 'Flowers',
                categorySlug: 'flowers',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: OccasionDetailScreen(occasionId: occasionId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spoil reminder'), findsOneWidget);
    expect(find.text('Gift suggestions'), findsOneWidget);
    expect(find.text("Test Partner's Birthday"), findsOneWidget);
    expect(find.text('Spring Bloom'), findsOneWidget);
  });

  testWidgets('SubscriptionsScreen lists available plans', (tester) async {
    const plans = [
      SubscriptionPlanModel(
        id: 1,
        name: 'Monthly Spoil Box',
        slug: 'spoil-box',
        modelType: 'spoil_box',
        tagline: 'Curated monthly surprises',
        description: 'A box of joy each month.',
        priceMonthly: '499.00',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionPlansProvider.overrideWith((ref) async => plans),
          mySubscriptionsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: SubscriptionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Available plans'), findsOneWidget);
    expect(find.text('Monthly Spoil Box'), findsOneWidget);
    expect(find.text('Subscribe'), findsWidgets);
  });
}