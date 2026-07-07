import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/subscription_models.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  return SubscriptionsRepository(dio: ref.watch(apiClientProvider));
});

class SubscriptionsRepository {
  SubscriptionsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<SubscriptionPlanModel>> fetchPlans() async {
    final response = await _dio.get('/subscriptions/plans/');
    return (response.data as List<dynamic>)
        .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserSubscriptionModel>> fetchMySubscriptions() async {
    final response = await _dio.get('/subscriptions/me/');
    return (response.data as List<dynamic>)
        .map((e) => UserSubscriptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SubscriptionPaymentInitResult> initiateSubscribe({
    required int planId,
    String recipientName = '',
    String notes = '',
    int? occasionId,
  }) async {
    final response = await _dio.post('/subscriptions/subscribe/', data: {
      'plan_id': planId,
      if (recipientName.isNotEmpty) 'recipient_name': recipientName,
      if (notes.isNotEmpty) 'notes': notes,
      if (occasionId != null) 'occasion_id': occasionId,
    });
    return SubscriptionPaymentInitResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserSubscriptionModel> verifySubscribe({
    required int subscriptionId,
    required String reference,
  }) async {
    final response = await _dio.post('/subscriptions/subscribe/verify/', data: {
      'subscription_id': subscriptionId,
      'reference': reference,
    });
    final data = response.data as Map<String, dynamic>;
    return UserSubscriptionModel.fromJson(data['subscription'] as Map<String, dynamic>);
  }

  Future<UserSubscriptionModel> cancelSubscription(int id) async {
    final response = await _dio.post('/subscriptions/$id/cancel/');
    return UserSubscriptionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SubscriptionFulfillmentModel>> fetchFulfillments() async {
    final response = await _dio.get('/subscriptions/fulfillments/');
    final data = response.data as Map<String, dynamic>;
    return (data['fulfillments'] as List<dynamic>)
        .map((e) => SubscriptionFulfillmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (data is Map) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
      }
    }
    return 'Something went wrong. Please try again.';
  }
}