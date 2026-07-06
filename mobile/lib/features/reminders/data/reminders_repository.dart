import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/recipient_model.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(dio: ref.watch(apiClientProvider));
});

class RemindersRepository {
  RemindersRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<RecipientModel>> fetchRecipients() async {
    final response = await _dio.get('/reminders/recipients/');
    return (response.data as List<dynamic>)
        .map((e) => RecipientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UpcomingOccasionModel>> fetchUpcoming() async {
    final response = await _dio.get('/reminders/upcoming/');
    return (response.data as List<dynamic>)
        .map((e) => UpcomingOccasionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipientModel> createRecipient(RecipientModel recipient) async {
    final response = await _dio.post('/reminders/recipients/', data: recipient.toJson());
    return RecipientModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipientModel> updateRecipient(RecipientModel recipient) async {
    final response = await _dio.patch('/reminders/recipients/${recipient.id}/', data: recipient.toJson());
    return RecipientModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecipient(int id) async {
    await _dio.delete('/reminders/recipients/$id/');
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