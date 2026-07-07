import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../../orders/screens/paystack_webview_screen.dart';
import '../data/group_gifts_repository.dart';
import '../providers/group_gifts_provider.dart';

class GroupGiftContributeScreen extends ConsumerStatefulWidget {
  const GroupGiftContributeScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<GroupGiftContributeScreen> createState() => _GroupGiftContributeScreenState();
}

class _GroupGiftContributeScreenState extends ConsumerState<GroupGiftContributeScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _paying = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _contribute() async {
    final repo = ref.read(groupGiftsRepositoryProvider);
    setState(() => _paying = true);
    try {
      final payment = await repo.initiateContribution(
        token: widget.token,
        amount: _amountController.text.trim(),
        contributorName: _nameController.text.trim(),
        contributorEmail: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;

      if (payment.demoMode) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Demo payment'),
            content: Text('Confirm contribution of ${formatZar(payment.amount)}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
            ],
          ),
        );
        if (confirmed != true) {
          setState(() => _paying = false);
          return;
        }
        await repo.verifyContribution(contributionId: payment.contributionId, reference: payment.reference);
      } else if (payment.authorizationUrl != null) {
        setState(() => _paying = false);
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackWebViewScreen(
              authorizationUrl: payment.authorizationUrl!,
              onPaymentComplete: (reference) => repo.verifyContribution(
                contributionId: payment.contributionId,
                reference: reference,
              ),
            ),
          ),
        );
      }

      ref.invalidate(groupGiftByTokenProvider(widget.token));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for chipping in!')));
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repo.parseError(e))));
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final giftAsync = ref.watch(groupGiftByTokenProvider(widget.token));

    return Scaffold(
      appBar: AppBar(title: const Text('Chip in')),
      body: giftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load group gift.\n$e')),
        data: (gift) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(gift.title, style: Theme.of(context).textTheme.titleLarge),
            if (gift.recipientName.isNotEmpty)
              Text('For ${gift.recipientName}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: gift.progressPercent / 100, color: SpoilColors.teal),
            const SizedBox(height: 8),
            Text(
              '${formatZar(gift.amountCollected)} of ${formatZar(gift.targetAmount)} raised',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SpoilTextField(controller: _nameController, label: 'Your name'),
            const SizedBox(height: 12),
            SpoilTextField(controller: _emailController, label: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            SpoilTextField(
              controller: _amountController,
              label: 'Amount (max ${formatZar(gift.remainingAmount)})',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            SpoilTextField(controller: _messageController, label: 'Message (optional)', maxLines: 2),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _paying || !gift.isOpen ? null : _contribute,
              child: _paying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Contribute'),
            ),
          ],
        ),
      ),
    );
  }
}