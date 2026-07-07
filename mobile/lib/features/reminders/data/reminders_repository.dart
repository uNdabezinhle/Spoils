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

  Future<int?> approveAutoGift({
    required int occasionId,
    required int addressId,
    int? productId,
  }) async {
    final response = await _dio.post(
      '/reminders/occasions/$occasionId/approve-gift/',
      data: {
        'address_id': addressId,
        if (productId != null) 'product_id': productId,
      },
    );
    return (response.data as Map<String, dynamic>)['order_id'] as int?;
  }

  Future<void> rejectAutoGift(int occasionId) async {
    await _dio.post('/reminders/occasions/$occasionId/reject-gift/');
  }

  Future<Map<String, dynamic>> importContacts(List<Map<String, dynamic>> contacts) async {
    final response = await _dio.post('/reminders/import/contacts/', data: {'contacts': contacts});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> importCalendarEvents(List<Map<String, dynamic>> events) async {
    final response = await _dio.post('/reminders/import/calendar/', data: {'events': events});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSurpriseSettings(
    int occasionId, {
    bool? surpriseModeEnabled,
    String? surpriseBudget,
    bool? giftAnonymously,
    bool? shareWithFamily,
    int? surpriseAddressId,
    bool? autoSendEnabled,
  }) async {
    final response = await _dio.post('/reminders/occasions/$occasionId/surprise-settings/', data: {
      if (surpriseModeEnabled != null) 'surprise_mode_enabled': surpriseModeEnabled,
      if (surpriseBudget != null) 'surprise_budget': surpriseBudget,
      if (giftAnonymously != null) 'gift_anonymously': giftAnonymously,
      if (shareWithFamily != null) 'share_with_family': shareWithFamily,
      if (surpriseAddressId != null) 'surprise_address_id': surpriseAddressId,
      if (autoSendEnabled != null) 'auto_send_enabled': autoSendEnabled,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> markOccasionSent(int occasionId, {int? productId}) async {
    await _dio.post('/reminders/occasions/$occasionId/mark-sent/', data: {
      if (productId != null) 'product_id': productId,
    });
  }

  Future<void> leaveFamilyGroup() async {
    await _dio.post('/reminders/family/leave/');
  }

  Future<FamilyCalendarMonthModel> fetchFamilyCalendar({required int year, required int month}) async {
    final response = await _dio.get('/reminders/family/calendar/', queryParameters: {'year': year, 'month': month});
    return FamilyCalendarMonthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FamilyGroupModel?> fetchFamilyGroup() async {
    final response = await _dio.get('/reminders/family/');
    final data = response.data as Map<String, dynamic>;
    final group = data['group'];
    if (group == null) return null;
    return FamilyGroupModel.fromJson(group as Map<String, dynamic>);
  }

  Future<FamilyGroupModel> createFamilyGroup(String name) async {
    final response = await _dio.post('/reminders/family/', data: {'name': name});
    final data = response.data as Map<String, dynamic>;
    return FamilyGroupModel.fromJson(data['group'] as Map<String, dynamic>);
  }

  Future<FamilyGroupModel> joinFamilyGroup(String inviteCode) async {
    final response = await _dio.post('/reminders/family/join/', data: {'invite_code': inviteCode});
    final data = response.data as Map<String, dynamic>;
    return FamilyGroupModel.fromJson(data['group'] as Map<String, dynamic>);
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