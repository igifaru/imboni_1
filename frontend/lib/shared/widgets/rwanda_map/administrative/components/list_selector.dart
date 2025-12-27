import 'package:flutter/material.dart';

class ListSelector extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelected;
  final VoidCallback? onBack;

  const ListSelector({
    required this.title,
    required this.items,
    required this.onSelected,
    this.onBack,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(items[index]),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => onSelected(items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
