import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_repository.dart';
import '../models/content_models.dart';

final staticPageProvider = FutureProvider.autoDispose.family<StaticPageModel, String>((ref, pageType) {
  return ref.read(contentRepositoryProvider).fetchPage(pageType);
});

final faqListProvider = FutureProvider.autoDispose<List<FaqModel>>((ref) {
  return ref.read(contentRepositoryProvider).fetchFaqs();
});