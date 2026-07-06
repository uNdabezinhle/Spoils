import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/spoil_colors.dart';
import '../../features/cart/models/cart_models.dart';
import '../../features/catalog/models/product_model.dart';

class GiftPreviewCard extends StatelessWidget {
  const GiftPreviewCard({
    super.key,
    required this.product,
    required this.customisation,
  });

  final ProductModel product;
  final CustomisationDetails customisation;

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return SpoilColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ribbonColor = _parseColor(
      customisation.ribbonColor.isNotEmpty ? customisation.ribbonColor : '#C9A227',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ribbonColor, width: 3),
                color: SpoilColors.cream,
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: _buildImage(),
                  ),
                  if (customisation.wrappingName.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: ribbonColor.withOpacity(0.15),
                      child: Text(
                        customisation.wrappingName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (customisation.message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.format_quote, color: SpoilColors.teal, size: 20),
                          const SizedBox(height: 8),
                          Text(
                            customisation.message,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final photoUrl = customisation.photoUrl;
    if (photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _productImage(),
      );
    }
    return _productImage();
  }

  Widget _productImage() {
    if (product.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: product.imageUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 160,
      color: SpoilColors.blush,
      child: const Center(child: Icon(Icons.card_giftcard, size: 48, color: SpoilColors.teal)),
    );
  }
}