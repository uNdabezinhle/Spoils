import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/loyalty_models.dart';

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository(dio: ref.watch(apiClientProvider));
});

class LoyaltyRepository {
  LoyaltyRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<LoyaltyAccountModel> fetchAccount() async {
    final response = await _dio.get('/loyalty/me/');
    return LoyaltyAccountModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PointsLedgerEntryModel>> fetchHistory() async {
    final response = await _dio.get('/loyalty/history/');
    return (response.data as List<dynamic>)
        .map((e) => PointsLedgerEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> previewRedeem(int points) async {
    final response = await _dio.post('/loyalty/preview-redeem/', data: {'points_to_redeem': points});
    return response.data as Map<String, dynamic>;
  }
}