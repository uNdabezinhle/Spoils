import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../../auth/models/address_model.dart';
import '../../auth/providers/address_provider.dart';
import '../data/group_gifts_repository.dart';
import '../providers/group_gifts_provider.dart';

class CreateGroupGiftScreen extends ConsumerStatefulWidget {
  const CreateGroupGiftScreen({super.key});

  @override
  ConsumerState<CreateGroupGiftScreen> createState() => _CreateGroupGiftScreenState();
}

class _CreateGroupGiftScreenState extends ConsumerState<CreateGroupGiftScreen> {
  final _titleController = TextEditingController();
  final _recipientController = TextEditingController();
  final _messageController = TextEditingController();
  int? _addressId;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a delivery address.')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(groupGiftsRepositoryProvider);
    try {
      final gift = await repo.createGroupGift(
        title: _titleController.text.trim(),
        addressId: _addressId!,
        deliveryDate: DateFormat('yyyy-MM-dd').format(_deliveryDate),
        recipientName: _recipientController.text.trim(),
        message: _messageController.text.trim(),
      );
      ref.invalidate(myGroupGiftsProvider);
      if (mounted) {
        context.go('/group-gift/${gift.shareToken}');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repo.parseError(e))));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Split with friends')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Invite friends to chip in for a group gift. When fully funded, we place the order automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          SpoilTextField(controller: _titleController, label: 'Gift title', hint: "Mom's birthday hamper"),
          const SizedBox(height: 12),
          SpoilTextField(controller: _recipientController, label: 'Recipient name'),
          const SizedBox(height: 12),
          SpoilTextField(controller: _messageController, label: 'Message to contributors', maxLines: 2),
          const SizedBox(height: 16),
          Text('Delivery address', style: Theme.of(context).textTheme.titleSmall),
          addressesAsync.when(
            loading: () => const LinearProgressIndicator(color: SpoilColors.teal),
            error: (_, __) => const Text('Could not load addresses.'),
            data: (addresses) => Column(
              children: addresses.map((AddressModel a) {
                return RadioListTile<int>(
                  value: a.id!,
                  groupValue: _addressId,
                  onChanged: (v) => setState(() => _addressId = v),
                  title: Text(a.label),
                  subtitle: Text('${a.streetAddress}, ${a.city}'),
                );
              }).toList(),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Delivery date'),
            subtitle: Text(DateFormat('d MMM yyyy').format(_deliveryDate)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deliveryDate,
                firstDate: DateTime.now().add(const Duration(days: 2)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _deliveryDate = picked);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _create,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create group gift'),
          ),
        ],
      ),
    );
  }
}