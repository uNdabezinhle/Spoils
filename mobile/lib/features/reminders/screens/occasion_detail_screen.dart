import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/product_card.dart';
import '../../auth/models/address_model.dart';
import '../../auth/providers/address_provider.dart';
import '../data/reminders_repository.dart';
import '../models/auto_gift_proposal_model.dart';
import '../my_people_screen.dart';
import '../providers/reminders_provider.dart';

class OccasionDetailScreen extends ConsumerWidget {
  const OccasionDetailScreen({super.key, required this.occasionId});

  final int occasionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(occasionDetailProvider(occasionId));
    final suggestionsAsync = ref.watch(occasionSuggestionsProvider(occasionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Spoils reminder')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load occasion.\n$e')),
        data: (detail) {
          final date = DateTime.tryParse(detail.date);
          final dateLabel = date != null ? DateFormat('d MMMM yyyy').format(date) : detail.date;
          final countdown = detail.daysUntil <= 0
              ? 'Today!'
              : detail.daysUntil == 1
                  ? 'Tomorrow'
                  : 'In ${detail.daysUntil} days';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: SpoilColors.cream,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail.recipientName}\'s ${detail.typeLabel}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('$dateLabel · $countdown', style: Theme.of(context).textTheme.bodyMedium),
                      if (detail.recipientNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(detail.recipientNotes, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                      if (detail.skippedThisYear)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Reminders skipped for this year.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.charcoalMuted),
                          ),
                        ),
                      if (detail.snoozedUntil != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Snoozed until ${detail.snoozedUntil}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.charcoalMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (detail.hasPendingAutoGift) ...[
                const SizedBox(height: 16),
                _AutoGiftApprovalCard(
                  proposal: AutoGiftProposalModel.fromJson(detail.pendingAutoGift!),
                  onApprove: () => _approveAutoGift(context, ref, detail.pendingAutoGift!),
                  onReject: () => _rejectAutoGift(context, ref),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snooze(context, ref),
                      icon: const Icon(Icons.snooze),
                      label: const Text('Remind later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _skip(context, ref),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: const Text('Skip year'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Gift suggestions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Curated for ${detail.typeLabel.toLowerCase()} occasions.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              suggestionsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: SpoilColors.teal))),
                error: (_, __) => const Text('Could not load suggestions.'),
                data: (products) {
                  if (products.isEmpty) {
                    return ElevatedButton(
                      onPressed: () => context.go(shopPathForOccasion(detail.type)),
                      child: const Text('Browse all gifts'),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => ProductCard(product: products[i]),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go(shopPathForOccasion(detail.type)),
                child: const Text('See all matching gifts'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(remindersRepositoryProvider).snoozeOccasion(occasionId);
    if (context.mounted && ok) {
      ref.invalidate(occasionDetailProvider(occasionId));
      ref.invalidate(inAppRemindersProvider);
      ref.invalidate(upcomingOccasionsProvider);
      ref.invalidate(occasionCalendarProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder snoozed for 3 days.')));
    }
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(remindersRepositoryProvider).skipOccasion(occasionId);
    if (context.mounted && ok) {
      ref.invalidate(occasionDetailProvider(occasionId));
      ref.invalidate(inAppRemindersProvider);
      ref.invalidate(upcomingOccasionsProvider);
      ref.invalidate(occasionCalendarProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skipped for this year.')));
    }
  }

  Future<void> _approveAutoGift(BuildContext context, WidgetRef ref, Map<String, dynamic> proposalJson) async {
    final addresses = await ref.read(addressesProvider.future);
    if (!context.mounted) return;
    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a delivery address in Profile before approving.')),
      );
      return;
    }

    final addressId = await _pickAddress(context, addresses);
    if (addressId == null || !context.mounted) return;

    try {
      final orderId = await ref.read(remindersRepositoryProvider).approveAutoGift(
            occasionId: occasionId,
            addressId: addressId,
            productId: proposalJson['product']?['id'] as int?,
          );
      if (context.mounted) {
        ref.invalidate(occasionDetailProvider(occasionId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderId != null ? 'Gift approved! Order #$orderId confirmed.' : 'Gift approved!')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(remindersRepositoryProvider).parseError(e))),
        );
      }
    }
  }

  Future<void> _rejectAutoGift(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip this gift?'),
        content: const Text('We will not send the suggested gift for this occasion.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Skip gift')),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(remindersRepositoryProvider).rejectAutoGift(occasionId);
    if (context.mounted) {
      ref.invalidate(occasionDetailProvider(occasionId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gift proposal skipped.')));
    }
  }

  Future<int?> _pickAddress(BuildContext context, List<AddressModel> addresses) {
    if (addresses.length == 1) return Future.value(addresses.first.id);

    return showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Delivery address'),
        children: addresses
            .map(
              (a) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, a.id),
                child: Text('${a.label} — ${a.streetAddress}, ${a.city}'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AutoGiftApprovalCard extends StatelessWidget {
  const _AutoGiftApprovalCard({
    required this.proposal,
    required this.onApprove,
    required this.onReject,
  });

  final AutoGiftProposalModel proposal;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SpoilColors.blush.withOpacity(0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auto-gift ready for approval', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'We picked ${proposal.product.name} for ${proposal.recipientName}\'s ${proposal.occasionTypeLabel.toLowerCase()}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatZar(proposal.product.basePrice)} · Deliver ${proposal.deliveryDate}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.teal),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onReject, child: const Text('Skip')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: onApprove, child: const Text('Approve & send')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}