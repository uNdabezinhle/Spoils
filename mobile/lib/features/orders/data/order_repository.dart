import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(dio: ref.watch(apiClientProvider));
});

class OrderRepository {
  OrderRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CheckoutPreview> previewCheckout({
    required String deliveryType,
    String? promoCode,
  }) async {
    final response = await _dio.post('/orders/checkout/preview/', data: {
      'delivery_type': deliveryType,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
    });
    return CheckoutPreview.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentInitResult> initiateCheckout({
    required int addressId,
    required String deliveryDate,
    required String deliveryType,
    String? promoCode,
  }) async {
    final response = await _dio.post('/orders/checkout/initiate/', data: {
      'address_id': addressId,
      'delivery_date': deliveryDate,
      'delivery_type': deliveryType,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
    });
    return PaymentInitResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderModel> verifyPayment({
    required String reference,
    required int orderId,
  }) async {
    final response = await _dio.post('/orders/checkout/verify/', data: {
      'reference': reference,
      'order_id': orderId,
    });
    final data = response.data as Map<String, dynamic>;
    return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> fetchOrders() async {
    final response = await _dio.get('/orders/');
    return (response.data as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> fetchOrder(int id) async {
    final response = await _dio.get('/orders/$id/');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ReceiptData> fetchReceipt(int id) async {
    final response = await _dio.get('/orders/$id/receipt/');
    return ReceiptData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> reorder(int orderId) async {
    final response = await _dio.post('/orders/$orderId/reorder/');
    return response.data['items_added'] as int? ?? 0;
  }

  String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return 'Something went wrong. Please try again.';
  }
}