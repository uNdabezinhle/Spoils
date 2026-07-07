import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../../orders/screens/paystack_webview_screen.dart';
import '../data/subscriptions_repository.dart';
import '../models/subscription_models.dart';
import '../providers/subscriptions_provider.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final subsAsync = ref.watch(mySubscriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
        ),
        title: const Text('Subscriptions'),
      ),
      body: RefreshIndicator(
        color: SpoilColors.teal,
        onRefresh: () async {
          ref.invalidate(subscriptionPlansProvider);
          ref.invalidate(mySubscriptionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: SpoilColors.cream,
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: SpoilColors.teal),
                title: const Text('Your box'),
                subtitle: const Text('See past & upcoming subscription deliveries'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/subscriptions/box'),
              ),
            ),
            const SizedBox(height: 16),
            subsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
              ),
              error: (e, _) => Text('Could not load your subscriptions.\n$e'),
              data: (subs) {
                if (subs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'No active subscriptions yet. Pick a plan below to spoil someone every month.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your plans', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...subs.map((sub) => _ActiveSubscriptionCard(subscription: sub)),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            Text('Available plans', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            plansAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SpoilColors.teal))),
              error: (e, _) => Text('Could not load plans.\n$e'),
              data: (plans) => Column(
                children: plans
                    .map(
                      (plan) => _PlanCard(
                        plan: plan,
                        onSubscribe: () => _subscribe(context, ref, plan),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, WidgetRef ref, SubscriptionPlanModel plan) async {
    final activeIds = (ref.read(mySubscriptionsProvider).valueOrNull ?? [])
        .where((s) => s.isActive && s.plan.id == plan.id)
        .map((s) => s.plan.id)
        .toSet();
    if (activeIds.contains(plan.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have an active subscription to this plan.')),
      );
      return;
    }

    String recipientName = '';
    if (plan.needsRecipient) {
      recipientName = await _showRecipientDialog(context, plan) ?? '';
      if (!context.mounted) return;
      if (recipientName.isEmpty) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Subscribe to ${plan.name}?'),
          content: Text(
            '${formatZar(plan.priceMonthly)}/month — ${plan.tagline.isNotEmpty ? plan.tagline : plan.description}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Subscribe')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final repo = ref.read(subscriptionsRepositoryProvider);
    try {
      final payment = await repo.initiateSubscribe(
        planId: plan.id,
        recipientName: recipientName,
      );
      if (!context.mounted) return;

      if (payment.demoMode) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Demo payment'),
            content: Text(
              'Paystack is in demo mode. Confirm subscription payment of ${formatZar(payment.amount)}?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
            ],
          ),
        );
        if (confirmed != true) return;
        await repo.verifySubscribe(
          subscriptionId: payment.subscriptionId,
          reference: payment.reference,
        );
      } else if (payment.authorizationUrl != null) {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackWebViewScreen(
              authorizationUrl: payment.authorizationUrl!,
              onPaymentComplete: (reference) => repo.verifySubscribe(
                subscriptionId: payment.subscriptionId,
                reference: reference,
              ),
            ),
          ),
        );
        if (success != true) return;
      } else {
        throw Exception('Payment could not be started.');
      }

      if (context.mounted) {
        ref.invalidate(mySubscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscribed to ${plan.name}!')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.parseError(e))),
        );
      }
    }
  }

  Future<String?> _showRecipientDialog(BuildContext context, SubscriptionPlanModel plan) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Subscribe to ${plan.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${formatZar(plan.priceMonthly)}/month',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SpoilTextField(
              controller: controller,
              label: 'Who are you spoiling?',
              hint: 'Name of recipient',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, name);
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}

class _ActiveSubscriptionCard extends ConsumerWidget {
  const _ActiveSubscriptionCard({required this.subscription});

  final UserSubscriptionModel subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = subscription;
    final billing = sub.nextBillingDate;
    final billingLabel = billing != null
        ? (DateTime.tryParse(billing) != null
            ? DateFormat('d MMM yyyy').format(DateTime.parse(billing))
            : billing)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: sub.isActive ? SpoilColors.cream : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(sub.plan.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                _StatusChip(status: sub.status),
              ],
            ),
            if (sub.recipientName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('For ${sub.recipientName}', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (billingLabel != null) ...[
              const SizedBox(height: 4),
              Text('Next billing: $billingLabel', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (sub.isActive) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Cancel subscription'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: Text('Cancel ${subscription.plan.name}? You can re-subscribe anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel plan')),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(subscriptionsRepositoryProvider);
    try {
      await repo.cancelSubscription(subscription.id);
      if (context.mounted) {
        ref.invalidate(mySubscriptionsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription cancelled.')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repo.parseError(e))));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'active' => 'Active',
      'pending_payment' => 'Pending payment',
      'paused' => 'Paused',
      'cancelled' => 'Cancelled',
      _ => status,
    };
    final color = switch (status) {
      'active' => SpoilColors.teal,
      'cancelled' => SpoilColors.charcoalMuted,
      'pending_payment' => SpoilColors.gold,
      _ => SpoilColors.gold,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSubscribe});

  final SubscriptionPlanModel plan;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.imageUrl.isNotEmpty)
            Image.network(
              plan.imageUrl,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 140,
                color: SpoilColors.blush,
                child: const Icon(Icons.card_giftcard, size: 48, color: SpoilColors.teal),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                if (plan.tagline.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(plan.tagline, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.teal)),
                ],
                const SizedBox(height: 8),
                Text(
                  '${formatZar(plan.priceMonthly)}/month',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(plan.description, style: Theme.of(context).textTheme.bodySmall),
                if (plan.features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...plan.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: SpoilColors.teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: Theme.of(context).textTheme.bodySmall)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onSubscribe, child: const Text('Subscribe')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}