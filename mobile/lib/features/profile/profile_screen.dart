import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_constants.dart';
import '../../core/theme/spoil_colors.dart';
import '../../core/theme/spoil_decorations.dart';
import '../../shared/widgets/profile_avatar.dart';
import '../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          decoration: const BoxDecoration(
            gradient: SpoilDecorations.profileHeaderGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Text(
                BrandConstants.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              Text(
                BrandConstants.tagline,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.goldLight),
              ),
              if (auth.isAuthenticated && user != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        name: user.displayName,
                        avatarUrl: user.avatarUrl,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: SpoilDecorations.card(),
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
                      leading: const Icon(Icons.stars_outlined, color: SpoilColors.teal),
                      title: const Text('Spoil Points'),
                      subtitle: const Text('Earn & redeem loyalty rewards'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile/loyalty'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, color: SpoilColors.teal),
                      title: const Text('Live chat'),
                      subtitle: const Text('Chat with our support team'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/support'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.autorenew, color: SpoilColors.teal),
                      title: const Text('Subscriptions'),
                      subtitle: const Text('Monthly spoil plans & gift credit'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/subscriptions'),
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
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}