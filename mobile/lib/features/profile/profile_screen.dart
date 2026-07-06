import 'package:flutter/material.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/spoil_logo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(child: SpoilLogo(showTagline: true)),
        const SizedBox(height: 32),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: SpoilColors.teal),
                title: const Text('Sign in'),
                subtitle: const Text('Phase 2 — create your Spoil account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline, color: SpoilColors.teal),
                title: const Text('How it works'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: SpoilColors.teal),
                title: const Text('Privacy & Terms'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}