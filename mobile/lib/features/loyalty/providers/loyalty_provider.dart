import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/loyalty_repository.dart';
import '../models/loyalty_models.dart';

final loyaltyAccountProvider = FutureProvider.autoDispose<LoyaltyAccountModel>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) {
    return const LoyaltyAccountModel(balance: 0, lifetimeEarned: 0);
  }
  return ref.read(loyaltyRepositoryProvider).fetchAccount();
});

final loyaltyHistoryProvider = FutureProvider.autoDispose<List<PointsLedgerEntryModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(loyaltyRepositoryProvider).fetchHistory();
});