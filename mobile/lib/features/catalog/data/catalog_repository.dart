import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(dio: ref.watch(apiClientProvider));
});

class CatalogHomeData {
  const CatalogHomeData({
    required this.categories,
    required this.featured,
    required this.popular,
  });

  final List<CategoryModel> categories;
  final List<ProductModel> featured;
  final List<ProductModel> popular;
}

class ProductFilters {
  const ProductFilters({
    this.search = '',
    this.categorySlug,
    this.minPrice,
    this.maxPrice,
    this.featuredOnly = false,
    this.popularOnly = false,
  });

  final String search;
  final String? categorySlug;
  final double? minPrice;
  final double? maxPrice;
  final bool featuredOnly;
  final bool popularOnly;

  ProductFilters copyWith({
    String? search,
    String? categorySlug,
    double? minPrice,
    double? maxPrice,
    bool? featuredOnly,
    bool? popularOnly,
    bool clearCategory = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return ProductFilters(
      search: search ?? this.search,
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      featuredOnly: featuredOnly ?? this.featuredOnly,
      popularOnly: popularOnly ?? this.popularOnly,
    );
  }
}

class CatalogRepository {
  CatalogRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CatalogHomeData> fetchHome() async {
    final response = await _dio.get('/products/home/');
    final data = response.data as Map<String, dynamic>;
    return CatalogHomeData(
      categories: (data['categories'] as List<dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      featured: (data['featured'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      popular: (data['popular'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _dio.get('/products/categories/');
    return (response.data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> fetchProducts(ProductFilters filters) async {
    final params = <String, dynamic>{};
    if (filters.search.isNotEmpty) params['search'] = filters.search;
    if (filters.categorySlug != null) params['category'] = filters.categorySlug;
    if (filters.minPrice != null) params['min_price'] = filters.minPrice!.toStringAsFixed(0);
    if (filters.maxPrice != null) params['max_price'] = filters.maxPrice!.toStringAsFixed(0);
    if (filters.featuredOnly) params['featured'] = 'true';
    if (filters.popularOnly) params['popular'] = 'true';

    final response = await _dio.get('/products/', queryParameters: params);
    return (response.data as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel> fetchProduct(String slug) async {
    final response = await _dio.get('/products/$slug/');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }
}