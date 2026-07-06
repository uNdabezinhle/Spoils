import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/social_auth_service.dart';
import '../../../core/notifications/device_token_service.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    deviceTokenService: ref.watch(deviceTokenServiceProvider),
    socialAuthService: ref.watch(socialAuthServiceProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository repository,
    required TokenStorage tokenStorage,
    required DeviceTokenService deviceTokenService,
    required SocialAuthService socialAuthService,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        _deviceTokenService = deviceTokenService,
        _socialAuthService = socialAuthService,
        super(const AuthState(status: AuthStatus.unknown));

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final DeviceTokenService _deviceTokenService;
  final SocialAuthService _socialAuthService;

  final _changes = ValueNotifier<int>(0);
  ValueListenable<int> get changes => _changes;

  void _notifyRouter() => _changes.value++;

  Future<void> restoreSession() async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      _notifyRouter();
      return;
    }
    try {
      final user = await _repository.fetchMe();
      state = AuthState(status: AuthStatus.authenticated, user: user);
      await _deviceTokenService.registerIfAuthenticated();
    } catch (_) {
      await _tokenStorage.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
    _notifyRouter();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      await _deviceTokenService.registerIfAuthenticated();
      _notifyRouter();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _repository.parseErrorMessage(e),
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
    String phone = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = AuthState(status: AuthStatus.authenticated, user: result.user);
      await _deviceTokenService.registerIfAuthenticated();
      _notifyRouter();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _repository.parseErrorMessage(e),
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> socialSignIn(String provider) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final SocialAuthResult? result = provider == 'apple'
          ? await _socialAuthService.signInWithApple()
          : await _socialAuthService.signInWithGoogle();
      if (result == null) {
        state = state.copyWith(isLoading: false, error: 'Sign-in was cancelled or is not configured.');
        return false;
      }
      final authResult = await _repository.socialLogin(
        provider: result.provider,
        idToken: result.idToken,
        firstName: result.firstName,
        lastName: result.lastName,
      );
      state = AuthState(status: AuthStatus.authenticated, user: authResult.user);
      await _deviceTokenService.registerIfAuthenticated();
      _notifyRouter();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _repository.parseErrorMessage(e),
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.uploadAvatar(filePath);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _repository.parseErrorMessage(e));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: _repository.parseErrorMessage(e));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
    _notifyRouter();
  }

  Future<void> syncFromStorage() async {
    final access = await _tokenStorage.getAccessToken();
    if (access == null && state.isAuthenticated) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      _notifyRouter();
    }
  }
}