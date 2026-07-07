import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../providers/group_gifts_provider.dart';

class GroupGiftDetailScreen extends ConsumerWidget {
  const GroupGiftDetailScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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