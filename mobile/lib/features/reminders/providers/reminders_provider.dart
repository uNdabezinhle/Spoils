import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../catalog/models/product_model.dart';
import '../data/reminders_repository.dart';
import '../models/recipient_model.dart';
import '../services/device_import_service.dart';

final deviceImportServiceProvider = Provider<DeviceImportService>((ref) => DeviceImportService());

final recipientsProvider = FutureProvider.autoDispose<List<RecipientModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(remindersRepositoryProvider).fetchRecipients();
});

final upcomingOccasionsProvider = FutureProvider.autoDispose<List<UpcomingOccasionModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(remindersRepositoryProvider).fetchUpcoming();
});

final inAppRemindersProvider = FutureProvider.autoDispose<List<InAppReminderModel>>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return [];
  return ref.read(remindersRepositoryProvider).fetchInAppReminders();
});

final occasionDetailProvider = FutureProvider.autoDispose.family<OccasionDetailModel, int>((ref, id) async {
  return ref.read(remindersRepositoryProvider).fetchOccasionDetail(id);
});

final occasionSuggestionsProvider = FutureProvider.autoDispose.family<List<ProductModel>, int>((ref, id) async {
  return ref.read(remindersRepositoryProvider).fetchOccasionSuggestions(id);
});

final occasionCalendarProvider =
    FutureProvider.autoDispose.family<CalendarMonthModel, (int, int)>((ref, params) async {
  return ref.read(remindersRepositoryProvider).fetchCalendar(year: params.$1, month: params.$2);
});

final familyGroupProvider = FutureProvider.autoDispose<FamilyGroupModel?>((ref) async {
  if (!ref.watch(authProvider).isAuthenticated) return null;
  return ref.read(remindersRepositoryProvider).fetchFamilyGroup();
});

final familyCalendarProvider =
    FutureProvider.autoDispose.family<FamilyCalendarMonthModel, (int, int)>((ref, params) async {
  return ref.read(remindersRepositoryProvider).fetchFamilyCalendar(year: params.$1, month: params.$2);
});

final recipientFormProvider = StateNotifierProvider.autoDispose<RecipientFormNotifier, AsyncValue<void>>((ref) {
  return RecipientFormNotifier(ref.read(remindersRepositoryProvider), ref);
});

class RecipientFormNotifier extends StateNotifier<AsyncValue<void>> {
  RecipientFormNotifier(this._repository, this._ref) : super(const AsyncData(null));

  final RemindersRepository _repository;
  final Ref _ref;

  Future<bool> save(RecipientModel recipient) async {
    state = const AsyncLoading();
    try {
      if (recipient.id == null) {
        await _repository.createRecipient(recipient);
      } else {
        await _repository.updateRecipient(recipient);
      }
      _ref.invalidate(recipientsProvider);
      _ref.invalidate(upcomingOccasionsProvider);
      _ref.invalidate(inAppRemindersProvider);
      _ref.invalidate(occasionCalendarProvider);
      state = const AsyncData(null);
      return true;
    } on DioException catch (e) {
      state = AsyncError(_repository.parseError(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> remove(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteRecipient(id);
      _ref.invalidate(recipientsProvider);
      _ref.invalidate(upcomingOccasionsProvider);
      _ref.invalidate(inAppRemindersProvider);
      _ref.invalidate(occasionCalendarProvider);
      state = const AsyncData(null);
      return true;
    } on DioException catch (e) {
      state = AsyncError(_repository.parseError(e), StackTrace.current);
      return false;
    }
  }
}