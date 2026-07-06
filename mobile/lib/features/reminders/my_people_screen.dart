import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class MyPeopleScreen extends StatelessWidget {
  const MyPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_outline,
      title: 'My People',
      subtitle: 'Never miss a birthday or anniversary again. Add the people you love — we\'ll remind you in time to spoil them.',
      action: ElevatedButton(onPressed: () {}, child: const Text('Add someone special')),
    );
  }
}