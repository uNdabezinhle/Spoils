import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../models/subscription_models.dart';
import '../providers/subscriptions_provider.dart';

class SubscriptionBoxScreen extends ConsumerWidget {
  const SubscriptionBoxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fulfillmentsAsync = ref.watch(subscriptionFulfillmentsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/subscriptions'),
        ),
        title: const Text('Your box'),
      ),
      body: RefreshIndicator(
        color: SpoilColors.teal,
        onRefresh: () async => ref.invalidate(subscriptionFulfillmentsProvider),
        child: fulfillmentsAsync.when(
          loading: () => ListView(
            children: const [
              SizedBox(height: 120),
              Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [Text('Could not load your boxes.\n$e')],
          ),
          data: (boxes) {
            if (boxes.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.inventory_2_outlined, size: 64, color: SpoilColors.teal.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No subscription boxes yet',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When your subscription renews, we create an order and it will show up here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: OutlinedButton(
                      onPressed: () => context.go('/subscriptions'),
                      child: const Text('View subscription plans'),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Past & upcoming boxes from your subscriptions',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...boxes.map((box) => _FulfillmentCard(box: box)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({required this.box});

  final SubscriptionFulfillmentModel box;

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('d MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (box.status) {
      'paid' => 'Paid',
      'processing' => 'Preparing your box',
      'shipped' => 'On the way',
      'delivered' => 'Delivered',
      'pending' => 'Pending',
      _ => box.status,
    };
    final statusColor = switch (box.status) {
      'delivered' => SpoilColors.teal,
      'shipped' => SpoilColors.gold,
      'processing' => SpoilColors.gold,
      _ => SpoilColors.charcoalMuted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/orders/${box.orderId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (box.productImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: box.productImageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholderImage(),
                  ),
                )
              else
                _placeholderImage(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(box.productName, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Delivery ${_formatDate(box.deliveryDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatZar(box.totalAmount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SpoilColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SpoilColors.charcoalMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: SpoilColors.blush,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.card_giftcard, color: SpoilColors.teal),
    );
  }
}