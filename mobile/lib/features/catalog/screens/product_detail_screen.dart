import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../providers/catalog_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Gift details')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load this gift.\n$e')),
        data: (product) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 280,
                          color: SpoilColors.blush,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 280,
                          color: SpoilColors.blush,
                          child: const Icon(Icons.card_giftcard, size: 64, color: SpoilColors.teal),
                        ),
                      )
                    else
                      Container(
                        height: 280,
                        color: SpoilColors.blush,
                        child: const Center(child: Icon(Icons.card_giftcard, size: 64, color: SpoilColors.teal)),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.categoryName.isNotEmpty)
                            Text(
                              product.categoryName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SpoilColors.gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          const SizedBox(height: 8),
                          Text(product.name, style: Theme.of(context).textTheme.displayMedium),
                          const SizedBox(height: 8),
                          Text(
                            formatZar(product.basePrice),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: SpoilColors.teal),
                          ),
                          const SizedBox(height: 20),
                          Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                          if (product.deliveryInfo.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: SpoilColors.blush.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, color: SpoilColors.teal),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
                                        Text(product.deliveryInfo, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/personalise/$slug'),
                        child: const Text('Personalise & add to cart'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Make it special with a message, photo, or beautiful wrapping.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}