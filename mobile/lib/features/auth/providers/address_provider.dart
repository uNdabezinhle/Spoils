import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/address_model.dart';

final addressesProvider = FutureProvider.autoDispose<List<AddressModel>>((ref) async {
  return ref.read(authRepositoryProvider).fetchAddresses();
});

final addressFormProvider = StateNotifierProvider.autoDispose<AddressFormNotifier, AsyncValue<void>>((ref) {
  return AddressFormNotifier(ref.read(authRepositoryProvider), ref);
});

class AddressFormNotifier extends StateNotifier<AsyncValue<void>> {
  AddressFormNotifier(this._repository, this._ref) : super(const AsyncData(null));

  final AuthRepository _repository;
  final Ref _ref;

  Future<bool> save(AddressModel address) async {
    state = const AsyncLoading();
    try {
      if (address.id == null) {
        await _repository.createAddress(address);
      } else {
        await _repository.updateAddress(address);
      }
      _ref.invalidate(addressesProvider);
      state = const AsyncData(null);
      return true;
    } on DioException catch (e) {
      state = AsyncError(_repository.parseErrorMessage(e) ?? 'Error', StackTrace.current);
      return false;
    }
  }

  Future<bool> remove(int id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteAddress(id);
      _ref.invalidate(addressesProvider);
      state = const AsyncData(null);
      return true;
    } on DioException catch (e) {
      state = AsyncError(_repository.parseErrorMessage(e) ?? 'Error', StackTrace.current);
      return false;
    }
  }
}