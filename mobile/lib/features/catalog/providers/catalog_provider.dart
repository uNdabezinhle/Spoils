import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../models/product_model.dart';

final catalogHomeProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(catalogRepositoryProvider).fetchHome();
});

final categoriesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(catalogRepositoryProvider).fetchCategories();
});

final productFiltersProvider = StateProvider.autoDispose<ProductFilters>((ref) {
  return const ProductFilters();
});

final productsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filters = ref.watch(productFiltersProvider);
  return ref.read(catalogRepositoryProvider).fetchProducts(filters);
});

final productDetailProvider = FutureProvider.autoDispose.family<ProductModel, String>((ref, slug) async {
  return ref.read(catalogRepositoryProvider).fetchProduct(slug);
});