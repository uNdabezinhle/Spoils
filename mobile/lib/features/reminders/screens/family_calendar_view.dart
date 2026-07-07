import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../data/reminders_repository.dart';
import '../models/recipient_model.dart';
import '../providers/reminders_provider.dart';

class FamilyCalendarView extends ConsumerStatefulWidget {
  const FamilyCalendarView({super.key});

  @override
  ConsumerState<FamilyCalendarView> createState() => _FamilyCalendarViewState();
}

class _FamilyCalendarViewState extends ConsumerState<FamilyCalendarView> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  Future<void> _leaveFamily(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave family group?'),
        content: const Text('Your shared occasions will no longer appear on the family calendar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(remindersRepositoryProvider).leaveFamilyGroup();
      ref.invalidate(familyGroupProvider);
      ref.invalidate(familyCalendarProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left family group.')));
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(remindersRepositoryProvider).parseError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(familyGroupProvider);

    return groupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
      error: (e, _) => Center(child: Text('Could not load family group.\n$e')),
      data: (group) {
        if (group == null) {
          return _FamilyOnboarding(onCreated: () => ref.invalidate(familyGroupProvider));
        }

        final calendarAsync = ref.watch(
          familyCalendarProvider((_focusedMonth.year, _focusedMonth.month)),
        );

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: SpoilColors.cream,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Invite code: ${group.inviteCode}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy invite code',
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: group.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite code copied.')),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      '${group.members.length} member${group.members.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SpoilColors.charcoalMuted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _leaveFamily(context, ref),
                      child: const Text('Leave family group'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            calendarAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: SpoilColors.teal))),
              error: (e, _) => Text('Could not load family calendar.\n$e'),
              data: (calendar) => _FamilyMonthGrid(
                calendar: calendar,
                onPrev: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FamilyOnboarding extends ConsumerStatefulWidget {
  const _FamilyOnboarding({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_FamilyOnboarding> createState() => _FamilyOnboardingState();
}

class _FamilyOnboardingState extends ConsumerState<_FamilyOnboarding> {
  final _nameController = TextEditingController(text: 'My Family');
  final _codeController = TextEditingController();
  bool _busy = false;
  bool _joinMode = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final repo = ref.read(remindersRepositoryProvider);
    try {
      if (_joinMode) {
        final code = _codeController.text.trim();
        if (code.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an invite code.')));
          return;
        }
        await repo.joinFamilyGroup(code);
      } else {
        await repo.createFamilyGroup(_nameController.text.trim().isEmpty ? 'My Family' : _nameController.text.trim());
      }
      widget.onCreated();
      ref.invalidate(familyCalendarProvider);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.parseError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.family_restroom_outlined, size: 48, color: SpoilColors.teal),
          const SizedBox(height: 16),
          Text('Shared family calendar', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'See birthdays and anniversaries your family has chosen to share. Surprise mode stays hidden.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Create')),
              ButtonSegment(value: true, label: Text('Join')),
            ],
            selected: {_joinMode},
            onSelectionChanged: (s) => setState(() => _joinMode = s.first),
          ),
          const SizedBox(height: 16),
          if (_joinMode)
            SpoilTextField(
              controller: _codeController,
              label: 'Invite code',
              hint: 'e.g. ABC123',
            )
          else
            SpoilTextField(controller: _nameController, label: 'Family name', hint: 'The Mokoena Family'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_joinMode ? 'Join family' : 'Create family'),
          ),
        ],
      ),
    );
  }
}

class _FamilyMonthGrid extends StatelessWidget {
  const _FamilyMonthGrid({
    required this.calendar,
    required this.onPrev,
    required this.onNext,
  });

  final FamilyCalendarMonthModel calendar;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = calendar.daysInMonth;
    final firstWeekday = DateTime(calendar.year, calendar.month, 1).weekday;
    final leading = firstWeekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
            Text(calendar.monthName, style: Theme.of(context).textTheme.titleMedium),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((d) => Expanded(child: Center(child: Text(d, style: Theme.of(context).textTheme.bodySmall))))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: leading + daysInMonth,
          itemBuilder: (_, index) {
            if (index < leading) return const SizedBox.shrink();
            final day = index - leading + 1;
            final key = DateFormat('yyyy-MM-dd').format(DateTime(calendar.year, calendar.month, day));
            final events = calendar.events[key] ?? [];
            final hasEvents = events.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: hasEvents ? SpoilColors.blush.withOpacity(0.4) : null,
                borderRadius: BorderRadius.circular(8),
                border: hasEvents ? Border.all(color: SpoilColors.gold.withOpacity(0.4)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$day', style: TextStyle(fontWeight: hasEvents ? FontWeight.w700 : FontWeight.w500)),
                  if (hasEvents)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(color: SpoilColors.gold, shape: BoxShape.circle),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text('Shared occasions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...calendar.events.entries.expand((entry) {
          final date = DateTime.tryParse(entry.key);
          final label = date != null ? DateFormat('d MMM').format(date) : entry.key;
          return entry.value.map(
            (e) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.celebration_outlined, color: SpoilColors.gold),
                title: Text('${e.recipientName} — ${e.typeLabel}'),
                subtitle: Text('$label · ${e.ownerEmail}'),
              ),
            ),
          );
        }),
        if (calendar.events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No shared occasions this month. Turn on "Share with family" on an occasion to include it here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}