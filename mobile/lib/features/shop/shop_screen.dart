import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.storefront_outlined,
      title: 'Shop coming alive',
      subtitle: 'Phase 3 will bring the full gift catalogue — flowers, hampers, experiences, and more.',
      action: OutlinedButton(onPressed: () {}, child: const Text('Explore soon')),
    );
  }
}