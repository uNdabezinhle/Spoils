import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/empty_state.dart';
import 'models/order_model.dart';
import 'providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load orders.\n$e'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(ordersProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No orders yet',
              subtitle:
                  'When you spoil someone, your orders will appear here — beautifully tracked from gift to doorstep.',
              action: ElevatedButton(
                onPressed: () => context.go('/shop'),
                child: const Text('Browse gifts'),
              ),
            );
          }

          return RefreshIndicator(
            color: SpoilColors.teal,
            onRefresh: () async => ref.invalidate(ordersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: orders[i]),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(order.createdAt);
    final dateLabel = date != null ? DateFormat('d MMM yyyy').format(date) : order.createdAt;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SpoilColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, color: SpoilColors.teal),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${order.statusLabel} · $dateLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · Delivers ${order.deliveryDate}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                formatZar(order.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SpoilColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}