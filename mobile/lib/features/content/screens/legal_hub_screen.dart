import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Terms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Your trust matters to us. Spoil is built POPIA-first — your data stays yours.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: SpoilColors.teal),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/content/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: SpoilColors.teal),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/content/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: SpoilColors.teal),
                  title: const Text('About Spoil'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/content/about'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: SpoilColors.teal),
                  title: const Text('FAQs'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/content/faq'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}