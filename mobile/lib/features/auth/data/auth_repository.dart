import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/address_model.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<({UserModel user, AuthTokens tokens})> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
    String phone = '',
  }) async {
    final response = await _dio.post('/auth/register/', data: {
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    });
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<({UserModel user, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    return _parseAuthResponse(response.data as Map<String, dynamic>);
  }

  Future<UserModel> fetchMe() async {
    final response = await _dio.get('/auth/me/');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final response = await _dio.patch('/auth/me/', data: {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    });
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> requestPasswordReset(String email) async {
    await _dio.post('/auth/password-reset/', data: {'email': email});
  }

  Future<void> confirmPasswordReset({
    required String uid,
    required String token,
    required String password,
  }) async {
    await _dio.post('/auth/password-reset/confirm/', data: {
      'uid': uid,
      'token': token,
      'password': password,
    });
  }

  Future<List<AddressModel>> fetchAddresses() async {
    final response = await _dio.get('/auth/addresses/');
    final list = response.data as List<dynamic>;
    return list.map((e) => AddressModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AddressModel> createAddress(AddressModel address) async {
    final response = await _dio.post('/auth/addresses/', data: address.toJson());
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    final response = await _dio.patch('/auth/addresses/${address.id}/', data: address.toJson());
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) async {
    await _dio.delete('/auth/addresses/$id/');
  }

  Future<void> logout() async {
    final refresh = await _tokenStorage.getRefreshToken();
    try {
      if (refresh != null) {
        await _dio.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {
      // Best-effort server logout; always clear local tokens.
    }
    await _tokenStorage.clear();
  }

  Future<({UserModel user, AuthTokens tokens})> _parseAuthResponse(Map<String, dynamic> data) async {
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    await _tokenStorage.saveTokens(access: tokens.access, refresh: tokens.refresh);
    return (user: user, tokens: tokens);
  }

  String? parseErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) return data['detail'].toString();
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }
    return 'Something went wrong. Please try again.';
  }
}