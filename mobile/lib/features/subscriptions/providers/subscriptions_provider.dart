import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/subscriptions_repository.dart';
import '../models/subscription_models.dart';

final subscriptionPlansProvider = FutureProvider.autoDispose<List<SubscriptionPlanModel>>((ref) async {
  return ref.read(subscriptionsRepositoryProvider).fetchPlans();
});

final mySubscriptionsProvider = FutureProvider.autoDispose<List<UserSubscriptionModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(subscriptionsRepositoryProvider).fetchMySubscriptions();
});

final subscriptionFulfillmentsProvider =
    FutureProvider.autoDispose<List<SubscriptionFulfillmentModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(subscriptionsRepositoryProvider).fetchFulfillments();
});