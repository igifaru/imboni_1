import 'package:flutter/material.dart';

class ListSelector extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelected;
  final VoidCallback? onBack;
  final Map<String, int>? counts;

  const ListSelector({
    required this.title,
    required this.items,
    required this.onSelected,
    this.onBack,
    this.counts,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Header with back button and title
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final count = counts?[item] ?? 0;
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(item),
                  subtitle: count > 0 
                      ? Text('$count cases', style: TextStyle(color: theme.colorScheme.primary))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCountColor(count),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => onSelected(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getCountColor(int count) {
    if (count >= 10) return const Color(0xFFF44336); // High
    if (count >= 5) return const Color(0xFFFF9800); // Medium
    return const Color(0xFF4CAF50); // Low
  }
}
