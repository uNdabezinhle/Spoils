import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/support_repository.dart';
import '../models/support_models.dart';

final supportConversationProvider = FutureProvider.autoDispose<SupportConversationModel>((ref) async {
  return ref.read(supportRepositoryProvider).fetchConversation();
});