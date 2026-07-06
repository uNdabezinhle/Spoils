import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/cart_models.dart';
import '../models/customisation_options.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(dio: ref.watch(apiClientProvider));
});

final customisationRepositoryProvider = Provider<CustomisationRepository>((ref) {
  return CustomisationRepository(dio: ref.watch(apiClientProvider));
});

class CartRepository {
  CartRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CartModel> fetchCart() async {
    final response = await _dio.get('/orders/cart/');
    return CartModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartItemModel> addItem({
    required int productId,
    int quantity = 1,
    CustomisationDetails? customisation,
  }) async {
    final response = await _dio.post('/orders/cart/items/', data: {
      'product_id': productId,
      'quantity': quantity,
      if (customisation != null) 'customisation': customisation.toJson(),
    });
    return CartItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CartItemModel> updateItem({
    required int itemId,
    int? quantity,
    CustomisationDetails? customisation,
  }) async {
    final response = await _dio.patch('/orders/cart/items/$itemId/', data: {
      if (quantity != null) 'quantity': quantity,
      if (customisation != null) 'customisation': customisation.toJson(),
    });
    return CartItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeItem(int itemId) async {
    await _dio.delete('/orders/cart/items/$itemId/');
  }

  Future<void> clearCart() async {
    await _dio.post('/orders/cart/clear/');
  }

  String? parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return 'Something went wrong. Please try again.';
  }
}

class CustomisationRepository {
  CustomisationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<WrappingOptionModel>> fetchWrappingOptions() async {
    final response = await _dio.get('/customisation/wrapping-options/');
    return (response.data as List<dynamic>)
        .map((e) => WrappingOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageTemplateModel>> fetchMessageTemplates({String? occasion}) async {
    final response = await _dio.get(
      '/customisation/message-templates/',
      queryParameters: occasion != null ? {'occasion': occasion} : null,
    );
    return (response.data as List<dynamic>)
        .map((e) => MessageTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> uploadPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/customisation/upload-photo/', data: formData);
    return (response.data as Map<String, dynamic>)['photo_url'] as String;
  }
}