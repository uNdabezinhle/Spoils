import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/sa_provinces.dart';
import '../../../core/theme/spoil_colors.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../models/address_model.dart';
import '../providers/address_provider.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        backgroundColor: SpoilColors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load addresses: $e')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No saved addresses yet. Add one for faster checkout.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                child: ListTile(
                  title: Text('${address.label}${address.isDefault ? ' (Default)' : ''}'),
                  subtitle: Text('${address.recipientName}\n${address.shortSummary}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _openForm(context, ref, address: address);
                      } else if (value == 'delete') {
                        await ref.read(addressFormProvider.notifier).remove(address.id!);
                        ref.invalidate(addressesProvider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, {AddressModel? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddressFormSheet(address: address),
    ).then((_) => ref.invalidate(addressesProvider));
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  const _AddressFormSheet({this.address});

  final AddressModel? address;

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _suburbController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalController;
  late String _province;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelController = TextEditingController(text: a?.label ?? 'Home');
    _nameController = TextEditingController(text: a?.recipientName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _streetController = TextEditingController(text: a?.streetAddress ?? '');
    _suburbController = TextEditingController(text: a?.suburb ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _postalController = TextEditingController(text: a?.postalCode ?? '');
    _province = a?.province.isNotEmpty == true ? a!.province : SaProvinces.all.first;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _suburbController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final model = AddressModel(
      id: widget.address?.id,
      label: _labelController.text.trim(),
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      streetAddress: _streetController.text.trim(),
      suburb: _suburbController.text.trim(),
      city: _cityController.text.trim(),
      province: _province,
      postalCode: _postalController.text.trim(),
      isDefault: _isDefault,
    );
    final ok = await ref.read(addressFormProvider.notifier).save(model);
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.address == null ? 'Add delivery address' : 'Edit address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SpoilTextField(controller: _labelController, label: 'Label', hint: 'Home, Work…'),
              const SizedBox(height: 12),
              SpoilTextField(controller: _nameController, label: 'Recipient name'),
              const SizedBox(height: 12),
              SpoilTextField(controller: _phoneController, label: 'Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              SpoilTextField(controller: _streetController, label: 'Street address'),
              const SizedBox(height: 12),
              SpoilTextField(controller: _suburbController, label: 'Suburb'),
              const SizedBox(height: 12),
              SpoilTextField(controller: _cityController, label: 'City'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _province,
                decoration: const InputDecoration(labelText: 'Province'),
                items: SaProvinces.all.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => setState(() => _province = v!),
              ),
              const SizedBox(height: 12),
              SpoilTextField(controller: _postalController, label: 'Postal code'),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Set as default address'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('Save address')),
            ],
          ),
        ),
      ),
    );
  }
}