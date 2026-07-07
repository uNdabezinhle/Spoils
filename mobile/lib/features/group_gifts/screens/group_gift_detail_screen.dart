import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/group_gifts_repository.dart';
import '../providers/group_gifts_provider.dart';

class GroupGiftDetailScreen extends ConsumerWidget {
  const GroupGiftDetailScreen({super.key, required this.token});

  final String token;

  Future<void> _cancelGift(BuildContext context, WidgetRef ref, int giftId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel group gift?'),
        content: const Text('Contributors will be refunded. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel gift')),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(groupGiftsRepositoryProvider);
    try {
      await repo.cancelGroupGift(giftId);
      ref.invalidate(groupGiftByTokenProvider(token));
      ref.invalidate(myGroupGiftsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group gift cancelled and refunds issued.')));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repo.parseError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final giftAsync = ref.watch(groupGiftByTokenProvider(token));

    return Scaffold(
      appBar: AppBar(title: const Text('Group gift')),
      body: giftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load group gift.\n$e')),
        data: (gift) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(gift.title, style: Theme.of(context).textTheme.titleLarge),
            if (gift.recipientName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Spoiling ${gift.recipientName}', style: Theme.of(context).textTheme.bodyMedium),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: gift.progressPercent / 100, color: SpoilColors.teal, minHeight: 8),
            const SizedBox(height: 8),
            Text(
              '${formatZar(gift.amountCollected)} of ${formatZar(gift.targetAmount)} · ${gift.progressPercent}%',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (gift.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(gift.message, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 24),
            if (gift.isOpen) ...[
              ElevatedButton(
                onPressed: () => context.push('/group-gift/$token/contribute'),
                child: const Text('Chip in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  final link = 'spoils://group-gift/$token';
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share link copied!')));
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Copy share link'),
              ),
              if (isAuthenticated) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _cancelGift(context, ref, gift.id),
                  child: const Text('Cancel & refund contributors', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ] else
              Text(
                gift.status == 'ordered' ? 'Fully funded — order placed!' : 'This group gift is ${gift.status}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (gift.contributions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Contributors', style: Theme.of(context).textTheme.titleMedium),
              ...gift.contributions.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.contributorName),
                  trailing: Text(formatZar(c.amount)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}