import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoil/features/catalog/models/product_model.dart';
import 'package:spoil/features/reminders/models/recipient_model.dart';
import 'package:spoil/features/reminders/providers/reminders_provider.dart';
import 'package:spoil/features/reminders/screens/occasion_detail_screen.dart';
import 'package:spoil/features/subscriptions/models/subscription_models.dart';
import 'package:spoil/features/subscriptions/providers/subscriptions_provider.dart';
import 'package:spoil/features/subscriptions/screens/subscription_box_screen.dart';
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

    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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

    expect(find.text('Spoils reminder'), findsOneWidget);
    expect(find.text('Gifting preferences'), findsOneWidget);
    expect(find.text('Gift suggestions'), findsOneWidget);
    expect(find.text("Test Partner's Birthday"), findsOneWidget);
    expect(find.text('Spring Bloom'), findsOneWidget);
  });

  testWidgets('OccasionDetailScreen shows auto-gift approval card', (tester) async {
    const occasionId = 2;
    const detail = OccasionDetailModel(
      id: occasionId,
      recipientId: 10,
      recipientName: 'Zanele',
      relationship: 'Friend',
      type: 'birthday',
      typeLabel: 'Birthday',
      date: '2026-08-01',
      daysUntil: 5,
      pendingAutoGift: {
        'id': 1,
        'occasion_id': occasionId,
        'status': 'pending_approval',
        'delivery_date': '2026-08-01',
        'expires_at': '2026-07-30T23:59:59Z',
        'recipient_name': 'Zanele',
        'occasion_type': 'birthday',
        'occasion_type_label': 'Birthday',
        'product': {
          'id': 9,
          'name': 'Birthday Roses',
          'slug': 'birthday-roses',
          'base_price': '399.00',
          'image_url': '',
        },
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          occasionDetailProvider(occasionId).overrideWith((ref) async => detail),
          occasionSuggestionsProvider(occasionId).overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: OccasionDetailScreen(occasionId: occasionId)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Auto-gift ready for approval'), findsOneWidget);
    expect(find.text('Approve & send'), findsOneWidget);
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

  testWidgets('SubscriptionBoxScreen shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionFulfillmentsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: SubscriptionBoxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your box'), findsOneWidget);
    expect(find.text('No subscription boxes yet'), findsOneWidget);
  });
}