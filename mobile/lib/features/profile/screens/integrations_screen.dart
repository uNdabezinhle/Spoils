import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/social_auth_service.dart';
import '../../../core/theme/spoil_colors.dart';

const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
const _firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
const _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
const _firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');

class IntegrationsScreen extends ConsumerWidget {
  const IntegrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialAuthServiceProvider);
    final pushReady = _firebaseProjectId.isNotEmpty &&
        _firebaseApiKey.isNotEmpty &&
        _firebaseAppId.isNotEmpty &&
        _firebaseMessagingSenderId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Integrations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Build-time configuration',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Push notifications and social sign-in activate when you pass the values below as --dart-define at build time (see mobile/scripts/build_production.ps1).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _IntegrationTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push notifications (Firebase)',
            configured: pushReady,
            detail: pushReady
                ? 'Firebase project $_firebaseProjectId is configured for this build.'
                : 'Set FIREBASE_PROJECT_ID, FIREBASE_API_KEY, FIREBASE_APP_ID, and FIREBASE_MESSAGING_SENDER_ID.',
          ),
          _IntegrationTile(
            icon: Icons.g_mobiledata_rounded,
            title: 'Google sign-in',
            configured: social.isGoogleConfigured,
            detail: social.isGoogleConfigured
                ? 'GOOGLE_CLIENT_ID is set for this build.'
                : 'Set GOOGLE_CLIENT_ID (same value as backend GOOGLE_OAUTH_CLIENT_ID).',
          ),
          _IntegrationTile(
            icon: Icons.apple,
            title: 'Apple sign-in',
            configured: true,
            detail: 'Uses native Sign in with Apple. Ensure APPLE_CLIENT_ID is set on the backend.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SpoilColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Example build', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                const SelectableText(
                  'flutter run \\\n'
                  '  --dart-define=API_BASE_URL=https://api.spoils.co.za/api/v1 \\\n'
                  '  --dart-define=FIREBASE_PROJECT_ID=your-project \\\n'
                  '  --dart-define=FIREBASE_API_KEY=... \\\n'
                  '  --dart-define=FIREBASE_APP_ID=... \\\n'
                  '  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \\\n'
                  '  --dart-define=GOOGLE_CLIENT_ID=...apps.googleusercontent.com',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({
    required this.icon,
    required this.title,
    required this.configured,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final bool configured;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = configured ? SpoilColors.teal : SpoilColors.gold;
    final label = configured ? 'Ready' : 'Needs setup';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title),
        subtitle: Text(detail),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}