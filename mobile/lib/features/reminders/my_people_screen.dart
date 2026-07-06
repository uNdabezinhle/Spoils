import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/spoil_text_field.dart';
import 'models/recipient_model.dart';
import 'providers/reminders_provider.dart';

class MyPeopleScreen extends ConsumerWidget {
  const MyPeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientsAsync = ref.watch(recipientsProvider);
    final upcomingAsync = ref.watch(upcomingOccasionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My People')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        backgroundColor: SpoilColors.teal,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add someone'),
      ),
      body: recipientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Could not load your people.\n$e'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(recipientsProvider),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (recipients) {
          if (recipients.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: 'My People',
              subtitle:
                  'Never miss a birthday or anniversary again. Add the people you love — we\'ll remind you in time to spoil them.',
              action: ElevatedButton(
                onPressed: () => _openForm(context, ref),
                child: const Text('Add someone special'),
              ),
            );
          }

          return RefreshIndicator(
            color: SpoilColors.teal,
            onRefresh: () async {
              ref.invalidate(recipientsProvider);
              ref.invalidate(upcomingOccasionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                upcomingAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (upcoming) {
                    if (upcoming.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coming up', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ...upcoming.take(5).map((o) => _UpcomingCard(occasion: o)),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                Text('Your people', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...recipients.map((r) => _RecipientCard(
                      recipient: r,
                      onEdit: () => _openForm(context, ref, recipient: r),
                      onDelete: () => _confirmDelete(context, ref, r),
                      onShop: () => context.go('/shop'),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, {RecipientModel? recipient}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RecipientFormSheet(recipient: recipient),
    ).then((_) {
      ref.invalidate(recipientsProvider);
      ref.invalidate(upcomingOccasionsProvider);
    });
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, RecipientModel recipient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove person?'),
        content: Text('Remove ${recipient.name} and their occasions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && recipient.id != null) {
      await ref.read(recipientFormProvider.notifier).remove(recipient.id!);
    }
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.occasion});

  final UpcomingOccasionModel occasion;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(occasion.date);
    final dateLabel = date != null ? DateFormat('d MMM').format(date) : occasion.date;
    final countdown = occasion.daysUntil <= 0
        ? 'Today!'
        : occasion.daysUntil == 1
            ? 'Tomorrow'
            : 'In ${occasion.daysUntil} days';

    return Card(
      color: SpoilColors.cream,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.celebration_outlined, color: SpoilColors.gold),
        title: Text('${occasion.recipientName} — ${occasion.typeLabel}'),
        subtitle: Text('$dateLabel · $countdown'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/shop'),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.recipient,
    required this.onEdit,
    required this.onDelete,
    required this.onShop,
  });

  final RecipientModel recipient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final nextOccasion = recipient.occasions.isNotEmpty ? recipient.occasions.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: SpoilColors.blush,
                  child: Text(
                    recipient.name.isNotEmpty ? recipient.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: SpoilColors.teal, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipient.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(recipient.relationship, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                    if (value == 'shop') onShop();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'shop', child: Text('Find a gift')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            if (nextOccasion != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: SpoilColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    '${nextOccasion.typeLabel} · ${nextOccasion.date} · remind ${nextOccasion.reminderDaysBefore}d before',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (recipient.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(recipient.notes, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecipientFormSheet extends ConsumerStatefulWidget {
  const _RecipientFormSheet({this.recipient});

  final RecipientModel? recipient;

  @override
  ConsumerState<_RecipientFormSheet> createState() => _RecipientFormSheetState();
}

class _RecipientFormSheetState extends ConsumerState<_RecipientFormSheet> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _notesController = TextEditingController();
  String _occasionType = 'birthday';
  int _reminderDays = 14;
  DateTime? _occasionDate;
  bool _popiaConsent = false;
  bool _saving = false;

  static const _occasionTypes = {
    'birthday': 'Birthday',
    'anniversary': 'Anniversary',
    'just_because': 'Just Because',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.recipient;
    if (r != null) {
      _nameController.text = r.name;
      _relationshipController.text = r.relationship;
      _notesController.text = r.notes;
      _popiaConsent = r.popiaConsent;
      if (r.occasions.isNotEmpty) {
        final o = r.occasions.first;
        _occasionType = o.type;
        _reminderDays = o.reminderDaysBefore;
        _occasionDate = DateTime.tryParse(o.date);
      }
    } else {
      _occasionDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occasionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'When is the occasion?',
    );
    if (picked != null) setState(() => _occasionDate = picked);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name.')));
      return;
    }
    if (!_popiaConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please consent to store this information (POPIA).')),
      );
      return;
    }
    if (_occasionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose an occasion date.')));
      return;
    }

    setState(() => _saving = true);
    final occasion = OccasionModel(
      type: _occasionType,
      date: DateFormat('yyyy-MM-dd').format(_occasionDate!),
      reminderDaysBefore: _reminderDays,
      notes: _notesController.text.trim(),
    );
    final existingOccasions = widget.recipient?.occasions ?? [];
    final occasions = existingOccasions.isEmpty
        ? [occasion]
        : [occasion, ...existingOccasions.skip(1)];

    final model = RecipientModel(
      id: widget.recipient?.id,
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim().isEmpty ? 'Loved one' : _relationshipController.text.trim(),
      notes: _notesController.text.trim(),
      popiaConsent: _popiaConsent,
      occasions: occasions,
    );

    final ok = await ref.read(recipientFormProvider.notifier).save(model);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.recipient == null ? 'Add someone special' : 'Edit details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SpoilTextField(controller: _nameController, label: 'Name'),
            const SizedBox(height: 12),
            SpoilTextField(controller: _relationshipController, label: 'Relationship', hint: 'Partner, Mom, Friend…'),
            const SizedBox(height: 16),
            Text('Occasion', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _occasionType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _occasionTypes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _occasionType = v ?? 'birthday'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _occasionDate != null
                    ? DateFormat('d MMMM yyyy').format(_occasionDate!)
                    : 'Choose date',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            Text('Remind me', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7d')),
                ButtonSegment(value: 14, label: Text('14d')),
                ButtonSegment(value: 21, label: Text('21d')),
              ],
              selected: {_reminderDays},
              onSelectionChanged: (s) => setState(() => _reminderDays = s.first),
            ),
            const SizedBox(height: 12),
            SpoilTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'Loves plants, favourite colours…',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _popiaConsent,
              onChanged: (v) => setState(() => _popiaConsent = v ?? false),
              title: const Text(
                'I consent to Spoil storing this information to send me occasion reminders (POPIA).',
                style: TextStyle(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: SpoilColors.teal,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.recipient == null ? 'Save person' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}