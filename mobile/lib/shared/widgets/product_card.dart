import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/spoil_colors.dart';
import '../../core/theme/spoil_decorations.dart';
import '../../features/catalog/models/product_model.dart';
import '../utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.width,
    this.compact = false,
    this.showFeaturedBadge = false,
  });

  final ProductModel product;
  final double? width;
  final bool compact;
  final bool showFeaturedBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SpoilColors.radiusLg),
          onTap: () => context.push('/product/${product.slug}'),
          child: Ink(
            decoration: SpoilDecorations.card(),
            child: compact ? _buildCompact(context) : _buildFull(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductImageStack(
          url: product.imageUrl,
          height: 120,
          price: product.basePrice,
          showBadge: showFeaturedBadge,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductImageStack(
          url: product.imageUrl,
          height: 150,
          price: product.basePrice,
          showBadge: showFeaturedBadge || product.isFeatured,
        ),
        Padding(
          padding: const EdgeInsets.all(14),
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
              const SizedBox(height: 4),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductImageStack extends StatelessWidget {
  const _ProductImageStack({
    required this.url,
    required this.height,
    required this.price,
    this.showBadge = false,
  });

  final String url;
  final double height;
  final String price;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SpoilColors.radiusLg)),
      child: Stack(
        children: [
          _ProductImage(url: url, height: height),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SpoilColors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formatZar(price),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SpoilColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Featured',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SpoilColors.charcoal,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
        ],
      ),
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
        color: SpoilColors.tealTint,
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
        color: SpoilColors.tealTint,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SpoilColors.teal)),
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: SpoilColors.tealTint,
        child: const Icon(Icons.card_giftcard, color: SpoilColors.teal, size: 40),
      ),
    );
  }
}