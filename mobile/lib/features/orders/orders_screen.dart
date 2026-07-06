import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'No orders yet',
      subtitle: 'When you spoil someone, your orders will appear here — beautifully tracked from gift to doorstep.',
    );
  }
}