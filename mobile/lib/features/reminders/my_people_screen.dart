import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/spoil_colors.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/spoil_text_field.dart';
import 'data/reminders_repository.dart';
import 'models/recipient_model.dart';
import 'providers/reminders_provider.dart';
import 'screens/family_calendar_view.dart';
import 'screens/people_calendar_view.dart';

String shopPathForOccasion(String type) => '/shop?occasion=$type';

String occasionPathForId(int id) => '/people/occasion/$id';

class MyPeopleScreen extends ConsumerStatefulWidget {
  const MyPeopleScreen({super.key});

  @override
  ConsumerState<MyPeopleScreen> createState() => _MyPeopleScreenState();
}

class _MyPeopleScreenState extends ConsumerState<MyPeopleScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _query = '';
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipientsAsync = ref.watch(recipientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My People'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SpoilColors.gold,
          labelColor: SpoilColors.teal,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'List'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
            Tab(icon: Icon(Icons.family_restroom_outlined), text: 'Family'),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, ref),
              backgroundColor: SpoilColors.teal,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add someone'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _PeopleListTab(
            recipientsAsync: recipientsAsync,
            searchController: _searchController,
            query: _query,
            onQueryChanged: (value) => setState(() => _query = value),
            onAdd: () => _openForm(context, ref),
            onEdit: (recipient) => _openForm(context, ref, recipient: recipient),
            onDelete: (recipient) => _confirmDelete(context, ref, recipient),
            onImportContacts: () => _importContacts(context, ref),
            onImportCalendar: () => _importCalendar(context, ref),
          ),
          const PeopleCalendarView(),
          const FamilyCalendarView(),
        ],
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
      ref.invalidate(occasionCalendarProvider);
    });
  }

  Future<void> _importContacts(BuildContext context, WidgetRef ref) async {
    final consented = await _confirmPopiaImport(context, 'contacts');
    if (consented != true || !context.mounted) return;

    final service = ref.read(deviceImportServiceProvider);
    final contacts = await service.fetchContacts();
    if (!context.mounted) return;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contacts found or permission denied.')),
      );
      return;
    }

    try {
      final result = await ref.read(remindersRepositoryProvider).importContacts(
            contacts.map((c) => {...c, 'popia_consent': true}).toList(),
          );
      ref.invalidate(recipientsProvider);
      ref.invalidate(upcomingOccasionsProvider);
      ref.invalidate(occasionCalendarProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${result['created']} contacts (${result['skipped']} skipped).')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<void> _importCalendar(BuildContext context, WidgetRef ref) async {
    final consented = await _confirmPopiaImport(context, 'calendar events');
    if (consented != true || !context.mounted) return;

    final service = ref.read(deviceImportServiceProvider);
    final events = await service.fetchCalendarEvents();
    if (!context.mounted) return;
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No calendar events found or permission denied.')),
      );
      return;
    }

    try {
      final result = await ref.read(remindersRepositoryProvider).importCalendarEvents(
            events.map((e) => {...e, 'popia_consent': true}).toList(),
          );
      ref.invalidate(recipientsProvider);
      ref.invalidate(upcomingOccasionsProvider);
      ref.invalidate(occasionCalendarProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${result['occasions_created']} occasions '
              '(${result['recipients_created']} new people, ${result['skipped']} skipped).',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Future<bool?> _confirmPopiaImport(BuildContext context, String source) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Import from $source'),
        content: Text(
          'Spoils will read your device $source to add people and occasions. '
          'You consent to storing this information for reminders (POPIA).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
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

class _PeopleListTab extends ConsumerWidget {
  const _PeopleListTab({
    required this.recipientsAsync,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onImportContacts,
    required this.onImportCalendar,
  });

  final AsyncValue<List<RecipientModel>> recipientsAsync;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAdd;
  final void Function(RecipientModel recipient) onEdit;
  final Future<void> Function(RecipientModel recipient) onDelete;
  final VoidCallback onImportContacts;
  final VoidCallback onImportCalendar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingOccasionsProvider);

    return recipientsAsync.when(
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
          final filtered = recipients.where((r) {
            if (query.isEmpty) return true;
            final q = query.toLowerCase();
            return r.name.toLowerCase().contains(q) ||
                r.relationship.toLowerCase().contains(q) ||
                r.notes.toLowerCase().contains(q);
          }).toList();

          if (recipients.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_outline,
              title: 'My People',
              subtitle:
                  'Never miss a birthday or anniversary again. Add the people you love — we\'ll remind you in time to spoil them.',
              action: ElevatedButton(
                onPressed: onAdd,
                child: const Text('Add someone special'),
              ),
            );
          }

          return RefreshIndicator(
            color: SpoilColors.teal,
            onRefresh: () async {
              ref.invalidate(recipientsProvider);
              ref.invalidate(upcomingOccasionsProvider);
              ref.invalidate(occasionCalendarProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search people…',
                    prefixIcon: const Icon(Icons.search, color: SpoilColors.teal),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              onQueryChanged('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => onQueryChanged(value.trim()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onImportContacts,
                        icon: const Icon(Icons.contacts_outlined, size: 18),
                        label: const Text('Contacts'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onImportCalendar,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: const Text('Calendar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No matches for "$query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filtered.map((r) => _RecipientCard(
                        recipient: r,
                        onEdit: () => onEdit(r),
                        onDelete: () => onDelete(r),
                        onShop: (occasion) => context.go(shopPathForOccasion(occasion)),
                      )),
              ],
            ),
          );
        },
      );
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
        onTap: () => context.push(occasionPathForId(occasion.id)),
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
  final void Function(String occasion) onShop;

  @override
  Widget build(BuildContext context) {
    final activeOccasions = recipient.occasions.where((o) => o.isActive).toList();

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
                    if (value.startsWith('shop:')) onShop(value.split(':').last);
                  },
                  itemBuilder: (_) => [
                    if (activeOccasions.isNotEmpty)
                      PopupMenuItem(
                        value: 'shop:${activeOccasions.first.type}',
                        child: const Text('Find a gift'),
                      )
                    else
                      const PopupMenuItem(value: 'shop:birthday', child: Text('Find a gift')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            if (recipient.occasions.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...recipient.occasions.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: o.id != null ? () => context.push(occasionPathForId(o.id!)) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            o.isActive ? Icons.event_outlined : Icons.notifications_off_outlined,
                            size: 18,
                            color: o.isActive ? SpoilColors.teal : SpoilColors.charcoalSubtle,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${o.typeLabel} · ${o.date} · remind ${o.reminderDaysBefore}d before'
                              '${o.isActive ? '' : ' · paused'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: o.isActive ? null : SpoilColors.charcoalSubtle,
                                  ),
                            ),
                          ),
                          if (o.id != null)
                            const Icon(Icons.chevron_right, size: 18, color: SpoilColors.charcoalSubtle),
                        ],
                      ),
                    ),
                  ),
                ),
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

class _OccasionDraft {
  _OccasionDraft({
    this.id,
    this.type = 'birthday',
    this.date,
    this.reminderDays = 14,
    this.notes = '',
    this.isActive = true,
  });

  int? id;
  String type;
  DateTime? date;
  int reminderDays;
  String notes;
  bool isActive;
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
  final List<_OccasionDraft> _occasions = [];
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
      for (final o in r.occasions) {
        _occasions.add(_OccasionDraft(
          id: o.id,
          type: o.type,
          date: DateTime.tryParse(o.date),
          reminderDays: o.reminderDaysBefore,
          notes: o.notes,
          isActive: o.isActive,
        ));
      }
    }
    if (_occasions.isEmpty) {
      _occasions.add(_OccasionDraft(date: DateTime.now().add(const Duration(days: 30))));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(_OccasionDraft draft) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'When is the occasion?',
    );
    if (picked != null) setState(() => draft.date = picked);
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
    if (_occasions.any((o) => o.date == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a date for each occasion.')));
      return;
    }

    setState(() => _saving = true);
    final occasions = _occasions
        .map(
          (o) => OccasionModel(
            id: o.id,
            type: o.type,
            date: DateFormat('yyyy-MM-dd').format(o.date!),
            reminderDaysBefore: o.reminderDays,
            notes: o.notes,
            isActive: o.isActive,
          ),
        )
        .toList();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Occasions', style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => setState(() => _occasions.add(_OccasionDraft(date: DateTime.now().add(const Duration(days: 30))))),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._occasions.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Occasion ${index + 1}', style: Theme.of(context).textTheme.titleSmall),
                          ),
                          if (_occasions.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: SpoilColors.charcoalMuted),
                              onPressed: () => setState(() => _occasions.removeAt(index)),
                            ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        value: draft.type,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _occasionTypes.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => draft.type = v ?? 'birthday'),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          draft.date != null
                              ? DateFormat('d MMMM yyyy').format(draft.date!)
                              : 'Choose date',
                        ),
                        trailing: const Icon(Icons.calendar_today_outlined),
                        onTap: () => _pickDate(draft),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 7, label: Text('7d')),
                          ButtonSegment(value: 14, label: Text('14d')),
                          ButtonSegment(value: 21, label: Text('21d')),
                        ],
                        selected: {draft.reminderDays},
                        onSelectionChanged: (s) => setState(() => draft.reminderDays = s.first),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: draft.isActive,
                        onChanged: (v) => setState(() => draft.isActive = v),
                        title: const Text('Reminders active', style: TextStyle(fontSize: 13)),
                        activeColor: SpoilColors.teal,
                      ),
                    ],
                  ),
                ),
              );
            }),
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
                'I consent to Spoils storing this information to send me occasion reminders (POPIA).',
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