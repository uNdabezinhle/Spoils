import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/spoil_colors.dart';
import '../providers/reminders_provider.dart';

class PeopleCalendarView extends ConsumerStatefulWidget {
  const PeopleCalendarView({super.key});

  @override
  ConsumerState<PeopleCalendarView> createState() => _PeopleCalendarViewState();
}

class _PeopleCalendarViewState extends ConsumerState<PeopleCalendarView> {
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

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(
      occasionCalendarProvider((_focusedMonth.year, _focusedMonth.month)),
    );

    return calendarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
      error: (e, _) => Center(child: Text('Could not load calendar.\n$e')),
      data: (calendar) {
        final daysInMonth = calendar.daysInMonth;
        final firstWeekday = DateTime(calendar.year, calendar.month, 1).weekday;
        final leading = firstWeekday - 1;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
                Text(calendar.monthName, style: Theme.of(context).textTheme.titleMedium),
                IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
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
                return InkWell(
                  onTap: hasEvents
                      ? () => context.push('/people/occasion/${events.first.id}')
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: hasEvents ? SpoilColors.tealTint : null,
                      borderRadius: BorderRadius.circular(8),
                      border: hasEvents ? Border.all(color: SpoilColors.teal.withOpacity(0.3)) : null,
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
                            decoration: const BoxDecoration(color: SpoilColors.teal, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('This month', style: Theme.of(context).textTheme.titleMedium),
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
                    subtitle: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/people/occasion/${e.id}'),
                  ),
                ),
              );
            }),
            if (calendar.events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No occasions this month. Add someone in My People.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}