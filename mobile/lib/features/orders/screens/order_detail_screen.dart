import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/order_status_stepper.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/order_repository.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Receipt',
            onPressed: () => context.push('/orders/$orderId/receipt'),
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load order.\n$e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.statusLabel, style: Theme.of(context).textTheme.titleMedium),
                        Text(formatZar(order.totalAmount), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: SpoilColors.teal)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Placed ${order.createdAt.split('T').first}'),
                    Text('Delivery: ${order.deliveryDate} · ${order.deliveryType == 'express' ? 'Express' : 'Standard'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (order.timeline.isNotEmpty) ...[
              OrderStatusStepper(timeline: order.timeline),
              const SizedBox(height: 16),
            ],
            if (order.deliveryAddress.isNotEmpty) ...[
              Text('Delivery address', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(order.deliveryAddress['recipient_name']?.toString() ?? ''),
                  subtitle: Text(_formatAddress(order.deliveryAddress)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...order.items.map((item) => Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.productImageUrl.isNotEmpty
                          ? CachedNetworkImage(imageUrl: item.productImageUrl, width: 48, height: 48, fit: BoxFit.cover)
                          : Container(
                              width: 48,
                              height: 48,
                              color: SpoilColors.blush,
                              child: const Icon(Icons.card_giftcard, color: SpoilColors.teal, size: 24),
                            ),
                    ),
                    title: Text(item.productName),
                    subtitle: Text('Qty ${item.quantity}'),
                    trailing: Text(formatZar(item.lineTotal)),
                  ),
                )),
            const SizedBox(height: 24),
            if (order.isPaid)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _reorder(context, ref),
                  icon: const Icon(Icons.replay),
                  label: const Text('Order again'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> addr) {
    final parts = [
      addr['street_address'],
      addr['suburb'],
      addr['city'],
      addr['province'],
      addr['postal_code'],
    ].where((p) => p != null && p.toString().isNotEmpty).map((p) => p.toString());
    return parts.join(', ');
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    try {
      final count = await ref.read(orderRepositoryProvider).reorder(orderId);
      ref.invalidate(cartProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count item(s) added to your cart.')),
        );
        context.push('/cart');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reorder. Please try again.')),
        );
      }
    }
  }
}