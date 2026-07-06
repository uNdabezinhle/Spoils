import 'package:flutter/material.dart';

import '../../core/theme/spoil_colors.dart';
import '../../features/orders/models/order_model.dart';

class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.timeline});

  final List<OrderTimelineStep> timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order tracking', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...timeline.asMap().entries.map((entry) {
              final step = entry.value;
              final isLast = entry.key == timeline.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        step.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: step.completed ? SpoilColors.teal : Colors.grey,
                        size: 22,
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: step.completed ? SpoilColors.teal : Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Text(
                        step.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: step.completed ? FontWeight.w600 : FontWeight.normal,
                              color: step.completed ? SpoilColors.charcoal : Colors.grey,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}