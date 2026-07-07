import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/group_gifts_repository.dart';
import '../models/group_gift_models.dart';

final myGroupGiftsProvider = FutureProvider.autoDispose<List<GroupGiftModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(groupGiftsRepositoryProvider).fetchMyGroupGifts();
});

final groupGiftByTokenProvider = FutureProvider.autoDispose.family<GroupGiftModel, String>((ref, token) async {
  return ref.read(groupGiftsRepositoryProvider).fetchByToken(token);
});