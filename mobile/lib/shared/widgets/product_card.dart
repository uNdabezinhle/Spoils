import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spoil_colors.dart';
import '../../features/catalog/models/product_model.dart';
import '../utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.compact = false,
  });

  final ProductModel product;
  final double? width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/product/${product.slug}'),
          child: compact ? _buildCompact(context) : _buildFull(context),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(url: product.imageUrl, height: 90),
          const SizedBox(height: 10),
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(formatZar(product.basePrice), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.teal, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductImage(url: product.imageUrl, height: 140),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.categoryName.isNotEmpty)
                Text(product.categoryName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.gold)),
              const SizedBox(height: 4),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(formatZar(product.basePrice), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SpoilColors.teal)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        height: height,
        width: double.infinity,
        color: SpoilColors.blush,
        child: const Icon(Icons.card_giftcard, color: SpoilColors.teal, size: 40),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: height,
        color: SpoilColors.blush,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: SpoilColors.blush,
        child: const Icon(Icons.card_giftcard, color: SpoilColors.teal, size: 40),
      ),
    );
  }
}