import 'package:flutter/material.dart';

class TimelineItem {
  final String title;
  final String description;
  final DateTime date;
  final Color? color;
  final IconData? icon;

  const TimelineItem({
    required this.title,
    required this.description,
    required this.date,
    this.color,
    this.icon,
  });
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> items;

  const TimelineWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Column
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.date.hour}:${item.date.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.date.day}/${item.date.month}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Line and Dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color ?? Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50, // Minimum height between items
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), // Spacing between items
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
