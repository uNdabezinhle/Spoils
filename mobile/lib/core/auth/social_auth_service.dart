import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

const _googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) => const SocialAuthService());

class SocialAuthResult {
  const SocialAuthResult({
    required this.provider,
    required this.idToken,
    this.firstName = '',
    this.lastName = '',
  });

  final String provider;
  final String idToken;
  final String firstName;
  final String lastName;
}

class SocialAuthService {
  const SocialAuthService();

  bool get isGoogleConfigured => _googleClientId.isNotEmpty;

  Future<SocialAuthResult?> signInWithGoogle() async {
    if (!isGoogleConfigured) return null;
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? _googleClientId : null,
      scopes: const ['email', 'profile'],
    );
    final account = await googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) return null;
    return SocialAuthResult(provider: 'google', idToken: idToken);
  }

  Future<SocialAuthResult?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) return null;
      return SocialAuthResult(
        provider: 'apple',
        idToken: idToken,
        firstName: credential.givenName ?? '',
        lastName: credential.familyName ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}