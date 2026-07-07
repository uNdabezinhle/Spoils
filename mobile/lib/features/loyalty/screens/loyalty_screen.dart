import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyAccountProvider);
    final historyAsync = ref.watch(loyaltyHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Spoil Points'),
      ),
      body: RefreshIndicator(
        color: SpoilColors.teal,
        onRefresh: () async {
          ref.invalidate(loyaltyAccountProvider);
          ref.invalidate(loyaltyHistoryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            accountAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
              error: (e, _) => Text('Could not load points.\n$e'),
              data: (account) => Card(
                color: SpoilColors.cream,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('${account.balance}', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: SpoilColors.teal)),
                      Text('Spoil Points available', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${account.lifetimeEarned} earned all time · 100 pts = R10 off',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: SpoilColors.teal)),
              error: (_, __) => const Text('Could not load history.'),
              data: (entries) {
                if (entries.isEmpty) {
                  return const Text('Earn points every time you spoil someone — 1 point per R1 spent.');
                }
                return Column(
                  children: entries.map((entry) {
                    final date = DateTime.tryParse(entry.createdAt);
                    final label = date != null ? DateFormat('d MMM yyyy').format(date) : entry.createdAt;
                    final sign = entry.points >= 0 ? '+' : '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.description.isNotEmpty ? entry.description : entry.entryType),
                      subtitle: Text(label),
                      trailing: Text(
                        '$sign${entry.points}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: entry.points >= 0 ? SpoilColors.teal : SpoilColors.charcoalMuted,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}