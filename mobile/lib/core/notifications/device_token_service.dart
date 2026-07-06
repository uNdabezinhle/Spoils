import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';

const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  return DeviceTokenService(repository: ref.watch(authRepositoryProvider));
});

class DeviceTokenService {
  DeviceTokenService({required AuthRepository repository}) : _repository = repository;

  final AuthRepository _repository;
  static bool _firebaseReady = false;
  String? _lastToken;

  Future<void> registerIfAuthenticated() async {
    if (_firebaseProjectId.isEmpty) return;
    try {
      await _ensureFirebase();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty || token == _lastToken) return;

      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';
      await _repository.registerDeviceToken(token: token, platform: platform);
      _lastToken = token;
    } catch (_) {
      // Firebase not configured for this build — push registration skipped.
    }
  }

  Future<void> _ensureFirebase() async {
    if (_firebaseReady) return;
    final options = _firebaseOptions();
    if (options == null) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    _firebaseReady = true;
  }

  FirebaseOptions? _firebaseOptions() {
    if (_firebaseProjectId.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
      appId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
      projectId: _firebaseProjectId,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: ''),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: ''),
    );
  }
}