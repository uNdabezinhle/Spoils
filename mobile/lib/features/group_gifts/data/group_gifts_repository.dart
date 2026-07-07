import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/group_gift_models.dart';

final groupGiftsRepositoryProvider = Provider<GroupGiftsRepository>((ref) {
  return GroupGiftsRepository(dio: ref.watch(apiClientProvider));
});

class GroupGiftsRepository {
  GroupGiftsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<GroupGiftModel> createGroupGift({
    required String title,
    required int addressId,
    required String deliveryDate,
    String recipientName = '',
    String message = '',
    String deliveryType = 'standard',
  }) async {
    final response = await _dio.post('/group-gifts/', data: {
      'title': title,
      'address_id': addressId,
      'delivery_date': deliveryDate,
      if (recipientName.isNotEmpty) 'recipient_name': recipientName,
      if (message.isNotEmpty) 'message': message,
      'delivery_type': deliveryType,
    });
    return GroupGiftModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GroupGiftModel>> fetchMyGroupGifts() async {
    final response = await _dio.get('/group-gifts/');
    return (response.data as List<dynamic>)
        .map((e) => GroupGiftModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupGiftModel> fetchByToken(String token) async {
    final response = await _dio.get('/group-gifts/public/$token/');
    return GroupGiftModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupGiftPaymentInitResult> initiateContribution({
    required String token,
    required String amount,
    required String contributorName,
    required String contributorEmail,
    String message = '',
  }) async {
    final response = await _dio.post('/group-gifts/public/$token/contribute/', data: {
      'amount': amount,
      'contributor_name': contributorName,
      'contributor_email': contributorEmail,
      if (message.isNotEmpty) 'message': message,
    });
    return GroupGiftPaymentInitResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupGiftModel> verifyContribution({
    required int contributionId,
    required String reference,
  }) async {
    final response = await _dio.post('/group-gifts/contribute/verify/', data: {
      'contribution_id': contributionId,
      'reference': reference,
    });
    final data = response.data as Map<String, dynamic>;
    return GroupGiftModel.fromJson(data['group_gift'] as Map<String, dynamic>);
  }

  String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return 'Something went wrong. Please try again.';
  }
}