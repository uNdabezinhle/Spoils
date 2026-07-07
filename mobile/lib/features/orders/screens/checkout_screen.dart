import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../auth/models/address_model.dart';
import '../../auth/providers/address_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../loyalty/providers/loyalty_provider.dart';
import '../data/order_repository.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import 'paystack_webview_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _selectedAddressId;
  String _deliveryType = 'standard';
  DateTime? _deliveryDate;
  final _promoController = TextEditingController();
  CheckoutPreview? _preview;
  bool _loadingPreview = false;
  bool _paying = false;
  String? _error;
  bool _usePoints = false;
  int _pointsToRedeem = 0;

  @override
  void initState() {
    super.initState();
    _deliveryDate = DateTime.now().add(const Duration(days: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  String get _deliveryDateStr => DateFormat('yyyy-MM-dd').format(_deliveryDate!);

  Future<void> _refreshPreview() async {
    setState(() {
      _loadingPreview = true;
      _error = null;
    });
    try {
      final preview = await ref.read(orderRepositoryProvider).previewCheckout(
            deliveryType: _deliveryType,
            promoCode: _promoController.text.trim().isEmpty ? null : _promoController.text.trim(),
            pointsToRedeem: _usePoints ? _pointsToRedeem : 0,
          );
      if (mounted) {
        setState(() {
          _preview = preview;
          _loadingPreview = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = ref.read(orderRepositoryProvider).parseError(e);
          _loadingPreview = false;
        });
      }
    }
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'When should we deliver?',
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  Future<void> _pay() async {
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
      );
      return;
    }
    if (_deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a delivery date.')),
      );
      return;
    }

    setState(() => _paying = true);
    final repo = ref.read(orderRepositoryProvider);
    final promo = _promoController.text.trim();

    try {
      final payment = await repo.initiateCheckout(
        addressId: _selectedAddressId!,
        deliveryDate: _deliveryDateStr,
        deliveryType: _deliveryType,
        promoCode: promo.isEmpty ? null : promo,
        pointsToRedeem: _usePoints ? _pointsToRedeem : 0,
      );

      if (!mounted) return;

      if (payment.demoMode) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Demo payment'),
            content: Text(
              'Paystack is in demo mode. Confirm payment of ${formatZar(payment.amount)}?',
            ),
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
        await _verifyAndComplete(payment.orderId, payment.reference);
      } else if (payment.authorizationUrl != null) {
        setState(() => _paying = false);
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackWebViewScreen(
              authorizationUrl: payment.authorizationUrl!,
              onPaymentComplete: (reference) => _verifyAndComplete(payment.orderId, reference),
            ),
          ),
        );
        if (success != true && mounted) setState(() => _paying = false);
      } else {
        throw Exception('Payment could not be started.');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.parseError(e))),
        );
        setState(() => _paying = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() => _paying = false);
      }
    }
  }

  Future<void> _verifyAndComplete(int orderId, String reference) async {
    final repo = ref.read(orderRepositoryProvider);
    try {
      await repo.verifyPayment(reference: reference, orderId: orderId);
      ref.invalidate(cartProvider);
      ref.invalidate(ordersProvider);
      if (mounted) {
        context.go('/orders/confirmation/$orderId');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.parseError(e))),
        );
        setState(() => _paying = false);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load addresses: $e')),
        data: (addresses) {
          if (_selectedAddressId == null) {
            AddressModel? pick;
            for (final a in addresses) {
              if (a.isDefault) {
                pick = a;
                break;
              }
            }
            pick ??= addresses.isNotEmpty ? addresses.first : null;
            if (pick?.id != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _selectedAddressId == null) {
                  setState(() => _selectedAddressId = pick!.id);
                }
              });
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text('Delivery address', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (addresses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('Add a delivery address to continue.'),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => context.push('/profile/addresses'),
                                child: const Text('Add address'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...addresses.map((a) => _AddressTile(
                            address: a,
                            groupValue: _selectedAddressId,
                            onTap: () => setState(() => _selectedAddressId = a.id),
                          )),
                    const SizedBox(height: 24),
                    Text('Delivery date', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined, color: SpoilColors.teal),
                        title: Text(
                          _deliveryDate != null
                              ? DateFormat('EEEE, d MMMM yyyy').format(_deliveryDate!)
                              : 'Choose a date',
                        ),
                        subtitle: const Text('We deliver nationwide across South Africa'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickDeliveryDate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Delivery speed', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _DeliveryOption(
                      title: 'Standard',
                      subtitle: '3–5 business days · ${formatZar('79')}',
                      selected: _deliveryType == 'standard',
                      onTap: () {
                        setState(() => _deliveryType = 'standard');
                        _refreshPreview();
                      },
                    ),
                    const SizedBox(height: 8),
                    _DeliveryOption(
                      title: 'Express',
                      subtitle: '1–2 business days · ${formatZar('149')}',
                      selected: _deliveryType == 'express',
                      onTap: () {
                        setState(() => _deliveryType = 'express');
                        _refreshPreview();
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Promo code', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. SPOIL10',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _loadingPreview ? null : _refreshPreview,
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 24),
                    Consumer(
                      builder: (context, ref, _) {
                        final loyalty = ref.watch(loyaltyAccountProvider);
                        return loyalty.when(
                          data: (account) {
                            if (account.balance <= 0) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Spoil Points', style: Theme.of(context).textTheme.titleMedium),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Use ${account.balance} points'),
                                  subtitle: const Text('100 points = R10 off'),
                                  value: _usePoints,
                                  onChanged: (v) {
                                    setState(() {
                                      _usePoints = v;
                                      _pointsToRedeem = v ? account.balance : 0;
                                    });
                                    _refreshPreview();
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    _OrderSummary(preview: _preview, loading: _loadingPreview),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _paying || addresses.isEmpty || _preview == null ? null : _pay,
                      child: _paying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _preview != null
                                  ? 'Pay ${formatZar(_preview!.total)}'
                                  : 'Pay now',
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.groupValue,
    required this.onTap,
  });

  final AddressModel address;
  final int? groupValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == address.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? SpoilColors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: RadioListTile<int>(
          value: address.id!,
          groupValue: groupValue,
          onChanged: (_) => onTap(),
          title: Text('${address.label}${address.isDefault ? ' (Default)' : ''}'),
          subtitle: Text('${address.recipientName}\n${address.shortSummary}'),
          isThreeLine: true,
          activeColor: SpoilColors.teal,
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? SpoilColors.teal : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? SpoilColors.teal : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.preview, required this.loading});

  final CheckoutPreview? preview;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: SpoilColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (loading && preview == null)
              const Center(child: CircularProgressIndicator(color: SpoilColors.teal))
            else if (preview != null) ...[
              _SummaryRow(label: 'Subtotal', value: formatZar(preview!.subtotal)),
              _SummaryRow(label: 'Delivery', value: formatZar(preview!.deliveryFee)),
              if (double.tryParse(preview!.discount) != null && double.parse(preview!.discount) > 0)
                _SummaryRow(
                  label: 'Discount',
                  value: '-${formatZar(preview!.discount)}',
                  valueColor: SpoilColors.teal,
                ),
              if (preview!.pointsToRedeem > 0)
                _SummaryRow(
                  label: 'Points (${preview!.pointsToRedeem})',
                  value: '-${formatZar(preview!.pointsDiscount)}',
                  valueColor: SpoilColors.teal,
                ),
              const Divider(),
              _SummaryRow(
                label: 'Total',
                value: formatZar(preview!.total),
                bold: true,
              ),
              if (preview!.demoMode) ...[
                const SizedBox(height: 8),
                Text(
                  'Demo mode — no real charge.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.gold),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: style?.copyWith(
              fontWeight: bold ? FontWeight.w700 : null,
              color: valueColor ?? (bold ? SpoilColors.teal : null),
            ),
          ),
        ],
      ),
    );
  }
}