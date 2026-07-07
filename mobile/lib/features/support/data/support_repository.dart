import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(dio: ref.watch(apiClientProvider));
});

class SupportRepository {
  SupportRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<SupportConversationModel> fetchConversation({String? since}) async {
    final response = await _dio.get(
      '/support/conversation/',
      queryParameters: since != null ? {'since': since} : null,
    );
    return SupportConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SupportMessageModel> sendMessage(String body) async {
    final response = await _dio.post('/support/conversation/', data: {'body': body});
    return SupportMessageModel.fromJson(response.data as Map<String, dynamic>);
  }
}