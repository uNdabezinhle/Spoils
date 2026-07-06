import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spoil_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../../shared/widgets/spoil_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: SpoilLogo(showTagline: true)),
        const SizedBox(height: 24),
        if (auth.isAuthenticated && user != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: SpoilColors.blush,
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SpoilColors.teal),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                        Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                        if (user.phone.isNotEmpty)
                          Text(user.phone, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(
            children: [
              if (!auth.isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.person_outline, color: SpoilColors.teal),
                  title: const Text('Sign in'),
                  subtitle: const Text('Go on — spoil them properly'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/auth/login?redirect=${Uri.encodeComponent('/profile')}'),
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: SpoilColors.teal),
                  title: const Text('Edit profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined, color: SpoilColors.teal),
                  title: const Text('Delivery addresses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/addresses'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: SpoilColors.teal),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out — see you soon!')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.help_outline, color: SpoilColors.teal),
                title: const Text('How it works'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/content/how_it_works'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: SpoilColors.teal),
                title: const Text('Privacy & Terms'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/legal'),
              ),
              if (auth.isAuthenticated) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: SpoilColors.teal),
                  title: const Text('Your data (POPIA)'),
                  subtitle: const Text('Export or delete your information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/data'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}