import 'package:flutter/material.dart';
import 'selection_card.dart';

class GridSelector extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelected;
  final VoidCallback? onBack;
  final Map<String, int>? counts;
  final bool isDark;

  const GridSelector({
    required this.title,
    required this.items,
    required this.onSelected,
    this.onBack,
    this.counts,
    this.isDark = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxCount = counts?.values.fold(0, (a, b) => (a ?? 0) > (b ?? 0) ? a : b) ?? 0;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: items.length < 6 ? 2 : 3, // Responsive columns
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return SelectionCard(
                label: item,
                onTap: () => onSelected(item),
                count: counts?[item],
                maxCount: maxCount,
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}
