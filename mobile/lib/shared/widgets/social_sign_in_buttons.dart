import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/social_auth_service.dart';
import '../../core/theme/spoil_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final social = ref.watch(socialAuthServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: TextStyle(color: SpoilColors.charcoalMuted, fontSize: 13)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        if (social.isGoogleConfigured)
          OutlinedButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    final ok = await ref.read(authProvider.notifier).socialSignIn('google');
                    if (ok) onSuccess();
                  },
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: SpoilColors.teal),
            label: const Text('Google'),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: auth.isLoading
              ? null
              : () async {
                  final ok = await ref.read(authProvider.notifier).socialSignIn('apple');
                  if (ok) onSuccess();
                },
          icon: const Icon(Icons.apple, color: SpoilColors.charcoal),
          label: const Text('Apple'),
        ),
        if (!social.isGoogleConfigured)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Google sign-in activates when GOOGLE_CLIENT_ID is set at build time.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}