import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../models/cart_models.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          cartAsync.maybeWhen(
            data: (cart) => cart.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmClear(context, ref),
                  ),
            orElse: () => null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load cart.\n$e')),
        data: (cart) {
          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64, color: SpoilColors.teal),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Find something special and spoil someone properly.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/shop'),
                      child: const Text('Browse gifts'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                ),
              ),
              _CartSummary(subtotal: cart.subtotal),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).clear();
    }
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = item.customisation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.productImageUrl.isNotEmpty
                  ? CachedNetworkImage(imageUrl: item.productImageUrl, width: 72, height: 72, fit: BoxFit.cover)
                  : Container(
                      width: 72,
                      height: 72,
                      color: SpoilColors.blush,
                      child: const Icon(Icons.card_giftcard, color: SpoilColors.teal),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: Theme.of(context).textTheme.titleMedium),
                  if (c.message.isNotEmpty)
                    Text(
                      '"${c.message}"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  if (c.wrappingName.isNotEmpty)
                    Text('${c.wrappingName} wrapping', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(formatZar(item.lineTotal), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SpoilColors.teal)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.quantity > 1
                            ? () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1)
                            : null,
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.subtotal});

  final String subtotal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: Theme.of(context).textTheme.titleMedium),
                Text(formatZar(subtotal), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SpoilColors.teal)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
                child: const Text('Proceed to checkout'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/group-gifts/create'),
                icon: const Icon(Icons.people_outline),
                label: const Text('Split with friends'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}