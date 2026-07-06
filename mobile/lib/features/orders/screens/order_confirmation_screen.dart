import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../providers/order_provider.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => _ConfirmationBody(
          orderId: orderId,
          child: Text('Order placed! Details loading…\n$e'),
        ),
        data: (order) => _ConfirmationBody(
          orderId: orderId,
          child: Column(
            children: [
              Text(
                'Order #${order.id}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: SpoilColors.teal),
              ),
              const SizedBox(height: 8),
              Text(
                formatZar(order.totalAmount),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Delivering on ${order.deliveryDate}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  const _ConfirmationBody({required this.orderId, required this.child});

  final int orderId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SpoilColors.blush,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 64, color: SpoilColors.teal),
            ),
            const SizedBox(height: 24),
            Text(
              'Spoiled properly!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you — your gift is on its way. We\'ll keep you updated every step of the journey.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            child,
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/orders/$orderId'),
                child: const Text('View order'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/shop'),
                child: const Text('Keep shopping'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}