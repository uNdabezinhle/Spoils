import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../data/order_repository.dart';
import '../models/order_model.dart';

final receiptProvider = FutureProvider.autoDispose.family<ReceiptData, int>((ref, id) {
  return ref.read(orderRepositoryProvider).fetchReceipt(id);
});

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load receipt.\n$e')),
        data: (receipt) {
          final order = receipt.order;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: SpoilColors.cream,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      receipt.receiptTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SpoilColors.teal),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      receipt.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    if (receipt.customerName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(receipt.customerName, textAlign: TextAlign.center),
                    ],
                    const Divider(height: 32),
                    _ReceiptRow('Order', '#${order.id}'),
                    _ReceiptRow('Date', order.createdAt.split('T').first),
                    _ReceiptRow('Status', order.statusLabel),
                    _ReceiptRow('Delivery', order.deliveryDate),
                    const SizedBox(height: 16),
                    Text('Items', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${item.productName} × ${item.quantity}')),
                            Text(formatZar(item.lineTotal)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                    _ReceiptRow('Subtotal', formatZar(order.subtotal)),
                    _ReceiptRow('Total', formatZar(order.totalAmount), bold: true),
                    const SizedBox(height: 24),
                    Text(
                      'Thank you for spoiling someone properly.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style?.copyWith(fontWeight: bold ? FontWeight.w700 : null)),
        ],
      ),
    );
  }
}