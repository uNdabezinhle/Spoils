import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../catalog/models/product_model.dart';
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

  Future<OccasionDetailModel> fetchOccasionDetail(int id) async {
    final response = await _dio.get('/reminders/occasions/$id/');
    return OccasionDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProductModel>> fetchOccasionSuggestions(int id) async {
    final response = await _dio.get('/reminders/occasions/$id/suggestions/');
    final data = response.data as Map<String, dynamic>;
    return (data['products'] as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> snoozeOccasion(int id, {int days = 3}) async {
    await _dio.post('/reminders/occasions/$id/snooze/', data: {'days': days});
    return true;
  }

  Future<bool> skipOccasion(int id) async {
    await _dio.post('/reminders/occasions/$id/skip/');
    return true;
  }

  Future<CalendarMonthModel> fetchCalendar({required int year, required int month}) async {
    final response = await _dio.get('/reminders/calendar/', queryParameters: {'year': year, 'month': month});
    return CalendarMonthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<InAppReminderModel>> fetchInAppReminders() async {
    final response = await _dio.get('/reminders/in-app/');
    return (response.data as List<dynamic>)
        .map((e) => InAppReminderModel.fromJson(e as Map<String, dynamic>))
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